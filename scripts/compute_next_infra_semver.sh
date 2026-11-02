#!/usr/bin/env bash
# Compute the next infra SemVer tag for this repo (Argo draven targetRevision: '*').
# Usage: compute_next_infra_semver.sh <major|minor|patch>
# Prints the next version to stdout. Ignores non X.Y.Z tags.
# First tag (no SemVer tags yet): patch|minor → 0.1.0; major → 1.0.0
set -euo pipefail

bump="${1:-}"
if [[ ! "$bump" =~ ^(major|minor|patch)$ ]]; then
  echo "Usage: $0 <major|minor|patch>" >&2
  exit 2
fi

# Highest existing plain SemVer tag (no leading v, no pre-release suffix).
mapfile -t tags < <(
  git tag -l --sort=-v:refname \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    || true
)

if [[ ${#tags[@]} -eq 0 || -z "${tags[0]:-}" ]]; then
  case "$bump" in
    major) echo "1.0.0" ;;
    minor|patch) echo "0.1.0" ;;
  esac
  exit 0
fi

highest="${tags[0]}"
IFS=. read -r major minor patch <<<"$highest"

case "$bump" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
esac

echo "${major}.${minor}.${patch}"
