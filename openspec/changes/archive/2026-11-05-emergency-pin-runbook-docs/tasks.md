## 1. Emergency pin runbook

- [x] 1.1 Create `docs/ops/emergency-pin.md` with sync-pause → wrapper pin → child pins → no-bootstrap → exit sequence
- [x] 1.2 Document why wrapper-only pin fails under `lock_children_to_revision: "*"`
- [x] 1.3 Document draven (SemVer tag) vs fizz (commit SHA; emergency pin unusual) revision identity
- [x] 1.4 Document who may pin (global Argo admin and `fairagro-m42-admin`)
- [x] 1.5 Use plain language only (no R1/R2 letter codes)

## 2. Process + README

- [x] 2.1 Add short happy-path + emergency pin vs SemVer release rollback + emergency-only ruleset bypass section (in
      the runbook)
- [x] 2.2 Link the runbook from README GitOps / rollback text; replace stale emergency-pin → #43 pointer with #68 / docs
      path
