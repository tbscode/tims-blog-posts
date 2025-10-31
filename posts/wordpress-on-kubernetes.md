---
title: "WordPress on Kubernetes with TrueCharts (short guide)"
description: "Set up WordPress on a self-hosted Kubernetes cluster using the TrueCharts Helm chart."
date: "2025-10-03"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "CMS"]
tags: ["Kubernetes", "Helm", "TrueCharts", "WordPress", "Ingress", "TLS"]
---

A quick, repeatable way to run WordPress on Kubernetes using the maintained TrueCharts chart. Small footprint, TLS via cert-manager, and a clean ingress.

### Chart

The TrueCharts WordPress chart ships via OCI and builds on the TrueCharts common library for consistent values and sane defaults.

- Chart page: [truecharts.org/charts/stable/wordpress](https://truecharts.org/charts/stable/wordpress/)

```bash
helm install wp oci://oci.trueforge.org/truecharts/wordpress \
  --namespace blogging \
  --create-namespace \
  -f values.wordpress.yaml
```

### Example values

Sanitize domains, credentials, and secret names for the target setup.

```yaml
ingress:
  main:
    enabled: true
    ingressClassName: public
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
    hosts:
      - host: wp.<your-domain>
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts: [wp.<your-domain>]
        secretName: wp-<your-domain>-tls

wordpress:
  user: "<admin-username>"
  pass: "<strong-password>"

workload:
  main:
    replicas: 1
    podSpec:
      containers:
        main:
          env:
            WORDPRESS_EXTRA_WP_CONFIG_CONTENT: |
              define('WP_HOME','https://wp.<your-domain>');
              define('WP_SITEURL','https://wp.<your-domain>');

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "4"
    memory: "8Gi"
```

Notes:

- Ensure `ingress` and `cert-manager` are installed and a `ClusterIssuer` named `letsencrypt-prod` exists.
- Set DNS for `wp.<your-domain>` to the ingress IP. After install, visit `https://wp.<your-domain>`.
- TrueCharts maintains a broad catalog and a shared common chart, providing consistent configuration across apps; the WordPress chart is kept up-to-date and is straightforward to automate.


