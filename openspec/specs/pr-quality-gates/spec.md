# pr-quality-gates

## Purpose

Merge-time quality for `main` (auto-deploy to fizz-class): CI gates, Infra pre-commit root, Conventional Commits
steering, PR template, and admin docs for required status checks. Synced from change `pr-quality-gates`.

## Requirements

### Requirement: PR CI runs deploy-relevant automated checks

Pull requests targeting `main` SHALL run automated checks that include: `helm template` for the applications umbrella
and leaf charts against fizz and draven values (with TLS disabled for render), validation that checked-in Argo
Application YAML under `environments/*/argocd/` parses, always-on draven release-pin check (successful no-op when there
is nothing to fail), yamllint, commitlint on PR commits, gitleaks secret scan, and shellcheck on `scripts/*.sh`.

#### Scenario: Helm render fails the PR check

- **WHEN** a PR breaks Helm templating for a fizz or draven overlay in the matrix
- **THEN** the corresponding CI job fails

#### Scenario: Draven pin check is present on non-draven PRs

- **WHEN** a PR does not touch `environments/draven/values/`
- **THEN** the draven pin check still runs and exits successfully if no pre-release pins exist under draven values

### Requirement: Local pre-commit mirrors feasible gates

The repository SHALL provide a `.pre-commit-config.yaml` that installs the synced Infra fleet root
(`.pre-commit-config.infrastructure.yaml`: gitleaks, actionlint, commitlint / commit-path-check, prettier/markdownlint,
helm-lint, and foundation hygiene — not python-product gates). Yamllint and shellcheck SHALL remain CI jobs under
`pr-quality` (not required as local pre-commit hooks after the fleet root switch). Docs SHALL describe hook install and
the CI vs local split.

#### Scenario: Developer installs hooks

- **WHEN** a developer follows the documented pre-commit install steps
- **THEN** commit-msg commitlint and the configured Infra fleet pre-commit hooks are available locally

### Requirement: Conventional commit message steering

The repository SHALL ship Devinfra-compatible `commitlint.config.cjs` and IDE/agent steering (`.cursorrules` and Copilot
commit message generation instructions) so generated commit subjects target Conventional Commits.

#### Scenario: Non-conventional subject is rejected by commitlint

- **WHEN** a commit message does not satisfy `commitlint.config.cjs`
- **THEN** commitlint fails (CI and/or commit-msg hook)

### Requirement: PR template checklist

The repository SHALL provide `.github/PULL_REQUEST_TEMPLATE.md` with a human checklist covering intent, draven pin
rules, secrets hygiene, local/CI checks, and emergency bypass disclosure.

#### Scenario: Opening a PR shows the template

- **WHEN** a contributor opens a pull request on GitHub
- **THEN** the PR body is prefilled from `PULL_REQUEST_TEMPLATE.md`

### Requirement: Admin documentation for required status checks

The repository SHALL document the stable CI check names and that a repository admin must mark them required on the
`main` ruleset (documentation only; no automated ruleset mutation).

#### Scenario: Admin checklist lists check names

- **WHEN** an admin opens the quality/ruleset documentation after the workflows land
- **THEN** they find an explicit list of check names to require
