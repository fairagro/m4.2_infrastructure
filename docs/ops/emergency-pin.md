# Emergency pin (Argo CD) #

Emergency rollback **on the cluster**: temporarily run a known-good git revision
while a lasting fix is prepared (usually a **SemVer release rollback** via Actions →
**release-rollback**, issue [#57](https://github.com/fairagro/m4.2_infrastructure/issues/57)).
This is **not** the same as reverting `main` alone (draven follows SemVer **tags**,
not `main`).

Tracking: issue [#68](https://github.com/fairagro/m4.2_infrastructure/issues/68)
(parent epic [#40](https://github.com/fairagro/m4.2_infrastructure/issues/40)).

## Who may perform an emergency pin ##

- Argo CD **global admin**, and
- Project admin **`fairagro-m42-admin`**

Both may pause sync and set Application revisions. Colleagues **without** Argo
access use Actions → **release-rollback** (SemVer release rollback, #57).

## Happy path vs rollback (short) ##

| Path | What happens |
|------|----------------|
| Happy | `feature/*` → PR → `main` → fizz auto-sync; draven promote PR → Actions **release** SemVer tag → draven `*` |
| **Emergency pin** | Argo: sync-pause → pin wrapper **and** children to a known-good revision (this doc) |
| **SemVer release rollback** | Actions → **release-rollback**: new **higher** patch tag at previous (or override) tag SHA; `*` picks it up (#57) — no Argo UI |
| Ruleset bypass | **Emergency only** (merge without normal gates); not a substitute for pin or SemVer rollback |

Related: deploy failure notifications [#43](https://github.com/fairagro/m4.2_infrastructure/issues/43)
(platform: [zalf-rdm/misc#571](https://github.com/zalf-rdm/misc/issues/571));
PR quality [#46](https://github.com/fairagro/m4.2_infrastructure/issues/46).

## Why wrapper-only pin fails ##

On **draven**, children are rendered with literal `targetRevision: "*"` via
`lock_children_to_revision: "*"` in `environments/draven/values/fairagro-m42-applications.yaml`.
Argo resolves `*` **per Application** to the highest SemVer tag. The wrapper does
**not** pass its resolved tag down to children.

If the wrapper still has **automated sync + selfHeal**, it keeps reconciling child
Application specs back to `*`. Manually pinning a child to an old tag is then
undone, and `*` again selects the newest (bad) tag.

**Therefore an emergency pin always:** pause wrapper sync first, then pin wrapper
**and every child** to the same exact revision.

## Revision identity ##

Same **procedure** on every Path A cluster; the revision string differs:

| Environment | Known-good revision | Notes |
|-------------|---------------------|--------|
| **draven** | SemVer **tag** (e.g. `0.1.0`) | Normal emergency-pin target |
| **fizz** / elise | Git **commit SHA** (or older tip) | Emergency pin is **unusual** — prefer fix-forward or revert on `main` |

## Application names ##

Discover live names before pinning:

```bash
source ./scripts/set_context.sh <env>   # fizz | draven | elise
kubectl get applications -A | rg -i 'fairagro|m42'
```

**Path A (git):** wrapper Application `fairagro-m42-applications` in namespace
`fairagro-m42-applications` (`environments/<env>/argocd/fairagro-m42-applications.yaml`).

**Children** (namespace `fairagro-m42-applications`):

- `basic-middleware`
- `fairagro-advanced-middleware`
- `fairagro-advanced-middleware-harvester`
- `fairagro-advanced-middleware-sql-to-arc`

**Legacy:** some clusters may still show wrapper `fairagro-m42-application-wrapper`
in namespace `argocd`. Prefer migrating to Path A (`./scripts/setup_project_in_argocd.sh`);
until then, use the live wrapper name/namespace in the commands below.

CLI examples use Path A names and `-N fairagro-m42-applications`. For a legacy
wrapper in `argocd`, omit `-N` or use `-N argocd` and that wrapper’s name.
Verified against `argocd` client **v2.12.x** (`--sync-policy`, `--self-heal`,
`--source-position`, `--revision`).

## Procedure (CLI-first) ##

Replace `<GOOD>` with the known-good revision (tag or SHA). Replace `<env>` with
`draven` or `fizz`.

### 1. Context ###

```bash
source ./scripts/set_context.sh <env>
```

### 2. Pause automated sync on the **wrapper** ###

```bash
WRAPPER=fairagro-m42-applications
WRAP_NS=fairagro-m42-applications

argocd app set "$WRAPPER" -N "$WRAP_NS" --sync-policy none
```

Optional UI: open the wrapper Application → disable automated sync / self-heal
(same intent as `--sync-policy none`).

### 3. Pin the wrapper (all sources) ###

Multi-source apps: set **each** source position (1 = chart path, 2 = values `ref`).

```bash
argocd app set "$WRAPPER" -N "$WRAP_NS" --source-position 1 --revision "<GOOD>"
argocd app set "$WRAPPER" -N "$WRAP_NS" --source-position 2 --revision "<GOOD>"
argocd app sync "$WRAPPER" -N "$WRAP_NS"
```

### 4. Pin **every child** to the same revision ###

```bash
CHILDREN=(
  basic-middleware
  fairagro-advanced-middleware
  fairagro-advanced-middleware-harvester
  fairagro-advanced-middleware-sql-to-arc
)
CHILD_NS=fairagro-m42-applications

for app in "${CHILDREN[@]}"; do
  argocd app set "$app" -N "$CHILD_NS" --sync-policy none
  argocd app set "$app" -N "$CHILD_NS" --source-position 1 --revision "<GOOD>"
  argocd app set "$app" -N "$CHILD_NS" --source-position 2 --revision "<GOOD>"
  argocd app sync "$app" -N "$CHILD_NS"
done
```

### 5. Verify ###

```bash
argocd app get "$WRAPPER" -N "$WRAP_NS" -o wide
for app in "${CHILDREN[@]}"; do
  argocd app get "$app" -N "$CHILD_NS" -o wide
done
# Expect sync revisions / compared revisions to match <GOOD>, not the bad tip.
```

### 6. While pinned — do **not** ###

- Run `./scripts/setup_project_in_argocd.sh <env>` or otherwise upsert
  `environments/<env>/argocd/fairagro-m42-applications.yaml` (git still has `*` /
  `main` and will fight the pin).
- Re-enable wrapper automated sync until you are ready to leave the pin.

## Exit the emergency pin ##

Prefer a lasting content fix:

1. Ship a **SemVer release rollback** (Actions → **release-rollback**, #57) or a
   normal fixed SemVer tag / `main` commit as appropriate.
2. Restore tracking, then automated sync:

**Draven** (back to `*`):

```bash
argocd app set "$WRAPPER" -N "$WRAP_NS" --source-position 1 --revision '*'
argocd app set "$WRAPPER" -N "$WRAP_NS" --source-position 2 --revision '*'
argocd app set "$WRAPPER" -N "$WRAP_NS" --sync-policy automated --self-heal

for app in "${CHILDREN[@]}"; do
  argocd app set "$app" -N "$CHILD_NS" --source-position 1 --revision '*'
  argocd app set "$app" -N "$CHILD_NS" --source-position 2 --revision '*'
  argocd app set "$app" -N "$CHILD_NS" --sync-policy automated --self-heal
done
```

**Fizz** (back to `main`):

```bash
argocd app set "$WRAPPER" -N "$WRAP_NS" --source-position 1 --revision main
argocd app set "$WRAPPER" -N "$WRAP_NS" --source-position 2 --revision main
argocd app set "$WRAPPER" -N "$WRAP_NS" --sync-policy automated --self-heal
# same for each child with revision main
```

Do not leave production on a manual pin longer than necessary.
