## ADDED Requirements

### Requirement: Shared harvester RDI catalog in the umbrella chart

The infrastructure repository SHALL define harvest source defaults as a map `fairagro-advanced-middleware-harvester-chart.rdi_catalog` in `helmcharts/fairagro-advanced-middleware-harvester`, keyed by RDI id. Each catalog entry MUST include `enabled` (default `false`) and the plugin/parser/mapper fields needed to harvest that RDI. The map key SHALL be the RDI id used as `rdi` in the rendered repository entry.

#### Scenario: Chart defaults leave RDIs disabled

- **WHEN** the harvester umbrella is rendered with chart defaults and no environment overlay enabling catalog entries
- **THEN** the rendered harvester ConfigMap `config.repositories` list is empty (or contains no catalog-derived entries)

#### Scenario: Catalog entry identity

- **WHEN** a catalog map key is `bonares` and that entry is enabled
- **THEN** the corresponding ConfigMap repository object has `rdi: bonares`

### Requirement: Per-environment enablement and overrides

Environment value files under `environments/{fizz,draven,elise,local_dev}/values/` SHALL select harvest sources by setting `rdi_catalog.<rdi>.enabled` and MAY override nested fields (for example CSW or entry URLs) under the same map keys. After migration, those env files MUST NOT maintain a parallel full `config.repositories` list for catalog-managed RDIs.

#### Scenario: Enable a subset on fizz

- **WHEN** fizz values set `enabled: true` only for a subset of catalog keys (and optional URL overrides)
- **THEN** `helm template` / Argo sync for fizz yields a `repositories` list containing exactly those enabled RDIs with overrides applied

#### Scenario: Broader portfolio on draven

- **WHEN** draven values enable the production portfolio of catalog RDIs with production URLs where they differ from defaults
- **THEN** the rendered `repositories` list includes that portfolio and does not require copying full plugin bodies from fizz

#### Scenario: Same pattern on elise and local_dev

- **WHEN** elise or local_dev harvester values are migrated to the catalog
- **THEN** they use `rdi_catalog` enablement/overrides rather than a duplicated full `repositories` list

### Requirement: Map-to-list rendering into upstream config

The harvester umbrella SHALL render enabled `rdi_catalog` entries into `config.repositories` as a YAML list for the harvester ConfigMap consumed by the CronJob. Disabled entries MUST be omitted. The `enabled` field MUST NOT appear on rendered repository objects. List order SHALL be deterministic (stable sort by RDI id).

#### Scenario: Enabled entries become list items

- **WHEN** two catalog entries `edal` and `bonares` are enabled and others are disabled
- **THEN** ConfigMap `config.repositories` is a list of two objects for those RDIs only, without `enabled` keys, in deterministic order

#### Scenario: URL override reaches ConfigMap

- **WHEN** chart defaults set a production CSW URL for `bonares` and the env overlay sets a different `rdi_catalog.bonares.inspire.csw_url`
- **THEN** the rendered `bonares` repository uses the overlay CSW URL

### Requirement: Harvester catalog stays separate from API known_rdis

This change MUST NOT generate, merge, or replace middleware API `config.known_rdis` from the harvester `rdi_catalog`. API allowlists remain independently maintained.

#### Scenario: API values untouched by catalog render

- **WHEN** harvester `rdi_catalog` enablement changes in an environment
- **THEN** middleware API `known_rdis` in that environment’s API values is unchanged by the harvester catalog mechanism
