---
title: "Expose NAT Services Across Two Kubernetes Clusters with Tailscale"
description: "A production-style setup to publish private k3s services through a public microk8s edge cluster using the Tailscale Kubernetes Operator."
date: "2026-05-16T12:00:00+02:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Kubernetes", "Networking"]
tags: ["k3s", "microk8s", "Tailscale", "Ingress", "cert-manager", "NAT"]
---

I use this pattern when I want to keep workloads private in a k3s cluster, but still expose selected services to the public internet through a separate public microk8s edge cluster.

This is a full, production-style walkthrough for exposing a private service across two clusters with Tailscale Kubernetes Operator.

It is tailored to this exact topology:

- Source (private) cluster: k3s, kubeconfig at `kubeconfig-node-A.yaml`
- Public edge cluster: microk8s, kubeconfig at `kubeconfig-node-B.yaml`
- Private app example: service `<app-service>` in k3s namespace `<app-namespace>`
- Public hostname example: `example.server.com`
- TLS issuer on public cluster: `letsencrypt-prod` using ACME HTTP-01

---

## 1. Architecture and Traffic Flow

Goal:

- Keep app workloads private in k3s.
- Publish them safely via public ingress in microk8s.
- Use Tailscale as encrypted inter-cluster transport.

Data path:

1. Client requests `https://example.server.com`.
2. DNS resolves to the public microk8s node IP.
3. microk8s ingress controller (`IngressClass=public`) receives request.
4. Ingress routes to `<app-service>-tailnet` service in microk8s.
5. Tailscale operator egress proxy in microk8s forwards traffic over tailnet.
6. Tailnet reaches the k3s Tailscale-exposed service `<app-hostname-node-a>.<tailnet>.ts.net`.
7. k3s service forwards to the private app pod.

This pattern works for many NAT/internal services, not only one specific app.

---

## 2. Prerequisites

### 2.1 DNS

- `example.server.com` must point to the public microk8s ingress IP.

### 2.2 cert-manager in public cluster

- `cert-manager` installed and healthy.
- `ClusterIssuer` named `letsencrypt-prod` configured for HTTP-01.

Check:

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl get pods -n cert-manager
kubectl get clusterissuer letsencrypt-prod
```

### 2.3 Ingress controller class in microk8s

In this environment, ingress class is `public` (not `nginx`).

Check:

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl get ingressclass
kubectl -n ingress get pods
```

### 2.4 Tailscale operator installed in both clusters

Check:

```bash
export KUBECONFIG=./kubeconfig-node-A.yaml
kubectl get pods -n tailscale

export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl get pods -n tailscale
```

Both should show the operator pod running.

---

## 3. Phase A: Expose Service in k3s (Source Cluster)

You can expose an existing `ClusterIP` service via annotations.

For service `<app-service>` in namespace `<app-namespace>`:

```bash
export KUBECONFIG=./kubeconfig-node-A.yaml
kubectl annotate service <app-service> -n <app-namespace> \
  tailscale.com/expose=true \
  tailscale.com/hostname=<app-hostname-node-a> \
  --overwrite
```

Verify:

```bash
export KUBECONFIG=./kubeconfig-node-A.yaml
kubectl -n <app-namespace> get svc <app-service> -o yaml
kubectl -n tailscale get pods,svc,secrets
```

Expected:

- The source service has `tailscale.com/expose: "true"`.
- A proxy pod appears in `tailscale` namespace (for example `ts-<app-service>-xxxxx-0`).
- A tailnet FQDN is created.

Get tailnet FQDN from secret:

```bash
export KUBECONFIG=./kubeconfig-node-A.yaml
kubectl -n tailscale get secret <proxy-secret-name> -o jsonpath='{.data.device_fqdn}' | base64 -d
```

Example value:

- `<app-hostname-node-a>.taild4f875.ts.net.`

Keep this FQDN. It is the inter-cluster target.

---

## 4. Phase B: Configure microk8s as Public Edge Cluster

Use Tailscale cluster egress mode in microk8s. This is the critical part.

Do not use a plain `ExternalName` directly to `<name>.ts.net` without Tailscale egress annotations. The ingress controller may fail DNS resolution and return `504`.

### 4.1 Manifest

Create `app-proxy.yaml` in the public cluster context with this content:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <app-namespace>
---
apiVersion: v1
kind: Service
metadata:
  name: <app-service>-tailnet
  namespace: <app-namespace>
  annotations:
    tailscale.com/tailnet-fqdn: <app-hostname-node-a>.taild4f875.ts.net
spec:
  type: ExternalName
  externalName: placeholder
  ports:
    - name: http
      port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app-service>-public
  namespace: <app-namespace>
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: public
  tls:
      - hosts:
        - example.server.com
      secretName: example-server-com-tls
  rules:
    - host: example.server.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <app-service>-tailnet
                port:
                  number: 80
```

Apply:

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl apply -f app-proxy.yaml
```

Why `externalName: placeholder` is correct:

- Tailscale operator rewrites `spec.externalName` to an internal service it creates in `tailscale` namespace.
- This enables reliable egress proxying to tailnet targets.

---

## 5. Validation Workflow (End-to-End)

Run these checks in order.

### 5.1 In public cluster, check rewritten egress service

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n <app-namespace> get svc <app-service>-tailnet -o yaml
```

Expected:

- `spec.externalName` changed from `placeholder` to something like `ts-<app-service>-tailnet-xxxxx.tailscale.svc.cluster.local`.
- `status.conditions` includes `TailscaleProxyReady=True`.

### 5.2 Check tailscale proxy objects in public cluster

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n tailscale get pods,svc,secrets
```

Expected:

- pod `ts-<app-service>-tailnet-xxxxx-0` is `Running`.

### 5.3 Check ingress and certificate

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n <app-namespace> get ingress <app-service>-public -o wide
kubectl -n <app-namespace> get certificate,certificaterequest,order,challenge
```

Expected:

- Ingress class shown as `public`.
- Certificate `example-server-com-tls` is `Ready=True`.

### 5.4 In-cluster backend connectivity test

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n <app-namespace> run curlcheck --image=curlimages/curl:8.8.0 --restart=Never --rm -i --command -- sh -c "curl -sS -o /dev/null -w '%{http_code}\n' http://<app-service>-tailnet.<app-namespace>.svc.cluster.local"
```

Expected output:

- `200`

### 5.5 Public test

```bash
curl -I https://example.server.com
```

Expected:

- HTTP `200` (or app-specific expected code), valid TLS chain.

---

## 6. Troubleshooting by Symptom

### 6.1 Symptom: `504 Gateway Time-out`

Most common causes:

- Ingress points to wrong class (`nginx` instead of `public` in this microk8s setup).
- Service is direct `ExternalName -> <name>.ts.net` without `tailscale.com/tailnet-fqdn` egress annotation.
- Tailscale egress proxy pod not created or not ready.

Check ingress logs:

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n ingress logs <nginx-ingress-controller-pod> --tail=200
```

If you see repeated DNS `name error` for tailnet hostname or `placeholder`, your service wiring is incorrect or still converging.

### 6.2 Symptom: TLS cert not issued

Check:

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n <app-namespace> get certificate,certificaterequest,order,challenge
kubectl -n <app-namespace> describe ingress <app-service>-public
```

Common causes:

- `example.server.com` DNS not pointing to public ingress endpoint.
- Wrong `cluster-issuer` name.
- HTTP-01 solver path blocked by firewall/proxy.

### 6.3 Symptom: Ingress serves default cert

Cause:

- `spec.tls[].secretName` mismatched with cert-manager-produced secret.

Fix:

- Ensure `Ingress.spec.tls.secretName` equals certificate secret (for example `example-server-com-tls`).

### 6.4 Symptom: Tailscale operator ignores service

Check:

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n tailscale logs deploy/operator --tail=300
```

If logs show no egress reconciliation for your service, ensure:

- Service is type `ExternalName`.
- Has annotation `tailscale.com/tailnet-fqdn` or `tailscale.com/tailnet-ip`.
- Tailscale operator is healthy.

---

## 7. Operational Best Practices

- Use dedicated namespace per proxied application (for example `<app-namespace>`).
- Use explicit hostnames per service (for example `<app1-hostname-node-a>`, `<app2-hostname-node-a>`).
- Keep private cluster service as `ClusterIP` only; avoid public LB there.
- Terminate public TLS in edge cluster ingress.
- Monitor ingress and tailscale operator logs for DNS and proxy readiness conditions.
- Keep cert-manager issuer names consistent across manifests.

---

## 8. Pattern Reuse for Any NAT Service

To expose another private k3s service through the same public microk8s cluster:

1. Annotate source service in k3s with `tailscale.com/expose=true` and a unique hostname.
2. In microk8s, create annotated `ExternalName` service with `tailscale.com/tailnet-fqdn` to that hostname.
3. Create public ingress for the desired DNS host with `ingressClassName: public`.
4. Attach cert-manager annotation `cert-manager.io/cluster-issuer: letsencrypt-prod`.
5. Validate service rewrite, proxy pod readiness, and certificate readiness.

This gives a repeatable, encrypted cross-cluster edge publishing model.

---

## 9. Reference Commands Cheat Sheet

Source cluster (k3s):

```bash
export KUBECONFIG=./kubeconfig-node-A.yaml
kubectl -n <app-namespace> get svc <app-service> -o yaml
kubectl -n tailscale get pods,svc,secrets
```

Public cluster (microk8s):

```bash
export KUBECONFIG=./kubeconfig-node-B.yaml
kubectl -n <app-namespace> get svc,ingress
kubectl -n <app-namespace> get certificate,certificaterequest,order,challenge
kubectl -n tailscale get pods,svc,secrets
kubectl -n tailscale logs deploy/operator --tail=200
kubectl -n ingress logs <nginx-ingress-controller-pod> --tail=200
```

Public endpoint test:

```bash
curl -I https://example.server.com
```
