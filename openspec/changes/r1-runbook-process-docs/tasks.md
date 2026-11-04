## 1. R1 runbook

- [ ] 1.1 Create `docs/ops/r1-emergency-pin.md` with sync-pause → wrapper pin → child pins → no-bootstrap → exit sequence
- [ ] 1.2 Document why wrapper-only pin fails (`lock_children_to_revision: "*"` / literal child `*`)
- [ ] 1.3 Document draven (SemVer tag) vs fizz (commit SHA; R1 unusual) revision identity
- [ ] 1.4 Document who may R1 (global Argo admin and `fairagro-m42-admin`)
- [ ] 1.5 Add CLI-first commands (`set_context.sh`, pause/resume sync, set `targetRevision` on wrapper + children, verify revisions); optional short UI note

## 2. Process map + README

- [ ] 2.1 Add short happy-path + R1 vs R2 + emergency-only ruleset bypass section (in the runbook or adjacent `docs/ops/` page)
- [ ] 2.2 Link the runbook from README GitOps / rollback text; replace stale R1 → #43 pointer with #68 / docs path
- [ ] 2.3 Cross-link #43, #57, #46 where operators need them

## 3. Verify

- [ ] 3.1 Confirm documented app names match live names (`fairagro-m42-applications` + children) via `argocd app list` / kubectl on fizz (and note draven parity)
- [ ] 3.2 Spot-check pause/resume CLI against installed `argocd` version; adjust runbook if flags differ
