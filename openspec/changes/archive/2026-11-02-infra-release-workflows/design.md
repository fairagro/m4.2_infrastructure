## Context

Path A GitOps is in place (`argocd-gitops-bootstrap`): fizz/elise track `main`; draven wrapper uses `targetRevision: '*'`. Image pins are env-asymmetric (fizz may use product pre-releases; draven only releases), enforced by `scripts/check_draven_release_pins.sh`. What is missing is cutting **infra** SemVer tags so `*` resolves.

Product repos (harvester/API) already release via `workflow_dispatch` with an explicit `version_bump` choice — not auto-SemVer from commits. Explore for #42 locked the same model here, Soft-only fizz attestation, and a Thin MVP (no R2, no commitlint/helm in this change).

Stakeholders: operators who promote to draven without Argo UI; reviewers of promote PRs; Argo on-prem (consumes tags only).

## Goals / Non-Goals

**Goals:**

- One-click (Actions) path: bump choice + Soft fizz checkbox → pin check → tag + GitHub Release on `main`.
- Document when to choose major/minor/patch and that tags should come from the WF.
- Keep golden rule: CI never commits pin or Application YAML changes.

**Non-Goals:**

- R2 rollback WF (#57).
- commitlint, merge-time/pre-tag helm template (#46).
- Fizz image lineage, git-history protocol, or Argo Healthy gates.
- Tag-protection Ruleset (README hint only).
- Changing Argo manifests, pin policy, or product image build pipelines.

## Decisions

### 1. Manual SemVer bump (not conventional-commit auto)

- **Choice:** `workflow_dispatch` input `version_bump: major | minor | patch`, default `patch`. Next version = highest existing SemVer tag + bump (ignore non-SemVer tags).
- **Why:** Matches product repos; infra commits are mostly chore pins — auto-`feat`/`fix` would mis-signal. Soft Leitplanken in README guide humans.
- **Alternatives:** semantic-release from commits (rejected); calendar/`0.0.N` always (too coarse for communication/R2 later).

### 2. Soft fizz comparability only

- **Choice:** Required boolean input (e.g. `fizz_validated`) must be `true` or the workflow fails before tagging. No comparison of current/historical fizz pins to draven.
- **Why:** Current fizz pin is not proof of past validation (fizz moves on). Lineage/history deferred; human attestation is the Thin MVP contract.
- **Alternatives:** Medium lineage vs HEAD (rejected); git-history “was ever on fizz” (deferred); Argo health (impossible from GitHub-hosted runners).

### 3. Validate-then-tag job shape

- **Choice:** Single workflow, roughly: assert `main` → assert Soft checkbox → run draven pin script on the checkout → compute version → create annotated tag → `gh release create` with notes summarizing bump + reminder of Soft attestation. Fail closed: no tag if any gate fails.
- **Why:** Same validate-then-tag story as #42; pin script already exists and matches policy.
- **Alternatives:** Separate “propose version” PR (conflicts with golden rule / Thin MVP); tag without Release (worse colleague UX).

### 4. Version / tag identity

- **Choice:** Plain SemVer tags (`1.2.3`), no `v` prefix unless the repo already standardizes otherwise — Argo `*` matches SemVer; keep tags Argo-friendly. First tag when none exist: **`0.1.0`** on a `patch`/`minor` request from empty, or allow `major` → `1.0.0` (document in README).
- **Why:** Draven Application uses bare `*`; product images use their own `docker-v` scheme and must not be conflated with infra tags.
- **Alternatives:** `infra-v` prefix + Argo tagPrefix (extra config, deferred unless needed).

### 5. Docs vs Ruleset for tag protection

- **Choice:** README states tags SHOULD be created only via the Release workflow; no Ruleset in this change.
- **Why:** Agreed Thin MVP; Ruleset needs org/admin follow-up.
- **Alternatives:** Enforce immediately (out of scope).

### 6. OpenSpec capability boundary

- **Choice:** New capability `infra-semver-release`; do not MODIFY `argocd-gitops-bootstrap` (it already requires `*` and explicitly deferred tagging).
- **Why:** Clean separation: bootstrap = how Argo tracks; this change = how tags are produced.

## Risks / Trade-offs

- **[Soft checkbox is honor-system]** → Mitigation: README wording; promote PR / trial cadence still the real control; lineage later if needed (#42 follow-up).
- **[First tag / empty tag set]** → Mitigation: document `0.1.0` / `1.0.0` behaviour; bootstrap already allows “no tag yet”.
- **[Manual wrong bump]** → Mitigation: Leitplanken; default `patch`; Release notes show chosen bump.
- **[Tag created but Argo not applied / no auto-sync]** → Mitigation: outside this change; ops must have wrapper with `*` applied (#41); notifications are #43.
- **[Concurrent dispatch]** → Mitigation: workflow `concurrency` group so only one release runs at a time.

## Migration Plan

1. Land WF + README on `main` (no cluster change).
2. Ensure draven wrapper with `*` is applied (bootstrap).
3. Cut first infra tag via WF after a known-good promote (or empty promote if pins already release-only).
4. Verify Argo resolves the new tag on draven.
5. Rollback of a bad tag content is **not** deleting the tag in-cluster story — use R1 pin (#43) or future R2 (#57); do not rewrite history as the happy path.

## Open Questions

- Exact GitHub Release notes template (changelog from commits since last tag vs short static summary) — default to short summary + link to compare URL unless #46 commitlint makes richer notes cheap.
- Whether `workflow_dispatch` is restricted to a GitHub Environment (`draven-release`) with required reviewers — nice hardening; optional in implementation if low cost, otherwise follow-up.
