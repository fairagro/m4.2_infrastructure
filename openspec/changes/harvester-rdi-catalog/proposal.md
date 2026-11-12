## Why

Harvester RDI definitions are copy-pasted as large `config.repositories:` lists across fizz, draven, elise, and
local_dev. Promoting or tweaking one source means editing the same block in multiple overlays, while fizz intentionally
runs a slim set and needs different URLs (e.g. BonaRes test CSW) than draven. Issue #44 asks for a shared catalog with
per-env enablement and overrides so lists stop drifting.

## What Changes

- Introduce a **harvester RDI catalog** as a map keyed by `rdi` in the **infra umbrella chart**
  (`charts/fairagro-advanced-middleware-harvester`), with catalog defaults `enabled: false`.
- Per environment: set `enabled: true` and sparse overrides (URLs, plugin knobs) under the same map keys — fizz slim,
  draven broad portfolio, same pattern for elise and local_dev.
- Helm **map → list** so the harvester ConfigMap still receives `config.repositories` as a list of enabled entries only
  — implemented in the **product Helm chart** (`m4.2_middleware_harvester`), not by vendoring/forking the OCI chart in
  infra.
- Prefer Helm’s native map merge for overrides; deeper merge helpers only if cheap.
- After the chart release: migrate env `repositories:` blocks into catalog defaults + thin env overlays.
- **Non-goals:** unifying or generating API `config.known_rdis`; identical enabled sets across envs;
  `environments/common/`; infra-local chart vendor/fork.

## Capabilities

### New Capabilities

- `harvester-rdi-catalog`: Shared map-shaped RDI harvest definitions in the harvester umbrella chart, per-env
  enablement/overrides, and map→list rendering into upstream `config.repositories` (once the product chart supports it).

### Modified Capabilities

- (none)

## Impact

- Blocked on product chart support for optional `rdi_catalog` (issue in `fairagro/m4.2_middleware_harvester`).
- Then: umbrella dependency bump, catalog defaults, env overlay migration.
- No change to middleware API charts/`known_rdis`, Argo bootstrap, or release workflows.
- Tracks GitHub issue #44 (parent epic #40).
