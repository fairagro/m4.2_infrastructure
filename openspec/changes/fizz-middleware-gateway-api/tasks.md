## 1. Preconditions

- [x] 1.1 Confirm `charts/fairagro-advanced-middleware` on this branch depends on
      `fairagro-advanced-middleware-api-chart` `≥ 3.0.0` (from #131); bump only if missing
- [x] 1.2 Confirm elise overlay already has HTTPRoute + Ingress-off (no elise values churn unless parentRefs/spec drift)

## 2. Fizz Gateway overlay (dual-path)

- [x] 2.1 Enable fizz `api.httpRoute` for `middleware-test.fairagro.net` with `clientTls` (`project: fairagro-m42`,
      `verifyDepth: 3`)
- [x] 2.2 Set fizz `parentRefs` to stable ListenerSet contract (`gateway.networking.k8s.io`, `fairagro-https`,
      `kube-gateway-api`, `sectionName: https`)
- [x] 2.3 Keep fizz `api.ingress.enabled: true` with existing mTLS (dual-path) until live check

## 3. Verification

- [x] 3.1 `helm template` fizz: HTTPRoute + SnippetsFilter + Ingress present; parentRefs use stable group
- [x] 3.2 `helm template` / values check: draven still Ingress-only (no HTTPRoute); elise still Gateway-sole
- [x] 3.3 Document operator live check (5A) in PR body: with/without client cert via Gateway `--resolve`; platform CA
      full chain; DNS → Gateway LB; then Ingress-off (checklist:
      `openspec/changes/fizz-middleware-gateway-api/live-check.md`)

## 4. Post live-check (same change when ready)

- [ ] 4.1 Set fizz `api.ingress.enabled: false` after successful live check (host/tls kept for rollback)
- [ ] 4.2 Re-`helm template` fizz: no Ingress object; HTTPRoute + SnippetsFilter remain
