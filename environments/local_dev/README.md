# Local kind environment for stack integration tests

Prerequisites (inside the Dev Container with DinD):

```bash
./scripts/init-submodules.sh   # once / after clone
./scripts/local-dev-up.sh      # kind + ingress + Zalando postgres-operator
./scripts/local-dev-build.sh   # docker build + kind load
./scripts/local-dev-deploy.sh  # helm install API + harvester + sql-to-arc
```

Tear down:

```bash
./scripts/local-dev-down.sh
```

Context:

```bash
source ./scripts/set_context.sh local_dev
```

## Notes

- Images are built from git submodules under `deps/` and never pushed.
- `sql-to-arc` chart: `helmcharts/fairagro-advanced-middleware-sql-to-arc` (Zalando `postgresql` CR, converter Job with dump-reload init container). Values: `values/fairagro-advanced-middleware-sql-to-arc.yaml`.
- Postgres Operator is installed by `local-dev-up.sh` (not present on kind by default). Ensure `teamId: fairagro` is allowed.
- Edaphobase dump bootstrap downloads from `https://repo.edaphobase.org/rep/dumps/FAIRagro.sql` — **no local fallback**; kind needs egress to that URL.
- Datahub / real RDIs still need network access from the kind cluster.
