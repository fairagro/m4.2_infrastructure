# argocd-gitops-bootstrap

## Purpose

Path-A GitOps for Argo-backed clusters: a Root Application tracks `environments/<env>/argocd/` on `main`; checked-in wrapper Applications pin fizz-class to `main` and draven to SemVer `*`; child revision asymmetry and bootstrap via script/docs. CI must not rewrite Application pins.

Synced from change `gitops-bootstrap` (archived).

## Requirements

### Requirement: Checked-in wrapper Application per Argo environment

The repository SHALL contain a plaintext Argo CD Application manifest for the m42 wrapper under `environments/<env>/argocd/` for each Argo-backed environment **fizz**, **elise**, and **draven**. These manifests MUST NOT contain SOPS-encrypted secrets.

#### Scenario: Operator can inspect wrapper desired state in git

- **WHEN** an operator opens `environments/fizz/argocd/` (and likewise elise, draven) on branch `main`
- **THEN** a wrapper Application manifest is present that points at `helmcharts/fairagro-m42-applications` with multi-source valueFiles for that environment

### Requirement: Root Application syncs argocd defs from main

Each Argo-backed cluster SHALL be bootstrapped with a Root Application whose `targetRevision` is `main` and whose path is `environments/<env>/argocd`, so wrapper Application definitions are applied from git without CI rewriting them on each release.

#### Scenario: Root apply creates or updates the wrapper Application

- **WHEN** the Root Application is synced successfully for environment `fizz`
- **THEN** the wrapper Application for that cluster matches the manifest in `environments/fizz/argocd/` on `main`

### Requirement: fizz-class tracks main with automated sync

For fizz-class environments (at least **fizz** and **elise**), the wrapper Application `targetRevision` SHALL be `main`, and the wrapper SHALL enable automated sync so merges to `main` deploy without a manual Argo UI sync. Child Applications rendered for those environments SHOULD also enable automated sync so workload sync is not left manual when the wrapper updates.

#### Scenario: fizz wrapper follows main

- **WHEN** the fizz wrapper Application is applied from git
- **THEN** its `spec` sources use `targetRevision: main` (or equivalent default-branch tip) and automated sync is configured

### Requirement: draven tracks SemVer tags via star revision

For **draven**, the wrapper Application `targetRevision` SHALL be `*` (optionally with a tag prefix configuration) so Argo CD selects the highest matching SemVer git tag. The checked-in manifest MUST keep this star revision permanently; release automation MUST NOT commit a concrete version into that field.

#### Scenario: draven wrapper uses star revision

- **WHEN** the draven wrapper Application is applied from git
- **THEN** its sources use `targetRevision: '*'` (and optional tagPrefix if configured) rather than `main` or a hard-coded release tag string in the happy path

#### Scenario: no matching tag yet

- **WHEN** no SemVer tag matching the Application’s revision constraint exists
- **THEN** the bootstrap is still considered valid; resolving a concrete tag is deferred until a release tag exists (release workflow out of scope for this capability)

### Requirement: Child revision asymmetry

fizz-class child Application revisions SHALL default to `main` and MAY be overridden per child for split-tracking. On **draven**, enabled child Applications MUST NOT use a revision that resolves to the default branch tip independently of the release snapshot (bare `HEAD` as “follow main” is forbidden for enabled children). Children SHALL use the same git tag as the intended release snapshot (via env values and/or chart lock).

#### Scenario: fizz child can stay on main

- **WHEN** fizz umbrella values leave child `*_revision` unset or set to `main`
- **THEN** child Applications track `main`

#### Scenario: draven children do not silently follow main

- **WHEN** draven is configured for release-tag tracking
- **THEN** enabled child `*_revision` values do not resolve independently to default-branch `HEAD`/`main` while the wrapper is intended to run a release tag snapshot

### Requirement: Bootstrap script or documented one-shot Root create

The repository SHALL provide a script and/or documented command that creates or updates the Root Application for a given environment using existing Argo credentials (SOPS), without requiring the operator to hand-author the Root manifest each time.

#### Scenario: Bootstrap Root for fizz

- **WHEN** an operator with Argo credentials runs the documented bootstrap for `fizz`
- **THEN** a Root Application exists that syncs `environments/fizz/argocd` from `main`
