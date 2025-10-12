---
title: "Self-Hosted n8n on Kubernetes (Helm chart)"
description: "Minimal, repeatable setup to run n8n with TLS behind nginx ingress using the 8gears Helm chart."
date: "2025-10-08"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Automation"]
tags: ["Kubernetes", "Helm", "n8n", "Ingress", "TLS"]
---

n8n is a flexible, open-source workflow automation tool that runs well on a small self-hosted cluster. Below is a lean, production-minded setup using a maintained Helm chart. This mirrors my usual pattern: keep it simple, make it reproducible, and put it behind ingress with TLS.

### Helm chart

Maintained chart: [`8gears/n8n-helm-chart`](https://github.com/8gears/n8n-helm-chart) — solid defaults, clear values, and active maintenance by the 8gears team. Kudos to the authors and maintainers for keeping queue mode, probes, lifecycle hooks, and ingress settings tidy and well-documented.

> If you’re new to Kubernetes on a VPS, see my Microk8s setup first: [/blog/microk8s-on-vps](/blog/microk8s-on-vps)

### Example values

Sanitize hosts and secrets for your environment. This example uses `ClusterIP` with `nginx` and `cert-manager`.

```yaml
persistence:
  enabled: true

image:
  repository: n8nio/n8n
  pullPolicy: IfNotPresent
ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: n8n.t1m.me
      paths:
        - "/"
  tls:
    - hosts:
        - n8n.t1m.me
      secretName: n8n-example-com-tls
main:
  replicaCount: 1
  deploymentStrategy:
    type: Recreate
  persistence:
    enabled: true
    type: "dynamic"
    mountPath: "/home/node/.n8n"
    storageClass: "<your-default-storage-class>"
    size: 8Gi
    accessModes:
      - ReadWriteOnce
    annotations:
      helm.sh/resource-policy: keep
  nodes:
    builtin:
      enabled: true
      modules:
        - ws
      reinstallMissingPackages: true
  service:
    type: ClusterIP
    port: 5678
  config:
    n8n:
      host: "n8s.<your-domain>"
      protocol: "https"
      port: 5678
      editor_base_url: "https://n8s.<your-domain>"
      webhook_url: "https://n8s.<your-domain>"
      secure_cookie: "true"
      proxy_hops: 1
      log_level: "info"
      diagnostics_enabled: "false"
    db:
      type: "sqlite"
  secret:
    n8n:
      encryption_key: "CENSORED"
scaling:
  enabled: false
  worker:
    replicaCount: 0
  webhook:
    enabled: false
    replicaCount: 0
```

Notes:
- For quick single-node or hobby deployments, `sqlite` is fine. For multi-node or longevity, pick Postgres.
- Set `encryption_key` to a long, random value. Rotating it will invalidate existing encrypted credentials.
- If you want queue mode, enable `scaling.enabled` and configure Redis (internal `valkey` or external Redis) as per the chart docs.
- The `persistence` block ensures your workflows and credentials survive pod restarts.
- `helm.sh/resource-policy: keep` prevents accidental data loss during Helm uninstalls.

### Install/upgrade commands

Run with your `kubeconfig.yaml` and a dedicated namespace:

```bash
KUBECONFIG=./kubeconfig.yaml kubectl create ns n8n
KUBECONFIG=./kubeconfig.yaml helm uninstall n8n -n n8n
KUBECONFIG=./kubeconfig.yaml helm upgrade --install n8n oci://8gears.container-registry.com/library/n8n --namespace n8n -f n8n-values.yaml
```

After the release becomes `READY`, n8n should be reachable at `https://n8n.t1m.me` (or your configured host).

### Verify persistence before going live

**Critical**: Before creating workflows or adding credentials, verify that the persistent volume is working correctly. A failed volume mount means data loss on pod restarts.

Check the pod status and volume mount:

```bash
KUBECONFIG=./kubeconfig.yaml kubectl get pods -n n8n
KUBECONFIG=./kubeconfig.yaml kubectl describe pod -n n8n -l app.kubernetes.io/name=n8n
```

Look for:
- Pod status: `Running`
- Volume mount: `/home/node/.n8n` should be mounted from your PVC
- No volume-related errors in events

Test persistence by creating a simple workflow, restarting the pod, and verifying it still exists:

```bash
# Restart the pod to test persistence
KUBECONFIG=./kubeconfig.yaml kubectl delete pod -n n8n -l app.kubernetes.io/name=n8n
```

If your workflows disappear after the restart, the volume mount failed. Check your storage class and PVC status:

```bash
KUBECONFIG=./kubeconfig.yaml kubectl get pvc -n n8n
KUBECONFIG=./kubeconfig.yaml kubectl describe pvc -n n8n
```

### Credential management via CLI

n8n includes a CLI for bulk credential operations. Access the container and use these commands:

```bash
# Get into the running pod
KUBECONFIG=./kubeconfig.yaml kubectl exec -it -n n8n deployment/n8n -- /bin/sh

# Export all credentials (decrypted)
n8n export:credentials --all --decrypted --output=credentials.json

# Import credentials from file
n8n import:credentials --input=credentials.json
```

This is useful for:
- Backing up credentials before major updates
- Migrating between n8n instances
- Disaster recovery scenarios

**Security note**: The `--decrypted` flag exports credentials in plain text. Handle these files with extreme care and delete them immediately after use.

### Bulk restore / import n8n json workflows

For migrating workflows from another n8n instance or restoring from backups, you can bulk import JSON workflow files directly into your Kubernetes deployment.

Download and run the restoration script:

```bash
curl -fsSL https://raw.githubusercontent.com/tbscode/tims-blog-posts/refs/heads/main/assets/restore_workflow_json_files.sh -o restore_workflow_json_files.sh
chmod +x restore_workflow_json_files.sh
export KUBECONFIG=<your-kubeconfig>
SRC_DIR=<local-dir-containing-workflows>
./restore_workflow_json_files.sh $SRC_DIR
```

The script will:
- Find your running n8n pod automatically
- Upload all `.json` files from the specified directory
- Import each workflow using the n8n CLI
- Provide a summary of successful/failed imports
- Clean up temporary files

This makes it trivial to migrate workflows between n8n instances or restore from backups. The script handles all the Kubernetes complexity, so you just point it at a folder of JSON files.

### Hardening checklist

- Switch to Postgres for production and enable persistent volumes.
- Keep `secure_cookie: true` and TLS on end-to-end; n8n stores credentials for integrations.
- Limit ingress access (e.g., IP allowlists) if you only need the editor from trusted networks.
- Set `N8N_USER_MANAGEMENT_DISABLED=false` and create dedicated users; enable 2FA on your IdP if applicable.
- Regularly backup your persistent volume and test restore procedures.
- Monitor PVC usage to avoid running out of storage space.

### About the chart authors

The chart is maintained by the 8gears team and contributors. The repository is here: [`8gears/n8n-helm-chart`](https://github.com/8gears/n8n-helm-chart). They’ve done a great job exposing n8n’s core options (readiness/liveness probes, deployment strategies, webhook and worker modes, and Redis/Valkey integration) in a clean values structure.

That’s it—small, clean, and easy to back up. Perfect fit for a self-hosted automation hub.
