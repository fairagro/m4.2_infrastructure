# Argo CD manifests — elise

GitOps Path A: the **wrapper** Application here pins the umbrella chart to `main`
with automated sync. Apply it with the bootstrap script (no Root Application).

```bash
./scripts/setup_project_in_argocd.sh elise
argocd app sync fairagro-m42-applications
```

Re-run only when this YAML changes. Day-to-day pins: `../values/`.

See the repository README section **GitOps bootstrap (Argo CD)**.
