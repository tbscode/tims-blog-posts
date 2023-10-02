---
title: "MariaDB on Kubernetes with Backup Cron-job"
description: "This straightforward guide will walk you through deploying and exposing a basic MariaDB database on your microk8s Kubernetes cluster."
date: "2023-09-29T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes", "Helm", "Postgresql"]
---

Every now and then, when setting up a simple staging environment, the need for a quick-setup database that retains state consistently arises. In such situations, I often lean towards MariaDB, specifically utilizing the [Bitnami Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/mariadb), with slight tweaks to achieve the following:

- An auto-set, namespace setup
- Accessibility through a single host subdomain + port
- Easy hourly backups to a specified host path
- Exposure through TCP to the cluster host

### Prerequisites

This post is operating under the assumption that you have a `microk8s` Kubernetes cluster already set up, complete with `cert-manager`, `ingress`, `dns` and an active and configured `letsencrypt-prod` cluster issuer.

> Note: To jumpstart your setup, you might find [this Blog Post on Microk8s Private Cluster Setup](/blog/microk8s-on-vps) quite helpful.

### TL;DR 

For a swift deployment of this configuration:

1. [Grab this script](https://github.com/tbscode/tims-blog-posts/blob/main/assets/create_mariadb.sh)
2. Then run it as follows:

```bash
./create_mariadb.sh \
  RELEASE_NAME="<release-name>" \
  K8_NAMESPACE="<installation-namespace>" \
  DB_USERNAME="<db-username>" \
  DB_PASSWORD="<your-super-secure-password>" \
  DB_NAME="<db-name>" \
  TARGET_PORT="<desired-port>" \
  HOST_BACKUP_PATH="<your host backup volume>"
```

> Remember to expose the desired port through your firewall with a `sudo ufw allow $TARGET_PORT` command.
  
#### Uninstallation Process:

Execute the following command: 

```
microk8s helm uninstall $RELEASE_NAME
```

#### Connecting to the Database

Use this command to establish a connection to the database:

```bash
docker run -it --rm --network="host" mysql mysql --host <your-host-domain> --port <your-port> --user <your-user> --password --protocol=TCP
```

Remember to enter the admin password when prompted.

#### Backing up the Database

Here's a simple docker command for accomplishing this:

```bash
docker run --network="host" --rm mysql:5.7 mysqldump -h localhost -P 30004 -u <your-user> -p<your-admin-password> --protocol=TCP <your-db-name> > backup.sql
```

#### Host Backup Strategy

A straightforward example of a cron job that allows your database to be backed up regularly is created as follows:

1. First, create a secret to hold your MariaDB credentials:

```bash
microk8s kubectl create secret generic mariadb-creds --from-literal=password='$DB_PASSWORD' --from-literal=username='$DB_USER' -n $K8_NAMESPACE
```

2. Then, define a CronJob in a yaml file:

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          volumes:
            - name: backup-volume
              hostPath:
                path: "$HOST_BACKUP_PATH"
          containers:
            - name: backup-container
              image: mysql:5.7
              volumeMounts:
                - name: backup-volume
                  mountPath: /backup
              env:
                - name: MYSQL_PWD
                  valueFrom:
                    secretKeyRef:
                      name: mariadb-creds
                      key: password
                - name: MYSQL_USER
                  valueFrom:
                    secretKeyRef:
                      name: mariadb-creds
                      key: username
              command: ["sh", "-c", 'mysqldump -h database-host -P 30004 -u $MYSQL_USER --protocol=TCP database-name > /backup/backup-$(date +%Y%m%d-%H%M%S).sql']
          restartPolicy: OnFailure
```

With this configuration in place, you would have a CronJob that executes hourly backups of the database.