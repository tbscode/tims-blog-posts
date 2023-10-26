#!/bin/bash
microk8s helm repo add sentry https://sentry-kubernetes.github.io/charts

read -r -d '' PSQL_SECRET << EOM
apiVersion: v1
kind: Secret
metadata:
  name: postgres
  namespace: $K8_NAMESPACE
stringData:
  postgres-password: "$POSTGRES_PASSWORD"
EOM

microk8s kubectl create namespace $K8_NAMESPACE || true
microk8s kubectl apply -f - <<< $PSQL_SECRET

read -r -d '' VALUES << EOM
nginx:
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    enabled: true
    hostname: $SENTRY_HOSTNAME
    ingressClassName: "public"
    tls: true
    extraTls:
      - hosts:
          - $SENTRY_HOSTNAME
        secretName: sentry-$RELEASE_NAME-tls
kafka:
  zookeeper:
    enabled: false
  kraft:
    enabled: true
ingress:
  enabled: true
hooks:
  activeDeadlineSeconds: 3500
mail:
  backend: smtp
  useTls: true
  username: "$SMTP_USERNAME"
  password: "$SMTP_PASSWORD"
  port: $SMTP_PORT
  host: "$SMTP_HOST"
  from: "$SMTP_FROM_EMAIL"
user:
  create: true
  email: "$SENTRY_ADMIN_EMAIL"
  password: "$SENTRY_ADMIN_PASSWORD"
config:
  sentryConfPy: |
    SENTRY_FEATURES["organizations:session-replay"] = True
    SENTRY_FEATURES["organizations:session-replay-ui"] = True
EOM

microk8s helm install $RELEASE_NAME sentry/sentry -n sentry --values - <<< $VALUES