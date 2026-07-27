#!/usr/bin/env bash
# Initialise / update software git submodules under deps/.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ ! -f .gitmodules ]; then
  echo "ERROR: .gitmodules not found in $repo_root" >&2
  exit 1
fi

# sql_to_arc uses Git LFS; skip smudge so checkout works without fetching LFS blobs.
export GIT_LFS_SKIP_SMUDGE="${GIT_LFS_SKIP_SMUDGE:-1}"

echo "Updating git submodules under deps/ ..."
git submodule sync --recursive
git submodule update --init --recursive

echo "Submodule status:"
git submodule status
