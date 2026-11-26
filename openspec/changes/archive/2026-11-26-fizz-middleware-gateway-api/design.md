## Context

Elise advanced-middleware is already on Gateway sole entry after #130/#131 (`HTTPRoute` + `SnippetsFilter` optional
client TLS; Ingress disabled; umbrella OCI pin `3.0.0`). Fizz remains Ingress-only for `middleware-test.fairagro.net`.
Chart defaults still use `parentRefs.group: gateway.networking.x-k8s.io`, which does not Accept against the cluster
ListenerSet CRD (`gateway.networking.k8s.io/v1`). Platform project CA must be the full chain (Root + Intermediate +
Middleware Client CA) or presented client certs yield nginx `400 The SSL certificate error`.

Main specs still describe an elise-only capability (`elise-middleware-gateway`) whose “fizz remains Ingress-only”
scenario is obsolete once fizz opts in.

## Goals / Non-Goals

**Goals:**

- Opt fizz into HTTPRoute + clientTls with the same parentRefs pattern as elise
- Dual-path Ingress until live check; then Ingress-off + DNS to Gateway LB (operator)
- Replace `elise-middleware-gateway` with shared `middleware-gateway` covering elise + fizz
- Verify umbrella already depends on chart `≥ 3.0.0` (no new pin work if #131 is on `main`)

**Non-Goals:**

- Draven Gateway cutover
- Changing ArcStore / image / Rabbit / Couch pins on fizz
- Automating client-cert CI or owning platform CA/DNS in this repo
- Fixing upstream chart default `x-k8s.io` (track in API chart; override in values)

## Decisions

1. **Values-only fizz cutover (mirror elise overlay shape)** Add `api.httpRoute` block to
   `environments/fizz/values/fairagro-advanced-middleware.yaml` with hostnames `middleware-test.fairagro.net`,
   `clientTls` project `fairagro-m42`, `verifyDepth: 3`, and explicit `parentRefs` (stable group +
   `sectionName: https`). Keep existing Ingress enabled for dual-path (2A). _Alternatives:_ stacked PR on pre-merge #131
   (obsolete — #131 merged); Ingress-off in first sync (rejected without live check).

2. **Shared capability rename (3B)** Introduce `middleware-gateway` with ADDED requirements for umbrella pin, elise
   Gateway-sole, fizz dual-path, and parentRefs contract. REMOVED all requirements from `elise-middleware-gateway` with
   migration to the new capability; archive sync deletes/empties the old main-spec folder. _Alternatives:_ keep
   elise-only + new `fizz-middleware-gateway` (3A — rejected by lock-in).

3. **Chart pin = verify only** After #131, `charts/fairagro-advanced-middleware` already pins `3.0.0`. Apply confirms
   pin; bumps only if `main` regressed. _Alternatives:_ re-bump in this PR (noise).

4. **Operator live check in PR body (5A)** Checklist: resolve Host to Gateway LB; curl with/without harvester (or
   sql-to-arc) client cert; confirm platform CA full chain; then Ingress-off commit (same PR follow-up commit or fast
   follow on this branch). _Alternatives:_ block on platform ticket (5B — rejected).

5. **Ingress-off cadence** Prefer completing Ingress-off on the same change after live check (elise precedent). If live
   check is delayed, ship dual-path first and Ingress-off as a second commit on the same branch before ready-for-review.

## Risks / Trade-offs

- **[Risk] Dual-path same hostname hits Ingress LB via DNS** → Mitigation: live check uses `--resolve` to Gateway IP;
  DNS cutover required before/with Ingress-off
- **[Risk] Incomplete project CA on fizz Gateway dataplane** → Mitigation: PR checklist; reuse elise lesson (full
  chain); do not treat leaf-only Client CA as sufficient
- **[Risk] Spec rename confuses archive tooling** → Mitigation: REMOVED + ADDED deltas; archive sync then delete empty
  `elise-middleware-gateway` main spec if needed
- **[Risk] Chart default parentRefs still wrong for next env** → Mitigation: document override; optional linked
  follow-up on API chart defaults (out of done-when)

## Migration Plan

1. Merge values enabling fizz HTTPRoute dual-path; Argo syncs fizz
2. Operator live check (cert / no-cert / CA / DNS notes)
3. Disable fizz Ingress; point DNS at Gateway external LB
4. Archive OpenSpec change → main `middleware-gateway` spec; drop `elise-middleware-gateway`
5. Rollback: re-enable fizz Ingress and/or disable `httpRoute`; DNS back to Ingress LB

## Open Questions

- None for MVP — lock-ins 1A/2A/3B/4A/5A/6A settled; Ingress-off timing within the same PR after live check vs second
  commit is operator preference at apply time.
