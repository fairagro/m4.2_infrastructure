# Argo CD manifests — draven

GitOps Path A: the **wrapper** Application here uses `targetRevision: '*'` (highest
SemVer git tag). Apply it with the bootstrap script (no Root Application).
Child apps use `lock_children_to_revision: "*"` in values.

```bash
./scripts/setup_project_in_argocd.sh draven
argocd app sync fairagro-m42-applications
```

Re-run only when this YAML changes. Day-to-day pins: `../values/` + infra SemVer tags (#42).

See the repository README section **GitOps bootstrap (Argo CD)**.
