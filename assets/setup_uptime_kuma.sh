#!/usr/bin/env bash
set -euo pipefail

# Required env:
#   KUBECONFIG=/path/to/kubeconfig
#   HOST=status.example.com
#
# Optional env (with defaults):
NAMESPACE="${NAMESPACE:-monitoring}"
RELEASE="${RELEASE:-uptime-kuma}"
TLS_SECRET_NAME="${TLS_SECRET_NAME:-uptime-kuma-tls}"
INGRESS_CLASS="${INGRESS_CLASS:-public}"
HELM_REPO_URL="${HELM_REPO_URL:-https://dirsigler.github.io/uptime-kuma-helm}"
TZ_VAL="${TZ_VAL:-Europe/Berlin}"

: "${KUBECONFIG:?Set KUBECONFIG to your kubeconfig path}"
: "${HOST:?Set HOST to your desired hostname}"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

helm repo add uptime-kuma "$HELM_REPO_URL" >/dev/null 2>&1 || true
helm repo update >/dev/null

cat > values-uptime-kuma.yaml <<EOF
ingress:
  enabled: true
  ingressClassName: ${INGRESS_CLASS}
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: ${INGRESS_CLASS}
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
    nginx.ingress.kubernetes.io/server-snippets: |
      proxy_buffering off;
      proxy_cache off;
  hosts:
    - host: ${HOST}
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: ${TLS_SECRET_NAME}
      hosts:
        - ${HOST}

persistence:
  enabled: true
  size: 5Gi

service:
  type: ClusterIP
  port: 3001

env:
  TZ: ${TZ_VAL}
EOF

helm upgrade --install "${RELEASE}" uptime-kuma/uptime-kuma \
  --namespace "${NAMESPACE}" --create-namespace \
  -f values-uptime-kuma.yaml \
  --wait

echo "https://${HOST}"
