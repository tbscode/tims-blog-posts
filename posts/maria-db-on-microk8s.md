---
title: "MariaDB on Kubernetes with backup cronjob"
description: "Follow these simple steps to deploy and expose a basic MariaDB database from your microk8s cluster."
date: "2023-09-29T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes", "Helm", "Postgresql"]
---

When setting up a simple staging environment, a quick to set up and somewhat persistent database is often required. In case of MariaDB my preferred option is the [Bitnami Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/mariadb) with a little bit of configuration to achieve:

- An autoset and namespace setup
- Accessibility through one host sub-domain + port
- Easy hourly backups to a host path
- Exposure through TCP to the cluster host

### Prerequisites

This post assumes you have a `microk8s` cluster set up with `cert-manager`, `ingress`, and `dns` setup, and a cluster issuer `letsencrypt-prod` configured.

> To get started, you can follow [My Blog Post on Microk8s Private Cluster Setup](/blog/microk8s-on-vps).

### TL;DR 

[Use this script](https://github.com/tbscode/tims-blog-posts/blob/main/assets/create_mariadb.sh) for swift deployment of this configuration:

```bash
./create_mariadb.sh \
  RELEASE_NAME="<release-name>" \
  K8_NAMESPACE="<installation-namespace>" \
  DB_USERNAME="<db-username>" \
  DB_PASSWORD="<your-super-secure-password>" \
  DB_NAME="<db-name>" \
  TARGET_PORT="<>" \
  HOST_BACKUP_PATH="<your host backup volume>"
```

> Remember to expose the port through your firewall `sudo ufw allow $TARGET_PORT`.
  
#### Uninstall:

```
microk8s helm uninstall $RELEASE_NAME
```

#### Connect to the database

```
docker run -it --rm --network="host" mysql mysql --host <your-host-domain> --port <your-port> --user <your-user> --password --protocol=TCP
```

Enter the admin password when prompted.

#### Backup the database

We can also conveniently use a docker file for this!

```
docker run --network="host" --rm mysql:5.7 mysqldump -h localhost -P 30004 -u <your-user> -p<your-admin-password> --protocol=TCP <your-db-name> > backup.sql
```

#### Host Backup Strategy

I've created this simple example for a cron job to backup the database regularly.

```bash
microk8s kubectl create secret generic mariadb-creds --from-literal=password='$DB_PASSWORD' --from-literal=username='$DB_USER' -n $K8_NAMESPACE
```

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

As easy as that wew have a cron job running that creates hourly backups of our database.