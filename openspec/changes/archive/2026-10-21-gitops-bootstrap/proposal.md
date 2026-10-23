## Why

The wrapper Argo CD Application is created on-the-fly by `scripts/setup_project_in_argocd.sh` and lives only in the cluster DB. Sync is manual; there are no checked-in Application manifests, no Root app, and no clear rule that **fizz-class** tracks `main` while **draven** tracks SemVer release tags via `targetRevision: '*'`. That blocked multi-person deploys and the planned release workflow (#40 / #41). We need GitOps bootstrap first so later release tags and auto-sync have something durable to follow.

## What Changes

- Add checked-in wrapper Application manifests under `environments/{fizz,elise,draven}/argocd/` (and document local_dev as non-Argo / out of scope for this change).
- fizz-class wrappers: `targetRevision: main` + automated sync (including child Applications where practical).
- draven wrapper: `targetRevision: '*'` (optional `tagPrefix` if needed) so the highest SemVer infra release tag is selected; CI never rewrites this field.
- Introduce a one-shot **Root** Application per Argo-backed cluster that syncs `environments/<env>/argocd/` from `main`.
- Shrink / re-purpose `scripts/setup_project_in_argocd.sh` to bootstrap the Root (or document equivalent one-shot apply).
- Define child `*_revision` behaviour: fizz-class overridable defaulting to `main`; draven children locked to the same git revision as the release snapshot (not bare `HEAD` → main).
- **Non-goals:** ApplicationSet for tag follow; release/rollback GitHub workflows (#42); Argo Notifications / R1 runbook (#43); RDI catalog (#44); Image Updater; CI committing version pins; app-code changes under `deps/`.

## Capabilities

### New Capabilities

- `argocd-gitops-bootstrap`: Checked-in Argo CD Application (and Root) layout per environment, with fizz-class → `main` and draven → `*`, plus child-revision asymmetry and bootstrap script/docs.

### Modified Capabilities

- (none — no existing OpenSpec main specs in this repo yet)

## Impact

- New paths: `environments/{fizz,elise,draven}/argocd/*.yaml` (plaintext Application manifests; no secrets in these files).
- Script/docs: `scripts/setup_project_in_argocd.sh` and README or ops notes for one-shot Root create.
- Possible small changes to `helmcharts/fairagro-m42-applications` values/templates for child revision defaults / lock behaviour.
- Env values `fairagro-m42-applications.yaml` may set explicit `*_revision: main` (fizz-class) or tag-aligned revisions (draven) as designed.
- Clusters: operators must apply Root once per Argo instance; existing live wrapper apps need a documented migration (upsert / adopt) without requiring downtime beyond a sync.
- Tracks GitHub issue #41 (parent epic #40).
