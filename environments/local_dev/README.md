# Local kind environment for stack integration tests

Prerequisites (inside the Dev Container with DinD):

```bash
./scripts/init-submodules.sh   # once / after clone
./scripts/local-dev-up.sh      # kind + ingress
./scripts/local-dev-build.sh   # docker build + kind load
./scripts/local-dev-deploy.sh  # helm install API + harvester
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
- `sql_to_arc` is built as an image but not deployed here yet (no umbrella chart).
- Datahub / real RDIs still need network access from the kind cluster.
