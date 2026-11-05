#!/usr/bin/env bash
# Resolve the target tag for a SemVer release rollback (#57).
# Usage: resolve_infra_semver_rollback_target.sh [override_tag]
#   override empty → second-highest plain SemVer (previous)
# Prints to stdout (for GITHUB_OUTPUT / eval):
#   target=<tag>
#   target_sha=<sha>
#   highest=<tag>
# Exits non-zero on failure.
set -euo pipefail

override="${1:-}"

mapfile -t tags < <(
  git tag -l --sort=-v:refname \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    || true
)

if [[ ${#tags[@]} -eq 0 || -z "${tags[0]:-}" ]]; then
  echo "No plain SemVer tags found; cannot roll back." >&2
  exit 1
fi

highest="${tags[0]}"

if [[ -z "${override}" ]]; then
  if [[ ${#tags[@]} -lt 2 ]]; then
    echo "Need at least two plain SemVer tags to resolve previous (highest=${highest})." >&2
    exit 1
  fi
  target="${tags[1]}"
else
  if [[ ! "${override}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Override must be plain SemVer X.Y.Z (got: ${override})." >&2
    exit 1
  fi
  if ! git rev-parse -q --verify "refs/tags/${override}" >/dev/null; then
    echo "Override tag ${override} does not exist." >&2
    exit 1
  fi
  target="${override}"
fi

if [[ "${target}" == "${highest}" ]]; then
  echo "Target ${target} is already the highest SemVer tag; refusing noop rollback." >&2
  exit 1
fi

target_sha="$(git rev-list -n1 "${target}")"
if [[ -z "${target_sha}" ]]; then
  echo "Could not resolve SHA for tag ${target}." >&2
  exit 1
fi

echo "target=${target}"
echo "target_sha=${target_sha}"
echo "highest=${highest}"
