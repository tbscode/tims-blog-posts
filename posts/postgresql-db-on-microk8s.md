---
title: "Simple Development PostgresDB setup on Microk8s via Helm"
description: "Follow these simple steps to deploy and expose a basic Postgres database from your microk8s cluster."
date: "2021-09-13T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes", "Helm", "Postgresql"]
---

When setting up a simple staging environment, a quick to set up and somewhat persistent database is often required. My preferred option is the [Bitnami Helm Chart](oci://registry-1.docker.io/bitnamicharts/postgresql) with a little bit of configuration to achieve:

- An autoset and namespace setup
- Accessibility through one host sub-domain + port
- Easy hourly backups to a host path
- Exposure through TCP to the cluster host

### Prerequisites

This post assumes you have a `microk8s` cluster set up with `cert-manager`, `ingress`, and `dns` setup, and a cluster issuer `letsencrypt-prod` configured.

> To get started, you can follow [My Blog Post on Microk8s Private Cluster Setup]().

### TL;DR 

[Use this script](https://github.com/bitnami/charts/blob/master/bitnami/postgresql/README.md) for swift deployment of this configuration:

```bash
./create_postgresdb.sh \
  RELEASE_NAME="<release-name>" \
  K8_NAMESPACE="<installation-namespace>" \
  DB_USERNAME="<db-username>" \
  DB_PASSWORD="<your-super-secure-password>" \
  DB_NAME="<db-name>" \
  DB_CLUSTER_DOMAIN="<your-custom-domain>" \
  BACKUP_MOUNT_PATH="/some-host-path" \
  TARGET_PORT="<target-port(>30000,<40000)>"
```

### Configuration 

Let's delve into [the script](https://github.com/bitnami/charts/blob/master/bitnami/postgresql/README.md).

First, we create the namespace `microk8s kubectl create namespace $K8_NAMESPACE`.

Next, we essentially install the [Bitnami Helm Chart](oci://registry-1.docker.io/bitnamicharts/postgresql) with a few configurations:

```bash
    --set global.postgresql.auth.username="$DB_USERNAME" \
    --set global.postgresql.auth.password="$DB_PASSWORD" \
    --set global.postgresql.auth.database="$DB_NAME" \
    --set clusterDomain="$DB_CLUSTER_DOMAIN" \
```

Here, we create the base admin user and configure the password and username. We also configure a default base database `$DB_NAME`.

```bash
    --set backup.enabled=true \
    --set backup.cronjob.schedule="@hourly" \
    --set backup.cronjob.concurrencyPolicy=Allow \
    --set backup.cronjob.storage.mountPath="$BACKUP_MOUNT_PATH"
``` 

The Helm Chart conveniently supports backups. We configure it to perform a DB dump onto the server every hour.

> For any critical task, backups should be encrypted and synced to an additional S3 storage.

Now, we need to configure the microk8s `nginx-ingress-tcp-microk8s-conf` to expose the TCP traffic - through port `5432` of our PostgreSQL deployment - for accessibility through the `$CLUSTER_DOMAIN`.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-tcp-microk8s-conf
  namespace: ingress
data:
  5432: "$K8_NAMESPACE/$RELEASE_NAME-postgresql:5432"
```

Finally, we create a service to route this port to our host.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: $RELEASE_NAME-nodeport
  namespace: $K8_NAMESPACE
spec:
  type: NodePort
  ports:
    - name: tcp-postgresql
      protocol: TCP
      port: 5432
      targetPort: 5432
      nodePort: $TARGET_PORT
  selector:
    app.kubernetes.io/instance: $RELEASE_NAME
    app.kubernetes.io/name: postgresql
```

> Remember to expose the port through your firewall `sudo ufw allow $TARGET_PORT`.

Now, you can test the connection to the database:

```
psql -h <your-domain> -u <user-name>
```

Or configure the settings of a Django app to access the database:

```python
# settings.py

DATABASES = {
    'default': {
        'ENGINE': DB_ENGINE,
        'NAME': os.environ['DB_NAME'],
        'USER': os.environ['DB_USER'],
        'PASSWORD': os.environ['DB_PASSWORD'],
        'HOST': "<yourdb-host-domain>"
        'PORT': "<yourdb-port>
        'OPTIONS': {'sslmode': 'require'}
    }
}
```

> Always set `{'sslmode': 'require'}` to ensure the traffic to the server is encrypted.

#### Restoring Backups 

As per configuration, hourly backups are written to `$BACKUP_MOUNT_PATH`. To restore a backup, simply use a `psql` client and the database credentials:

```
psql -U [postgres-user] -p [database-port] -h [postgres-ip] -d [database-name] -f database.sql
```