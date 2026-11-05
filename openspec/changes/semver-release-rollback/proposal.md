## Why

Draven follows the highest infra SemVer tag (`targetRevision: '*'`). After a bad tag, operators without Argo UI need a lasting rollback that does not require emergency pin. Forward release (#42) already cuts tags; rollback was split to #57 so the MVP stayed thin.

## What Changes

- Add a dedicated **SemVer release rollback** GitHub Actions workflow (separate from forward `release`).
- Default target = **previous** plain SemVer tag (second-highest); optional override tag.
- Cut a **new higher** SemVer tag (**always patch**) pointing at the **SHA of the target tag** (same tree); GitHub Release notes state rollback clearly.
- Shared concurrency with forward release; update README / emergency-pin docs: tags only via forward **or** rollback workflows; no R1/R2 letter codes.
- Safety: acknowledge checkbox; hard-fail if target equals current highest SemVer; draven pin gate on the restored tree.

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `infra-semver-release`: Add SemVer release rollback workflow requirements (separate dispatch, previous+override, patch-only, tag-at-old-SHA, shared concurrency, docs). Operator docs MUST name both allowed tag workflows.

## Impact

- New workflow file (e.g. `.github/workflows/release-rollback.yml`); likely shared helper with `release.yml` for tag/Release creation.
- Concurrency group rename/share on existing `release.yml`.
- README + `docs/ops/emergency-pin.md` wording (emergency-pin capability not yet on main specs; doc edit only).
- Closes / implements [#57](https://github.com/fairagro/m4.2_infrastructure/issues/57); part of epic #40.
