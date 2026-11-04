## Context

Today each env overlay under `environments/*/values/fairagro-advanced-middleware-harvester.yaml` carries a full `fairagro-advanced-middleware-harvester-chart.config.repositories` **list**. Fizz and draven largely duplicate the same plugin/URL bodies; elise still has a shorter, partly older-shaped list. Promoting one RDI or changing a CSW URL means multi-file copy-paste (#44 / epic #40).

The infra umbrella at `helmcharts/fairagro-advanced-middleware-harvester` is a thin OCI dependency wrapper (`fairagro-advanced-middleware-harvester-chart` → ConfigMap is `toYaml .Values.config`). Local umbrellas have **no chart release/version bump process**; Argo syncs the git path. API `config.known_rdis` is a separate, broader allowlist and must stay out of scope.

Stakeholders: operators editing harvest sources; anyone syncing fizz/draven/elise/local_dev via Argo or `local-dev` scripts.

## Goals / Non-Goals

**Goals:**

- One shared **map** of RDI harvest definitions in the umbrella chart; default `enabled: false`.
- Thin per-env overlays: `enabled` + sparse overrides (especially test vs prod URLs).
- Render only enabled entries into upstream `config.repositories` (list).
- Same pattern for fizz, draven, elise, and local_dev.
- Behaviour-preserving first cut: enabled sets match what each env harvests today.

**Non-Goals:**

- Generating or merging API `known_rdis` from the harvester catalog.
- `environments/common/` values file.
- Forcing fizz down to a single RDI in this change (mechanism enables that later).
- Changing harvester application image/plugins or middleware API charts.
- Upstream OCI chart publish for the map→list helper (infra-local solution).

## Decisions

1. **Catalog lives in the umbrella chart values (not `environments/common/`)**
   - **Why:** Matches infra policy (shared defaults in local umbrellas). No umbrella SemVer release — catalog edits ship with git/`targetRevision` like any other values change.
   - **Rejected:** `environments/common/` — no clear win once umbrellas are unversioned; adds another Argo valueFile without removing chart complexity.

2. **Values key: `fairagro-advanced-middleware-harvester-chart.rdi_catalog`**
   - Map keyed by `rdi` id. Each entry holds `enabled` plus the same plugin/parser/mapper fields used today under a list item (minus the redundant `rdi:` field — the map key is the id).
   - Env overlays nest under the same subchart key they already use, so Argo valueFiles keep working.

3. **Map→list via a thin local ConfigMap template (vendor/unpack OCI chart)**
   - Upstream ConfigMap does `toYaml .Values.config` and cannot see a sibling catalog or compute a list from parent templates (Helm does not inject computed values into dependencies; parent templates cannot disable a single subchart template).
   - **Approach:** Unpack/vendor `fairagro-advanced-middleware-harvester-chart` under the umbrella `charts/` tree (file dependency), change `configmap.yaml` (and a small helper) to: deep-use merged `rdi_catalog`, filter `enabled: true`, strip `enabled`, set `rdi` from the key, stable-sort by key, assign into `config.repositories`, then `toYaml` the resulting config.
   - **Rejected:** Commit-time generator that writes lists back into env files (two sources of truth). **Rejected:** Parent duplicate ConfigMap (name clash with subchart). **Rejected:** Waiting for upstream chart support (blocks #44).

4. **Overrides: rely on Helm native map merge**
   - Chart supplies full entry bodies; env sets e.g. `rdi_catalog.bonares.enabled: true` and `rdi_catalog.bonares.inspire.csw_url: …`. Helm deep-merges maps, which covers BonaRes test/prod URLs without custom merge helpers.
   - Add `mergeOverwrite` (or similar) in templates only if a real nested case fails native merge; not in MVP.

5. **Keep `config.repositories` out of env overlays after migration**
   - Source of truth is `rdi_catalog`. Env files must not reintroduce a parallel full list. Optional empty/omitted `repositories` in chart `config:` defaults.

6. **API `known_rdis` stays separate**
   - Different cardinality and purpose; no generator from harvester catalog in this change. Soft doc note only if useful later (enabled harvest `rdi` SHOULD exist in API allowlist) — not a hard requirement here.

7. **Argo / revision**
   - No OCI app-chart version bump required for catalog content. Vendoring the subchart templates is a one-time infra git change; later upstream chart bumps mean re-vendor + re-apply the ConfigMap patch. Wrapper Application path unchanged (`helmcharts/fairagro-advanced-middleware-harvester` + env valueFiles).

## Risks / Trade-offs

- **[Risk] Vendored subchart drifts from OCI releases** → Mitigation: document re-vendor steps in chart README/comment; keep patch minimal (ConfigMap + helper only); bump dependency version intentionally when pulling upstream.
- **[Risk] Accidental empty harvest if all `enabled: false`** → Mitigation: migrate with explicit env `enabled: true` matching today’s lists; `helm template` smoke-check per env before merge.
- **[Risk] Nesting mistakes break plugin shape (elise still has legacy `schema_org` blocks)** → Mitigation: catalog defaults take **current fizz/draven** shapes; elise/local_dev move onto those shapes when adopting the catalog (modernize as part of migration, call out in PR).
- **[Trade-off] Chart values file grows large** → Acceptable; that bulk moves out of four env files into one shared place.
- **[Risk] Cluster-specific networking (BonaRes hostAliases, TLS)** stays in env overlays, not catalog → Mitigation: do not put hostAliases into `rdi_catalog`; keep them beside chart networking keys as today.

## Migration Plan

1. Vendor/unpack OCI chart; add `rdi_catalog` + ConfigMap map→list helper.
2. Seed catalog from the union of current fizz/draven repository definitions (prefer newer plugin shapes); all `enabled: false` in chart defaults.
3. Per env: replace `config.repositories` with `rdi_catalog.<id>.enabled` (+ URL overrides). Preserve today’s enabled membership.
4. `helm template` (or local-dev render) for each env; diff ConfigMap `repositories` against pre-change output.
5. Roll out via normal git sync (fizz first if desired); rollback = revert git revision / emergency pin — no separate feature flag.

## Open Questions

- None blocking implement: fizz “slim to one RDI” is a follow-up ops choice using `enabled`, not a merge gate for this change.
