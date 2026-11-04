## Why

API deployments still list most `known_rdis` as bare YAML strings. The API already prefers object entries (`{id, description?, url?}`) and will **reject** strings in [m4.2_advanced_middleware_api#559](https://github.com/fairagro/m4.2_advanced_middleware_api/issues/559). Infra must migrate first so that hard-cut does not break fizz/draven/elise/local_dev config load (#71).

## What Changes

- Convert every `known_rdis` item in `environments/{fizz,draven,elise,local_dev}/values/fairagro-advanced-middleware.yaml` to object form (`id` required; `description` / `url` optional).
- Keep the existing full `sradi` object (`description` + `url`); other RDIs may be id-only.
- Prefer fizz first, then draven (and elise/local_dev in the same change or immediately after).
- **Non-goals:** implementing API #559; filling description/url for every RDI; harvester values / `rdi_catalog` (#44); reopening SRADI-only #50/#51 work.

## Capabilities

### New Capabilities

- `known-rdis-object-form`: Infra middleware API values use only object-shaped `known_rdis` entries (no bare strings), preserving existing SRADI metadata.

### Modified Capabilities

- (none)

## Impact

- Env value files only under `environments/*/values/fairagro-advanced-middleware.yaml`.
- Unblocks API #559; tracks infra #71.
- No Helm chart template, harvester, secret, or workflow changes.
