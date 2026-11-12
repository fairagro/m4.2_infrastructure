## Context

Middleware API config `known_rdis` is the allowlist (and optional Investigation comment metadata) for RDI ids. Object
form `{id, description?, url?}` is already supported; bare strings still coerce with a deprecation warning. API #559
will reject strings. Infra #50/#51 only migrated `sradi` on fizz/draven.

Stakeholders: operators deploying the advanced middleware API; unblock API maintainers for #559.

## Goals / Non-Goals

**Goals:**

- No bare-string `known_rdis` items in fizz, draven, elise, or local_dev API values.
- Preserve `sradi` description/url.
- Id-only objects for other RDIs are enough.

**Non-Goals:**

- API #559 code change.
- Populating description/url for every RDI.
- Harvester overlays or chart changes.

## Decisions

1. **Id-only objects as the default migration shape**
   - `- edal` → `- id: edal`. Optional empty `description`/`url` omitted (API defaults to empty strings).
   - **Why:** Minimal diff; meets #559; avoids inventing catalog metadata.

2. **Keep the existing `sradi` rich object unchanged**
   - Already has description/url from #50/#51.

3. **Same membership and order per env**
   - Do not add/remove RDIs; only change entry shape. Keep list order for readable diffs.

4. **Ship all four envs in one change**
   - Values-only; no image bump required for object form (already accepted). Fizz-first review is fine, but
     elise/local_dev should not lag and reintroduce strings.

5. **Verify by YAML inspection / yq, not full cluster smoke**
   - Assert every list item is a mapping with `id`. Optional: `helm template` if convenient; secrets must not block.

## Risks / Trade-offs

- **[Risk] Missed bare string in an enc overlay or chart default** → Mitigation: search `known_rdis` under
  `environments/` and chart values; only the four middleware API value files are in scope today.
- **[Trade-off] Id-only objects give no Investigation description/url** → Acceptable; #559 does not require metadata;
  can enrich later.

## Migration Plan

1. Edit the four env value files.
2. Grep for remaining bare-string list items under `known_rdis`.
3. Merge; API #559 can proceed afterward.
4. Rollback: revert the values commit (strings still work until #559 ships).

## Open Questions

- None blocking.
