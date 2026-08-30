---
title: "vLLM + LiteLLM on AMD Strix Halo"
description: "Serving Qwen3.8-27B (INT4 AWQ) and Qwen3-4B (FP16) with vLLM on my two-node k3s cluster, fronted by a LiteLLM OpenAI-compatible router."
date: "2026-08-08"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["AI", "DevOps"]
tags: ["vLLM", "LLM", "Kubernetes", "k3s", "AMD", "ROCm", "LiteLLM", "Self-Hosting"]
---

## vLLM + LiteLLM on AMD Strix Halo

This is a follow-up to [my private LLM cluster post](https://blog.t1m.me/blog/building-own-private-kuberntes-ai-cluster);
meanwhile I've replaced the Ollama serving layer with vLLM on the same two Bosgame mini PCs (Ryzen AI MAX+ 395 / Radeon 8060S, 96 GiB unified LPDDR5X each).
The initial cluster set-up (NixOS, k3s over the tailnet, kubeconfig, cert-manager) is all covered in that post, so this one is only about the vLLM layer itself.

Each node has exactly one GPU, so I run one model per node:
the 27B model (the "brain") gets its own node so nothing shares its memory bandwidth;
the 4B model (the "fast worker") shares its node with the LiteLLM router and Postgres, which are CPU-only.
Clients (opencode, agents, scripts) all hit one OpenAI-compatible endpoint through LiteLLM.

### Why quantization is the decision on an APU

The Radeon 8060S is an APU; CPU and GPU share one pool of 96 GiB LPDDR5X.
Huge memory capacity for the price, but bandwidth is the hard wall; effective achievable bandwidth on these machines is ~125 GB/s, and token generation is 100% memory-bandwidth-bound:

```
max decode tok/s ≈ memory bandwidth ÷ model weight size (in bytes)
```

Every generated token streams the entire weight matrix through memory once. That single formula dictates everything below:

| Quantization | Weights | Peak decode (math) | Measured (27B) |
|---|---|---|---|
| BF16 (~2 B/param) | ~54 GB | ~2.5–4.5 tok/s | — |
| FP8 (W8A8, 1 B/param) | ~28.5 GiB | ~5–9 tok/s | 0.6 tok/s (eager, plus SW overhead) |
| INT4 AWQ (W4A16, 0.5 B/param) | 16.8 GiB loaded | ~9–17 tok/s | ~7 tok/s (bandwidth saturated) |

So on a bandwidth-starved APU, halving the weight bytes doubles your decode speed, nearly for free.
FP8 buys nothing here if the kernels aren't hardware-accelerated; INT4 AWQ is the sweet spot for 27B-class models.
For reference the 4B at FP16 (~8 GB weights) hits ~27 tok/s on the same memory, right at the bandwidth ceiling for its size.

### Node preparation

One node-specific thing that cost me two days: kernel pinning.
Both nodes were on `linuxPackages_latest`, which jumped 6.19 to 7.1.3, and kernel 7.x changed the `/sys/class/kfd` topology format enough that the AMD GPU device plugin could no longer resolve `drm_render_minor`; it marked the GPU unhealthy and silently stopped advertising `amd.com/gpu` entirely.
The fix is pinning a kernel the plugin understands (6.12 and 6.6 also work):

```nix
boot.kernelPackages = pkgs.linuxPackages_6_18;  # = 6.18.38
```

> On GPU nodes the kernel is part of your driver contract with the device plugin. Pin it deliberately, never let "latest" upgrade it silently.

After rebuild and reboot (rebuild does not reboot; `uname -r` still shows the old kernel), sanity-check the host before blaming Kubernetes:

```bash
ls -la /dev/kfd /dev/dri/         # expect kfd + card + renderD
rocm-smi                          # device 0x1586 with VRAM/temperature
rocminfo | grep -A4 "Agent 2"     # expect gfx1151, "Device Type: GPU", 40 CUs, 98304 MB
dmesg | grep -iE "amdgpu|kfd" | tail
```

If `rocminfo` lists the GPU agent on the host, your driver stack is fine; anything failing later is a Kubernetes/plugin problem.

### The AMD GPU device plugin, and the pitfall that breaks it

This was the hardest part of the whole setup, so read it even if you think your plugin "is fine".

Install the official chart (as of writing `amd-gpu` 0.21.0 with plugin image `rocm/k8s-device-plugin:1.31.0.9`):

```bash
helm repo add amd-gpu-helm https://rocm.github.io/k8s-device-plugin/
helm repo update

helm upgrade --install amd-gpu amd-gpu-helm/amd-gpu \
  --namespace kube-system \
  --kubeconfig ./kubeconfig.yaml
```

#### Chart defaults cannot see the GPU

The default DaemonSet runs the plugin non-privileged with `capabilities: { drop: [ALL] }` and mounts only `/sys` and the kubelet device-plugins dir.
On gfx1151 that's fatal: the plugin must read the GPU's KFD topology node, and inside a capability-stripped container that read fails with a silent I/O error, even though the same file reads fine on the host.

The plugin logs look like this:

```
E amdgpu.go:120] Topology property not found.  Regex: drm_render_minor\s(\d+)
I plugin.go:233] Found 1 AMDGPUs          # fallback finds it, but...
```

...and the kubelet journal shows a registration loop that produces zero advertised capacity:

```
E client.go:94] "ListAndWatch ended unexpectedly for device plugin" err="EOF" resource="amd.com/gpu"
```

#### Fix: privileged + proper device mounts

Patch the DaemonSet to run privileged with the device nodes mounted (mirroring the repo's own `k8s-ds-amdgpu-dp.yaml`):

```bash
export KUBECONFIG=./kubeconfig.yaml

# give the container /dev and /sys visibility it needs
kubectl -n kube-system patch ds amd-gpu-device-plugin-daemonset --type=strategic -p '{
  "spec":{"template":{"spec":{"containers":[{"name":"amd-gpu-dp-cntr","volumeMounts":[
    {"name":"dev-dri","mountPath":"/dev/dri"},
    {"name":"dev-kfd","mountPath":"/dev/kfd"},
    {"name":"kfd-sys","mountPath":"/sys/class/kfd"}
  ]}],"volumes":[
    {"name":"dev-dri","hostPath":{"path":"/dev/dri","type":"Directory"}},
    {"name":"dev-kfd","hostPath":{"path":"/dev/kfd","type":"CharDevice"}},
    {"name":"kfd-sys","hostPath":{"path":"/sys/class/kfd","type":"Directory"}}
  ]}}}}
'

# run privileged (drop-ALL cannot read GPU kfd sysfs on gfx1151)
kubectl -n kube-system patch ds amd-gpu-device-plugin-daemonset --type=json -p='[
 {"op":"replace","path":"/spec/template/spec/containers/0/securityContext",
  "value":{"privileged":true,"allowPrivilegeEscalation":true}}
]'

kubectl -n kube-system rollout status ds/amd-gpu-device-plugin-daemonset
```

> Note these patches are live-only; the next `helm upgrade` of `amd-gpu` reverts them. Bake them into your `values.yaml` or GitOps flow.

#### Verifying, and the jsonpath trap

The resource key `amd.com/gpu` contains a dot, which silently breaks naive jsonpath queries; I "confirmed" a healthy GPU was missing for a full debugging session because of this:

```bash
# wrong, splits on dots and prints <none> even when advertised
kubectl get node -o custom-columns=NAME:.metadata.name,GPU:.status.capacity.amd.com/gpu

# correct, parse the JSON properly
kubectl get nodes -o json | jq '.items[] |
  {name: .metadata.name,
   gpu_capacity:   .status.capacity["amd.com/gpu"],
   gpu_allocatable:.status.allocatable["amd.com/gpu"]}'
# → {"name":"amd-node-1","gpu_capacity":"1","gpu_allocatable":"1"} (per node)
```

Also worth checking: the plugin container can now read the topology
(`grep drm_render_minor /sys/class/kfd/kfd/topology/nodes/1/properties` inside the plugin pod),
and the kubelet's device manager has the device registered
(`strings /var/lib/kubelet/device-plugins/kubelet_internal_checkpoint`).

### Choosing the models & quantizations

#### The big model: `philbert440/Qwen3.8-27B-W4A16-AWQ` (INT4, W4A16)

Qwen3.8-27B is a hybrid-attention model (3:1 linear-attention/Gated-DeltaNet to full-attention, native 262 144-token context). What I evaluated:

| Repo | Format | Verdict |
|---|---|---|
| `Qwen/Qwen3.8-27B` | BF16, 360 GB | won't fit meaningfully |
| `Qwen/Qwen3.8-27B-FP8` | FP8 W8A8, 28.5 GiB | fits, but 0.6 tok/s, bandwidth-hungry kernels |
| `amd/Qwen3.8-27B-Quark-AWQ-INT4-W4A16` | Quark INT4, 19.5 GB | `quant_method: quark` crashes vLLM 0.23.0's loader |
| `philbert440/Qwen3.8-27B-W4A16-AWQ` | compressed-tensors INT4, 16.8 GiB loaded | works, ~11x faster decode than FP8 |

Details that matter: the checkpoint uses `compressed-tensors` (`pack-quantized`, 4-bit, group 128), which vLLM loads via `TritonW4A16LinearKernel`.
I kept the served name `qwen38-27b-fp8` for LiteLLM compatibility, though it's a misnomer now since it's INT4.
The model supports 262 144 tokens natively; I cap serving at 65 536.

#### The small model: `Qwen/Qwen3-4B-Instruct-2507` (FP16)

A dense 4B instruct model; at ~8 GB in FP16 it's already at the small end of the bandwidth optimum, and quantizing further buys little while costing quality.
Native context is 262 144; I serve 131 072 (128K), which needs the `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1` escape hatch.

Both models run on the same vLLM image even though the 4B is classic `Qwen3ForCausalLM` and the 27B is the newer hybrid GDN architecture; the hybrid one just needs a newer `transformers` (pinned in the manifest below).

### Model caches on the nodes (the fast-restart trick)

A cold vLLM start does two expensive things inside the container's ephemeral filesystem:

1. downloads the model from Hugging Face (~5 min for 19 GB, if the CDN cooperates; unauthenticated downloads are rate-limited and stall regularly), and
2. JIT-compiles dozens of Triton kernels for your exact GPU + shapes, ~40–45 min on this APU!

Both live in `/root/.cache` (HF hub + vLLM compile cache) and `/root/.triton`.
Mounting both on node-local `hostPath` volumes (via `DirectoryOrCreate`, see the manifests) turns a ~50-minute cold start into a ~2-minute warm start, and the pod survives node reboots with zero re-work.

One more habit worth having: the `huggingface_hub` downloader occasionally deadlocks mid-shard on a stalled connection that never times out (a `*.incomplete` blob that stops growing).
If that happens, bypass the downloader: get the shard's expected SHA from the HF API, `curl -L` the `resolve/main/...` URL into the cache's `blobs/` under that SHA256 name, symlink it into the `snapshots/` layout, delete the partials;
then set `HF_HUB_OFFLINE=1` so vLLM never touches the network again.

### The vLLM pod manifests

I run bare `Pod` objects (not Deployments) pinned with `nodeName`, because each model owns its node's entire GPU and the caches are node-local.
Two consequences to accept consciously:

- `restartPolicy: Never` + a node reboot means pods land in `UnexpectedAdmissionError` / `ContainerStatusUnknown` and must be deleted + re-applied (a 2-minute operation with warm caches).
- A `hostPath` cache is node-bound; moving a pod to the other node means full cold start. Choose the node per model and stay put.

#### The 27B INT4 coder

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vllm-qwen38-27b-pod-exp
  namespace: vllm
  labels:
    app: vllm-qwen38-27b-pod-exp
spec:
  nodeName: <NODE-B>              # pin: this node's GPU is dedicated
  restartPolicy: Never
  containers:
    - name: vllm
      image: vllm/vllm-openai-rocm:v0.23.0
      command: ["/bin/bash", "-lc"]
      args:
        - |
          # qwen3_5 architecture needs transformers 5.x; PIN it, a floating
          # --upgrade can break the engine on any upstream release.
          pip install -q transformers==5.15.0 && \
          vllm serve philbert440/Qwen3.8-27B-W4A16-AWQ \
            --host 0.0.0.0 \
            --port 8000 \
            --served-model-name qwen38-27b-fp8 \
            --dtype auto \
            --max-model-len 65536 \
            --max-num-seqs 8 \
            --max-num-batched-tokens 8192 \
            --limit-mm-per-prompt '{"image":0,"video":0}' \
            --skip-mm-profiling \
            --kv-cache-dtype fp8 \
            --enable-prefix-caching \
            --gpu-memory-utilization 0.95 \
            --enforce-eager \
            --enable-auto-tool-choice \
            --tool-call-parser hermes \
            --reasoning-parser qwen3
      ports:
        - containerPort: 8000
      volumeMounts:
        - name: triton-cache
          mountPath: /root/.triton      # Triton JIT cache (40 min to seconds)
        - name: root-cache
          mountPath: /root/.cache       # HF weights + vLLM compile cache
      resources:
        requests:
          amd.com/gpu: "1"
          cpu: "6"
          memory: 20Gi
        limits:
          amd.com/gpu: "1"
          cpu: "10"
          memory: 30Gi
  volumes:
    - name: triton-cache
      hostPath:
        path: /var/cache/vllm-qwen38-27b/triton
        type: DirectoryOrCreate
    - name: root-cache
      hostPath:
        path: /var/cache/vllm-qwen38-27b/root-cache
        type: DirectoryOrCreate
```

The flags that actually matter:

| Flag | Why |
|---|---|
| `--max-model-len 65536` | 64K covers coding agents with huge system prompts; the KV pool still fits 31x concurrent 64K sessions |
| `--kv-cache-dtype fp8` | doubles KV capacity, to 2 057 557 tokens of cache |
| `--enable-prefix-caching` | agents re-send identical system prompts; cached-prefix TTFT drops from ~13 s to 0.86 s |
| `--enforce-eager` | v0.23.0's inductor+CUDAGraph path hangs forever on gfx1151 (100% CPU, GPU idle). Eager is the reliable path; overhead is ~1% here anyway since decode is bandwidth-bound |
| `--reasoning-parser qwen3` | without it, thinking models emit `think` markers into `content` and clients like opencode break; this splits them into `reasoning_content` |
| `pip install transformers==5.15.0` | image ships 4.x; the hybrid arch needs 5.x, and it must stay pinned |

Expected engine report on boot:

```
Available KV cache memory: 72.13 GiB
GPU KV cache size: 2,057,557 tokens
Maximum concurrency for 65,536 tokens per request: 31.40x
```

#### The 128K fast worker

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vllm-qwen3-4b-instruct-2507-pod-exp
  namespace: vllm
  labels:
    app: vllm-qwen3-4b-instruct-2507-pod-exp
spec:
  nodeName: <NODE-A>
  restartPolicy: Never
  containers:
    - name: vllm
      image: vllm/vllm-openai-rocm:v0.23.0
      command: ["/bin/bash", "-lc"]
      args:
        - |
          vllm serve Qwen/Qwen3-4B-Instruct-2507 \
            --host 0.0.0.0 \
            --port 8000 \
            --served-model-name qwen3-4b-instruct-2507 \
            --dtype float16 \
            --max-model-len 131072 \
            --max-num-seqs 4 \
            --max-num-batched-tokens 2048 \
            --enforce-eager \
            --gpu-memory-utilization 0.90 \
            --enable-prefix-caching \
            --enable-auto-tool-choice \
            --tool-call-parser hermes
      env:
        - name: HF_HUB_DOWNLOAD_TIMEOUT
          value: "30"
        - name: HF_HUB_OFFLINE          # boot from the local cache only,
          value: "1"                    # the HF downloader can deadlock
        - name: VLLM_ALLOW_LONG_MAX_MODEL_LEN
          value: "1"                    # required for >32K on this model
      ports:
        - containerPort: 8000
      volumeMounts:
        - name: triton-cache
          mountPath: /root/.triton
        - name: root-cache
          mountPath: /root/.cache
      resources:
        requests:
          amd.com/gpu: "1"
          cpu: "4"
          memory: 16Gi
        limits:
          amd.com/gpu: "1"
          cpu: "8"
          memory: 24Gi
  volumes:
    - name: triton-cache
      hostPath:
        path: /var/cache/vllm-qwen3-4b/triton
        type: DirectoryOrCreate
    - name: root-cache
      hostPath:
        path: /var/cache/vllm-qwen3-4b/root-cache
        type: DirectoryOrCreate
```

Expected: `GPU KV cache size: 570,224 tokens`, ~4.35x concurrency at 131K.

#### Services

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vllm-qwen38-27b-pod-exp
  namespace: vllm
spec:
  selector:
    app: vllm-qwen38-27b-pod-exp
  ports:
    - name: http
      port: 8000
      targetPort: 8000
```

...same shape for the 4B pod with `name/selector: vllm-qwen3-4b-instruct-2507-pod-exp`.

### Deploying & first boot

```bash
kubectl create namespace vllm
kubectl -n vllm apply -f vllm-qwen38-27b.yaml
kubectl -n vllm apply -f vllm-qwen3-4b.yaml
kubectl -n vllm apply -f vllm-services.yaml

# watch the first boot, expect ~40-50 min (Triton JIT dominates), one time only:
kubectl -n vllm logs -f vllm-qwen38-27b-pod-exp | grep -E \
  "Loading weights|KV cache|init engine|Application startup"
```

Every restart after the first reads weights + Triton cache from the hostPath volumes and reaches `Application startup complete` in ~2 minutes.
Useful habit: the pods have no readinessProbe, so k8s shows `1/1 Running` while the engine is still warming; trust the log line, not the phase.

Smoke-test directly:

```bash
kubectl -n vllm port-forward svc/vllm-qwen38-27b-pod-exp 18000:8000 &
curl -s http://localhost:18000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen38-27b-fp8","messages":[{"role":"user","content":"Say ok"}],"max_tokens":5}'
```

### LiteLLM: the OpenAI-compatible router

LiteLLM sits in front of both vLLM pods (plus any cloud fallbacks) and exposes one endpoint, one auth model, per-key quotas, spend tracking and retries.
Same helm chart as in [the cluster post](https://blog.t1m.me/blog/building-own-private-kuberntes-ai-cluster); the only vLLM-specific wiring is the `api_base`, in-cluster DNS straight to each pod's Service, and `api_key: none` because vLLM runs unauthenticated inside the cluster (LiteLLM is the auth layer).

Values file (`litellm-vllm.values.yaml`, secrets redacted; UI admin + provider keys go in via `environmentSecrets`/`extraResources` as before):

```yaml
masterkey: sk-<REDACTED>

db:
  deployStandalone: true                # in-cluster postgres
  useExisting: false

ingress:
  enabled: true
  className: traefik
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-<your-issuer>
  hosts:
    - host: litellm.<your-domain>
      paths: [{ path: /, pathType: Prefix }]
  tls:
    - hosts: [litellm.<your-domain>]
      secretName: litellm-tls

proxy_config:
  general_settings:
    master_key: os.environ/PROXY_MASTER_KEY
    store_model_in_db: true
  litellm_settings:
    drop_params: true
    request_timeout: 600                # LLM calls are slow; don't time out at 60 s
  router_settings:
    num_retries: 2
    routing_strategy: usage-based-routing
    timeout: 600

  model_list:
    # NOTE: input/output costs below are electricity estimates
    # (~300 W APU @ $0.33/kWh), not API prices.
    - model_name: qwen38-27b-fp8_vllm          # 27B INT4 AWQ (name kept from FP8 era)
      litellm_params:
        api_base: http://vllm-qwen38-27b-pod-exp.vllm.svc.cluster.local:8000/v1
        api_key: none
        model: openai/qwen38-27b-fp8
        rpm: 60
      model_info:
        input_cost_per_token: 1.5e-07
        output_cost_per_token: 9.0e-07
    - model_name: qwen3-4b-instruct-2507_vllm  # 4B FP16, 128K ctx
      litellm_params:
        api_base: http://vllm-qwen3-4b-instruct-2507-pod-exp.vllm.svc.cluster.local:8000/v1
        api_key: none
        model: openai/qwen3-4b-instruct-2507
        rpm: 120
      model_info:
        input_cost_per_token: 3.0e-08
        output_cost_per_token: 1.5e-07
```

Deploy and verify the router knows both local models:

```bash
helm upgrade --install litellm-vllm oci://docker.litellm.ai/berriai/litellm-helm \
  --version 1.82.3 \
  -n vllm \
  -f litellm-vllm.values.yaml \
  --kubeconfig ./kubeconfig.yaml

kubectl -n vllm exec deploy/litellm-vllm -- \
  curl -s http://localhost:4000/v1/models \
       -H "Authorization: Bearer sk-<MASTER-KEY>" | jq '.data[].id'
```

### End-to-end verification

From any pod with curl (the LiteLLM image ships without one, use a vLLM pod):

```bash
kubectl -n vllm exec vllm-qwen3-4b-instruct-2507-pod-exp -- sh -c '
  curl -s --max-time 90 http://litellm-vllm.vllm.svc.cluster.local:4000/v1/chat/completions \
    -H "Authorization: Bearer sk-<USER-KEY>" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"qwen3-4b-instruct-2507_vllm\",
         \"messages\":[{\"role\":\"user\",\"content\":\"Say ok\"}],
         \"max_tokens\":5}"'
```

Also confirm the reasoning parser is doing its job on the 27B: thinking tokens must arrive in `reasoning_content`, not `content`:

```bash
curl -s http://localhost:18000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen38-27b-fp8",
       "messages":[{"role":"user","content":"What is 17*23?"}],
       "max_tokens":200}' | jq '.choices[0].message | keys'
# → ["content","reasoning_content","role"]
```

And check the GPU is actually being exercised inside the pods with `rocm-smi`.

### Measured performance

All numbers from the live cluster, single stream, `temperature 0`.

The quantization decision, quantified (27B):

| Config | Decode (short ctx) | Decode (8K ctx) | TTFT 4K cold | TTFT cached prefix |
|---|---|---|---|---|
| FP8 W8A8, eager, 8K ctx | 0.6 tok/s | 0.6 tok/s | 73 s | 5.6 s |
| INT4 AWQ, 65K ctx, prefix caching | ~7 tok/s | 3.4–4.4 tok/s | 24.6 s | 0.86 s |

The 4B FP16:

| Metric | Value |
|---|---|
| Decode | ~27 tok/s |
| 12K-token prompt prefill | ~8 s (~1 500 tok/s) |
| 45K-token prompt | ~85 s (532 tok/s prefill) |
| Restart (warm, from caches) | ~2 min (vs ~50 min cold) |

Reality check on the hardware ceiling: 7 tok/s x 16.8 GiB is ~125 GB/s effective bandwidth, the LPDDR5X is the wall, not the software.
The 20–30 tok/s people get from 27B models require discrete-GPU bandwidth; on a 96 GiB APU, a 27B INT4 topping out around 7 tok/s is simply the physics.
Plan accordingly: 27B for quality-bound agent steps, the 4B for interactive loops, and let LiteLLM route between them.

### Debugging notes when things break

A few ideas that saved me, in the order I'd check them:

- Pod stuck in `UnexpectedAdmissionError: no healthy devices present`: the device plugin isn't handing out the GPU. Work top-down: is `amd.com/gpu` advertised at all (with the jq check above), what do the plugin pod logs say, did the kubelet register the device (`kubelet_internal_checkpoint`), and is the kubelet's `ListAndWatch` streaming or EOF-looping (`journalctl -u k3s | grep -i "device plugin"`).
- If a sysfs path reads fine on the host but fails with I/O error inside the plugin container, it's a securityContext/mount problem, not a driver problem.
- vLLM hangs at 100% CPU with GPU idle after KV-cache sizing: that's torch.compile/CUDAGraph capture failing on gfx1151; keep `--enforce-eager`.
- Downloads stall forever mid-shard: unauthenticated HF rate limiting + dead connections; use the curl-and-verify rescue and flip `HF_HUB_OFFLINE=1` permanently after the first successful boot.
- Quantized model crashes on load: check `config.json`'s `quant_method` before downloading 19 GB; prefer standard `compressed-tensors`/`awq` exports over `quark` on current vLLM.
- Clients choke on stray think tokens: add the matching `--reasoning-parser`.
- NixOS `nixos-rebuild` fails with `Errno 28`: the 96 MB ESP filled with per-generation kernels; `nix-collect-garbage -d`, and set `boot.compressor = "zstd"` to keep initrds small.

---

That's the whole vLLM layer now running on the cluster; next up is more routing/benchmark work on top of it.

Cheers Tim
