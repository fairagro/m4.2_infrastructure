## 1. Wrapper Application manifests

- [x] 1.1 Add `environments/fizz/argocd/` wrapper Application YAML (multi-source umbrella + values ref; `targetRevision: main`; automated sync; CreateNamespace/Prune as today)
- [x] 1.2 Add `environments/elise/argocd/` wrapper Application YAML (same pattern as fizz; `targetRevision: main`; automated sync)
- [x] 1.3 Add `environments/draven/argocd/` wrapper Application YAML (`targetRevision: '*'`; optional tagPrefix placeholder/comment; automated sync as designed)
- [x] 1.4 Verify manifests with `argocd app create --dry-run` or equivalent YAML validation against current script output (no secrets in these files)

## 2. Child revision asymmetry

- [x] 2.1 Set fizz-class `environments/*/values/fairagro-m42-applications.yaml` child `*_revision` defaults explicitly to `main` where we enable apps (replace reliance on opaque `HEAD` where touched)
- [x] 2.2 Implement draven child lock: either chart support (preferred if small) so children share the release revision, or document + set draven values so enabled `*_revision` cannot stay as bare `HEAD`
- [x] 2.3 Add automated sync on child Application templates in `helmcharts/fairagro-m42-applications` for fizz-class behaviour (and draven as designed)

## 3. Bootstrap Root script / docs

- [x] 3.1 Replace or extend `scripts/setup_project_in_argocd.sh` to create/upsert the **Root** Application (`path: environments/<env>/argocd`, `targetRevision: main`) using existing SOPS Argo credentials
- [x] 3.2 Document one-shot bootstrap + migration from live script-created wrapper (adopt/upsert expectations) in README or `environments/*/argocd` notes
- [x] 3.3 Note `local_dev` remains helm/kind-only (no Argo Root required for this change)

## 4. Verification

- [x] 4.1 `helm template` umbrella chart with fizz and draven `fairagro-m42-applications` values; confirm child revisions and syncPolicy look correct
- [x] 4.2 Dry-run or documented checklist: Root create → sync → wrapper appears with expected `targetRevision` (`main` vs `*`)
- [x] 4.3 Cross-check against GitHub issue #41 acceptance criteria; leave #42/#43/#44 untouched
