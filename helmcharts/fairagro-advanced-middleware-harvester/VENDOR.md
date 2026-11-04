# Vendored harvester chart

The OCI chart `oci://registry-1.docker.io/zalf/fairagro-advanced-middleware-harvester-chart`
is vendored under `vendor/fairagro-advanced-middleware-harvester-chart` so the infra
umbrella can render `rdi_catalog` (map) into upstream `config.repositories` (list).

## Local patches (re-apply after re-vendor)

1. `templates/_helpers.tpl` — `harvester.repositoriesFromCatalog`
2. `templates/configmap.yaml` — set `config.repositories` from that helper before `toYaml`

## Re-vendor

```bash
cd helmcharts/fairagro-advanced-middleware-harvester
VER=1.1.0   # or newer
rm -rf vendor/fairagro-advanced-middleware-harvester-chart
helm pull oci://registry-1.docker.io/zalf/fairagro-advanced-middleware-harvester-chart \
  --version "$VER" --untar -d vendor/
# re-apply the two patches above (see git history)
# bump version in Chart.yaml dependencies
helm dependency update .
```
