## Why

Elise Middleware API is on Gateway (`HTTPRoute` + optional client TLS); fizz still serves only via ingress-nginx. After
the elise trial (#130 / #131), fizz should take the same path for `middleware-test.fairagro.net`. Spec-wise, the
elise-only capability should become a shared `middleware-gateway` contract covering elise (Gateway sole entry) and fizz
(dual-path trial).

## What Changes

- Enable fizz `api.httpRoute` + `clientTls` (project `fairagro-m42`) with corrected `parentRefs`
  (`gateway.networking.k8s.io`, ListenerSet `fairagro-https`, `sectionName: https`)
- Keep fizz Ingress mTLS dual-path until live check; then disable Ingress (same cadence as elise)
- Confirm shared umbrella already pins Gateway-capable chart `≥ 3.0.0` (from #131); no RC pin work
- **BREAKING (spec rename):** replace capability `elise-middleware-gateway` with shared `middleware-gateway` (elise
  post-cutover + fizz dual-path; draven out of scope)
- Document operator live check (with/without client cert, platform CA full chain, DNS → Gateway LB)

## Capabilities

### New Capabilities

- `middleware-gateway`: Shared Gateway HTTPRoute + optional client TLS contract for advanced-middleware overlays that
  opt in (elise sole Gateway entry; fizz dual-path then Ingress-off; umbrella chart `≥ 3.0.0`; stable ListenerSet
  parentRefs; draven remains Ingress-only until a later change)

### Modified Capabilities

- `elise-middleware-gateway`: Retire — requirements move into `middleware-gateway` (remove after archive sync so main
  specs no longer keep an elise-only capability)

## Impact

- `environments/fizz/values/fairagro-advanced-middleware.yaml` (HTTPRoute + dual-path Ingress)
- `openspec/specs/elise-middleware-gateway/` → replaced by `openspec/specs/middleware-gateway/`
- Shared umbrella `charts/fairagro-advanced-middleware` already on `3.0.0` after #131 (verify only)
- Platform: project CA full chain + DNS for `middleware-test.fairagro.net` (operator checklist, not repo-owned)
- Out of scope: draven Gateway cutover (#134 AC)
