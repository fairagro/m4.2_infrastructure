## Summary

<!-- What and why (1–3 bullets). Prefer one intent per PR. -->

## Intent

- [ ] fizz trial / image pin
- [ ] draven promote / prod values
- [ ] chart / GitOps / CI
- [ ] docs / OpenSpec
- [ ] other: <!-- … -->

## Checklist

- [ ] If fizz image pin: pre-release or release tag is intentional
- [ ] If draven values touched: prod release tags only (no `-rc`); pin check passes
- [ ] Secrets only in `*.enc.yaml` / credentials — no plaintext PEMs/passwords in the diff
- [ ] `pre-commit` / local checks run, or CI green
- [ ] Emergency ruleset bypass used? If yes: reason below

### Bypass reason (if any)

<!-- Leave empty unless bypassing required checks/reviews. -->
