## Why

Merges to `main` auto-deploy to fizz. PR quality must fail before merge — not after Argo breaks the cluster (#46). Review-ruleset politics stay as-is for now (option C); we maximize **automatic** checks instead.

## What Changes

- GitHub Actions on PRs to `main`: always-on `helm template` matrix (umbrella + leaf charts × **fizz+draven**, TLS disabled via `--set`), Argo Application YAML parse, always-on `check_draven_release_pins` (may no-op/exit 0), **yamllint** (level B, repo-wide, exclude `**/templates/**`), **commitlint**, **gitleaks**, **shellcheck** on `scripts/*.sh`.
- `.pre-commit-config.yaml` mirroring the locally feasible checks; Devinfra-aligned **commitlint** (`commitlint.config.cjs` + npm pins); **no** `commit-path-check` in this slice.
- Message steering: `.cursorrules` + VS Code/Copilot `commitMessageGeneration.instructions` (Infra lacks Devinfra issue-fixer skills).
- `.github/PULL_REQUEST_TEMPLATE.md` checklist from #46.
- Docs: how to install pre-commit; **documentation-only** list of check names for an admin to mark required on the ruleset (no Ruleset API automation).
- **Non-goals:** `require_last_push_approval`; actionlint (#73); kubeconform (#75); ggshield (#74 follows gitleaks); dismiss-stale-reviews; notifications (#43).

## Capabilities

### New Capabilities

- `pr-quality-gates`: Automated PR/merge quality gates and local mirrors for infra GitOps (helm render, pins, lint, secrets, commit messages, PR template, admin required-check docs).

### Modified Capabilities

- (none)

## Impact

- New/updated `.github/workflows/*`, pre-commit/npm/commitlint config, IDE steering files, PR template, short README/docs.
- Tracks #46; related #73/#74/#75.
- Admin must manually add required status checks after checks have run once.
