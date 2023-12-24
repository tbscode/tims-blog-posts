#!/bin/bash

KUBECMD_PREFIX="${KUBECMD_PREFIX:=microk8s}"

$KUBECMD_PREFIX kubectl create namespace $K8_NAMESPACE || true

read -r -d '' VALUES << EOM
wordpressUsername: $WP_USERNAME
wordpressPassword: $WP_PASSWORD
ingress:
  enabled: true
  ingressClassName: "public"
  host: $WP_HOSTNAME
  annotations:
    kubernetes.io/ingress.class: public
    cert-manager.io/cluster-issuer: letsencrypt-prod
  tls:
    - hosts:
        - $WP_HOSTNAME
      secretName: minio-$RELEASE_NAME-tls
EOM

$KUBECMD_PREFIX helm install $RELEASE_NAME oci://registry-1.docker.io/bitnamicharts/wordpress \
    -n $K8_NAMESPACE \
    -f- <<< "$VALUES" 