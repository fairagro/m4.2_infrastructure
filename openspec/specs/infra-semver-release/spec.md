# infra-semver-release

## Purpose

Manual SemVer tagging for this infra repo so draven’s Argo `targetRevision: '*'` resolves to a validated snapshot: Soft
fizz attestation, draven pin gate before tag, GitHub Release, operator docs, and SemVer release rollback. Synced from
changes `infra-release-workflows` and `semver-release-rollback`.

## Requirements

### Requirement: Manual SemVer release via workflow dispatch

The repository SHALL provide a GitHub Actions workflow that creates an infra SemVer git tag and a GitHub Release only
when triggered with `workflow_dispatch` on branch `main`. The workflow MUST accept a `version_bump` input whose allowed
values are `major`, `minor`, and `patch`, and MUST compute the next version from the highest existing SemVer tag (or the
documented first-tag rules when none exist). The workflow MUST NOT rewrite Application manifests or environment value
files.

#### Scenario: Patch bump from existing tag

- **WHEN** an operator runs the release workflow on `main` with `version_bump: patch` and the highest SemVer tag is
  `1.2.3`
- **THEN** the workflow creates tag `1.2.4` and a corresponding GitHub Release when all gates pass

#### Scenario: Rejected off main

- **WHEN** the release workflow is triggered from a ref other than `main`
- **THEN** the workflow fails without creating a tag or Release

### Requirement: Soft fizz validation attestation

Before creating a tag, the release workflow MUST require a boolean Soft attestation input (fizz validated) to be true.
The workflow MUST NOT implement image lineage checks against current or historical fizz pins, and MUST NOT query Argo CD
health.

#### Scenario: Checkbox false blocks release

- **WHEN** an operator runs the release workflow with the Soft fizz attestation set to false
- **THEN** the workflow fails before creating a tag or Release

#### Scenario: Checkbox true allows gates to proceed

- **WHEN** an operator runs the release workflow on `main` with Soft fizz attestation true and other gates pass
- **THEN** the workflow may create the SemVer tag and GitHub Release

### Requirement: Draven release-pin gate before tag

The release workflow MUST run the existing draven release-pin check (`scripts/check_draven_release_pins.sh` or
equivalent) against the checkout being tagged and MUST NOT create a tag if that check fails. Pre-release pins under
fizz/elise MUST remain unconstrained by this gate.

#### Scenario: Pre-release pin under draven blocks tag

- **WHEN** `environments/draven/values/` contains a product image tag that the pin check classifies as pre-release
- **THEN** the release workflow fails without creating a tag or Release

#### Scenario: Clean draven pins allow tag

- **WHEN** the pin check reports no pre-release image pins under `environments/draven/values/` and other gates pass
- **THEN** the release workflow creates the SemVer tag and GitHub Release

### Requirement: SemVer release rollback via separate workflow

The repository SHALL provide a GitHub Actions workflow distinct from the forward release workflow that creates a new
higher infra SemVer git tag and GitHub Release for rolling draven back to a prior release tree. The rollback workflow
MUST be triggerable only with `workflow_dispatch` on branch `main`. It MUST NOT require Soft fizz attestation. It MUST
NOT rewrite Application manifests or environment value files. It MUST NOT call the Argo CD API.

#### Scenario: Rollback from main succeeds

- **WHEN** an operator runs the rollback workflow on `main` with acknowledgment true, a resolvable target tag, and gates
  pass
- **THEN** the workflow creates a new SemVer tag and GitHub Release whose notes identify a SemVer release rollback

#### Scenario: Rejected off main

- **WHEN** the rollback workflow is triggered from a ref other than `main`
- **THEN** the workflow fails without creating a tag or Release

### Requirement: Rollback target is previous SemVer or optional override

When the optional override input is empty, the rollback workflow MUST resolve the target tag as the newest plain SemVer
tag (`X.Y.Z`) that is strictly older than the oldest existing tag sharing the highest tag's commit SHA (so a prior
rollback that re-tagged an older tree does not make empty-default select a superseded tip between that baseline and the
highest tag). When the override is non-empty, the workflow MUST use that value as the target tag if and only if it
matches plain SemVer and exists. The workflow MUST fail if acknowledgment is false, if previous cannot be resolved (no
older distinct baseline below that shared-SHA origin, or fewer than two usable tags), if an override is invalid or
missing, or if the resolved target equals the current highest plain SemVer tag.

#### Scenario: Default previous

- **WHEN** an operator leaves the override empty, acknowledgment is true, and plain SemVer tags include at least `1.2.0`
  and `1.2.1` with distinct SHAs and `1.2.1` highest
- **THEN** the workflow uses `1.2.0` as the target tag

#### Scenario: Empty default refuses superseded tip after rollback alias

- **WHEN** tags `1.2.0`@C0, `1.2.1`@C1 (bad), and `1.2.2`@C0 (rollback alias) exist and override is empty
- **THEN** the workflow fails without selecting `1.2.1` (no older baseline below `1.2.0`)

#### Scenario: Override tag

- **WHEN** an operator sets the override to an existing older plain SemVer tag `1.1.0` while highest is `1.2.1`
- **THEN** the workflow uses `1.1.0` as the target tag

#### Scenario: Target equals highest fails

- **WHEN** the resolved target tag is the current highest plain SemVer tag
- **THEN** the workflow fails without creating a tag or Release

#### Scenario: Acknowledgment false blocks

- **WHEN** the rollback acknowledgment input is false
- **THEN** the workflow fails without creating a tag or Release

### Requirement: Rollback tag is patch bump at target SHA

The rollback workflow MUST compute the next version with a **patch** bump from the highest existing plain SemVer tag
using the `compute_next_infra_semver.sh` (or equivalent) from the workflow dispatch tip on `main` (not from the
checked-out target tree), and MUST create the new annotated tag pointing at the git object of the target tag (same tree;
no new commit required). GitHub Release notes MUST state that the release is a SemVer release rollback to the target tag
and MUST identify the new and target versions.

#### Scenario: Patch tag on previous SHA

- **WHEN** highest is `1.2.1`, target is `1.2.0` at commit `C`, and gates pass
- **THEN** the workflow creates tag `1.2.2` pointing at `C` and a Release whose notes mention rollback to `1.2.0`

### Requirement: Draven pin gate on rollback tree

Before creating the rollback tag, the rollback workflow MUST run the draven release-pin check against the tree of the
target tag and MUST NOT create a tag if that check fails.

#### Scenario: Dirty pins on target tree block rollback

- **WHEN** the target tag’s tree has a pre-release image pin under `environments/draven/values/`
- **THEN** the rollback workflow fails without creating a tag or Release

### Requirement: Shared concurrency for SemVer tag producers

The forward release workflow and the rollback workflow MUST share a single concurrency group so that only one of them
creates or pushes an infra SemVer tag at a time, and MUST NOT cancel an in-progress run of the other
(`cancel-in-progress: false`).

#### Scenario: Overlapping dispatch waits

- **WHEN** a forward release run is in progress and a rollback run is dispatched
- **THEN** the rollback run waits for the shared concurrency group rather than racing tag creation

### Requirement: Operator documentation for SemVer and release cadence

The repository README (or linked ops docs) MUST document: (1) Leitplanken for choosing major vs minor vs patch for infra
tags on the **forward** release workflow; (2) that infra tags are cut via the forward release workflow after a draven
promote lands on `main`; (3) that Soft fizz attestation is required on forward release and honor-system; (4) that tags
SHOULD be created only via the forward **or** SemVer release rollback workflows (Ruleset enforcement MAY be deferred);
(5) that SemVer release rollback defaults to the previous plain SemVer tag (optional override), always patch-bumps, tags
the target tag’s SHA, and does not use Soft fizz attestation; (6) when to use emergency pin vs SemVer release rollback.

#### Scenario: Operator finds bump guidance

- **WHEN** an operator opens the documented GitOps / release section before cutting a release
- **THEN** they can determine typical bump choice for an image-only promote vs breaking ops change and the Soft checkbox
  expectation

#### Scenario: Operator finds rollback entry point

- **WHEN** an operator needs to undo a bad infra SemVer tag without Argo UI
- **THEN** docs name the rollback workflow, previous-vs-override behavior, and contrast with emergency pin
