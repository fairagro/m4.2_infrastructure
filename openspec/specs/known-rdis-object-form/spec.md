# known-rdis-object-form

## Purpose

Middleware API env overlays use only object-shaped `known_rdis` entries (`id` required; optional `description` / `url`),
so API bare-string hard-cut (m4.2_advanced_middleware_api#559) can ship without breaking deploys.

Synced from change `known-rdis-object-form` (infra #71).

## Requirements

### Requirement: known_rdis entries are object-shaped in all env overlays

Every item in `config.known_rdis` under
`environments/{fizz,draven,elise,local_dev}/values/fairagro-advanced-middleware.yaml` SHALL be a YAML mapping with a
required `id` field. Bare string list items MUST NOT appear.

#### Scenario: fizz has no bare-string known_rdis

- **WHEN** `environments/fizz/values/fairagro-advanced-middleware.yaml` is inspected under `known_rdis`
- **THEN** every list item is a mapping containing `id`

#### Scenario: draven has no bare-string known_rdis

- **WHEN** `environments/draven/values/fairagro-advanced-middleware.yaml` is inspected under `known_rdis`
- **THEN** every list item is a mapping containing `id`

#### Scenario: elise and local_dev have no bare-string known_rdis

- **WHEN** elise and local_dev advanced-middleware API value files are inspected under `known_rdis`
- **THEN** every list item is a mapping containing `id`

### Requirement: SRADI metadata is preserved

The `sradi` `known_rdis` entry on fizz and draven SHALL retain its existing non-empty `description` and `url` values
through the migration.

#### Scenario: sradi object keeps description and url

- **WHEN** fizz or draven `known_rdis` is migrated to object form
- **THEN** the `sradi` entry still includes the pre-migration `description` and `url`

### Requirement: Membership unchanged

Migration SHALL NOT add or remove RDI identifiers from each environment’s `known_rdis` list relative to the
pre-migration set (shape change only).

#### Scenario: same ids before and after on fizz

- **WHEN** the set of `id` values is compared to the pre-migration bare-string / object ids on fizz
- **THEN** the sets are equal
