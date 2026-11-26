## Context

Shared umbrella pins `fairagro-advanced-middleware-api-chart` `3.0.0`. Elise is Gateway-sole; fizz dual-paths with
proven live-check (Gateway LB `--resolve`, with/without client cert). Draven remains Ingress-only for
`middleware.fairagro.net`. Spec `middleware-gateway` still says draven stays Ingress-only. Chart default parentRefs use
`gateway.networking.x-k8s.io` (must override). DNS may not move yet — Ingress must stay (2A).

Draven values currently pin API/Celery **`14.1.0`** while elise/fizz use **`15.0.0`** (chart `appVersion`). This change
does not bump images unless operators require it for Gateway templates; flag as risk.

## Goals / Non-Goals

**Goals:**

- Opt draven into HTTPRoute + clientTls with the same parentRefs pattern as elise/fizz
- Dual-path Ingress until live check; Ingress-off after live check **and** when DNS can point at Gateway
- MODIFIED `middleware-gateway` for draven dual-path
- Verify chart `≥ 3.0.0` only

**Non-Goals:**

- DNS ownership / changing public records in this repo
- Replacing fizz/elise overlays
- Mandatory API image bump to 15.0.0 (separate decision if Gateway or app behaviour requires it)
- Fixing upstream chart default `x-k8s.io`

## Decisions

1. **Values-only mirror of fizz overlay** — Add `api.httpRoute` for `middleware.fairagro.net` with stable parentRefs,
   `clientTls` project `fairagro-m42`, `verifyDepth: 3`; keep Ingress enabled (2A). _Alternatives:_ Ingress-off
   immediately (rejected — DNS lag).

2. **Spec MODIFIED in place (3A)** — Replace Draven Ingress-only scenario under umbrella requirement; ADDED/MODIFIED
   draven dual-path requirement; include draven in parentRefs scenario WHEN clause. _Alternatives:_ new capability
   (rejected).

3. **Chart pin verify-only (1A)** — No bump if `3.0.0` already on branch tip.

4. **Operator live check (5A)** — PR checklist: ListenerSet on draven, CA full chain, curl Gateway LB with/without cert;
   Ingress-off only after that and DNS readiness.

5. **Image skew** — Leave `14.1.0` unless apply discovers chart/runtime break; then pause for operator lock-in rather
   than silent bump on production-like env.

## Risks / Trade-offs

- **[Risk] Draven ListenerSet/CA differs from elise/fizz** → Mitigation: live-check gate before ready; same failure
  modes as before (un-Accepted route / `400` SSL certificate error)
- **[Risk] API image `14.1.0` vs chart `appVersion` 15.0.0** → Mitigation: template smoke; pause for image bump if
  broken; do not silently bump production-like pins
- **[Risk] Dual-path DNS still hits Ingress** → Mitigation: `--resolve` to Gateway LB for verification; keep Ingress
  until DNS movable
- **[Risk] Production-like blast radius** → Mitigation: dual-path first; Ingress remains default public path

## Migration Plan

1. Merge values enabling draven HTTPRoute dual-path; Argo syncs
2. Operator live check on Gateway LB
3. When DNS can move: point at Gateway LB; set `api.ingress.enabled: false`
4. Archive OpenSpec change → sync `middleware-gateway`
5. Rollback: disable `httpRoute` and/or re-enable Ingress; DNS back to Ingress LB

## Open Questions

- Whether draven should bump API/Celery to `15.0.0` in the same PR if template/runtime requires it — default leave
  `14.1.0` until evidence.
