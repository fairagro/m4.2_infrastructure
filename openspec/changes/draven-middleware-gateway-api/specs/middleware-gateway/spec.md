## ADDED Requirements

### Requirement: Draven enables HTTPRoute with optional client TLS (dual-path)

The draven overlay SHALL enable `api.httpRoute` for hostname `middleware.fairagro.net` with optional client TLS
(`clientTls.enabled: true`, project `fairagro-m42`, parentRefs per the stable ListenerSet contract). During the trial,
draven SHALL keep Ingress enabled with mTLS (dual-path). After a successful live check (request with and without client
cert; docs/health or `/v3/liveness` usable without client cert; platform CA full chain and ListenerSet confirmed) and
when DNS can point at the Gateway external load balancer, draven SHOULD disable the Ingress path so Gateway is the sole
external entry.

#### Scenario: Draven values opt into Gateway

- **WHEN** an operator inspects draven advanced-middleware values after this change
- **THEN** `api.httpRoute.enabled` is true for `middleware.fairagro.net` and `api.httpRoute.clientTls.enabled` is true
  with project `fairagro-m42`

#### Scenario: Dual-path until live check and DNS readiness

- **WHEN** the Gateway trial has not yet completed live verification on draven or DNS still targets the Ingress LB
- **THEN** `api.ingress.enabled` remains true with mTLS so the existing Ingress path still works alongside HTTPRoute

## MODIFIED Requirements

### Requirement: Shared umbrella pins Gateway-capable API chart

The infrastructure umbrella chart at `charts/fairagro-advanced-middleware` SHALL depend on an OCI
`fairagro-advanced-middleware-api-chart` version that includes Gateway HTTPRoute and optional client TLS
(`SnippetsFilter`) support (`3.0.0` or newer on that line). Chart defaults SHALL leave HTTPRoute disabled so
environments that do not opt in remain on Ingress-only behaviour.

#### Scenario: Umbrella dependency is Gateway-capable

- **WHEN** an operator reads `charts/fairagro-advanced-middleware/Chart.yaml`
- **THEN** the `fairagro-advanced-middleware-api-chart` dependency version is `3.0.0` or newer on the Gateway-capable
  line

#### Scenario: Non-opt-in environments stay Ingress-only by values

- **WHEN** an environment overlay does not enable `api.httpRoute`
- **THEN** rendering the umbrella for that environment keeps Ingress as the configured external path and does not
  require Gateway hostnames

### Requirement: HTTPRoute parentRefs use stable ListenerSet API group

Environment overlays that enable `api.httpRoute` SHALL override `parentRefs` to use `group: gateway.networking.k8s.io`,
`kind: ListenerSet`, `name: fairagro-https`, `namespace: kube-gateway-api`, and `sectionName: https`. They SHALL NOT
rely on the chart default `gateway.networking.x-k8s.io` group alone.

#### Scenario: Opt-in overlay overrides parentRefs

- **WHEN** an operator inspects elise, fizz, or draven advanced-middleware values with `api.httpRoute.enabled: true`
- **THEN** `api.httpRoute.parentRefs` includes the stable API group and `sectionName: https` for ListenerSet
  `fairagro-https`
