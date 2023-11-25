#!/bin/bash
KUBECMD_PREFIX="${KUBECMD_PREFIX=:=microk8s}"

$KUBECMD_PREFIX kubectl create namespace $K8_NAMESPACE || true

# Create certificate
read -r -d '' CERTIFICATE << EOM
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: postgresql-cert
  namespace: $K8_NAMESPACE
spec:
  secretName: postgresql-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: $DB_HOSTNAME
  dnsNames:
  - $DB_HOSTNAME
EOM

$KUBECMD_PREFIX kubectl apply -f - <<< "$CERTIFICATE"

# Delay for certificate creation
echo "Waiting 5 minutes for the certificate to be issued..."
sleep 300

# Install Postgresql
$KUBECMD_PREFIX helm install $RELEASE_NAME oci://registry-1.docker.io/bitnamicharts/postgresql \
    -n $K8_NAMESPACE \
    --set global.postgresql.auth.username="$DB_USERNAME" \
    --set global.postgresql.auth.password="$DB_PASSWORD" \
    --set global.postgresql.auth.database="$DB_NAME" \
    --set clusterDomain="$DB_CLUSTER_DOMAIN" \
    --set backup.enabled=true \
    --set backup.cronjob.schedule="@hourly" \
    --set backup.cronjob.concurrencyPolicy=Allow \
    --set backup.cronjob.storage.mountPath="$BACKUP_MOUNT_PATH" \
    --set global.postgresql.ssl.enabled=true \
    --set global.postgresql.ssl.secret="postgresql-tls-secret"

# Create service and ingress
read -r -d '' INGRESS_CONFIG << EOM
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-tcp-microk8s-conf
  namespace: ingress
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
  ports:
    - name: tcp-postgresql
      protocol: TCP
      port: 5432
      targetPort: 5432
      nodePort: $TARGET_PORT
  selector:
    app.kubernetes.io/instance: $RELEASE_NAME
    app.kubernetes.io/name: postgresql
EOM

$KUBECMD_PREFIX kubectl apply -f - <<< "$INGRESS_CONFIG"
