## Context

Path A App-of-Apps (no Root): checked-in wrapper under `environments/<env>/argocd/`. Draven wrapper uses `targetRevision: '*'`; children get `lock_children_to_revision: "*"` so each child Application also has literal `targetRevision: "*"`, resolved **independently** by Argo to the highest SemVer tag. Infra release tags exist (`infra-semver-release` / #42). Notifications (#43) and R2 WF (#57) are separate. Issue #68 asks for operator docs only.

Stakeholders: operators with Argo access (global admin or `fairagro-m42-admin`); colleagues without UI who need to understand R1 vs R2.

## Goals / Non-Goals

**Goals:**

- Document a **correct** R1 procedure (sync-pause + wrapper + all children).
- Give a short happy-path + R1/R2/bypass map; link from README; fix stale #43 pointer.
- CLI-first instructions using `set_context.sh` / `argocd`.

**Non-Goals:**

- Implementing R2 (#57) or notifications (#43).
- Changing Helm `lock_children_to_revision` / default pins.
- Auto-rollback, ignoreDifferences hacks, or CI that edits Application YAML (golden rule).
- Full UI screenshot guide.

## Decisions

1. **Doc location: `docs/ops/r1-emergency-pin.md` (or `docs/ops/r1-runbook.md`) + README link**  
   Keeps README short; runbook can hold full CLI sequences. Alternative considered: README-only — rejected (too long / easy to stale).

2. **R1 requires sync pause on the wrapper**  
   With selfHeal, desired child specs from the umbrella still say `*`, so live child pins to an exact tag are reverted. Pause automated sync (and/or selfHeal) on the wrapper before pinning children. Alternative: redesign children to inherit resolved revision — deferred (chart change, not this doc).

3. **Same procedure, different revision id**  
   Draven: SemVer tag. Fizz: commit SHA / older tip. Document both; discourage fizz R1 as default. Alternative: draven-only runbook — rejected (user wants one procedure).

4. **CLI-first**  
   Match existing ops (`source ./scripts/set_context.sh <env>`, `argocd app …`). Optional one-liner that UI can pause sync too.

5. **Who: global admin and project admin**  
   Both may R1; no extra RBAC change in this change.

6. **R2 is the lasting exit**  
   Runbook tells operators to prefer shipping R2 / fixed tag, then restore `*` and re-enable sync — not leave clusters pinned indefinitely.

## Risks / Trade-offs

- **[Risk] Exact `argocd` flags for pause/resume differ by CLI version** → Mitigation: verify commands against current cluster CLI in apply; document `argocd app set --sync-policy none` / equivalent and how to restore automated+selfHeal.  
- **[Risk] Operator skips pause and thinks children are pinned** → Mitigation: runbook callout + “verify child sync.revisions” check.  
- **[Risk] Bootstrap re-apply undoes pins** → Mitigation: explicit “do not run setup_project_in_argocd.sh / upsert wrapper YAML while in R1”.  
- **[Trade-off] Docs-only does not make R1 easier** → Acceptable; chart redesign is a follow-up if R1 is used often.

## Migration Plan

- Docs-only merge to `main`; no cluster migration.  
- After merge, optionally dry-run R1 steps on fizz (non-prod) to validate CLI wording — not required to merge.

## Open Questions

- None blocking; optional filename (`r1-emergency-pin.md` vs `r1-runbook.md`) left to apply implementer (prefer `docs/ops/r1-emergency-pin.md`).
