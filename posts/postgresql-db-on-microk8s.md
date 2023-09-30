---
title: "Simple Development PostgresDB setup on Microk8s via Helm"
description: "Simple steps to deploy and exmpose a basic psqldatbase from your microk8s cluster"
date: "2021-09-13T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes", "Helm", "Postgresql"]
---

For simple staging environment you often want a quick to setup database that is somewhat persistant.

I like to use [this bitnami helm chart]() with a little configuration so that I get:

- authe and namespace set up
- make it accessibe through one host sub-domain + port
- easy hourly backups to a host path
- expose it though tcp to the cluster host

### TL;DR

You can [use this script]() to easyly deploy this configuration.

```
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