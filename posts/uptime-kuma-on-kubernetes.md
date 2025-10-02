---
title: "Self-Hosted Uptime Monitoring on Kubernetes with Uptime-Kuma"
description: "Tiny guide to deploy Uptime-Kuma on a self-hosted Kubernetes cluster using a maintained Helm chart."
date: "2025-10-01"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Monitoring"]
tags: ["Microk8s", "Kubernetes", "Helm", "Uptime-Kuma", "Ingress", "TLS"]
---

Uptime-Kuma is a lightweight status and monitoring dashboard suited for homelabs or lean production clusters. Below is a minimal, repeatable setup to run it behind an ingress with TLS.

### Helm Chart

A maintained chart is available: [dirsigler/uptime-kuma-helm](https://github.com/dirsigler/uptime-kuma-helm), from [`@dirsigler`](https://github.com/dirsigler/uptime-kuma-helm).

```bash
helm repo add uptime-kuma https://helm.irsigler.cloud
helm repo update
helm upgrade my-uptime-kuma uptime-kuma/uptime-kuma \
  --install \
  --namespace monitoring \
  --create-namespace \
  -f values.uptime-kuma.yaml
```

### Preview

The following screenshot shows how Uptime-Kuma presents monitoring data for this blog (`blog.t1m.me`).

![Uptime-Kuma dashboard for blog.t1m.me](/static/assets/uptime-kuma-dashboard.png)

### Example values

Sanitize hosts/secrets for the target environment. This example runs as a `ClusterIP` behind `nginx` and cert-manager.

```yaml
ingress:
  enabled: true
  ingressClassName: public
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: public
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://<your-domain>"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "false"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
    nginx.ingress.kubernetes.io/server-snippets: |
      proxy_buffering off;
      proxy_cache off;
  hosts:
    - host: status.<your-domain>
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: uptime-kuma-tls
      hosts:
        - status.<your-domain>

persistence:
  enabled: true
  size: 5Gi

service:
  type: ClusterIP
  port: 3001

env:
  TZ: Europe/Berlin
```

Notes:

- Keep persistence on; monitors would otherwise need reconfiguration after pod restarts.
- On Microk8s, ensure `ingress` and `cert-manager` are enabled and a `ClusterIssuer` named `letsencrypt-prod` exists.
- The app becomes reachable at `https://status.<your-domain>` after DNS is set.

That’s it—small, stable, and easy to back up. Perfect for keeping a quiet eye on your stack.


