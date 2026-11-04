## Why

Harvester RDI definitions are copy-pasted as large `config.repositories:` lists across fizz, draven, elise, and local_dev. Promoting or tweaking one source means editing the same block in multiple overlays, while fizz intentionally runs a slim set and needs different URLs (e.g. BonaRes test CSW) than draven. Issue #44 asks for a shared catalog with per-env enablement and overrides so lists stop drifting.

## What Changes

- Introduce a **harvester RDI catalog** as a map keyed by `rdi` in the **infra umbrella chart** (`helmcharts/fairagro-advanced-middleware-harvester`), with catalog defaults `enabled: false`.
- Per environment: set `enabled: true` and sparse overrides (URLs, plugin knobs) under the same map keys — fizz slim, draven broad portfolio, same pattern for elise and local_dev.
- Helm **map → list** so the upstream harvester ConfigMap still receives `config.repositories` as a list of enabled entries only.
- Prefer Helm’s native map merge for overrides; deeper merge helpers only if cheap.
- Migrate existing env `repositories:` blocks into catalog defaults + thin env overlays; remove duplicated list bodies from env values where the catalog covers them.
- **Non-goals:** unifying or generating API `config.known_rdis` from the harvester catalog; identical enabled sets across envs; `environments/common/` values file (umbrella chart is the shared home; local umbrellas have no release/version bump process).

## Capabilities

### New Capabilities

- `harvester-rdi-catalog`: Shared map-shaped RDI harvest definitions in the harvester umbrella chart, per-env enablement/overrides, and map→list rendering into upstream `config.repositories`.

### Modified Capabilities

- (none)

## Impact

- `helmcharts/fairagro-advanced-middleware-harvester/` (catalog defaults + map→list rendering; may need a thin local template/vendoring change because the OCI subchart serialises `config` verbatim).
- Env overlays: `environments/{fizz,draven,elise,local_dev}/values/fairagro-advanced-middleware-harvester.yaml`.
- No change to middleware API charts/`known_rdis`, Argo bootstrap, or release workflows.
- Tracks GitHub issue #44 (parent epic #40).
