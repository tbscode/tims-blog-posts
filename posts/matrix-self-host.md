---
title: "Secure Federated Chat: Self Host Matrix on Kubernetes"
description: "How to self host a Matrix.org server"
date: "2025-11-17T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes", "Gitea", "Helm"]
---

As privacy preserving communication options are vanishing rapidly, there remain only a few options for private secure communication.
While messaging services like Signal promise a good level of security and anonymity, its server is still managed by a corporate entity.

To truly control your own privacy and communication, you should consider joining a Matrix server hosted by a trusted party, or consider hosting one yourself.
This blog post will show how you can quickly setup and deploy a Matrix server on Kubernetes using [ananace's Helm charts](https://gitlab.com/ananace/charts).

### Performing the Helm Install

First, browse through the example values and the templates if required.
I managed to build a very minimal Matrix configuration via:

```bash
export KUBECONFIG=./kubeconfig.yaml 
helm repo add ananace-charts https://ananace.gitlab.io/charts
helm install matrix-synapse ananace-charts/matrix-synapse \
  --set serverName=example.com \
  --set publicServerName=matrix.example.com \
  --set wellknown.enabled=true
```

Or use a values file:

```yaml
serverName: example.com
publicServerName: matrix.example.com
wellknown:
  enabled: true
ingress:
  enabled: true
  tls:
    - secretName: matrix-synapse-crt
      hosts:
        - example.com
        - matrix.example.com
  hosts:
    - matrix.example.com
  className:
  annotations:
    kubernetes.io/ingress.class: "public"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  includeServerName: true
```

Also **you should change the default postgresql credentials**:

```yaml
postgresql:
  enabled: true
  auth:
    password: <db-password>
    username: <db-username>
    database: <db-name>
```

Same things goes for the redis server:

```yaml
redis:
  enabled: true
  password: <new-redis-password>
```

### Configuring Upload and File Size Limits

```yaml
extraConfig:
  max_upload_size: 20M
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "20m"
    nginx.ingress.kubernetes.io/client-max-body-size: "20m"
```

### Creating First User

To be able to login to your Matrix server you'll have to actually register a first user.

##### 1. Retrieve the Main Matrix Pod

```bash
export KUBECONFIG=./kubeconfig.yaml
export NS=<matrix-namespace>
export POD_NAME=$(kubectl get pods --namespace "$NS" \
  -l "app.kubernetes.io/name=matrix-synapse,app.kubernetes.io/instance=matrix-synapse,app.kubernetes.io/component=synapse" \
  -o jsonpath="{.items[0].metadata.name}")
```

##### 2. Run the 'register_new_matrix_user' command

```bash
kubectl exec --namespace "$NS" "$POD_NAME" -- register_new_matrix_user \
  -c /synapse/config/homeserver.yaml \
  -c /synapse/config/conf.d/secrets.yaml \
  -u "<your-user-name>" \
  -p "<your-strong-admin-password>" \
  --admin http://localhost:8008
```

### Setting up Element as Matrix Web-UI

Now you have a Matrix server, [you may connect to it with any client](https://doc.matrix.tu-dresden.de/clients/).
But you might also want to be able to use it directly in the web.

Element Web is the official web client for Matrix and provides a user-friendly interface for accessing your Matrix server through a browser.

To deploy Element Web, you'll need to create a values file that configures the default server URL and ingress settings:

```bash
export KUBECONFIG=./kubeconfig.yaml
helm upgrade --install element-matrix ananace-charts/element-web \
  -f values_element_web.yaml
```

Here's an example `values_element_web.yaml` configuration:

```yaml
defaultServer:
  url: 'https://matrix.example.com'
  name: 'example.com'
ingress:
  enabled: true
  tls:
    - secretName: element-matrix-crt
      hosts:
        - element.example.com
  hosts:
    - element.example.com
  className: "public"
  annotations:
    kubernetes.io/ingress.class: "public"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

Make sure to replace `example.com` with your actual domain and adjust the `defaultServer.url` to point to your Matrix server's public URL.

### Backup Existing Matrix Server

```bash
export NS=default
export KUBECONFIG=./kubeconfig.yaml

# List PVCs
kubectl get pvc -n $NS

# Find PostgreSQL secret
kubectl get secret -n $NS -o name | grep -i postgres

# Get PostgreSQL pod name
export PG_POD=$(kubectl get pods -n $NS -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}')

# Backup database (replace <db-password> with actual password from secret)
kubectl exec -n $NS "$PG_POD" -- sh -lc '
  export PGPASSWORD="<db-password>"
  /opt/bitnami/postgresql/bin/pg_dump -Fc -h 127.0.0.1 -U "<db-user>" "<db-name>"
' > postgres-FULL-$(date +%F).dump
```

### Backup All Matrix Media

```bash
export KUBECONFIG=./kubeconfig.yaml   # adjust path if needed
export NS=default
export RELEASE=matrix-synapse

# Get one synapse pod name
export SYNAPSE_POD=$(kubectl get pods -n $NS -l app.kubernetes.io/name=$RELEASE -o jsonpath='{.items[0].metadata.name}')

# Create tar.gz backup of media directory
kubectl exec -n $NS "$SYNAPSE_POD" -- sh -lc '
  set -e
  cd /synapse/data
  tar czf /tmp/matrix-media-backup.tar.gz media
  echo "Done."
'

# Copy backup from pod to local machine
kubectl cp $NS/$SYNAPSE_POD:/tmp/matrix-media-backup.tar.gz ./matrix-media-backup-$(date +%F).tar.gz
```