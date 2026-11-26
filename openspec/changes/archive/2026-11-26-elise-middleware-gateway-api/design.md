## Context

Elise advanced-middleware overlay still pins API `8.7.1-rc…` with top-level `git_repo` and ingress-nginx mTLS. Fizz
already runs dual-slot ArcStore + API `15.0.0` on umbrella chart `2.9.0`. Platform Gateway optional client TLS is on
elise; product chart PR #742 adds HTTPRoute + SnippetsFilter (`api.httpRoute.clientTls`) and published OCI pre-release
`3.0.0-rc.issue-738-helm-gateway-optiona.6`. Umbrella Application always renders from shared
`charts/fairagro-advanced-middleware` — one dependency version for every env on the same git revision.

Locked explore decisions (#130): MVP packs Elise refresh + shared chart RC + Elise HTTPRoute (1A); shared pin to RC
(2A); Ingress dual-path during trial (3A); no Elise `consolidated_store` yet (4B); live cert check remains operator AC
after sync (5A).

## Goals / Non-Goals

**Goals:**

- Elise plaintext/enc usable with current API image and ArcStore contract (`arc_store.git_repo` + token under
  `arc_store.git`).
- Shared umbrella on Gateway-capable chart RC without enabling HTTPRoute on fizz/draven.
- Elise HTTPRoute + clientTls against `ListenerSet` `fairagro-https` / project `fairagro-m42`, Ingress still on until
  live check.

**Non-Goals:**

- Fizz/draven Gateway cutover or Ingress-off elsewhere.
- Per-env chart trees / Application path forks.
- Product chart changes; inventing an Elise consolidated catalog repo.
- CI that presents client certs to Gateway.

## Decisions

1. **Shared umbrella → chart RC (not Elise-only pin)**
   - **Why:** Current GitOps model; HTTPRoute defaults off so fizz/draven keep Ingress-only behaviour.
   - **Rejected:** Wait for stable `chart-v3.x` before any infra bump (slower trial); per-env chart path (scope creep).

2. **Elise refresh from fizz shape with Elise identity**
   - Keep `middleware-dev.fairagro.net`, datahub-dev group/URL, Elise enc material.
   - Drop legacy `config.git_repo`; add `arc_store.git_repo` + migrate enc token path.
   - **Omit** `consolidated_store` (4B).
   - Align Rabbit/Couch/image pins with fizz unless Elise-specific constraint appears during apply.
   - `known_rdis`: keep Elise’s current set (not full fizz portfolio) unless apply finds chart/API requires topics for
     every known RDI — then add only required `rdi_gitlab_topics` keys.

3. **Gateway values on Elise only**
   - `api.httpRoute.enabled: true`, hostnames for `middleware-dev.fairagro.net`, `clientTls.enabled: true` with
     `project: fairagro-m42` (verifyDepth match Ingress depth where chart allows).
   - Leave default `parentRefs` (ListenerSet `fairagro-https` in `kube-gateway-api`) unless overlay must override.
   - Keep `api.ingress.enabled: true` + mTLS for dual-path; Ingress-off is a follow-up step after live check (same issue
     AC, can be a second commit/PR on this change if sync order needs it).

4. **Secret migration with sops**
   - Rewrite Elise enc: remove `config.git_repo.token`; add `config.arc_store.git.token` (reuse existing token value).
   - Do not commit plaintext secrets.

5. **Verification**
   - `helm dependency update` + `helm template` (or existing `ci_helm_template_matrix`) for Elise with Gateway chart.
   - Live check (5A) documented in tasks / PR — not automated here.

## Risks / Trade-offs

- **[Risk] Chart 3.0.0-rc is a major OCI bump for all envs** → Mitigation: rely on HTTPRoute/clientTls default off;
  template Elise + fizz before merge; roll forward to released chart when #742 merges.
- **[Risk] Elise ArcStore without consolidated_store differs from fizz** → Mitigation: intentional (4B); API must accept
  arc_store-only (fizz dual-slot optional consolidated).
- **[Risk] Enc key rename breaks sync if plaintext still references old path** → Mitigation: change plaintext and enc in
  the same apply; `sops` round-trip before push.
- **[Risk] Dual-path host served by both Ingress and Gateway** → Mitigation: expected during trial; after live check
  disable Ingress on Elise only.
- **[Risk] Namespace not on ListenerSet allowlist** → Mitigation: platform #562 / chart docs require
  `fairagro-advanced-middleware`; confirm on elise during live check.

## Migration Plan

1. Commit proposal/design/specs/tasks; on apply: umbrella Chart.yaml/lock → RC; Elise values + enc; optional docs note.
2. Merge → Argo on `main` pulls new chart everywhere; only Elise enables HTTPRoute.
3. Operator live check on elise; then disable Elise Ingress in a follow-up commit on this change or linked PR.
4. When #742 releases stable chart, bump umbrella off the RC tag.

**Rollback:** Revert umbrella dependency to `2.9.0` and/or Elise Gateway flags; restore previous Elise values/enc from
git.

## Open Questions

- Exact API image tag for the trial: match fizz `15.0.0` vs chart pre-release `appVersion` — resolve at apply by reading
  packaged chart metadata.
- Whether Elise Ingress-off lands in the same PR after first sync or a fast follow — prefer same change if live check is
  quick; otherwise second commit still under #130.
