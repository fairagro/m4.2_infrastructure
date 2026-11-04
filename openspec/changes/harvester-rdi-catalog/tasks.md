## 1. Upstream chart (product repo) — blocker

- [ ] 1.1 Product issue: harvester Helm chart supports optional `rdi_catalog` map → `config.repositories` list (no infra vendor fork) — https://github.com/fairagro/m4.2_middleware_harvester/issues/578
- [ ] 1.2 Land upstream chart change + publish OCI chart version usable by the infra umbrella

## 2. Infra after upstream release

- [ ] 2.1 Bump `helmcharts/fairagro-advanced-middleware-harvester` dependency to the chart version with `rdi_catalog` support
- [ ] 2.2 Add umbrella `rdi_catalog` defaults (`enabled: false`) from current fizz/draven shapes; omit parallel default `config.repositories`
- [ ] 2.3 Migrate fizz/draven/elise/local_dev overlays to enablement + sparse URL overrides
- [ ] 2.4 `helm template` per env: membership + key URLs match pre-migration; `openagrar` stays off; API `known_rdis` untouched
