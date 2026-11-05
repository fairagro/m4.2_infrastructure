#!/usr/bin/env bash
# Parse checked-in Argo Application wrapper YAML (no cluster CRDs required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mapfile -t files < <(find "$ROOT/environments" -path '*/argocd/*.yaml' | sort)
if [[ "${#files[@]}" -eq 0 ]]; then
  echo "No environments/*/argocd/*.yaml found" >&2
  exit 1
fi

for f in "${files[@]}"; do
  echo "==> parse $f"
  yq -e '.' "$f" >/dev/null
done

echo "OK: Argo YAML under environments/*/argocd/ parsed (${#files[@]} file(s))."
