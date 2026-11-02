## ADDED Requirements

### Requirement: Manual SemVer release via workflow dispatch

The repository SHALL provide a GitHub Actions workflow that creates an infra SemVer git tag and a GitHub Release only when triggered with `workflow_dispatch` on branch `main`. The workflow MUST accept a `version_bump` input whose allowed values are `major`, `minor`, and `patch`, and MUST compute the next version from the highest existing SemVer tag (or the documented first-tag rules when none exist). The workflow MUST NOT rewrite Application manifests or environment value files.

#### Scenario: Patch bump from existing tag

- **WHEN** an operator runs the release workflow on `main` with `version_bump: patch` and the highest SemVer tag is `1.2.3`
- **THEN** the workflow creates tag `1.2.4` and a corresponding GitHub Release when all gates pass

#### Scenario: Rejected off main

- **WHEN** the release workflow is triggered from a ref other than `main`
- **THEN** the workflow fails without creating a tag or Release

### Requirement: Soft fizz validation attestation

Before creating a tag, the release workflow MUST require a boolean Soft attestation input (fizz validated) to be true. The workflow MUST NOT implement image lineage checks against current or historical fizz pins, and MUST NOT query Argo CD health.

#### Scenario: Checkbox false blocks release

- **WHEN** an operator runs the release workflow with the Soft fizz attestation set to false
- **THEN** the workflow fails before creating a tag or Release

#### Scenario: Checkbox true allows gates to proceed

- **WHEN** an operator runs the release workflow on `main` with Soft fizz attestation true and other gates pass
- **THEN** the workflow may create the SemVer tag and GitHub Release

### Requirement: Draven release-pin gate before tag

The release workflow MUST run the existing draven release-pin check (`scripts/check_draven_release_pins.sh` or equivalent) against the checkout being tagged and MUST NOT create a tag if that check fails. Pre-release pins under fizz/elise MUST remain unconstrained by this gate.

#### Scenario: Pre-release pin under draven blocks tag

- **WHEN** `environments/draven/values/` contains a product image tag that the pin check classifies as pre-release
- **THEN** the release workflow fails without creating a tag or Release

#### Scenario: Clean draven pins allow tag

- **WHEN** the pin check reports no pre-release image pins under `environments/draven/values/` and other gates pass
- **THEN** the release workflow creates the SemVer tag and GitHub Release

### Requirement: Operator documentation for SemVer and release cadence

The repository README (or linked ops docs) MUST document: (1) Leitplanken for choosing major vs minor vs patch for infra tags; (2) that infra tags are cut via the release workflow after a draven promote lands on `main`; (3) that Soft fizz attestation is required and honor-system; (4) that tags SHOULD be created via the workflow (Ruleset enforcement MAY be deferred).

#### Scenario: Operator finds bump guidance

- **WHEN** an operator opens the documented GitOps / release section before cutting a release
- **THEN** they can determine typical bump choice for an image-only promote vs breaking ops change and the Soft checkbox expectation
