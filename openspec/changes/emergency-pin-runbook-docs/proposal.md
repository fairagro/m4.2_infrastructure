## Why

Draven follows SemVer via Argo `targetRevision: '*'`, and a bad tag can land in production before a SemVer release rollback (#57) exists. Operators with Argo access need a documented **emergency pin** that actually works with Path A and `lock_children_to_revision: "*"`. The README still pointed emergency pin at #43 and did not describe the sync-pause procedure. Issue #68 closes that docs gap (separate from notifications #43).

## What Changes

- Add a dedicated **emergency pin runbook** under `docs/` (CLI-first) covering:
  - pause wrapper automated sync / selfHeal;
  - pin wrapper **and** all children to the same known-good revision;
  - what not to do (bootstrap upsert while pinned);
  - exit via SemVer release rollback / fixed revision, then restore normal tracking.
- Same procedure shape for **draven** (SemVer tag) and **fizz** (typically commit SHA); state that emergency pin on fizz is unusual (prefer fix-forward / `main`).
- Short **process** section (happy path + emergency pin vs SemVer release rollback + ruleset bypass emergency-only).
- **README** link to the runbook; fix stale emergency-pin pointer (#43 → #68).
- Who may pin: global Argo admin **and** project admin (`fairagro-m42-admin`).
- **Non-goals:** SemVer release rollback workflow (#57); notifications (#43 / misc#571); auto-rollback; changing default `*` / `main` pins in git; implementing Argo automation for emergency pin.
- Naming: plain language only (**emergency pin**, **SemVer release rollback**) — no opaque letter codes (R1/R2).

## Capabilities

### New Capabilities

- `ops-emergency-pin`: Requirements for documenting and performing Argo emergency pin (sync-pause procedure, revision identity per env, roles, exit path, process cross-links).

### Modified Capabilities

- (none — `argocd-gitops-bootstrap` and `infra-semver-release` stay as-is; this change is operator documentation that consumes those behaviours.)

## Impact

- New markdown under `docs/` plus README GitOps section edits.
- No Helm/chart/workflow code changes required for MVP.
- Tracks GitHub issue #68 (parent epic #40); cross-links #43, #57, #46.
