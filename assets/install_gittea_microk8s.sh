#/bin/bash

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

microk8s kubectl create namespace $K8_NAMESPACE

microk8s helm install $RELEASE_NAME gitea-charts/gitea \
    -n $K8_NAMESPACE \
    --set postgresql-ha.enabled=false \
    --set postgresql.enabled=true \
    --set ingress.enabled=true \
    --set gitea.admin.username="$ADMIN_USERNAME" \
    --set gitea.admin.password="$ADMIN_PASSWORD" \
    --set "ingress.annotations.kubernetes\.io/ingress\.class=public" \
    --set "ingress.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod" \
    --set "ingress.annotations.nginx\.ingress\.kubernetes\.io/proxy-body-size=1g" \
    --set ingress.hosts[0].host="$INGRESS_HOST" \
    --set ingress.hosts[0].paths[0].path=/ \
    --set ingress.hosts[0].paths[0].pathType=Prefix \
    --set ingress.tls[0].secretName="git.$RELEASE_NAME-tls" \
    --set ingress.tls[0].hosts[0]="$INGRESS_HOST" \
    --set "gitea.additionalConfigFromEnvs[0].name=GITEA__ACTIONS__ENABLED" \
    --set "gitea.additionalConfigFromEnvs[0].value=\"true\"" \
    --set "gitea.additionalConfigFromEnvs[1].name=GITEA__SERVICE__REQUIRE_SIGNIN_VIEW" \
    --set "gitea.additionalConfigFromEnvs[1].value=\"true\""