## Context

Path A App-of-Apps (no Root): checked-in wrapper under `environments/<env>/argocd/`. Draven wrapper uses `targetRevision: '*'`; children get `lock_children_to_revision: "*"` so each child Application also has literal `targetRevision: "*"`, resolved **independently** by Argo to the highest SemVer tag. Infra release tags exist (`infra-semver-release` / #42). Notifications (#43) and SemVer release rollback (#57) are separate. Issue #68 asks for operator docs only.

Stakeholders: operators with Argo access (global admin or `fairagro-m42-admin`); colleagues without UI who need to understand emergency pin vs SemVer release rollback.

## Goals / Non-Goals

**Goals:**

- Document a **correct** emergency pin procedure (sync-pause + wrapper + all children).
- Give a short happy-path + emergency pin / SemVer release rollback / bypass map; link from README; fix stale #43 pointer.
- Use **plain language** in docs and filenames (no opaque letter codes).

**Non-Goals:**

- Implementing SemVer release rollback (#57) or notifications (#43).
- Changing chart defaults or automating pin in Argo.

## Decisions

1. **Doc location: `docs/ops/emergency-pin.md` + README link**
   Single CLI-first runbook; README is the entry point from GitOps text.

2. **Emergency pin requires sync pause on the wrapper**
   Without pausing automated sync / selfHeal, children stay on `*` and pins are overwritten.

3. **Revision identity differs by environment**
   Draven: SemVer tag. Fizz: commit SHA / older tip. Document both; discourage fizz emergency pin as default.

4. **Who may pin**
   Both global Argo admin and `fairagro-m42-admin` may pin; no extra RBAC change in this change.

5. **SemVer release rollback is the lasting exit**
   Runbook tells operators to prefer shipping a SemVer release rollback / fixed tag, then restore `*` and re-enable sync — not leave clusters pinned indefinitely.

6. **No R1/R2 codes**
   Prefer “emergency pin” and “SemVer release rollback (#57)” everywhere operators read.

## Risks / Trade-offs

- **[Risk] Bootstrap re-apply undoes pins** → Mitigation: explicit “do not run setup_project_in_argocd.sh / upsert wrapper YAML while pinned”.
- **[Trade-off] Docs-only does not make pin easier** → Acceptable; chart redesign is a follow-up if pin is used often.

## Migration / Compatibility

- After merge, optionally dry-run pin steps on fizz (non-prod) to validate CLI wording — not required to merge.
- Filename: `docs/ops/emergency-pin.md` (not `r1-*.md`).
