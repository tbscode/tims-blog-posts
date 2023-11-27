---
title: "Setting Up a Secure Bitnami PostgreSQL Instance on Microk8s"
description: "This guide provides a step-by-step approach to installing a PostgreSQL database using Bitnami's Helm chart on a Microk8s cluster, including TLS configuration for enhanced security."
date: "2023-09-30"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Database"]
tags: ["Microk8s", "Kubernetes", "Helm", "Postgresql", "cert-manager", "TLS", "Python", "SSL"]
---

Deploying Postgres on Kubernetes need not be complex. With automation in place, you can deploy a secure and isolated instance of PostgreSQL within your Microk8s cluster using Bitnami's Helm chart. The updated script covers everything from provisioning TLS certificates to configuring the database for secure connections.

### Preparing the Environment

The process starts with some initial setup tasks. We create a Kubernetes namespace for the PostgreSQL instance and establish the baseline for our commands:

```bash
#!/bin/bash

KUBECMD_PREFIX="${KUBECMD_PREFIX:=microk8s}"
CERT_MANAGER_NAMESPACE="cert-manager"

$KUBECMD_PREFIX kubectl create namespace $K8_NAMESPACE || true
```

### Configuring SSL/TLS Encryption

With cert-manager installed in our cluster, we can automatically provision and manage TLS certificates. This is a crucial step in ensuring that our database communication is encrypted:

```bash
cat <<EOF | $KUBECMD_PREFIX kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: $RELEASE_NAME-postgresql-tls
  namespace: $K8_NAMESPACE
spec:
  secretName: $RELEASE_NAME-postgresql-tls
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-prod
  dnsNames:
  - $DB_HOSTNAME
EOF
```

It's imperative to wait for the certificate to become ready. This script assures that by incorporating a timeout for the process:

```bash
$KUBECMD_PREFIX kubectl -n $K8_NAMESPACE wait --for=condition=ready certificate $RELEASE_NAME-postgresql-tls --timeout=300s
```

### Installing PostgreSQL with Helm

Having confirmed that the TLS certificate is in place, we proceed with the Helm chart installation:

```bash
$KUBECMD_PREFIX helm install $RELEASE_NAME oci://registry-1.docker.io/bitnamicharts/postgresql \
    -n $K8_NAMESPACE \
    --set global.postgresql.auth.username="$DB_USERNAME" \
    --set global.postgresql.auth.password="$DB_PASSWORD" \
    ...
    --set tls.certificatesSecret="$RELEASE_NAME-postgresql-tls" \
    --set tls.certFilename="tls.crt" \
    --set tls.certKeyFilename="tls.key"
```

The script passes the appropriate values to Helm, signaling it to deploy Postgres with TLS enabled.

### Networking Configuration

The `ConfigMap` and `Service` definitions are applied to route external traffic to the Postgres instance:

```bash
read -r -d '' INGRESS_CONFIG << EOM
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ingress
  name: nginx-ingress-tcp-microk8s-conf
data:
  5432: "$K8_NAMESPACE/$RELEASE_NAME-postgresql:5432"
---
apiVersion: v1
kind: Service
metadata:
  name: $RELEASE_NAME-nodeport
  namespace: $K8_NAMESPACE
spec:
  type: NodePort
  ...
  nodePort: $TARGET_PORT
  ...
EOM

$KUBECMD_PREFIX kubectl apply -f - <<< "$INGRESS_CONFIG"
```

### Testing the Database Connection

Once deployed, verify the secure connection using Python and the `psycopg2` library. The script aims to establish a connection, execute a command, and then gracefully terminate the connection:

```python
import psycopg2

conn = None
try:
    conn = psycopg2.connect(
        dbname='...',
        user='...',
        password='...',
        host='...',
        port='...',
        sslmode='require'
    )

    print("Success: Connected to the database!")
    cur = conn.cursor()
    cur.execute("SELECT version();")
    record = cur.fetchone()
    print("You are connected to - ", record, "\n")
    cur.close()
except (Exception, psycopg2.DatabaseError) as error:
    print("Error: ", error)
finally:
    if conn is not None:
        conn.close()
        print("Database connection closed.")
```

By requiring `sslmode='require'`, the script confirms that the connection is not only secure but also compliant with best practices.

### Wrapping Up

The combination of Microk8s's simplicity and Helm's power simplifies the deployment of a robust PostgreSQL database. TLS encryption, managed by cert-manager, makes sure the data remains secure in transit. For developers and administrators looking to setup PostgreSQL on Kubernetes, the process is now streamlined, automated, and immeasurably more secure than before.

Do check out the full deployment script and accompanying resources on the [GitHub repository](https://github.com/tbscode/tims-blog-posts/blob/main/assets/postgress_create_dynamic_k8s.sh) and ensure your databases are secure from setup to daily operations.