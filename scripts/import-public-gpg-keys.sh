#!/usr/bin/env bash
# Import public GPG keys from all environments (for SOPS encrypt / key-id checks).

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
environments_path="${repo_root}/environments"

shopt -s nullglob
for public_key_path in "${environments_path}"/*/public_gpg_keys; do
    keys=( "${public_key_path}"/*.asc )
    if [ ${#keys[@]} -eq 0 ]; then
        continue
    fi
    for file in "${keys[@]}"; do
        gpg --batch --import "$file"
    done
done
