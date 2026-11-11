#!/usr/bin/env bash
# Resolve the target tag for a SemVer release rollback (#57).
# Usage: resolve_infra_semver_rollback_target.sh [override_tag]
#   override empty → previous distinct baseline: newest plain SemVer strictly older
#   than the oldest tag that shares the highest tag's SHA (skips superseded tips
#   that a prior rollback already jumped over).
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
highest_sha="$(git rev-list -n1 "${highest}")"
if [[ -z "${highest_sha}" ]]; then
  echo "Could not resolve SHA for highest tag ${highest}." >&2
  exit 1
fi

if [[ -z "${override}" ]]; then
  # Oldest tag that points at the same tree as highest (rollback aliases share SHA).
  origin="${highest}"
  for t in "${tags[@]}"; do
    sha="$(git rev-list -n1 "${t}")"
    if [[ "${sha}" == "${highest_sha}" ]]; then
      origin="${t}"
    fi
  done

  target=""
  for t in "${tags[@]}"; do
    if [[ "${t}" == "${highest}" ]]; then
      continue
    fi
    # version-sort: skip tags that are not strictly older than origin
    newer="$(printf '%s\n%s\n' "${t}" "${origin}" | sort -V | tail -n1)"
    if [[ "${newer}" != "${origin}" || "${t}" == "${origin}" ]]; then
      continue
    fi
    target="${t}"
    break
  done

  if [[ -z "${target}" ]]; then
    echo "No older distinct SemVer baseline below ${origin} (highest=${highest} sha=${highest_sha})." >&2
    echo "Empty revert_to_tag cannot roll back further; pass an explicit older X.Y.Z override." >&2
    exit 1
  fi
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
