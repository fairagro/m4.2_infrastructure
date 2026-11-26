## 1. Umbrella chart pin (shared)

- [ ] 1.1 Set `charts/fairagro-advanced-middleware` dependency to Gateway-capable OCI chart
      (`3.0.0-rc.issue-738-helm-gateway-optiona.6` or newer RC/release on that line)
- [ ] 1.2 Run `helm dependency update` for the umbrella and commit `Chart.lock` / vendored `charts/*.tgz` as the repo
      normally tracks them
- [ ] 1.3 Confirm packaged chart exposes `api.httpRoute` / `clientTls` and note `appVersion` for Elise image pins

## 2. Elise values refresh (plaintext)

- [ ] 2.1 Replace legacy `config.git_repo` with `arc_store.git_repo` (datahub-dev URL/group; `rdi_gitlab_topics` for
      Elise `known_rdis` only); omit `consolidated_store`
- [ ] 2.2 Align API/Celery image tags with the trial pin (fizz `15.0.0` or chart `appVersion` if newer required)
- [ ] 2.3 Align RabbitMQ/CouchDB image pins with current fizz-class pins
- [ ] 2.4 Enable Elise `api.httpRoute` (+ `clientTls` project `fairagro-m42`, hostname `middleware-dev.fairagro.net`)
      while keeping Ingress mTLS dual-path

## 3. Elise secrets (enc)

- [ ] 3.1 With `sops`, migrate `config.git_repo.token` → `config.arc_store.git.token` (same token value); remove legacy
      key; do not commit plaintext

## 4. Verification

- [ ] 4.1 `helm template` (or `scripts/ci_helm_template_matrix.sh`) for elise against the updated umbrella — HTTPRoute /
      SnippetsFilter present; fizz still Ingress-oriented
- [ ] 4.2 Document operator live check (5A) in PR body: with/without client cert; docs/health without cert; then Ingress
      off on Elise when satisfied
