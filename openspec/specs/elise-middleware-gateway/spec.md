# elise-middleware-gateway

## Purpose

Elise advanced-middleware deploy is fizz-class ArcStore/image-wise and exposes the API via Gateway API HTTPRoute with
optional client TLS (dual-path with Ingress until verified), using the shared umbrella’s Gateway-capable OCI chart pin.
Synced from change `elise-middleware-gateway-api`.

## Requirements

### Requirement: Elise advanced-middleware uses current ArcStore config shape

The elise environment overlay for advanced middleware SHALL configure the API with dual-slot-era ArcStore settings:
required `arc_store` (`git_repo` backend) and SHALL NOT use the legacy top-level `config.git_repo` block. Elise SHALL
omit `consolidated_store` until an Elise catalog repository is provisioned. API and Celery image tags SHALL be current
release pins suitable for the Gateway-capable chart trial (aligned with fizz unless apply documents a newer required
tag). RabbitMQ and CouchDB image pins SHALL be brought in line with the current fizz-class pins.

#### Scenario: Plaintext overlay has no legacy git_repo

- **WHEN** an operator inspects `environments/elise/values/fairagro-advanced-middleware.yaml`
- **THEN** `config.arc_store.git_repo` is present with Elise datahub-dev URL/group and RDI topic mapping as required,
  and top-level `config.git_repo` is absent

#### Scenario: Encrypted token path matches ArcStore

- **WHEN** an operator inspects `environments/elise/values/fairagro-advanced-middleware.enc.yaml` structure (without
  decrypting values into git)
- **THEN** the GitLab token lives under `fairagro-advanced-middleware-api-chart.config.arc_store.git.token` and not
  under `config.git_repo.token`

### Requirement: Shared umbrella pins Gateway-capable API chart

The infrastructure umbrella chart at `charts/fairagro-advanced-middleware` SHALL depend on an OCI
`fairagro-advanced-middleware-api-chart` version that includes Gateway HTTPRoute and optional client TLS
(`SnippetsFilter`) support (`3.0.0` or newer on that line). Chart defaults SHALL leave HTTPRoute disabled so
environments that do not opt in remain on Ingress-only behaviour.

#### Scenario: Umbrella dependency is Gateway-capable

- **WHEN** an operator reads `charts/fairagro-advanced-middleware/Chart.yaml` (and lock)
- **THEN** the `fairagro-advanced-middleware-api-chart` dependency version is on the Gateway-capable chart line above

#### Scenario: Fizz remains Ingress-only by values

- **WHEN** fizz values do not enable `api.httpRoute`
- **THEN** rendering the umbrella for fizz does not require Elise-specific Gateway hostnames and keeps Ingress as the
  configured external path

### Requirement: Elise enables HTTPRoute with optional client TLS (dual-path)

The elise overlay SHALL enable `api.httpRoute` for hostname `middleware-dev.fairagro.net` with optional client TLS
(`clientTls.enabled: true`, project `fairagro-m42`, parentRefs suitable for ListenerSet `fairagro-https` in
`kube-gateway-api`). During the trial, Elise SHALL keep Ingress enabled with mTLS (dual-path). After a successful live
check (request with and without client cert; docs/health usable without client cert), Elise SHOULD disable the Ingress
mTLS path so Gateway is the sole external entry.

#### Scenario: Elise values opt into Gateway

- **WHEN** an operator inspects elise advanced-middleware values after this change
- **THEN** `api.httpRoute.enabled` is true for `middleware-dev.fairagro.net` and `api.httpRoute.clientTls.enabled` is
  true with project `fairagro-m42`

#### Scenario: Dual-path until live check

- **WHEN** the Gateway trial has not yet completed live verification on elise
- **THEN** `api.ingress.enabled` remains true with mTLS so the existing Ingress path still works alongside HTTPRoute
