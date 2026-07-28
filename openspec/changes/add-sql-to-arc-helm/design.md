# Context

`sql_to_arc` converts Edaphobase SQL into ARCs and uploads them to the Advanced Middleware API. Locally, `deps/m4.2_sql_to_arc/dev_environment/start-dev.sh` runs that stack via Compose:

```text
secrets (sops) → postgres → converter pod (dump-init → sql_to_arc) → external API (mTLS)
```

This infra repo already builds/loads the image for kind (`scripts/local-dev-build.sh`) but explicitly does not deploy it. The harvester is the closest operational pattern: thin umbrella chart + Argo Application under `fairagro-m42-applications` + env values / SOPS. Unlike the harvester, there is **no** published OCI Helm chart for sql-to-arc under `oci://registry-1.docker.io/zalf` yet, so this repo must own the chart templates initially.

Cluster roles (for scoping overlays):

| Environment | Role |
| - | - |
| `elise` | Deployment test |
| `fizz` | Operation test |
| `draven` | Production (out of scope for this change) |
| `local_dev` | kind integration (operator + chart exercise) |

## Goals / Non-Goals

**Goals:**

- First-class Helm + Argo CD deployment of sql-to-arc next to the harvester.
- Preserve the conceptual compose model: Postgres for RDI data, dump bootstrap, converter Job/CronJob, API mTLS via secrets — with deliberate deviations: bootstrap is download-only (no local dump fallback); Postgres via Zalando Operator CR, not Compose-style container Postgres.
- Environment overlays for **elise** (required) and optionally **fizz**, plus `local_dev` for kind; SOPS for credentials/keys.
- Keep application logic in `deps/m4.2_sql_to_arc`; this change is wiring only.

**Non-Goals:**

- Changing converter Python/CLI behaviour or Edaphobase schema mapping.
- Replacing Advanced Middleware API or CouchDB/RabbitMQ stacks.
- Installing or reconfiguring the cluster-wide Zalando Postgres Operator itself on elise/fizz/draven (it is a given there).
- Enabling sql-to-arc on **draven** (production) in this change.
- Publishing an OCI chart from the upstream sql_to_arc repo (may follow later; design should allow swapping to an umbrella dependency).
- Providing a local/pre-staged SQL dump fallback when download fails.

## Decisions

### 1. Chart name and layout

- **Choice:** Chart path `helmcharts/fairagro-advanced-middleware-sql-to-arc/` with templates for the Zalando `postgresql` CR, converter Job/CronJob (dump-init + convert), ConfigMap, TLS Secrets, ServiceAccount as needed.
- **Why not harvester-style OCI umbrella only?** No OCI sql-to-arc chart exists today; waiting blocks deployability.
- **Follow-up:** If upstream publishes an OCI chart, thin this repo chart to a dependency wrapper like the harvester.

### 2. Workload shape: Job on elise; CronJob on fizz

- **Choice:** Chart supports both a one-shot **Job** and a **CronJob** (values toggle).
  - **elise** (deployment test): one-shot Job only — no CronJob.
  - **fizz** (operation test): CronJob enabled for scheduled conversion runs.
- **Bootstrap:** Dump download + import runs as an **init container on every converter Job/CronJob pod** (not a separate one-shot Job), so each conversion uses a freshly downloaded daily dump. Init waits for Postgres Ready, then downloads and imports.
- **Why:** Matches compose semantics for elise (one run on deploy) and ensures fizz CronJob runs always see the latest dump.

### 3. Postgres: Zalando Postgres Operator (`acid.zalan.do/v1`)

- **Choice:** Declare a `postgresql` custom resource (same pattern as `helmcharts/fairagro-datahub/templates/postgres-db.yaml`). The **cluster-wide Zalando Postgres Operator** reconciles the CR — do **not** ship a chart-owned Postgres Deployment/StatefulSet/Bitnami subchart.
- **Why:** Operator is already installed cluster-wide on real clusters; matches existing infra (DataHUB); credentials/services follow operator conventions (e.g. `*.credentials.postgresql.acid.zalan.do`).
- **CR content:** `teamId` (e.g. `fairagro`), volume/size/storageClass from values, users + **`databases` including `rdi`** (operator creates DB/user; dump reload is converter init container), Postgres version aligned with start-dev (15+) / cluster practice (DataHUB uses 16).
- **Network:** Converter uses the operator-managed in-cluster Service DNS and Secret-backed password env vars. API URL points at in-cluster Advanced Middleware or an external URL as configured.
- **Alternative rejected:** Hand-rolled / Bitnami Postgres in the chart — duplicates what the operator already provides.

### 4. Dump bootstrap: download-only init container (every converter run)

- **Choice:** Dump download + import is an **init container** on the converter Job/CronJob pod, so every run (including each CronJob tick on fizz) refreshes `rdi` from the remote dump. **No** local/ConfigMap/PVC fallback SQL — unlike `compose.dev.yaml` `db-init`.
- **On failure:** Init container exits non-zero and logs an actionable message that includes the dump URL and states that download is required (no local fallback); the converter container does not start.
- **Cluster constraint:** Clusters need egress to `repo.edaphobase.org` (or the configured dump host); document this for ZALF egress policies.
- **Size:** Edaphobase dumps can be large — do not bake the dump into the git repo; download at each converter run.

### 5. Config and secrets (config.yaml + TLS mounts + password env vars)

- **ConfigMap `config.yaml`:** Non-secret configuration — same shape as `config.dev.yaml` (`rdi`, `api_url`, cert *paths*, concurrency, otel, log level). Mounted and selected with `-c`.
- **TLS cert/key:** Kubernetes Secret volume mounts (harvester pattern). Paths only in `config.yaml`. Compose’s `SQL_TO_ARC_CLIENT_KEY_DATA` → file write is local-only; in-cluster mount the PEMs directly.
- **Client identity:** Prefer a **dedicated sql-to-arc client certificate** (new identity). Reusing the harvester client identity is acceptable as a short-term fallback if issuing a new cert blocks deploy on elise.
- **Passwords / other non-TLS secrets:** Managed as env vars from Kubernetes Secrets (operator credentials). The chart sets `SQL_TO_ARC_CONNECTION_STRING` as a fixed env value using Kubernetes `$(VAR)` expansion over Service DNS + secret-backed `PGUSER`/`PGPASSWORD` — never stored in values/ConfigMap.
- **Do not** put PEM private keys or passwords in the ConfigMap.

### 6. Argo / naming / namespaces

- **Application:** Template under `helmcharts/fairagro-m42-applications/templates/` (e.g. `advanced-middleware-sql-to-arc.yaml`), valueFiles under `environments/<cluster>/values/fairagro-advanced-middleware-sql-to-arc.yaml` + `.enc.yaml`.
- **Namespace:** dedicated (e.g. `fairagro-advanced-middleware-sql-to-arc`), not shared with harvester.
- **Revision key:** e.g. `advanced_middleware_sql_to_arc_revision` on the umbrella values.
- **v1 target clusters:** **elise** (required); **fizz** optional/when ready; **draven** not in scope.

### 7. local_dev

- Wire deploy path so `local-dev-deploy.sh` (and docs) installs/syncs sql-to-arc with `image.repository/tag` = locally built `fairagro-sql-to-arc:local`, `imagePullPolicy: IfNotPresent`.
- **Postgres Operator on kind:** Not present today. Install it in `local-dev-up.sh` (or an adjacent step) via the official Helm chart — typically:

  ```bash
  helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
  helm upgrade --install postgres-operator postgres-operator-charts/postgres-operator -n postgres-operator --create-namespace
  ```

  That is the supported quickstart path for kind; no need to mirror the full production operator config. Ensure `teamId: fairagro` (or the CR’s teamId) is allowed in the operator config if the cluster restricts team IDs.
- Remove/update the current “built but not deployed” note once live.

## Risks / Trade-offs

- **[Large dump / Job time]** Bootstrap may exceed default Job activeDeadline → set generous deadlines and resource requests; allow skip-reimport when `rdi` already loaded (operator volume persists).
- **[Egress blocked to Edaphobase]** Download fails in locked-down clusters → Mitigation: fail the Job immediately with a clear log (URL + “no local fallback”); fix egress or dump URL in values — do not ship a silent alternate dump path.
- **[mTLS / API URL mismatch]** Wrong API host or client cert → Mitigation: elise/fizz values point at the correct middleware API + dedicated (or interim harvester) client material; validate with one dry-run Job.
- **[Operator / CR readiness]** Bootstrap must wait until the Zalando cluster is Ready and credentials Secret exists → Mitigation: sync-waves + wait-for conditions (same idea as DataHUB depending on operator).
- **[Dual chart ownership later]** Local templates vs future OCI chart → Mitigation: keep values schema close to app config keys so an OCI swap is mostly Chart.yaml dependency change.
- **[Argo hook ordering]** Hook Jobs can surprise sync → Mitigation: prefer explicit Job resources with documented sync waves (`argocd.argoproj.io/sync-wave`) over opaque hooks where possible.

## Migration Plan

1. Land chart `fairagro-advanced-middleware-sql-to-arc` + Application template + **elise** values (secrets encrypted); optionally **fizz** with CronJob.
2. Validate on **elise** (deployment test): Postgres Ready → dump-init Succeeded → converter Job completes against middleware API.
3. If/when enabling **fizz**: CronJob schedule + monitor operational runs.
4. **draven** later (out of scope here).
5. Rollback: disable/remove Application or pin previous revision; operator volume retain policy can keep DB for re-run.

## Open Questions

- (none — prior open questions resolved; see Decisions above)
