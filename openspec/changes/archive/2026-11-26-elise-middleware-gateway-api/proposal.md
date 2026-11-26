## Why

Platform Gateway optional client TLS is available on **elise**, and the Middleware API chart is gaining HTTPRoute +
SnippetsFilter support
([m4.2_advanced_middleware_api#738](https://github.com/fairagro/m4.2_advanced_middleware_api/issues/738) /
[PR #742](https://github.com/fairagro/m4.2_advanced_middleware_api/pull/742)). Infra still deploys via ingress-nginx
only, and **elise** itself is stuck on a stale API RC with legacy `git_repo` config — not a usable fizz-class base for
the Gateway trial (#130).

## What Changes

- Refresh **elise** advanced-middleware plaintext (+ enc as needed) toward current **fizz** shape: dual-slot `arc_store`
  (no `consolidated_store` until Elise has its own catalog repo), modern Rabbit/Couch pins, current API/Celery image;
  keep Elise host `middleware-dev.fairagro.net`, datahub-dev / Elise secrets, otel as appropriate.
- Bump shared umbrella `charts/fairagro-advanced-middleware` OCI dependency to the #742 chart pre-release
  (`3.0.0-rc.issue-738-helm-gateway-optiona.6` or newer RC/release). HTTPRoute remains off by default for fizz/draven.
- On **elise** only: enable `api.httpRoute` + `clientTls` (ListenerSet `fairagro-https`, project `fairagro-m42`) while
  keeping Ingress dual-path until live check; then disable Ingress mTLS path.
- **Non-goals:** fizz/draven Gateway cutover; app chart/code changes in `deps/`; inventing per-env umbrella chart paths;
  enabling Elise `consolidated_store` without a catalog repo; automating the live cert check in CI.

## Capabilities

### New Capabilities

- `elise-middleware-gateway`: Elise advanced-middleware deploy is fizz-class ArcStore/image-wise and exposes the API via
  Gateway API HTTPRoute with optional client TLS (dual-path with Ingress until verified), using the shared umbrella’s
  Gateway-capable OCI chart pin.

### Modified Capabilities

- (none)

## Impact

- Env: `environments/elise/values/fairagro-advanced-middleware.yaml` and `.enc.yaml` (secret key path migration
  `git_repo.token` → `arc_store.git.token`).
- Chart: shared `charts/fairagro-advanced-middleware` dependency + lock — **all** envs pick up the new chart version;
  only Elise enables HTTPRoute in values.
- Argo: Elise (and others on `main`) re-sync the umbrella; no Application template change expected.
- Tracks #130; depends on API #738 / PR #742 chart line (pre-release OK for trial).
