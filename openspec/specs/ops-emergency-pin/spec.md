# ops-emergency-pin

## Purpose

Operator documentation for **emergency pin** (Argo-side temporary pin with sync pause)
versus lasting **SemVer release rollback**, including who may pin and how revision
identity differs by environment. Synced from change `emergency-pin-runbook-docs`.

## Requirements

### Requirement: Emergency pin runbook documents sync-pause pin procedure

The repository SHALL provide an operator runbook under `docs/` that documents **emergency pin** as: pause automated sync / selfHeal on the umbrella wrapper Application; set the wrapper Application `targetRevision` (all sources) to a known-good revision; set every child Application `targetRevision` (all sources) to the same revision; forbid re-applying / upserting the checked-in wrapper Application manifest while pinned; and describe exit via SemVer release rollback or a fixed newer revision before restoring normal tracking and re-enabling automated sync. The runbook and README SHALL use plain language (**emergency pin**, **SemVer release rollback**) and MUST NOT rely on opaque letter codes (e.g. R1/R2) as the primary names.

#### Scenario: Operator follows documented emergency pin steps

- **WHEN** an operator opens the emergency pin runbook after a bad deploy
- **THEN** the runbook lists the sync-pause → wrapper pin → child pins → no-bootstrap → exit sequence in order

#### Scenario: Wrapper-only pin is called out as insufficient

- **WHEN** the runbook explains why children use literal `targetRevision: "*"` under `lock_children_to_revision` on draven
- **THEN** it states that pinning only the wrapper does not roll child workloads back to the known-good revision while `*` still resolves to the newest SemVer tag

### Requirement: Emergency pin revision identity is environment-specific

The emergency pin runbook SHALL state that the same procedure applies on draven and fizz-class clusters, that on draven the known-good revision is a SemVer git tag, that on fizz the known-good revision is typically a git commit SHA (or older `main` tip), and that using emergency pin on fizz is unusual compared with fixing forward or reverting on `main`.

#### Scenario: Draven pin uses a SemVer tag

- **WHEN** the operator performs emergency pin on draven
- **THEN** the runbook instructs pinning wrapper and children to an exact SemVer tag (not leaving `*`)

#### Scenario: Fizz pin uses commit identity and is discouraged as default

- **WHEN** the operator reads the fizz section of the runbook
- **THEN** the runbook describes commit-SHA (or equivalent) pinning and states emergency pin on fizz should be rare

### Requirement: Emergency pin authorization

The emergency pin runbook SHALL state that both the global Argo CD admin account and the project admin account (`fairagro-m42-admin`) MAY perform emergency pin.

#### Scenario: Who may pin

- **WHEN** an operator checks whether project admin may execute emergency pin
- **THEN** the runbook explicitly allows both global admin and `fairagro-m42-admin`

### Requirement: Process documentation and README entry points

The repository SHALL document the happy-path deploy sequence (branch/PR → fizz trial → draven promote → infra SemVer release) alongside emergency pin vs SemVer release rollback and emergency-only ruleset bypass, and the README GitOps section SHALL link to the emergency pin runbook and MUST NOT point emergency pin solely at issue #43. SemVer release rollback SHALL be documented as the Actions **release-rollback** path (issue #57) where that workflow exists.

#### Scenario: README links the runbook

- **WHEN** a reader follows GitOps / rollback pointers in the README
- **THEN** they reach `docs/ops/emergency-pin.md` and see SemVer release rollback referenced as the lasting rollback path (#57 / **release-rollback**)

#### Scenario: Emergency pin vs SemVer release rollback distinction

- **WHEN** the process doc compares rollback options
- **THEN** emergency pin is described as Argo-side temporary pin with sync pause, and SemVer release rollback as a new higher SemVer tag from an older tree without requiring Argo UI
