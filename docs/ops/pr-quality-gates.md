# PR quality gates

Merges to `main` auto-deploy to fizz-class clusters. Automated checks should fail **before** merge (#46).

## Local setup

**Dev Container:** `postCreateCommand` runs `npm ci`, installs `actionlint` + `gitleaks` from `versions.env` into
`/usr/local/bin` (so git hooks see them without relying on `~/.local/bin` / `HOME` in `remoteEnv`), then installs repo
hooks (`pre-commit` + `commit-msg`). The hook root is `.pre-commit-config.yaml` → symlink to the synced fleet file
`.pre-commit-config.infrastructure.yaml` (actionlint, helm-lint, commit-path-check, prettier/markdownlint, … — no
python-product gates). Rebuild / reopen the container if hooks are missing (no `.git/hooks/commit-msg`).

**Manual / outside the container:**

```bash
npm ci
# install pre-commit (pipx, uv tool, or distro package) if needed
sudo PINNED_TOOL_INSTALL_DIR=/usr/local/bin bash scripts/install-pinned-tool.sh actionlint
sudo PINNED_TOOL_INSTALL_DIR=/usr/local/bin bash scripts/install-pinned-tool.sh gitleaks
pre-commit install --hook-type pre-commit --hook-type commit-msg
pre-commit run --all-files   # optional first pass
```

Commit messages must pass [Conventional Commits](https://www.conventionalcommits.org/) via `commitlint.config.cjs`
(Devinfra-aligned). Cursor/Copilot commit generators are steered by `.cursorrules` and `.vscode/settings.json`.

## CI workflows

| Workflow            | Job / check name            | Purpose                                                                                            |
| ------------------- | --------------------------- | -------------------------------------------------------------------------------------------------- |
| `pr-quality`        | `helm-template-matrix`      | `helm template` umbrella + leaves × fizz/draven (`ci/helm-ci-overrides.yaml`, TLS off / stub auth) |
| `pr-quality`        | `argocd-yaml-parse`         | Parse `environments/*/argocd/*.yaml`                                                               |
| `pr-quality`        | `infra-quality`             | Hygiene bundle: yamllint, commitlint (PRs), gitleaks, shellcheck on `scripts/` (#96)               |
| `check-draven-pins` | `check-draven-release-pins` | No pre-release image tags under `environments/draven/values/` (runs every PR; exits 0 when clean)  |

**Ruleset target (4 checks):** `helm-template-matrix`, `argocd-yaml-parse`, `infra-quality`,
`check-draven-release-pins`. Do not re-add per-linter job names after #96.

Local pre-commit also runs **actionlint** on `.github/workflows/**` via the synced Infra hook root (replaces deferred
one-off #73). **yamllint** and **shellcheck** stay CI-only after that switch (not in the Infra pre-commit root). Fold
actionlint into the `infra-quality` CI job when implementing #95 (not a fifth required check name).

### gitleaks: CI vs pre-commit

- **CI** runs `gitleaks detect` on the whole git history (`fetch-depth: 0`). That catches old commits (e.g. a briefly
  committed `*.enc.decoded.yaml`) and will also match **SOPS ciphertext** unless paths are allowlisted in
  `.gitleaks.toml`.
- **pre-commit** only scans the files in the commit you are making. It does **not** re-scan history. It also does
  nothing until hooks are installed (`pre-commit install …`). Commits made without that install (or with `--no-verify`)
  never see the local hook.

Known-history fingerprints that are already purged from the tree live in `.gitleaksignore`. Do not blanket-ignore
`*.decoded.*` in config — new plaintext leaks should still fail.

## Admin: mark required status checks

Documentation only — a repository **admin** must update the `main` branch ruleset after these jobs have run at least
once on a PR:

1. Open the ruleset that protects `main` (currently named `no cmmits to main`).
2. Enable **Require status checks to pass**.
3. Add the check names above (GitHub UI shows them as `job name` / workflow context — use the **Job `name:`** column).
4. Do **not** turn on dismiss-stale-reviews (team decision).
5. Leave `require_last_push_approval` unchanged unless a later change revisits review politics.

## Out of scope (follow-ups)

- kubeconform — #75
- Secret-tool migration tracking — #74 (this repo uses **gitleaks**)
- actionlint in CI — #95 (add as a step under `infra-quality`, not a separate required check)
