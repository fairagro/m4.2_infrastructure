## ADDED Requirements

### Requirement: R1 runbook documents sync-pause pin procedure
The repository SHALL provide an operator runbook under `docs/` that documents emergency pin (**R1**) as: pause automated sync / selfHeal on the umbrella wrapper Application; set the wrapper Application `targetRevision` (all sources) to a known-good revision; set every child Application `targetRevision` (all sources) to the same revision; forbid re-applying / upserting the checked-in wrapper Application manifest while pinned; and describe exit via R2 or a fixed newer revision before restoring normal tracking and re-enabling automated sync.

#### Scenario: Operator follows documented R1 steps
- **WHEN** an operator opens the R1 runbook after a bad deploy
- **THEN** the runbook lists the sync-pause → wrapper pin → child pins → no-bootstrap → exit sequence in order

#### Scenario: Wrapper-only pin is called out as insufficient
- **WHEN** the runbook explains why children use literal `targetRevision: "*"` under `lock_children_to_revision` on draven
- **THEN** it states that pinning only the wrapper does not roll child workloads back to the known-good revision while `*` still resolves to the newest SemVer tag

### Requirement: R1 revision identity is environment-specific
The R1 runbook SHALL state that the same procedure applies on draven and fizz-class clusters, that on draven the known-good revision is a SemVer git tag, that on fizz the known-good revision is typically a git commit SHA (or older `main` tip), and that using R1 on fizz is unusual compared with fixing forward or reverting on `main`.

#### Scenario: Draven pin uses a SemVer tag
- **WHEN** the operator performs R1 on draven
- **THEN** the runbook instructs pinning wrapper and children to an exact SemVer tag (not leaving `*`)

#### Scenario: Fizz pin uses commit identity and is discouraged as default
- **WHEN** the operator reads the fizz section of the runbook
- **THEN** the runbook describes commit-SHA (or equivalent) pinning and states R1 on fizz should be rare

### Requirement: R1 authorization
The R1 runbook SHALL state that both the global Argo CD admin account and the project admin account (`fairagro-m42-admin`) MAY perform R1.

#### Scenario: Who may pin
- **WHEN** an operator checks whether project admin may execute R1
- **THEN** the runbook explicitly allows both global admin and `fairagro-m42-admin`

### Requirement: Process documentation and README entry points
The repository SHALL document the happy-path deploy sequence (branch/PR → fizz trial → draven promote → infra SemVer release) alongside R1 vs R2 and emergency-only ruleset bypass, and the README GitOps section SHALL link to the R1 runbook and MUST NOT point R1 solely at issue #43.

#### Scenario: README links the runbook
- **WHEN** a reader follows GitOps / rollback pointers in the README
- **THEN** they reach the `docs/` R1 runbook and see R2 referenced as the lasting rollback path (#57)

#### Scenario: R1 vs R2 distinction
- **WHEN** the process doc compares rollback options
- **THEN** R1 is described as Argo-side emergency pin with sync pause, and R2 as a new higher SemVer tag from an older tree without requiring Argo UI
