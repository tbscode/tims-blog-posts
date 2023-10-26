---
title: ""
description: "Self Hosted Error Tracking and Reporting using Selntry Kubernetes and Helm"
date: "2023-10-26T16:56:47+06:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Analytics"]
tags: ["Microk8s", "Kubernetes", "Helm", "Sentry"]
---

## Intro 

Sentry is an incredibly nice error tracking tool; it can significantly increase the speed of bug fixing and debugging. It also offers a bunch of other features. You should also check out [their service](https://sentry.io)

Since I like to know how the stuff works and willing to take it appart; I would always prefer to self-host if I can. This also gives me more comfort about controlling my own data which by the way also aids GDPR compliance (though this is also possible using Sentry's service directly).

Fortunately, there [still is a Helm chart](https://github.com/sentry-kubernetes/charts/tree/develop). 
'Still', because for example: [the deprecated Posthog chart](https://github.com/PostHog/charts-clickhouse), but also the originally (officially maintained?) [sentry chart](https://github.com/helm/charts/tree/master/stable/sentry) seems deprecated now.

## Setup

I prepared a script that will:

1. Configure an ingress with a cluster issuer annotation to serve under a specific `$HOSTNAME`
2. Configure a Postgres password
3. Enable session recordings and its interface

## Installation

Use the following script to install Sentry:

```bash
./install_sentry_microk8s.sh \
  K8_NAMESPACE="<installation-namespace>" \
  RELEASE_NAME="<release-name>" \
  SENTRY_HOSTNAME="<...>" \
  SENTRY_HOSTNAME="<...>" \
  POSTGRES_PASSWORD="<...>" \
  SMTP_USERNAME="<...>" \
  SMTP_PASSWORD="<...>" \
  SMTP_PORT="<...>" \
  SMTP_FROM_EMAIL="<...>" \
  SENTRY_ADMIN_EMAIL="<...>" \
  SENTRY_ADMIN_PASSWORD="<...>"
```

I found out about having to set and update the admin Postgres password using a secret; [in this Github issue](https://github.com/sentry-kubernetes/charts/issues/554).
That's why we create a simple secret for the Postgres-password here:

```bash
apiVersion: v1
kind: Secret
metadata:
  name: postgres
  namespace: $K8_NAMESPACE
stringData:
  postgres-password: "$POSTGRES_PASSWORD"
```

For enabling the session feature and directly setting the Python config, I read [over here](https://github.com/getsentry/self-hosted/issues/2057) and [here](https://github.com/getsentry/self-hosted/blob/master/sentry/sentry.conf.example.py) and [here](https://github.com/sentry-kubernetes/charts/issues/918), ending up with:

```yaml
config:
  sentryConfPy: |
    SENTRY_FEATURES["organizations:session-replay"] = True
    SENTRY_FEATURES["organizations:session-replay-ui"] = True
```

Ingress setup follows a pretty standard procedure:

```yaml
nginx:
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    enabled: true
    hostname: $SENTRY_HOSTNAME
    ingressClassName: "public"
    tls: true
    extraTls:
      - hosts:
          - $SENTRY_HOSTNAME
        secretName: sentry-tls
```

As in some of my other scripts, I like to assume the cluster issuer is named `"letsencrypt-prod"`. To me, that's a reasonable sacrifice for adding fewer inputs ;).

Also, **to get the install to succeed** I needed to increase the `hooks.activeDeadlineSeconds`; otherwise, it would time out and the installation would fail.

```yaml
hooks:
  activeDeadlineSeconds: 3500
```

## Open Issues

Currently, I still experience one of the metrics services failing. I'm not sure about the impact yet, but tracking seems to work just fine:

```bash
microk8s kubectl logs sentry-snuba-metrics-consumer -n sentry
snuba.clickhouse.errors.ClickhouseWriterError: Method write is not supported by storage Distributed with more than one shard and no sharding key provided (version 21.8.13.6 (official build))
```

seems like an issue with my storage provisioning possibly; no impact seen so-far.
