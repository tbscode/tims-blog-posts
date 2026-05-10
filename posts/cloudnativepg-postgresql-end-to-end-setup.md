---
title: "CloudNativePG PostgreSQL End-to-End Setup Guide"
description: "A full copy/paste-ready walkthrough to install CloudNativePG, deploy PostgreSQL on Kubernetes, bootstrap users and tables, and verify with Python."
date: "2026-05-10T23:10:00+02:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["DevOps", "Database"]
tags: ["Kubernetes", "k3s", "CloudNativePG", "PostgreSQL", "Helm", "Python", "psycopg"]
---

I needed a PostgreSQL setup on Kubernetes that is:

- allows automatic creation of db instances
- allow configuration based pre-defining users, passwords and configurations
- can be included into other helm charts as depencency
- single configuration, one-install, full setup approach

For this, [CloudNativePG Helm Chart](TODO) is one of the cleanest approaches I've found so far ( after the [Bitnami Postgsql Helm Chart being moved closed source]() ).

So this is the exact setup I currently use as a base template.
Everything below is copy/paste-ready and end-to-end reproducible.

### What this creates

- namespace: `app-db`
- cluster: `app-postgres`
- database: `app`
- app user: `appuser`
- app password: `apppass`
- readonly user: `readonly`
- readonly password: `readonlypass`
- table: `public.items`

### 0) Move to your project and export kubeconfig

```bash
export KUBECONFIG=./kubeconfig.yaml
kubectl get nodes
```

### 1) Install the CloudNativePG operator

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install cnpg cnpg/cloudnative-pg --namespace cnpg-system --create-namespace
kubectl get pods -n cnpg-system
```

Wait until the operator pod is `Running` before continuing.

### 2) Create a manifest folder

```bash
mkdir -p cnpg-app-db
```

### 3) Create namespace manifest

```bash
cat > cnpg-app-db/namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: app-db
EOF
```

### 4) Create app credentials secret

```bash
cat > cnpg-app-db/db-secret.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: app-db-user
  namespace: app-db
type: kubernetes.io/basic-auth
stringData:
  username: appuser
  password: apppass
EOF
```

### 5) Create PostgreSQL cluster manifest

```bash
cat > cnpg-app-db/postgres-cluster.yaml <<'EOF'
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: app-postgres
  namespace: app-db
spec:
  instances: 2
  imageName: ghcr.io/cloudnative-pg/postgresql:17
  storage:
    size: 10Gi
  bootstrap:
    initdb:
      database: app
      owner: appuser
      secret:
        name: app-db-user
      postInitApplicationSQL:
        - CREATE USER readonly WITH PASSWORD 'readonlypass';
        - GRANT CONNECT ON DATABASE app TO readonly;
        - CREATE TABLE IF NOT EXISTS public.items (id SERIAL PRIMARY KEY, name TEXT NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW());
        - ALTER TABLE public.items OWNER TO appuser;
        - GRANT ALL PRIVILEGES ON TABLE public.items TO appuser;
        - INSERT INTO public.items (name) VALUES ('seed-row-from-bootstrap');
        - GRANT USAGE ON SCHEMA public TO readonly;
        - GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
        - ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
EOF
```

### 6) Create full Python test script

```bash
cat > cnpg-app-db/test_db_query.py <<'EOF'
#!/usr/bin/env python3
import argparse
import os
import sys
from urllib.parse import quote_plus

import psycopg


def build_dsn(args: argparse.Namespace) -> str:
    if args.dsn:
        return args.dsn

    user = quote_plus(args.user)
    password = quote_plus(args.password)
    host = args.host
    port = args.port
    dbname = args.database
    return f"postgresql://{user}:{password}@{host}:{port}/{dbname}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Run a test query against CloudNativePG")
    parser.add_argument("--host", default=os.getenv("PGHOST", "127.0.0.1"), help="PostgreSQL host")
    parser.add_argument("--port", default=os.getenv("PGPORT", "5432"), help="PostgreSQL port")
    parser.add_argument("--database", default=os.getenv("PGDATABASE", "app"), help="Database name")
    parser.add_argument("--user", default=os.getenv("PGUSER", "appuser"), help="Database user")
    parser.add_argument(
        "--password",
        default=os.getenv("PGPASSWORD", "apppass"),
        help="Database password",
    )
    parser.add_argument(
        "--dsn",
        default=os.getenv("DATABASE_URL"),
        help="Full PostgreSQL DSN. Overrides host/user/password options when set.",
    )
    args = parser.parse_args()
    dsn = build_dsn(args)

    try:
        with psycopg.connect(dsn) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT current_user, current_database(), version()")
                user_name, db_name, version = cur.fetchone()
                print(f"connected_as={user_name}")
                print(f"database={db_name}")
                print(f"version={version}")

                cur.execute("SELECT id, name, created_at FROM public.items ORDER BY id")
                rows = cur.fetchall()
                print(f"items_count={len(rows)}")
                for row in rows:
                    print(f"item id={row[0]} name={row[1]} created_at={row[2]}")
    except Exception as exc:
        print(f"connection/query failed: {exc}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
```

### 7) Fresh redeploy (safe reset for this cluster)

If you've tested a few times and want a clean restart, run the block below.
This recreates the setup from the manifests above.

```bash
kubectl delete cluster app-postgres -n app-db --ignore-not-found=true
kubectl delete pvc -n app-db --all --ignore-not-found=true
kubectl delete secret app-db-user -n app-db --ignore-not-found=true
kubectl apply -f cnpg-app-db/namespace.yaml
kubectl apply -f cnpg-app-db/db-secret.yaml
kubectl apply -f cnpg-app-db/postgres-cluster.yaml
```

### 8) Wait until cluster is ready

```bash
kubectl wait --for=condition=Ready cluster/app-postgres -n app-db --timeout=600s
kubectl get cluster -n app-db
kubectl get pods -n app-db
kubectl get svc -n app-db
```

Expected result:

- `app-postgres` shows healthy and ready instances
- Pods `app-postgres-1` and `app-postgres-2` are `Running`
- Services exist: `app-postgres-rw`, `app-postgres-ro`, `app-postgres-r`

### 9) Optional direct `psql` test in the pod

```bash
kubectl exec -it -n app-db app-postgres-1 -- psql -U appuser -d app
```

Then run:

```sql
SELECT current_user, current_database();
SELECT * FROM public.items;
\q
```

### 10) Install Python dependency (`psycopg`)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install psycopg[binary]
```

### 11) Test app user (`appuser`) via RW service

Terminal 1:

```bash
kubectl port-forward -n app-db svc/app-postgres-rw 5432:5432
```

Terminal 2:

```bash
source .venv/bin/activate
python cnpg-app-db/test_db_query.py --host 127.0.0.1 --port 5432 --database app --user appuser --password apppass
```

### 12) Test readonly user (`readonly`) via RO service

Terminal 1:

```bash
kubectl port-forward -n app-db svc/app-postgres-ro 5433:5432
```

Terminal 2:

```bash
source .venv/bin/activate
python cnpg-app-db/test_db_query.py --host 127.0.0.1 --port 5433 --database app --user readonly --password readonlypass
```

### 13) Useful connection strings

```text
postgresql://appuser:apppass@app-postgres-rw.app-db.svc.cluster.local:5432/app
postgresql://readonly:readonlypass@app-postgres-ro.app-db.svc.cluster.local:5432/app
postgresql://appuser:apppass@127.0.0.1:5432/app
postgresql://readonly:readonlypass@127.0.0.1:5433/app
```

### Notes from my side

- Keeping bootstrap SQL in the cluster manifest is very convenient for small/medium setups.
- Splitting `rw` and `ro` service usage early helps avoid accidental write paths later in app code.
- For production, definitely swap the demo passwords and move secrets handling to your preferred secret manager flow.

That's it.
From here you have a reproducible CloudNativePG Postgres setup with:

- predefined users
- schema bootstrap
- seed data
- python connectivity test
- read/write and readonly validation paths

## Optional Add-On: DNS-01 cert flow

If you want to keep using your domain-based access (`test-db.<your-domain>.com`) with stronger trust setup across clients, a DNS-01 cert-manager flow is a good optional add-on.

At minimum:

1. install your DNS webhook solver
2. create a `ClusterIssuer`
3. issue certificate(s) and use them in your service exposure stack

I still keep this optional here, because CNPG already gives working Postgres TLS out of the box.

## Optional Add-On: tiny tailscale gimmick (cluster-to-cluster)

If you have tailscale operator on both clusters, you can expose this DB quickly via tailnet and consume it from another cluster using a simple `ExternalName` service.

High-level mini flow:

1. annotate exposed DB service with `tailscale.com/expose=true`
2. use tailnet hostname (`test-db.<tailnet>.ts.net`)
3. in cluster 2, create `ExternalName` -> that hostname

Useful when you just want quick private cross-cluster connectivity without extra public routing work.

Cheers Tim
