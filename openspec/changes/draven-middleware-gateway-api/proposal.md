## Why

Elise and fizz already expose Middleware API via Gateway (`HTTPRoute` + optional client TLS). Draven still serves
`middleware.fairagro.net` only through ingress-nginx. After fizz live-check succeeded (#134 / #135), draven should take
the same dual-path cutover while DNS may still lag on the Ingress LB.

## What Changes

- Enable draven `api.httpRoute` + `clientTls` (project `fairagro-m42`) with corrected `parentRefs`
  (`gateway.networking.k8s.io`, ListenerSet `fairagro-https`, `sectionName: https`)
- Keep draven Ingress mTLS dual-path until live check (and until DNS can move to Gateway); then Ingress-off
- Confirm umbrella already pins chart `≥ 3.0.0` (no RC / no bump unless missing)
- Update `middleware-gateway` so draven is dual-path opt-in instead of “Ingress-only by values”
- Document operator live check (with/without client cert via Gateway `--resolve`; CA full chain; ListenerSet on draven)

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `middleware-gateway`: Replace “Draven remains Ingress-only” with draven HTTPRoute dual-path requirement; extend
  parentRefs scenario to include draven; refresh Purpose (elise sole / fizz+draven dual-path)

## Impact

- `environments/draven/values/fairagro-advanced-middleware.yaml`
- `openspec/specs/middleware-gateway/spec.md`
- Platform: ListenerSet + project CA on draven cluster; DNS cutover when possible (operator)
- Out of scope unless separately locked: bumping draven API/Celery image off `14.1.0` toward chart `appVersion` 15.0.0
