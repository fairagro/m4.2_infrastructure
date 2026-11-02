## 1. Release workflow skeleton

- [x] 1.1 Add `.github/workflows/release.yml` with `workflow_dispatch` inputs `version_bump` (choice: major|minor|patch, default patch) and Soft `fizz_validated` (boolean), `concurrency` group, `permissions` for contents/releases
- [x] 1.2 Assert job runs only on `main`; fail closed otherwise
- [x] 1.3 Fail closed when Soft `fizz_validated` is not true (before tagging)

## 2. Validate-then-tag

- [x] 2.1 Checkout `main` at the dispatch SHA and run `scripts/check_draven_release_pins.sh`; fail closed on non-zero
- [x] 2.2 Compute next SemVer from highest existing SemVer tag + `version_bump`; implement first-tag rules (`0.1.0` from empty on patch/minor; `1.0.0` on major) as in design
- [x] 2.3 Create annotated git tag and push; create GitHub Release with short notes (bump, Soft attestation reminder, compare URL if prior tag exists)
- [x] 2.4 Ensure no step commits or opens PRs that rewrite Application YAML or env values

## 3. Operator docs

- [x] 3.1 Extend README GitOps / image-pin cadence: SemVer Leitplanken (major/minor/patch), Soft fizz checkbox, “cut tag via Release WF after promote”, tags SHOULD come from WF (Ruleset later)
- [x] 3.2 Point operator sequence step 6 at the new workflow (and mention R2 is #57, not this WF)

## 4. Verification

- [x] 4.1 Dry-run locally where practical (version bump script / pin script on current tree); confirm workflow YAML parses (`actionlint` if available, else review)
- [x] 4.2 `openspec validate infra-release-workflows --strict` (or project-equivalent) and fix artifact issues if any
