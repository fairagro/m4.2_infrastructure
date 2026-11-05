## 1. Tooling configs

- [x] 1.1 Add Devinfra-aligned `commitlint.config.cjs`, `package.json` / lock for commitlint; `.yamllint.yaml` (B + exclude templates); gitleaks config/ignore as needed
- [x] 1.2 Add `.cursorrules` + Copilot commitMessageGeneration instructions; `.github/PULL_REQUEST_TEMPLATE.md`
- [x] 1.3 Add `.pre-commit-config.yaml` (yamllint, gitleaks, shellcheck, commitlint commit-msg; exclude helm templates)

## 2. CI workflows

- [x] 2.1 Helm template matrix workflow (umbrella + leaves × fizz/draven, tls disabled)
- [x] 2.2 Always-on draven pins (adapt `check-draven-pins.yml`); Argo YAML parse job; yamllint; commitlint; gitleaks; shellcheck
- [x] 2.3 Stable job/`name:` strings suitable for required checks

## 3. Docs + cleanup

- [x] 3.1 README / docs: pre-commit install + admin required-check name list
- [x] 3.2 Fix yamllint/shellcheck findings introduced or uncovered by level B
- [x] 3.3 Verify workflows dry-run locally where practical (`helm template`, scripts)
