---
title: "Setting up a Private Kubernetes Cluster on Your Own VPS Using Microk8s"
description: "A step-by-step guide to setting up a fully configurable private Kubernetes cluster"
date: "2023-09-21T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Programming"]
tags: ["Microk8s", "Kubernetes"]
---

> Discover the cheapest and easiest way I've found to create personal Kubernetes clusters.

This blog post provides a step-by-step guide to setting up a private Kubernetes cluster on a Virtual Private Server (VPS), with the following features ready and configured:

- VPS firewall setup to expose HTTP/HTTPS & kubeapi server
- MetalLB configured for load balancing and exposing VPS IP
- Ingress and cert-manager setup for quick & automatic TLS management
- Kubeapi server configured for restricted remote access

The **prerequisites** for this tutorial are: **A VPS with a Public IP**, **A domain with a configurable DNS**.

## Step 1: Create a base user

Connect to your VPS. In a terminal, create a user and add them to the sudoers.

```bash
adduser <user-name>
usermod -aG sudo <user-name>
```

## Step 2: Create SSH keys

On your local machine, create SSH keys to access the server.
Set a secure password for the key.

```bash
ssh-keygen -b 2048 -t rsa
chmod 600 <key-file> <key-file>.pub
```

Copy the content of `<key-name>.pub` to your VPS at `/home/<user-name>/.ssh/authorized_keys`.

Now we edit the ssh config to require the ssh key, edit `/etc/ssh/sshd_config`

```bash
PasswordAuthentication no # yes before
PubkeyAuthentication yes # no before
```

Then restart the ssh service `service ssh restart`

> Note: these are minimal ssh setup setups and depending on the environment extra steps should be taken to make ssh more robust agains outside attacks.

## Step 3: Set up and enable the firewall

Set up the firewall to allow SSH, HTTP, HTTPS connections and also expose port `16443` which will be used to access the Kubeapi server.

```bash
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 16443
ufw enable
```

Now disconnect from your server and reconnect as the new user:

```bash
ssh -i "<private-server-key>" <user-name>@<server-IP>
```

## Step 4: Install and set up microk8s

```bash
sudo snap install microk8s --classic --channel=1.28
sudo microk8s enable rbac
sudo microk8s start
microk8s enable ingress dns hostpath-storage cert-manager
```

If you want to use the current user to manage microk8s; this is not recomended for production clusters

```
sudo usermod -a -G microk8s <your-user>
```

Now we create a default cluster issuer: `letsencrypt-prod`:

```bash
microk8s kubectl apply -f - <<EOF
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: letsencrypt-prod
spec:
 acme:
   email: <your email>
   server: https://acme-v02.api.letsencrypt.org/directory
   privateKeySecretRef:
     name: lets-encrypt-priviate-key
   solvers:
   - http01:
       ingress:
         class: public
EOF
```

We also need to enable some additional rules for the firewall ([see this github comment](https://github.com/canonical/microk8s/issues/2418#issuecomment-877350375)):

```bash
sudo ufw allow in on cali+
sudo ufw allow out on cali+
```

To check for general configration issues use `microk8s inspect`
This can give you some easy setup configuration infos and warnings such as:

To enable ip forwarding:

```
sudo iptables -P FORWARD ACCEPT
sudo apt-get install iptables-persistent
```


No to konfigure kubeserver access through the host dns, edit `/var/snap/microk8s/current/certs/csr.conf.template`:

```bash
[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
DNS.6 = k8s.<your-domain>
```

Refresh the server certificate:

```bash
sudo microk8s refresh-certs --cert server.crt
```

View the updated client certificate: `microk8s config > kubeconfig.yaml`.
Open the `kubeconfig.yaml` and edit the `server:` entry.

```bash
...
- cluster:
    certificate-authority-data: XXXXXXXXCENSOREDXXXXXXX
    server: <pub-IP> <---- put k8s.<domain> here
...
```

Now you can connect to the Kubernetes cluster from your local machine:

```bash
KUBECONFIG="./kubeconfig.yaml" kubectl get pods --all-namespaces
```

## Step 5: Setting Up MetalLB

First, prepare `<your-domain>`. 
Create a specific or one wildcard DNS entry:

```bash
<your-domain> -> <vps-ip>
*.<your-domain> -> <vps-ip>
```

Enable `metallb` via `microk8s enable metallb:<your-ip>-<your-ip>`.

To make `metallb` work correctly, apply the patch described in [this GitHub comment](https://github.com/canonical/microk8s/issues/824#issuecomment-1003284063).


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

You can now use LoadBalancer nodes that distribute the `<VPS-IP>`.

## Some Tips

#### Enabling tab completion for microk8s

`vim ~/.bash_aliases`

```bash
# add the fllowing
alias kubectl='microk8s kubectl'
export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)  
```

#### Patching External Traffic Policies

```bash
kubectl patch svc nodeport -p '{"spec":{"externalTrafficPolicy":"Local"}}'
```

#### Testing the preservation of client IP adresses

```bash
kubectl expose deployment source-ip-app --name=loadbalancer --port=80 --target-port=8080 --type=LoadBalancer
```

## Conclusion

You now have a Kubernetes cluster with services that can be exposed via ingress, have a load balancer, and cert manager ready. You should be able to access these services through a host domain. 

> The possibilities are endless from here ;^)

You even have the option to connect this to multiple VPSs to extend your cluster. More on that in a future blog post.
