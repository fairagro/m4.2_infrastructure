## Context

Today each Argo-backed cluster gets a `fairagro-m42-application-wrapper` Application via `scripts/setup_project_in_argocd.sh`, which renders a multi-source Application (umbrella chart `fairagro-m42-applications` + `$values` ref) into the Argo API. That Application is not checked into git. Child Applications are rendered by the umbrella Helm chart with per-app `*_revision` (chart default `HEAD`). Sync is manual.

Stakeholders: infra maintainers (Argo access on-prem) and a colleague who must deploy without Argo UI. Epic #40 / issue #41. Downstream #42 expects draven to follow SemVer tags via Application `*`.

Constraints: separate Argo instance per environment (no hub); CI must not rewrite Application YAML for version bumps; on-prem Argo has outbound git access to GitHub; no ApplicationSet for tag follow.

## Goals / Non-Goals

**Goals:**

- Durable Git source of truth for wrapper Application specs under `environments/<env>/argocd/`.
- Root Application per cluster syncs that directory from `main`.
- fizz-class → `main` + automated sync; draven → `*` (+ optional tagPrefix).
- Child revision asymmetry designed so draven snapshots do not silently track `main` via `HEAD`.
- Bootstrap path that migrates from the current script without inventing ApplicationSet.

**Non-Goals:**

- Release / rollback GitHub Actions (#42).
- Notifications / R1 runbook detail (#43).
- RDI catalog (#44).
- ApplicationSet, Image Updater, hub Argo.
- Changing image tags or RDI harvest configs in this change.

## Decisions

### 1. Two-layer Applications: Root (defs) vs Wrapper (workloads)

- **Root** (one-shot, rarely changed): `path: environments/<env>/argocd`, `targetRevision: main`, destination Argo namespace (e.g. `argocd` or project-owned ns). Syncs wrapper Application YAML(s).
- **Wrapper** (in git under that path): existing multi-source shape from the setup script; `targetRevision` is env-specific (`main` vs `*`).

**Why:** Separates “how we define apps” (always evolve on `main`) from “what workloads run” (fizz tip vs draven release tag). Root must not live inside the path it syncs.

**Alternatives:** Single Application with no Root (manual `kubectl apply` of wrapper forever) — rejected; loses GitOps for the wrapper itself. ApplicationSet for envs — rejected (separate Argo per cluster; overkill).

### 2. draven uses Application `targetRevision: '*'` (not ApplicationSet)

Argo resolves the highest SemVer-compatible tag. Optional `tagPrefix` if the repo gains unrelated tags. Unique running version is observed via Argo sync status and (later) GitHub Releases — not by rewriting YAML.

**Why:** No plugin generator; CI does not edit git; works with on-prem pull.

### 3. Child `*_revision` asymmetry

- **fizz-class:** defaults and env values use `main` (prefer explicit `main` over opaque `HEAD` where we touch files). Operators may override one child to a feature branch.
- **draven:** children MUST NOT use bare `HEAD` (resolves to default branch tip). At a minimum, document that tagged commits used as releases must set all enabled `*_revision` fields to that same tag name; prefer a chart mechanism (`lock_children_to_revision` / single `revision` used when set) if low-cost in this change, otherwise values discipline + verification in tasks.

**Why:** Otherwise wrapper on tag `1.4.0` while children track `main` breaks immutable releases.

### 4. Automated sync on wrapper and children (fizz-class)

Enable `syncPolicy.automated` (prune/selfHeal as appropriate) on fizz-class wrapper and child Application templates so merge-to-main actually deploys without Argo clicks. Draven: automated sync is desirable so `*` resolution deploys after a new tag; prune policy to be conservative if needed.

### 5. Bootstrap script becomes Root create

`setup_project_in_argocd.sh` (or successor) creates/updates only the Root Application pointing at `environments/$env/argocd` on `main`. Wrapper content comes from git after Root syncs. Document migration: existing wrapper Applications with the same name are adopted/updated by Root sync (upsert semantics).

### 6. Secrets

Application manifests under `argocd/` are plaintext only (repo URL, paths, revisions). No `.enc.yaml` in that directory. Existing SOPS valueFiles on child apps unchanged.

## Risks / Trade-offs

- **[Risk] Root sync resets a live emergency pin on draven (R1)** → Mitigation: document in #43; optional `ignoreDifferences` on wrapper `targetRevision` is a later ops choice, not required for bootstrap happy path.
- **[Risk] `*` matches unintended tags** → Mitigation: optional `tagPrefix`; tag naming conventions in #42; tag protection.
- **[Risk] Children still on `HEAD` after first draven tag** → Mitigation: explicit lock design + verification task; block incomplete draven values in review.
- **[Risk] Adopting Root overwrites hand-tuned live Application fields** → Mitigation: compare live vs git before first Root sync; keep manifests faithful to current script output.
- **[Trade-off] Explicit `main` vs `HEAD`** → Prefer `main` for clarity where we edit; Argo treats both as default-branch tip today but `HEAD` is easy to misread as “parent revision”.

## Migration Plan

1. Merge manifests + script/docs to `main` (no cluster change yet).
2. Per cluster: create Root Application (new script) with revision `main`.
3. Root sync → wrapper Application appears/updates; sync wrapper (and children).
4. Verify fizz-class follows `main`; draven shows `*` (no matching tags yet is OK until #42).
5. Rollback of the *bootstrap change*: delete Root and revert to script-created wrapper if needed (documented); not a software rollback.

## Open Questions

- Exact Argo destination namespace for Root vs wrapper (`argocd` vs `fairagro-m42-applications`) — match current project conventions when implementing.
- Whether child lock is chart-level in this change or values-only for the first PR (prefer chart lock if small; otherwise values + docs and follow-up).
- Whether `local_dev` gets an `argocd/` stub or stays helm-only (prefer helm-only / out of scope).
