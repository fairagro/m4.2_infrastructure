## Context

`main` → fizz auto-deploy. Today: path-filtered `check-draven-pins` only; no pre-commit/PR template; ruleset has team review but `require_last_push_approval: false` and no required status checks. Devinfra is the fleet quality model (commitlint, pre-commit); Infra is not a product sync consumer but should align where practical. Explore locked option **C** (no last-push politics yet) + maximal automaten.

## Goals / Non-Goals

**Goals:** Required-check-ready CI; local fail-early; conventional commits + steering; PR checklist; admin doc for ruleset.

**Non-Goals:** last_push_approval; actionlint; kubeconform; ggshield; Ruleset API edits.

## Decisions

1. **Always-on helm matrix (fizz+draven only)** — umbrella `fairagro-m42-applications` + each leaf under `helmcharts/` with matching env values; `tls.enabled=false` (or chart-equivalent) so SOPS secrets are not required.
2. **Draven pins every PR** — remove path filter (or keep workflow always scheduled); script may exit 0 when clean / nothing to enforce.
3. **yamllint B** — trailing spaces, EOF newline, key duplicates; disable harsh line-length/document-start as needed; exclude `**/templates/**` (and chart package tarballs).
4. **commitlint = Devinfra `commitlint.config.cjs`**; skip `commit-path-check`.
5. **gitleaks** for secrets (CI + pre-commit), not ggshield.
6. **shellcheck** on `scripts/*.sh` in this slice; kubeconform → #75.
7. **One PR** with CI + pre-commit + template + steering + docs.
8. **Required checks: documentation only** — README/docs list exact GitHub check names for an admin.

## Risks / Trade-offs

- **[Risk] Full matrix runtime** → Mitigation: no cluster; helm only; monitor duration.
- **[Risk] yamllint noise on existing YAML** → Mitigation: level B + one cleanup pass in same PR if needed.
- **[Risk] gitleaks false positives** → Mitigation: `.gitleaksignore` / config allowlist as needed.
- **[Trade-off] TLS templates untested in CI** → Accepted (tls.enabled=false).

## Migration Plan

1. Land workflows + local tooling; fix yamllint/shellcheck findings.
2. Merge; run once on a PR so check names exist.
3. Admin marks required checks per docs.
4. Follow-ups: #73 actionlint, #75 kubeconform, optional last_push_approval later.

## Open Questions

- None blocking (gitleaks chosen; #340 informed).
