## Context

Forward infra SemVer tagging lives in `.github/workflows/release.yml` (#42 / `infra-semver-release`):
`workflow_dispatch` on `main`, Soft fizz checkbox, draven pin gate, `version_bump`, tag + GitHub Release at
`GITHUB_SHA`. Draven Argo uses `targetRevision: '*'`. Emergency pin (`docs/ops/emergency-pin.md`) is the Argo-side
temporary path; lasting rollback without UI is issue #57.

Explore decisions (2026-11-05): separate rollback workflow; tag at old SHA; always patch; previous + optional override;
shared concurrency; hard-fail if target equals highest SemVer.

## Goals / Non-Goals

**Goals:**

- Operator can roll draven back to the previous (or overridden) SemVer tree via Actions only.
- New higher patch tag on the target tag’s commit; Release notes say rollback.
- Docs: both workflows are the allowed SemVer producers; plain language only.

**Non-Goals:**

- Soft fizz attestation on rollback; Argo API; auto-rollback on health; rewriting env values; major/minor bump choice on
  rollback; history rewrite of bad tags.

## Decisions

1. **Separate workflow (`release-rollback.yml`)** — Forward MVP stays thin; Actions UI matches intent. Alternative (one
   WF, mode input) rejected for mis-click risk.

2. **Tag at target SHA** — `git tag -a <next> <target_sha>`; no new commit. Compare URLs may be empty; notes MUST state
   same tree as target tag.

3. **Always patch** — `compute_next_infra_semver.sh patch` against current highest (including the bad tip). No
   `version_bump` input.

4. **Target resolution** — Empty `revert_to_tag` ⇒ second-highest plain SemVer; non-empty ⇒ that tag (must exist, plain
   SemVer). Fail if fewer than two SemVer tags when using previous.

5. **Hard-fail if target == highest** — Avoid noop renumbering of tip.

6. **Shared concurrency `infra-semver-tag`** — Both forward and rollback; `cancel-in-progress: false`. Update forward WF
   group from `${{ github.workflow }}`.

7. **Pin gate on restored tree** — Checkout/check at target SHA before tagging.

8. **Shared tag/Release tail** — Prefer a small script or duplicated careful steps initially; extract if duplication
   hurts. Preserve forward orphan-tag retry semantics; rollback creates a _new_ tag name on an _old_ SHA (forward “reuse
   tag at this SHA” must not block naming a new version).

9. **Docs** — README + emergency-pin: “SemVer release rollback” workflow name; tags only via `release` or
   `release-rollback`; drop issue-only pointers where the WF exists.

## Risks / Trade-offs

- **[Risk] Parallel forward+rollback race** → Shared concurrency group.
- **[Risk] Operator expects free-form “any old good tag” as default** → Default is previous; override documented.
- **[Risk] Multiple tags on one commit confuse humans** → Notes + runbook; normal for this model.
- **[Risk] Ruleset later blocks one of two WFs** → Document both as producers when Ruleset lands.

## Migration Plan

- Ship WF + docs on `main`; no cluster change until an operator runs rollback.
- First use needs ≥2 existing SemVer tags (chicken-egg after first #42 release).

## Open Questions

- None blocking (explore closed).
