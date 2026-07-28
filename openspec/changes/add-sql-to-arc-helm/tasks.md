# 1. Chart scaffold

- [ ] 1.1 Create `helmcharts/fairagro-advanced-middleware-sql-to-arc/` with `Chart.yaml`, `values.yaml`, `.helmignore`, and helpers
- [ ] 1.2 Mirror DataHUB Zalando `postgresql` CR conventions (`teamId`, volume, users/`databases` including `rdi`, version); document dependency on cluster-wide postgres-operator
- [ ] 1.3 Add default values for image, Zalando CR sizing/storageClass, dump URL, converter config (`rdi`, `api_url`, TLS paths), Job vs CronJob toggles

## 2. Workload templates

- [ ] 2.1 Add `acid.zalan.do/v1` `postgresql` CR template (DataHUB pattern) with `rdi` under `databases:` / users
- [ ] 2.2 Add db-init Job: wait for operator Postgres Ready + credentials; download and import Edaphobase dump into existing `rdi` only (clear error on failure); generous deadlines
- [ ] 2.3 Add converter Job + CronJob templates (values toggle); mount ConfigMap `config.yaml` via `-c`; mount client cert/key from Secret volumes; inject passwords via env vars
- [ ] 2.4 Add ConfigMap for non-secret `config.yaml`; Secret templates for TLS PEMs (volume mounts) and passwords/connection string (env vars)
- [ ] 2.5 Set Argo sync-wave / ordering annotations so Postgres → bootstrap → converter is predictable

## 3. Argo CD wiring

- [ ] 3.1 Add Application template under `helmcharts/fairagro-m42-applications/templates/` for advanced-middleware-sql-to-arc (dedicated namespace + valueFiles)
- [ ] 3.2 Add umbrella revision/enable keys (e.g. `advanced_middleware_sql_to_arc_revision`) in m42-applications values defaults
- [ ] 3.3 Verify with `helm template` that manifests render for elise (and fizz if present)

## 4. Environment values

- [ ] 4.1 Add `environments/elise/values/fairagro-advanced-middleware-sql-to-arc.yaml` (+ `.enc.yaml`): one-shot Job only (no CronJob); pinned image; API/mTLS settings; prefer dedicated client cert
- [ ] 4.2 Add `environments/fizz/values/fairagro-advanced-middleware-sql-to-arc.yaml` (+ `.enc.yaml`) when enabling operation test: CronJob enabled
- [ ] 4.3 Add `environments/local_dev/values/fairagro-advanced-middleware-sql-to-arc.yaml` (+ `.enc.yaml`) using `fairagro-sql-to-arc:local` / `IfNotPresent`
- [ ] 4.4 Do not add draven overlays in this change (production out of scope)

## 5. Local-dev integration

- [ ] 5.1 Extend `scripts/local-dev-up.sh` to install Zalando postgres-operator via Helm if missing (kind-friendly defaults; allow `teamId` used by the CR)
- [ ] 5.2 Update `scripts/local-dev-deploy.sh` (and/or related docs) to deploy/sync sql-to-arc; remove “built but not deployed” note
- [ ] 5.3 Update `environments/local_dev/README.md` to describe sql-to-arc, operator prerequisite, and Edaphobase dump egress (no local fallback)

## 6. Verification

- [ ] 6.1 `helm template` the chart with elise (and fizz/local_dev) values; fix render errors
- [ ] 6.2 On kind and/or elise: confirm Postgres Ready → bootstrap Job Succeeded → converter Job reaches Middleware API
- [ ] 6.3 Confirm no plaintext client keys or DB passwords are committed outside `.enc.yaml`
