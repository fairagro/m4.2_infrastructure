## 1. Upstream chart (product repo) — blocker

- [x] 1.1 Product issue: harvester Helm chart supports optional `rdi_catalog` map → `config.repositories` list (no infra
      vendor fork) — https://github.com/fairagro/m4.2_middleware_harvester/issues/578
- [x] 1.2 Land upstream chart change + publish OCI chart version usable by the infra umbrella (OCI `1.3.0` via Helm
      Chart Release)

## 2. Infra after upstream release

- [x] 2.1 Bump `charts/fairagro-advanced-middleware-harvester` dependency to the chart version with `rdi_catalog`
      support (`1.3.0`)
- [x] 2.2 Add umbrella `rdi_catalog` defaults (`enabled: false`) from current fizz/draven shapes; omit parallel default
      `config.repositories`
- [x] 2.3 Migrate fizz/draven/elise/local_dev overlays to enablement + sparse URL overrides
- [x] 2.4 `helm template` per env: membership + key URLs match pre-migration; `openagrar` stays off; API `known_rdis`
      untouched
