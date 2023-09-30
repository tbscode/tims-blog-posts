---
title: "Microk8s VPS Setup."
description: "How to setup Microk8s on a vps."
date: "2021-09-13T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps"]
tags: ["Microk8s", "Kubernetes"]
---

# Microk8s on VPS

First we get a simple ubuntu 22.04 vps with a public IP address.

## 1. Create a base user

Create a user, and add it to the sudoers.

```
adduser <user-name>
usermod -aG sudo <user-name>
```

## 2. Create ssh keys

```
ssh-keygen -b 2048 -t rsa
chmod 600 <key-file> <key-file>.pub
```

Copy the content of `<key-name>.pub` to your VPS `/home/<user-name>/authorized_keys`

## 3. setup and enable the firewall

```
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 16433
ufw enable
```

> We also allow access to 16433 for the cube api server

Now disconnect from your server and connect again as the new user:

```
ssh -i "<private-server-key> <user-name>@<server-IP>
```

## 4. Install and setup microk8s

```
sudo snap install microk8s --classic --channel=1.28
sudo microk8s start
mirok8s enable ingress hostpath certmanager
```

Now edit `/var/snap/microk8s/current/certs/csr.conf.template`

```
[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
DNS.6 = k8s.<your-domain>
```

Refresh the server certificate:

```
sudo microk8s refresh-certs --cert server.crt
```

View the updated client certificate: `microk8s config > kubeconfig.yaml`
Open the `kubeconfig.yaml` and edit the `server:` entry.

```
...
- cluster:
    certificate-authority-data: XXXXXXXXCENSOREDXXXXXXX
    server: <pub-IP> <---- put k8s.<domain> here
...
```

Now you can connect to the kubernetes cluster from your local machine:

```
KUBECONFIG="./kubeconfig.yaml" kubectl get pods --all-namespaces
```

## 5. Setting up Matallb

First get <your-domain> ready. 
Create specific or one wildcard dns entry:

```
<your-domain> -> <vps-ip>
*.<your-domain> -> <vps-ip>
```

Enable `metallb` via `microk8s enable metallb <your-ip>`.

For `metallb` - to work correctly - apply the patch described in [this github comment](https://github.com/canonical/microk8s/issues/824#issuecomment-1003284063).

```bash
#!/bin/sh

command -v kubectl > /dev/null 2>&1 && KUBECTL=kubectl
command -v microk8s.kubectl > /dev/null 2>&1 && KUBECTL=microk8s.kubectl

INGTMPFILE=$(mktemp -t ingress_daemonset.XXXXXXXX)

trap "rm -f ${INGTMPFILE}" 0 1 2 3

${KUBECTL} -n ingress get daemonset nginx-ingress-microk8s-controller -o yaml | \
    sed -e 's|- --publish-status-address=.*|- --publish-service=$(POD_NAMESPACE)/ingress|' > ${INGTMPFILE}

${KUBECTL} diff -f ${INGTMPFILE}
if [ $? -eq 0 ]; then
    echo "No changes need to be made"
else
    ${KUBECTL} apply -f ${INGTMPFILE}
fi
```

Now we can actually use LoadBalancer nodes that distrubte the <vps-IP>.

## 6. Making a cluster
