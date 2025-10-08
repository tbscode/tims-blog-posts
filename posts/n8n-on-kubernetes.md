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
      encryption_key: "<SUPER_LONG_SECURE_KEY>"
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

### Install/upgrade commands

Run with your `kubeconfig.yaml` and a dedicated namespace:

```bash
KUBECONFIG=./kubeconfig.yaml kubectl create ns n8n
KUBECONFIG=./kubeconfig.yaml helm uninstall n8n -n n8n
KUBECONFIG=./kubeconfig.yaml helm upgrade --install n8n oci://8gears.container-registry.com/library/n8n --namespace n8n -f n8n-values.yaml
```

After the release becomes `READY`, n8n should be reachable at `https://n8s.<your-domain>` (or your configured host).

### Hardening checklist

- Switch to Postgres for production and enable persistent volumes.
- Keep `secure_cookie: true` and TLS on end-to-end; n8n stores credentials for integrations.
- Limit ingress access (e.g., IP allowlists) if you only need the editor from trusted networks.
- Set `N8N_USER_MANAGEMENT_DISABLED=false` and create dedicated users; enable 2FA on your IdP if applicable.

### About the chart authors

The chart is maintained by the 8gears team and contributors. The repository is here: [`8gears/n8n-helm-chart`](https://github.com/8gears/n8n-helm-chart). They’ve done a great job exposing n8n’s core options (readiness/liveness probes, deployment strategies, webhook and worker modes, and Redis/Valkey integration) in a clean values structure.

That’s it—small, clean, and easy to back up. Perfect fit for a self-hosted automation hub.
