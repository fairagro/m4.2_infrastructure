# Argo CD manifests — fizz

GitOps Path A: the **Root** Application (`fairagro-m42-root`) tracks this directory
on `main`. The wrapper Application here pins the umbrella chart to `main` with
automated sync.

Bootstrap once per cluster:

```bash
./scripts/setup_project_in_argocd.sh fizz
```

See the repository README section **GitOps bootstrap (Argo CD)**.
