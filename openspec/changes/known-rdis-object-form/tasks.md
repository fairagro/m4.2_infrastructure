## 1. Migrate env values

- [ ] 1.1 Convert all bare-string `known_rdis` in `environments/fizz/values/fairagro-advanced-middleware.yaml` to `{id: …}`; leave `sradi` description/url intact
- [ ] 1.2 Same for `environments/draven/values/fairagro-advanced-middleware.yaml`
- [ ] 1.3 Same for `environments/elise/values/fairagro-advanced-middleware.yaml`
- [ ] 1.4 Same for `environments/local_dev/values/fairagro-advanced-middleware.yaml`

## 2. Verification

- [ ] 2.1 Confirm no bare-string items remain under `known_rdis` in those four files (e.g. yq/grep)
- [ ] 2.2 Confirm per-env RDI id membership unchanged vs pre-migration
- [ ] 2.3 Confirm fizz/draven `sradi` still has description + url
