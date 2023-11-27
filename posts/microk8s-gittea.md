---
title: "Self-Hosted Git Server with Gitea on Kubernetes"
description: "This guide will demonstrate how you can effortlessly host Gitea on a private Kubernetes cluster and utilize it as a package registry."
date: "2023-09-26T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes", "Gitea", "Helm"]
---

> Are you tired of overpriced package registries? Rapidly deploy your own git and package registry - with [Gitea](https://about.gitea.com/) - using [their helm chart](https://gitea.com/gitea/helm-chart).

### Prerequisites

This post assumes that you have a `microk8s` cluster set up with `cert-manager`, `ingress`, and `dns` configured, and a cluster issuer `letsencrypt-prod` ready.

> To get started, feel free to follow my [Blog Post on Microk8s Private Cluster Setup](/blog/microk8s-on-vps).

## Setting it Up

> **Please note** - This is meant for a quick temporary private package. There is **no persistence intended.**

For easy installation, you can use [this simple script](https://github.com/tbscode/tims-blog-posts/blob/main/assets/install_gitea_microk8s.sh)

```bash
./install_gitea_microk8s.sh \
  K8_NAMESPACE="<installation-namespace>" \
  RELEASE_NAME="<release-name>" \
  ADMIN_USERNAME="<...>" \
  ADMIN_PASSWORD="<...>" \ 
  INGRESS_HOST="<host-url>"
```

In the above script, `$INGRESS_HOST` represents a subdomain you've configured a DNS entry for, pointing to your server, for instance: `my-git.example.com`.

### Configuration

First, to ensure that this doesn't consume too many resources, we disable the high-availability database and use the default one instead.

```bash
microk8s helm install $RELEASE_NAME gitea-charts/gitea \
    -n $K8_NAMESPACE \
    --set postgresql-ha.enabled=false \
    --set postgresql.enabled=true \
```

Next, we establish some credentials for our default admin user:

```bash
    --set gitea.admin.username="$ADMIN_USERNAME" \
    --set gitea.admin.password="$ADMIN_PASSWORD" \
```

We then enable and configure the ingress. Please note we are increasing the `proxy-body-size` to 1GB to allow us to push larger packages.
```bash
    --set ingress.enabled=true \
    --set "ingress.annotations.kubernetes\.io/ingress\.class=public" \
    --set "ingress.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod" \
    --set "ingress.annotations.nginx\.ingress\.kubernetes\.io/proxy-body-size=1g" \
    --set ingress.hosts[0].host="$INGRESS_HOST" \
    --set ingress.hosts[0].paths[0].path=/ \
    --set ingress.hosts[0].paths[0].pathType=Prefix \
    --set ingress.tls[0].secretName="git.$RELEASE_NAME-tls" \
    --set ingress.tls[0].hosts[0]="$INGRESS_HOST" \
```

> To make packages of the admin user private, sign in at `$INGRESS_HOST`, navigate to Settings > Profile > Visibility, and set it to Private.

### Uploading a Package

You can push a package to a path under your Gitea user as follows:

```bash
echo "<your-admin-password" | docker login $INGRESS_HOST -u <your-gitea-admin> --password-stdin
docker tag <image-id> $INGRESS_HOST/<your-gitea-admin>/<some-package-name>
```
### Authenticating Deployments for Pulling Images

It's essential to authorize your deployments to pull your private container images. You can create a simple image pull secret in your Helm chart as outlined below.

```yaml
kind: Secret
type: kubernetes.io/dockerconfigjson
apiVersion: v1
metadata:
  name: dockerconfigjson-github-com
  namespace: {{ .Values.rootNamespace }}
stringData:
  .dockerconfigjson: >
    {{
      (
        dict "auths"
        (
          dict "$INGRESS_HOST"
          (
            dict "auth" .Values.registryAuth.token
          )
        )
      )
      |
      toJson
    }}
{{- end }}
```

> If you're using Github packages, for instance, `$INGRESS_HOST` would be `ghcr.io`

Create a token by Base64 encoding the `user:password` string:

```bash
echo "<gitea-admin>:<gitea-admin-password" | base64
```
This will allow you to pull from your private repositories.

### Setting up gitea action runners via helm

