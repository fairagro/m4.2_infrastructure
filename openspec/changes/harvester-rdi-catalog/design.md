## Context

Today each env overlay under `environments/*/values/fairagro-advanced-middleware-harvester.yaml` carries a full `fairagro-advanced-middleware-harvester-chart.config.repositories` **list**. Fizz and draven largely duplicate the same plugin/URL bodies; elise still has a shorter, partly older-shaped list. Promoting one RDI or changing a CSW URL means multi-file copy-paste (#44 / epic #40).

The infra umbrella at `helmcharts/fairagro-advanced-middleware-harvester` is a thin OCI dependency wrapper. The upstream ConfigMap does `toYaml .Values.config` only (`helm/harvester/templates/configmap.yaml` in `m4.2_middleware_harvester`). Local umbrellas have **no chart release/version bump process**. API `config.known_rdis` stays out of scope.

## Goals / Non-Goals

**Goals:**

- One shared **map** of RDI harvest definitions (defaults `enabled: false`).
- Thin per-env overlays: `enabled` + sparse overrides (test vs prod URLs).
- Render only enabled entries into upstream `config.repositories` (list).
- Same pattern for fizz, draven, elise, and local_dev.

**Non-Goals:**

- Generating or merging API `known_rdis` from the harvester catalog.
- `environments/common/` values file.
- Forcing fizz down to a single RDI in the first cut.
- **Vendoring / forking the OCI harvester chart in infra** to patch ConfigMap templates.

## Decisions

1. **Catalog lives in the umbrella chart values (not `environments/common/`)**
   - Shared defaults in the local umbrella; env overlays stay thin. No umbrella SemVer release.

2. **Values key: `fairagro-advanced-middleware-harvester-chart.rdi_catalog`**
   - Map keyed by `rdi` id; `enabled` + plugin/parser/mapper fields; map key is the rendered `rdi`.

3. **Map→list MUST be implemented in the product Helm chart (not infra vendor)**
   - Helm cannot inject computed `config.repositories` into an OCI subchart from the parent; parent templates cannot replace the subchart ConfigMap without name clashes.
   - **Rejected:** Vendoring the OCI chart under `vendor/` / `file://` in infra (drift, re-vendor cost, forks prod chart ownership).
   - **Approach:** Upstream chart (`fairagro/m4.2_middleware_harvester`) grows optional `rdi_catalog` support: filter `enabled: true`, strip `enabled`, set `rdi` from key, stable-sort, assign `config.repositories`, then `toYaml`. Infra adopts after a chart release and bumps the umbrella dependency version.
   - Tracked by a product-repo GitHub issue (linked from infra #44).

4. **Overrides: Helm native map merge**
   - Chart/catalog defaults + env `enabled` / nested URL overrides. Custom `mergeOverwrite` only if native merge fails a real case.

5. **API `known_rdis` stays separate**

## Risks / Trade-offs

- **[Risk] Infra #44 blocked on harvester chart release** → Mitigation: product issue with concrete ConfigMap contract; keep env `repositories` lists until then.
- **[Trade-off] No infra-only shortcut** → Acceptable; avoids maintaining a forked chart.

## Migration Plan

1. Land upstream `rdi_catalog` → `repositories` in the harvester Helm chart; publish OCI chart version.
2. Bump umbrella dependency; seed catalog defaults in umbrella `values.yaml` (`enabled: false`).
3. Migrate env overlays to enablement + URL overrides; drop duplicated `repositories` lists.
4. `helm template` per env; behaviour-preserving membership first.

## Open Questions

- Exact values schema naming (`rdi_catalog` vs upstream preference) — settle on the product issue.
