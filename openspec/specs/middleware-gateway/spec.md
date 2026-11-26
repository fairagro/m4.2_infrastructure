# middleware-gateway

## Purpose

Advanced-middleware environments that opt into Gateway API expose the API via HTTPRoute with optional client TLS
(`SnippetsFilter`), using the shared umbrella’s Gateway-capable OCI chart pin. Elise is Gateway-sole; fizz dual-paths
with Ingress until live check; draven stays Ingress-only until a later change. Synced from change
`fizz-middleware-gateway-api` (replaces retired `elise-middleware-gateway`).

## Requirements

### Requirement: Shared umbrella pins Gateway-capable API chart

The infrastructure umbrella chart at `charts/fairagro-advanced-middleware` SHALL depend on an OCI
`fairagro-advanced-middleware-api-chart` version that includes Gateway HTTPRoute and optional client TLS
(`SnippetsFilter`) support (`3.0.0` or newer on that line). Chart defaults SHALL leave HTTPRoute disabled so
environments that do not opt in remain on Ingress-only behaviour.

#### Scenario: Umbrella dependency is Gateway-capable

- **WHEN** an operator reads `charts/fairagro-advanced-middleware/Chart.yaml`
- **THEN** the `fairagro-advanced-middleware-api-chart` dependency version is `3.0.0` or newer on the Gateway-capable
  line

#### Scenario: Draven remains Ingress-only by values

- **WHEN** draven values do not enable `api.httpRoute`
- **THEN** rendering the umbrella for draven keeps Ingress as the configured external path and does not require Gateway
  hostnames

### Requirement: HTTPRoute parentRefs use stable ListenerSet API group

Environment overlays that enable `api.httpRoute` SHALL override `parentRefs` to use `group: gateway.networking.k8s.io`,
`kind: ListenerSet`, `name: fairagro-https`, `namespace: kube-gateway-api`, and `sectionName: https`. They SHALL NOT
rely on the chart default `gateway.networking.x-k8s.io` group alone.

#### Scenario: Opt-in overlay overrides parentRefs

- **WHEN** an operator inspects elise or fizz advanced-middleware values with `api.httpRoute.enabled: true`
- **THEN** `api.httpRoute.parentRefs` includes the stable API group and `sectionName: https` for ListenerSet
  `fairagro-https`

### Requirement: Elise exposes Middleware API via Gateway as sole external entry

The elise overlay SHALL enable `api.httpRoute` for hostname `middleware-dev.fairagro.net` with optional client TLS
(`clientTls.enabled: true`, project `fairagro-m42`, `verifyDepth` matching the Ingress verify depth used before
cutover). Elise SHALL keep `api.ingress.enabled: false` so Gateway is the sole external entry after the elise live
check.

#### Scenario: Elise values opt into Gateway without Ingress

- **WHEN** an operator inspects elise advanced-middleware values
- **THEN** `api.httpRoute.enabled` is true for `middleware-dev.fairagro.net`, `api.httpRoute.clientTls.enabled` is true
  with project `fairagro-m42`, and `api.ingress.enabled` is false

### Requirement: Fizz enables HTTPRoute with optional client TLS (dual-path)

The fizz overlay SHALL enable `api.httpRoute` for hostname `middleware-test.fairagro.net` with optional client TLS
(`clientTls.enabled: true`, project `fairagro-m42`, parentRefs per the stable ListenerSet contract). During the trial,
fizz SHALL keep Ingress enabled with mTLS (dual-path). After a successful live check (request with and without client
cert; docs/health usable without client cert; platform CA full chain confirmed), fizz SHOULD disable the Ingress path so
Gateway is the sole external entry and DNS points at the Gateway external load balancer.

#### Scenario: Fizz values opt into Gateway

- **WHEN** an operator inspects fizz advanced-middleware values after this change
- **THEN** `api.httpRoute.enabled` is true for `middleware-test.fairagro.net` and `api.httpRoute.clientTls.enabled` is
  true with project `fairagro-m42`

#### Scenario: Dual-path until live check

- **WHEN** the Gateway trial has not yet completed live verification on fizz
- **THEN** `api.ingress.enabled` remains true with mTLS so the existing Ingress path still works alongside HTTPRoute
