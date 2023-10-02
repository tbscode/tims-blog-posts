---
title: "Quickly Deploy Any Next Js App On Kubernetes"
description: "Simple steps to build push and deploy a next js app on kubernetes"
date: "2023-10-01T16:56:47+06:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Web Development"]
tags: ["Microk8s", "Kubernetes", "Helm", "NextJS"]
---

- docker files for defining development and production nextjs images
- docker compose files for building and pushing images
- nextjs config to export static files
- simple helm chart to create deployment, serive and ingress for exposing our app

> A template repo containing all required code and configs, [can be found here]()
  
### Prerequisites
  
**This tutorial can also be adapted to work with any managed cluster**.
I've been usining similar setups to quickly deploy nextjs apps for a while.

Your cluster must have:

- `cert-manger` cluster issuer with name `letsencrypt-prod` setup.
- `nginx-ingress` installed
- `helm` installed
- Pulic IP and Host Url connected


> If you don't have a kubernetes cluster ready follow [My Blog Post on Microk8s Private Cluster Setup](/blog/microk8s-on-vps).

### 1. Start a nextjs app

Lets start by creating a simple nextjs app:

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

Note we called the app `./frontend` so the respecive folder is created.

### 2. Dockerize the application

We create two docker files:

1. [`./frontend/Dockerfile`](): Development docker file mounts frontend `./frontend` into the container for hot-reload
2. [`./frontend/pro.dockerfile`](): Production docker file, staticly build whole application and nextjs in a container

The development docker file is simple:

```Dockerfile
FROM node:16-alpine

WORKDIR /frontend
COPY ./package.json .

RUN apk add curl

RUN npm i --save-dev

ENTRYPOINT ["npm", "run", "dev"]
```

We just rum `npm i` and then `npm run dev`. 
Note that when mounted to the host the `./node_modules` dir will also be present on the host.

The production docker file [is based on nextjs example docker file]().

```Dockerfile
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

COPY --from=builder /app/content ./content
COPY --from=builder /app/styles ./styles
COPY --from=builder /app/public ./public

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

### 3. Compose files for development

For convenience we create two compose files:

1. [`docker-compose.yaml`](): 
2. [`docker-compose.pro.yaml`]():

```yaml
version: '3'
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: ./Dockerfile
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/frontend
    environment:
      ROOT_URL: 'http://localhost'
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

We use `./frontend` as build context and reference the development compose file.
We forward port `3000` and finaly we mount the `./frontend` dir which gives us host reload of the code on the client.
NextJS is smart entought to still connects it's htmr websocket so pages will also autoreload in browser if the code changes.

For convenience we also create a simple production compose file.

```yaml
version: '3'
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: ./prod.dockerfile
    image: "$FRONTEND_IMAGE"
    ports:
      - "3000:3000"
    environment:
      ROOT_URL: "$ROOT_URL"
```

Note that we reference the production docker file `./prod.dockerfile` this time.
And most importantly we inject the environment var `image: "$FRONTEND_IMAGE"` this is important as we will use it to tag the image and this changes depending on if we want to deploy this to our public cluster on test it locally.

Conviently docker-compose source the `.env` file on build, so lets set some sensible defaults:

```
FRONTEND_IMAGE="localhost:32000/frontend:registry"
ROOT_URL="http://localhost"
```

With these default added to the repo the local build will use a tag for the [microk8s local registry](https://microk8s.io/docs/registry-built-in)


### 4. Create Helm Chart

Now to easily manage the deployments and services we will need I prefere to create a simple helm chart that we can easily adopt, install and update.
Our helm chart need the following composents:

1. Frontend Deployment
2. Registry Image Pull Secrets
3. Frontend Service
4. Ingress

```
microk8s helm create
```

### 5. Test on local microk8s

I like to make sure that we can also deploy the whole infrastucture locally.
For this purpose we can use a simple local `microk8s` installation.

```
microk8s enable ingress dns
```

### 6. Deploy to private cluster

For being able to deploy to a priate clutser you'll reed some package resgistry available.

> If you qickly want a cheap registry [checkout my blogpost on deploying gittea in a private k8s cluster](/blog/microk8s-on-vps)

#### Modify env for production

First of all we need to modify the environemnt to push to our private registry with a modified tag.

```
docker-compose -f docker-compose.pro.yaml build
docker-compose -f docker-compose.pro.yaml push
microk8s helm install next-js-frontend ./helm/ --set rootNamespace="timsblog" --set ingress.use=true --set frontend.imageURL=""
```

### 7. Repo automations

Now we have a simple process to deploy the repo using [github actions](https://github.com/features/actions).
These actions can also be run on your own runners using [gittea actions](https://docs.gitea.com/usage/actions/overview).

> Possiblities from here are unlimited, you can easily have any pull to the main deploy a feature environment or connect a backend to your nextjs app