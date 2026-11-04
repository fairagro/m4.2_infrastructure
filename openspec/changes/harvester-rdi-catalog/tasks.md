## 1. Chart: vendor and map→list

- [x] 1.1 Unpack the OCI harvester subchart into `helmcharts/fairagro-advanced-middleware-harvester/charts/` as a local/file dependency (replace or supersede the `.tgz`-only layout) and note re-vendor steps in a short chart comment/README
- [x] 1.2 Add a Helm helper that filters `rdi_catalog` for `enabled: true`, strips `enabled`, sets `rdi` from the map key, and stable-sorts by key
- [x] 1.3 Patch the vendored ConfigMap template to build `config.repositories` from that helper before `toYaml` of `config`

## 2. Chart values: catalog defaults

- [x] 2.1 Add `fairagro-advanced-middleware-harvester-chart.rdi_catalog` to umbrella `values.yaml` with current fizz/draven repository shapes (newer plugin forms), each `enabled: false`
- [x] 2.2 Ensure default `config.repositories` is empty/omitted so catalog is the sole source of repository entries

## 3. Environment overlays (values-only)

- [x] 3.1 Migrate `environments/fizz/values/fairagro-advanced-middleware-harvester.yaml`: remove full `repositories` list; set `rdi_catalog` enablement + test URL overrides to match today’s fizz harvest set
- [x] 3.2 Migrate `environments/draven/values/fairagro-advanced-middleware-harvester.yaml` likewise for the production portfolio/URLs
- [x] 3.3 Migrate `environments/elise/values/fairagro-advanced-middleware-harvester.yaml` onto catalog shapes (modernize legacy `schema_org` entries as needed) with enablement matching current elise intent
- [x] 3.4 Migrate `environments/local_dev/values/fairagro-advanced-middleware-harvester.yaml` the same way

## 4. Verification

- [x] 4.1 `helm template` the umbrella with each env values file; confirm ConfigMap `repositories` membership and key fields (URLs, plugin keys) match pre-migration behaviour for that env
- [x] 4.2 Confirm middleware API env values / `known_rdis` were not modified
- [x] 4.3 Spot-check that disabled catalog RDIs (e.g. openagrar if still off) do not appear in rendered lists
