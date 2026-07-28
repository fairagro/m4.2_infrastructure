# ADDED Requirements

## Requirement: Dedicated Helm chart for sql-to-arc

The infrastructure repository SHALL provide a Helm chart at `helmcharts/fairagro-advanced-middleware-sql-to-arc/` that deploys sql-to-arc as its own Argo CD Application, parallel to the advanced middleware harvester, without embedding sql-to-arc into the harvester chart.

### Scenario: Chart is installable via umbrella Application

- **WHEN** an environment enables the sql-to-arc Application in `fairagro-m42-applications`
- **THEN** Argo CD syncs a Helm release from `helmcharts/fairagro-advanced-middleware-sql-to-arc` into a dedicated namespace for sql-to-arc

## Requirement: Postgres RDI database via Zalando Operator

The sql-to-arc chart SHALL declare a Zalando Postgres Operator resource (`apiVersion: acid.zalan.do/v1`, `kind: postgresql`) so the cluster-wide operator provisions Postgres hosting an `rdi` database usable by the converter (conceptual equivalent of the `postgres` service in `compose.dev.yaml`). The `rdi` database SHALL be declared in the CR `databases:` field. The chart MUST NOT deploy its own Postgres container stack (no hand-rolled Deployment/StatefulSet or Bitnami Postgres subchart).

### Scenario: Converter can connect to operator-managed Postgres

- **WHEN** the sql-to-arc workload starts after the operator cluster is ready and database bootstrap has completed
- **THEN** it connects using a connection string (secret via env) targeting the operator-managed Postgres `rdi` database

## Requirement: Edaphobase database bootstrap

The chart SHALL run a bootstrap Job that loads the Edaphobase dump into the operator-provisioned `rdi` database by downloading it from the configured URL (default `https://repo.edaphobase.org/rep/dumps/FAIRagro.sql`). The Job MUST NOT use a local or pre-staged dump fallback. Creating the `rdi` database itself is the operator’s responsibility via the `postgresql` CR.

### Scenario: Successful dump import

- **WHEN** Postgres is ready and the bootstrap Job runs with network access to the Edaphobase dump URL
- **THEN** the Job imports the dump into database `rdi` and exits successfully

### Scenario: Download failure fails the Job with a clear error

- **WHEN** download of the Edaphobase dump fails (network error, non-success HTTP status, or empty/invalid response)
- **THEN** the Job exits non-zero and logs an actionable error that names the dump URL and that no local fallback is used

## Requirement: Converter schedule by environment

The chart SHALL support both a one-shot Job and a CronJob for the converter. The **elise** overlay SHALL run a one-shot Job only (no CronJob). The **fizz** overlay SHALL enable a CronJob for scheduled runs.

### Scenario: elise uses one-shot Job

- **WHEN** sql-to-arc is deployed with elise values
- **THEN** a converter Job is created and no converter CronJob is active

### Scenario: fizz uses CronJob

- **WHEN** sql-to-arc is deployed with fizz values that enable the CronJob
- **THEN** a converter CronJob runs on the configured schedule

## Requirement: Converter workload with Middleware API mTLS

The chart SHALL run the sql-to-arc converter against the configured RDI (`edaphobase` by default) and Middleware API URL. Non-secret and structural settings SHALL come from a `config.yaml` file (same shape as `deps/m4.2_sql_to_arc/dev_environment/config.dev.yaml`), served from a Kubernetes ConfigMap and passed to the process with `-c` (or equivalent). Client certificate and private key SHALL be mounted into the pod from a Kubernetes Secret as files; `config.yaml` SHALL reference those paths via `api_client.client_cert_path` and `api_client.client_key_path`. Other secrets — primarily passwords — SHALL be managed as process environment variables from Kubernetes Secrets. Environment variables MUST NOT be used for non-secret settings (`api_url`, `rdi`, log level, cert paths, etc.). The deployment SHOULD use a dedicated sql-to-arc client identity; reusing the harvester client identity is allowed only as an interim measure.

### Scenario: Converter authenticates to API via mounted TLS files

- **WHEN** sql-to-arc runs with client cert and key volume-mounted from a Secret and those paths set in `config.yaml`
- **THEN** the process authenticates to the Middleware API with mutual TLS using the files at those paths (no env var for cert/key PEMs)

### Scenario: Non-secret config via ConfigMap config.yaml

- **WHEN** an operator changes non-secret settings (`api_url`, `rdi`, log level, cert paths, concurrency, otel, and related keys)
- **THEN** those settings appear in the mounted `config.yaml` ConfigMap and the converter reads them from that file — not from environment variables

### Scenario: Passwords and other non-TLS secrets via env vars

- **WHEN** a password or similar non-TLS secret is required (e.g. DB password, full connection string override)
- **THEN** it is injected as a process environment variable from a Kubernetes Secret and MUST NOT appear in the ConfigMap

## Requirement: Secrets via SOPS overlays

Client cert/key PEM material and password/connection-string secret material SHALL be supplied through encrypted Helm value files (`*.enc.yaml`) and MUST NOT be committed in plaintext. At runtime: TLS cert/key SHALL be Secret volume mounts (paths in `config.yaml`); passwords and other non-TLS secrets SHALL be Secret-backed environment variables.

### Scenario: Encrypted secrets overlay

- **WHEN** the Argo Application lists both plaintext and `.enc.yaml` value files for sql-to-arc
- **THEN** SOPS-decrypted secrets populate Kubernetes Secrets used for TLS file mounts and for password/env injection

## Requirement: Environment overlays and local_dev deployability

The **elise** environment SHALL have value overlays for the sql-to-arc chart. The **fizz** environment MAY have overlays when operational testing is enabled. The **draven** environment is out of scope for this change. **local_dev** SHALL have overlays and SHALL be able to use the image built by `scripts/local-dev-build.sh` (e.g. `fairagro-sql-to-arc:local`).

### Scenario: local_dev uses locally built image

- **WHEN** kind has loaded `fairagro-sql-to-arc:<tag>` from `local-dev-build.sh` and local_dev values point at that image
- **THEN** the sql-to-arc converter Pod/Job runs that image without requiring a pull from a remote registry

### Scenario: elise overlay exists

- **WHEN** operators deploy sql-to-arc for deployment testing
- **THEN** `environments/elise/values/fairagro-advanced-middleware-sql-to-arc.yaml` (+ `.enc.yaml`) is available to the Argo Application
