# Argo CD manifests — draven

GitOps Path A: the **Root** Application (`fairagro-m42-root`) tracks this directory
on `main`. The wrapper Application here uses `targetRevision: '*'` so Argo follows
the highest SemVer git tag (production release track). Child apps in values use
`*` as well so they stay locked to that same tag resolution.

Bootstrap once per cluster:

```bash
./scripts/setup_project_in_argocd.sh draven
```

See the repository README section **GitOps bootstrap (Argo CD)**.
