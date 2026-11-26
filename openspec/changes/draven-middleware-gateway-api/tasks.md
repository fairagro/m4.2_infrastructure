## 1. Preconditions

- [ ] 1.1 Confirm umbrella depends on `fairagro-advanced-middleware-api-chart` `≥ 3.0.0`; bump only if missing
- [ ] 1.2 Note draven API/Celery image pin (`14.1.0` vs chart `appVersion` 15.0.0); do not bump unless template/runtime
      fails — pause for lock-in if a bump is required

## 2. Draven Gateway overlay (dual-path)

- [ ] 2.1 Enable draven `api.httpRoute` for `middleware.fairagro.net` with `clientTls` (`project: fairagro-m42`,
      `verifyDepth: 3`)
- [ ] 2.2 Set draven `parentRefs` to stable ListenerSet contract (`gateway.networking.k8s.io`, `fairagro-https`,
      `kube-gateway-api`, `sectionName: https`)
- [ ] 2.3 Keep draven `api.ingress.enabled: true` with existing mTLS (dual-path) until live check and DNS readiness

## 3. Verification

- [ ] 3.1 `helm template` draven: HTTPRoute + SnippetsFilter + Ingress; parentRefs use stable group
- [ ] 3.2 Spot-check: elise still Gateway-sole; fizz still dual-path (or current main state)
- [ ] 3.3 Document operator live check (5A) in PR body / `live-check.md`: ListenerSet + CA on draven; with/without
      client cert via Gateway `--resolve`; Ingress-off only after DNS can move

## 4. Post live-check + DNS (same change when ready)

- [ ] 4.1 Set draven `api.ingress.enabled: false` after successful live check and DNS cutover (host/tls kept for
      rollback)
- [ ] 4.2 Re-`helm template` draven: no Ingress object; HTTPRoute + SnippetsFilter remain
