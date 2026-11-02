## Why

Draven’s wrapper already tracks SemVer via Argo `targetRevision: '*'`, but this repo has no way to cut infra release tags. Operators cannot promote a validated `main` (after a draven image promote PR) onto production without Argo UI tricks or ad-hoc tags. Issue #42 Thin MVP closes that gap: a GitHub Actions validate-then-tag workflow aligned with product repos.

## What Changes

- Add a **Release** GitHub Actions workflow (`workflow_dispatch` only) that, on `main`:
  - takes manual `version_bump` (`major` | `minor` | `patch`);
  - requires a Soft **fizz validated** checkbox;
  - reuses `scripts/check_draven_release_pins.sh` (no pre-release pins under `environments/draven/values/`);
  - computes the next SemVer from existing tags, creates the git tag, and publishes a GitHub Release.
- Document SemVer **Leitplanken** and the operator release step in the README (manual bump like product repos; image-pin-only promotes are normally `patch`; tags should be cut via the workflow — Ruleset later).
- **Non-goals (explicit):** R2 rollback (#57); commitlint / helm template (#46); fizz image lineage or history protocol; live Argo health; tag-protection Ruleset enforce; `argocd app set` / auto-rollback; CI committing pins (golden rule unchanged).

## Capabilities

### New Capabilities

- `infra-semver-release`: Manual SemVer tagging for this infra repo so draven’s `*` revision resolves to a validated snapshot; Soft fizz attestation; draven pin gate before tag; GitHub Release; operator docs.

### Modified Capabilities

- (none — `argocd-gitops-bootstrap` already requires draven `*`; this change supplies the tags that `*` selects. First-tag “no match yet” behaviour of bootstrap remains valid until the first successful release.)

## Impact

- New workflow under `.github/workflows/` (release); permissions for contents/releases.
- README GitOps / pin-cadence section extended with SemVer Leitplanken + release step.
- Reuses existing `scripts/check_draven_release_pins.sh` and `.github/workflows/check-draven-pins.yml` (no change to pin policy).
- Clusters: after the first tag exists and the draven wrapper is applied with `*`, Argo follows subsequent tags automatically.
- Tracks GitHub issue #42 (parent epic #40); R2 deferred to #57; QA/commitlint/helm to #46.
