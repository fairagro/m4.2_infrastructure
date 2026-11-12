## 1. Shared concurrency + helpers

- [x] 1.1 Change `release.yml` concurrency group to shared `infra-semver-tag` (`cancel-in-progress: false`)
- [x] 1.2 Add helper (script or documented step block) to resolve previous plain SemVer / validate override and fail if
      target == highest
- [x] 1.3 Reuse `compute_next_infra_semver.sh patch` for next version (no new bump modes)

## 2. Rollback workflow

- [x] 2.1 Add `.github/workflows/release-rollback.yml`: `workflow_dispatch` inputs `acknowledge_rollback` (bool) +
      optional `revert_to_tag` (string)
- [x] 2.2 Assert `main`, acknowledgment true, resolve target, checkout/pin-check at target SHA
- [x] 2.3 Create annotated patch tag at target SHA + GitHub Release with rollback notes (new vs target); handle remote
      tag collision like forward WF
- [x] 2.4 Align permissions (`contents: write` on tag job only) and shared concurrency group

## 3. Docs

- [x] 3.1 README: tags via `release` **or** `release-rollback`; previous+override; always patch; no Soft fizz on
      rollback
- [x] 3.2 `docs/ops/emergency-pin.md`: point SemVer release rollback at the workflow (not only #57)
- [x] 3.3 Forward `release.yml` notes footer: mention rollback workflow by name

## 4. Verify

- [x] 4.1 Dry-read workflow YAML; sanity-check helper against fake tag list (previous / override / fail highest)
- [x] 4.2 Confirm OpenSpec delta matches shipped behavior; link/close #57 when merged
