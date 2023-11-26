#!/bin/bash

CERT_SECRET_NAME="${RELEASE_NAME}-tls"

KUBECMD_PREFIX="${KUBECMD_PREFIX:=microk8s}"

# Create namespace
$KUBECMD_PREFIX kubectl create namespace $K8_NAMESPACE || true

# Add the Bitnami Helm repository and update
$KUBECMD_PREFIX helm repo add bitnami https://charts.bitnami.com/bitnami
$KUBECMD_PREFIX helm repo update

# Install PostgreSQL with Helm and custom values
$KUBECMD_PREFIX helm install $RELEASE_NAME bitnami/postgresql \
    -n $K8_NAMESPACE \
    --set auth.enablePostgresUser=true \
    --set auth.postgresPassword="$DB_PASSWORD" \
    --set auth.username="$DB_USERNAME" \
    --set auth.password="$DB_PASSWORD" \
    --set auth.database="$DB_NAME" \
    --set tls.enabled=true \
    --set primary.service.type=LoadBalancer \
    --set primary.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"=$DB_DOMAIN \
    --set backup.enabled=true \
    --set backup.cronjob.schedule="@hourly" \
    --set backup.cronjob.concurrencyPolicy=Allow \
    --set backup.cronjob.storage.mountPath="$BACKUP_MOUNT_PATH"

# Apply Ingress resource to route external traffic to PostgreSQL through cert-manager
read -r -d '' INGRESS_MANIFEST << EOM
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${RELEASE_NAME}-ingress
  namespace: $K8_NAMESPACE
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - $DB_DOMAIN
    secretName: $CERT_SECRET_NAME
  rules:
  - host: $DB_DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${RELEASE_NAME}-postgresql
            port:
              number: 5432
EOM

$KUBECMD_PREFIX kubectl apply -f - <<< "$INGRESS_MANIFEST"
