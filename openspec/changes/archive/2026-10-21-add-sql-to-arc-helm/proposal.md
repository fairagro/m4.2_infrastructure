# Why

`sql_to_arc` can already be built into kind via `deps/` and `local-dev-build.sh`, but this infrastructure repo has no Helm/Argo CD path to run it. The converter’s intended operational model already exists in `deps/m4.2_sql_to_arc/dev_environment/start-dev.sh` (Postgres + Edaphobase init + converter talking to an external Middleware API with mTLS). We need the same conceptual stack deployable next to the harvester so Edaphobase SQL→ARC conversion runs on-cluster like other Measure 4.2 jobs.

## What Changes

- Add Helm chart `helmcharts/fairagro-advanced-middleware-sql-to-arc/` (and Argo CD Application wiring), parallel to `fairagro-advanced-middleware-harvester`.
- Chart behaviour mirrors `start-dev.sh` / `compose.dev.yaml`:
  - PostgreSQL for the RDI database via the cluster-wide **Zalando Postgres Operator** (`acid.zalan.do/v1` CR; `rdi` declared in the CR)
  - Dump download + import as an init container on every converter Job/CronJob run (no local fallback; fail with a clear error if download fails)
  - sql-to-arc converter: **Job on elise**, **CronJob on fizz**
  - Non-secret config via `config.yaml` in a ConfigMap; client cert/key as Secret volume mounts (paths in config); passwords as env vars from Secrets
  - Prefer a **dedicated** sql-to-arc mTLS client identity (harvester identity acceptable only as interim)
- Environment overlays: **elise** (deployment test, required); **fizz** (operation test, optional); **draven** out of scope; plus `local_dev` for kind.
- Extend local-dev scripts so kind installs the Postgres Operator and can deploy the chart against `fairagro-sql-to-arc:local`.

## Capabilities

### New Capabilities

- `sql-to-arc-deploy`: Cluster deploy of sql-to-arc as a first-class Argo/Helm application with Zalando-managed Postgres, DB bootstrap, converter Job/CronJob, and Middleware API client configuration (including mTLS), matching the conceptual model of `start-dev.sh`.

### Modified Capabilities

- (none — no existing OpenSpec main specs yet)

## Impact

- New chart at `helmcharts/fairagro-advanced-middleware-sql-to-arc/` and Argo template in `helmcharts/fairagro-m42-applications`.
- New `environments/{elise,fizz?,local_dev}/values/fairagro-advanced-middleware-sql-to-arc.yaml` (+ `.enc.yaml`).
- Depends on published or locally built sql-to-arc image (`deps/m4.2_sql_to_arc`).
- Runtime dependency on Advanced Middleware API, cluster-wide Zalando Postgres Operator (installed via Helm on kind), and Edaphobase dump URL egress.
- Operational: operator-managed storage; Job vs CronJob per environment; dedicated client cert preferred.
