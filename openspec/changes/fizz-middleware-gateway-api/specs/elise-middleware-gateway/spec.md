## REMOVED Requirements

### Requirement: Elise advanced-middleware uses current ArcStore config shape

**Reason:** ArcStore/image baseline for elise was delivered by #130/#131 and is no longer part of the Gateway-facing
capability contract; Gateway rollout requirements move to shared `middleware-gateway`.

**Migration:** Retain ArcStore/image pins in elise values as shipped; do not reintroduce this requirement under
`middleware-gateway`. Follow ArcStore-related specs/issues for further ArcStore changes.

### Requirement: Shared umbrella pins Gateway-capable API chart

**Reason:** Superseded by the same requirement under `middleware-gateway` (shared multi-env contract).

**Migration:** See `middleware-gateway` requirement “Shared umbrella pins Gateway-capable API chart”.

### Requirement: Elise enables HTTPRoute with optional client TLS (dual-path)

**Reason:** Elise has completed live check and Ingress-off; dual-path trial language is obsolete. Elise Gateway-sole
behaviour and fizz dual-path live under `middleware-gateway`.

**Migration:** See `middleware-gateway` requirements “Elise exposes Middleware API via Gateway as sole external entry”
and “Fizz enables HTTPRoute with optional client TLS (dual-path)”.
