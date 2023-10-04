#/bin/bash

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

microk8s kubectl create namespace $K8_NAMESPACE

microk8s helm install $RELEASE_NAME oci://registry-1.docker.io/bitnamicharts/mariadb \
    -n $K8_NAMESPACE \
    --set auth.rootPassword="$DB_PASSWORD" \
    --set auth.username="$DB_USERNAME" \
    --set auth.password="$DB_PASSWORD" \
    --set auth.database="$DB_NAME"

read -r -d '' INGRESS_CONFIG << EOM
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-tcp-microk8s-conf
  namespace: ingress
data:
  5432: "$K8_NAMESPACE/$RELEASE_NAME:3306"
---
apiVersion: v1
kind: Service
metadata:
  name: $RELEASE_NAME-nodeport
  namespace: $K8_NAMESPACE
spec:
  type: NodePort
  ports:
    - name: mysql
      protocol: TCP
      port: 3306
      targetPort: 3306
      nodePort: $TARGET_PORT
  selector:
    app.kubernetes.io/instance: $RELEASE_NAME
    app.kubernetes.io/name: mariadb
EOM

microk8s kubectl apply -f - <<< "$INGRESS_CONFIG"

microk8s kubectl delete secret mariadb-creds -n $K8_NAMESPACE || true
microk8s kubectl create secret generic mariadb-creds --from-literal=password=$DB_PASSWORD --from-literal=username=$DB_USERNAME -n $K8_NAMESPACE


read -r -d '' BACKUP_JOB << EOM
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
  namespace: $K8_NAMESPACE
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          volumes:
            - name: backup-volume
              hostPath:
                path: $HOST_BACKUP_PATH
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
              command: ["sh", "-c", 'mysqldump -h $RELEASE_NAME-mariadb.$K8_NAMESPACE.svc.cluster.local -P 3306 -u \$MYSQL_USER --protocol=TCP $DB_NAME > /backup/backup-\$(date +%Y%m%d-%H%M%S).sql']
          restartPolicy: OnFailure
EOM

microk8s kubectl apply -f - <<< "$BACKUP_JOB"