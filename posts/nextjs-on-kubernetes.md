---
title: "Quickly Deploy Any Next Js App On Kubernetes"
description: "Simple steps to build, push, and deploy a Next.js app on Kubernetes"
date: "2023-10-01T16:56:47+06:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Web Development"]
tags: ["Microk8s", "Kubernetes", "Helm", "NextJS"]
---

This guide illustrates the steps required to build, push, and deploy a Next.js app on Kubernetes using docker files for defining development and production Next.js images. These docker compose files allow for the building and pushing of images, with a Next.js config able to export static files. A simple helm chart will create deployment, service, and ingress for exposing our app.

> Template repo containing all the required code and configs can be [found on my github](https://github.com/tbscode/nextjs-helm-template).

### Prerequisites

This tutorial can also be adapted to work with any managed cluster as I've been using similar setups to quickly deploy Next.js apps for a while.

For your cluster you'll need:

- `cert-manger` cluster issuer with name `letsencrypt-prod` setup.
- `nginx-ingress` installed.
- `helm` installed.
- Public IP and Host Url connected.

Further, a private container registry is required.

> If you don't have a Kubernetes cluster ready follow [My Blog Post on Microk8s Private Cluster Setup](/blog/microk8s-on-vps).

### 1. Start a Next.js App

Begin by creating a simple Next.js app:

```
npx create-next-app@latest
What is your project named?  frontend
Would you like to use TypeScript? Yes
Would you like to use ESLint?  Yes
Would you like to use Tailwind CSS?  Yes
Would you like to use `src/` directory?  No
Would you like to use App Router? (recommended)  Yes
Would you like to customize the default import alias (@/*)?  No
```

We named the app `./frontend` so the respective folder is created.

### 2. Dockerize the Application

Two docker files can be created:

1. [`./frontend/Dockerfile`](https://github.com/tbscode/nextjs-helm-template/blob/main/frontend/Dockerfile): A development docker file that mounts frontend `./frontend` into the container for hot-reload.
2. [`./frontend/pro.dockerfile`](https://github.com/tbscode/nextjs-helm-template/blob/main/frontend/prod.dockerfile): A production docker file that statically builds the entire application and Next.js in a container.

The development docker file is straightforward:

```Dockerfile
FROM node:16-alpine

WORKDIR /frontend
COPY ./package.json .

RUN apk add curl

RUN npm i --save-dev

ENTRYPOINT ["npm", "run", "dev"]
```

Here, we execute `npm i` and then `npm run dev`. When mounted to the host, the `./node_modules` directory will also be present on the host.

The production docker file, which is based on the Next.js example docker file, can be found [here.](https://nextjs.org/docs/pages/building-your-application/deploying#docker-image)

```dockerfile
FROM node:16-alpine AS deps
RUN apk add --no-cache libc6-compat curl
WORKDIR /app

COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
    if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm i; \
    elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
    else echo "Lockfile not found." && exit 1; \
    fi

FROM node:16-alpine AS builder
WORKDIR /app
COPY . .
RUN apk add --no-cache curl
RUN npm i
RUN npm install --unsafe-perm -g sharp

ENV NEXT_TELEMETRY_DISABLED 1

RUN yarn build

FROM node:16-alpine AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/styles ./styles
COPY --from=builder /app/public ./public

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

### 3. Compose Files for Development

Creating two compose files can pave the way for convenience:

1. [`docker-compose.yaml`](https://github.com/tbscode/nextjs-helm-template/blob/main/docker-compose.yaml): A development compose file.
2. [`docker-compose.pro.yaml`](https://github.com/tbscode/nextjs-helm-template/blob/main/docker-compose.pro.yaml): A production/ Local Infrastructure compose file.

Development is now always as straightforward as executing `docker-compose up`.

### 4. Creating a Helm Chart

To effectively manage the deployments and services we require, we prefer to create a simple Helm chart that can easily be adapted, installed, and updated. Our Helm chart will need the following components:

1. Frontend Deployment
2. Registry Image Pull Secrets
3. Frontend Service
4. Ingress

```
microk8s helm create ./helm
cd ./helm/template && rm -rf *
```

Everything will be deployed to a `rootNamespace`.

We have reset the template and created a simple setup for now [`./helm/template/frontend.yaml`](https://github.com/tbscode/nextjs-helm-template/blob/main/helm/templates/frontend.yaml).

```yaml
{{- if .Values.registryAuth.use }}
kind: Secret
type: kubernetes.io/dockerconfigjson
apiVersion: v1
metadata:
  name: dockerconfigjson-github-com
  namespace: {{ .Values.rootNamespace }}
stringData:
  .dockerconfigjson: >
    {{
      (
        dict "auths"
        (
          dict {{ .Values.registryAuth.registry }}
          (
            dict "auth" .Values.registryAuth.token
          )
        )
      )
      |
      toJson
    }}
{{- end }}
```

We've created a simple flag `.Values.registryAuth.use` to check if registry authentication should be used (as we wouldn't need it for local microk8s deployment).
We use `.Values.registryAuth.use` to define the registry that should be used.

Now we define a simple deployment for our nextjs backend:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-container
  namespace: {{ .Values.rootNamespace }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend-container
  template:
    metadata:
      labels:
        app: frontend-container
    spec:
      containers:
        - name: frontend-container
          image: {{ .Values.frontend.imageURL }}
          ports:
            - containerPort: 8000
          envFrom:
            - secretRef:
                name: frontend-secrets
      {{- if .Values.registryAuth.use }}
      imagePullSecrets:
        - name: dockerconfigjson-github-com
      {{- end }}
```

Note that we inject the `imageURL` and the registry pull secret if required. We go on to expose the port `3000` to the cluster through a simple service.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: {{ .Values.rootNamespace }}
  labels:
    app: frontend-container
spec:
  type: ClusterIP
  ports:
    - port: 3000
      targetPort: 3000
  selector:
    app: frontend-container

```

It's also advisable to create a secret that injects some general environment variables listed in `values.yaml:frontend.env.*`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: frontend-secrets
  namespace: {{ .Values.rootNamespace }}
type: Opaque
data:
{{- range $key, $value := .Values.frontend.env }}
  {{ $key }}: {{ $value | b64enc }}
{{- end }}
```

Finally, we set up an ingress:

```yaml
{{- if .Values.ingress.use }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: {{ .Values.rootNamespace }}
  annotations:
    nginx.ingress.kubernetes.io/proxy-connect-timeout: '3600'
    nginx.ingress.kubernetes.io/proxy-read-timeout: '3600'
    nginx.ingress.kubernetes.io/proxy-send-timeout: '3600'
    nginx.ingress.kubernetes.io/server-snippets: |
      location /ws/ {
        proxy_http_version 1.1;
        proxy_redirect off;
        proxy_buffering off;
      } 
    {{- if .Values.ingress.certManager }}
    cert-manager.io/cluster-issuer: letsencrypt-prod
    {{- end }}
    kubernetes.io/ingress.class: public
spec:
  {{- if .Values.ingress.certManager }}
  tls:
    - hosts:
      - {{ .Values.ingress.host }}
    secretName: frontend-ingress-tls
  {{- end }}
  rules:
  - host: {{ .Values.ingress.host }}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000
{{- end }}
```

We've introduced some flags to set up `tls` if required and some annotations to facilitate websocket forwards.

#### Configuration via `Values.yaml`

Finally, to tie this all together, we create some default [`values.yaml`](https://github.com/tbscode/nextjs-helm-template/blob/main/helm/values.yaml)

```yaml
rootNamespace: "default"
registryAuth:
  registry: "localhost:32000"
  use: false
  token: ""
ingress:
  use: true
  certManager: false
  host: "localhost"
frontend:
  imageURL: "localhost:32000/frontend:registry"
  env:
    HOSTNAME: "localhost"
```

This can be used to control all the configuration options we just created.

### 5. Testing on Local Microk8s

It's always good to ensure that we can also deploy the entire infrastructure locally. For this, we can use a simple local `microk8s` installation.

```
microk8s enable ingress dns registry
docker-compose -f docker-compose.pro.yaml build
docker-compose -f docker-compose.pro.yaml push
```

Since we set up the template `.env` earlier, we're already configured to push and pull the image from `localhost:32000/frontend:registry`.
So now, all we need to do is install our newly created chart:

```
microk8s helm install next-js-frontend ./helm/ --set rootNamespace="nextjsfront"
```

Since we also set up `$ROOT_URL="http://localhost"`, the ingress will be configured to route to `http://localhost`. Now let's check the browser:

![Next page on localhost via microk8s](/static/assets/nextjs-page.jpg)

### 6. Deploy to Private Cluster

For the capability to deploy to a private cluster, you'll need a package registry available.

> If you quickly want a cheap registry, you can [check out my blog post](/blog/microk8s-gittea) on deploying Gitea in a private k8s cluster.

#### Modify Environment for Production

Firstly, we need to modify the environment to push to our private registry with a modified tag.

```bash
rm .env
echo "FRONTEND_IMAGE=\"<your-frontend-image-url>\"" >> .env
echo "ROOT_URL=\"<your-host-url>\"" >> .env
```

An example of an image URL is `my-gitea.example.com/gitea-private-user/package:latest`.
A `ROOT_URL` could be something like `nextjs.example.com`.

Note that you can restore the old default `.env` at any time using `git checkout .env`.

We also need to encode access credentials to our registry so we can inject them into our secret.

```bash
echo "<your-registry-user>:<your-registry-password>" | base64
```

```bash
docker-compose -f docker-compose.pro.yaml build
docker-compose -f docker-compose.pro.yaml push
KUBECONFIG="./kubeconfig.yaml" microk8s helm install next-js-frontend ./helm/ \
--set rootNamespace="nextjsfront" \
--set ingress.use=true \
--set frontend.imageURL="<your-frontend-image-url>" \
--set certManager.use=true \
--set registryAuth.use=true \
--set registryAuth.registry="<your-registry-host>" \
--set registryAuth.token="<base64-encoded-token>"
```

> It works perfectly! In fact, this blog was deployed using this exact technique. 

### 7. Repository Automations

Now, we have a simple process to deploy the repository using GitHub Actions. 
These actions can also run on your own runners using Gitea Actions.

We create one simple workflow [`.github/workflow/deploy.yaml`](https://github.com/tbscode/nextjs-helm-template/blob/main/.github/workflow/deploy.yaml)

```yaml
name: Deploy NextJs App
    
on:
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    name: Deploy NextJS App
    steps:
      - uses: actions/checkout@master
        with:
          token: ${{ secrets.BOT_PAT }}
          submodules: recursive
          ref: ${{ github.event.pull_request.head.sha }}
      - name: Setup Kubeconfig
        id: setup_kubeconfig
        run: |
          touch .env; rm .env
          echo "${{ secrets.KUBE_CONFIG_BASE64 }}" | base64 -d > kubeconfig.yaml
      - name: Setup Environment
        id: setup_env
        run: |
          touch .env; rm .env; touch .env
          RANDOM_STRING="$( openssl rand -hex 3 )"
          FRONTEND_IMAGE="${{ secrets.CONTAINER_REGISTRY }}/${{ secrets.GITTEA_USER }}/nextjs-app:build-$RANDOM_STRING"
          echo "FRONTEND_IMAGE=\"$FRONTEND_IMAGE\"" >> .env
          echo "frontend_image=$FRONTEND_IMAGE" >> $GITHUB_OUTPUT
      - name: Build And Push Image
        run: |
          echo ${{ secrets.GITTEA_PASSWORD }} | docker login ${{ secrets.CONTAINER_REGISTRY }} -u ${{ secrets.GITTEA_USER }} --password-stdin
          DOCKER_BUILDKIT=1 docker-compose -f docker-compose.pro.yaml build
          DOCKER_BUILDKIT=1 docker-compose -f docker-compose.pro.yaml push
      - uses: azure/setup-helm@v3
        with:
           version: 'latest'
           token: ${{ secrets.BOT_PAT }}
        id: install-helm
      - uses: azure/setup-kubectl@v3
        with:
           version: 'latest'
        id: install-kubectl
      - name: Setup Cluster Connection
        id: cluster_connection
        run: |
          echo "Test"
          REGISTRY_AUTH=$(echo -n "${{ secrets.GITTEA_USER }}:${{ secrets.GITTEA_PASSWORD }}" | base64)
          KUBECONFIG=./kubeconfig.yaml kubectl create namespace nextjsnamespace || true
          cat << EOF | while read eval_command; do yq -i eval "$eval_command" ./helm/values.yaml; done
            .rootNamespace = "nextjsnamespace"
            .ingress.host = "${{ secrets.BOT_PAT }}"
            .frontend.imageURL = "${{ steps.setup_env.outputs.frontend_image }}"
            .ingress.certManager = true
            .registryAuth.token = "$REGISTRY_AUTH"
            .registryAuth.use = true
          EOF
          KUBECONFIG=./kubeconfig.yaml helm upgrade next-js-app ./helm/ --set rootNamespace="nextjsnamespace" --install
```

Using the following secrets configured in your GitHub account:

- `BOT_PAT`: GitHub bot access token
- `GITTEA_USER`: Private registry user
- `GITTEA_PASSWORD`: Private registry password or auth token
- `CONTAINER_REGISTRY`: Container registry host address
- `KUBE_CONFIG_BASE64`: Base64 encoded kubeconfig to connect to the k8s cluster

#### Automation Steps

1. Clone the repo and its sub-repos using `actions/checkout@master`.
2. Setup the `.env` with a random image tag
3. Build and push the production image using the generated tag
4. Setup Helm and kubectl using the Azure actions `azure/setup-helm@v3`, `azure/setup-kubectl@v3`
5. Modify `values.yaml` with our new configuration and update the Helm installation

> Opportunities from here are limitless; you can easily have any pull to the main deploy a feature environment or connect a backend to your Next.js app.