#!/usr/bin/env bash
# Fail if environments/draven/values/ plaintext overlays pin pre-release images.
# fizz/elise may pin pre-releases; this gate is draven-only (see README / #40 / #42).
#
# Usage: ./scripts/check_draven_release_pins.sh
# Exit 0 if clean; non-zero listing offending tag: lines.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALUES_DIR="$ROOT/environments/draven/values"

if [[ ! -d "$VALUES_DIR" ]]; then
  echo "Missing directory: $VALUES_DIR" >&2
  exit 1
fi

# Collect tag: values from non-encrypted YAML (image pins live in plaintext overlays).
mapfile -t tag_lines < <(
  grep -RIn --include='*.yaml' --exclude='*.enc.yaml' -E '^[[:space:]]*tag:[[:space:]]*' "$VALUES_DIR" || true
)

if [[ ${#tag_lines[@]} -eq 0 ]]; then
  echo "No tag: keys found under $VALUES_DIR (nothing to check)."
  exit 0
fi

is_prerelease_tag() {
  local tag="$1"
  # Strip optional quotes.
  tag="${tag%\"}"
  tag="${tag#\"}"
  tag="${tag%\'}"
  tag="${tag#\'}"

  case "$tag" in
    ""|latest|main|master|HEAD|head)
      return 0
      ;;
  esac

  # Explicit RC / pre / alpha / beta markers (case-insensitive).
  if echo "$tag" | grep -qiE '(-rc|[[:punct:]]rc[[:punct:]]|^rc\.|-pre|-alpha|-beta)'; then
    return 0
  fi

  # SemVer with pre-release suffix: MAJOR.MINOR.PATCH-PRERELEASE...
  if echo "$tag" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+-.+'; then
    return 0
  fi

  return 1
}

offenders=()
for line in "${tag_lines[@]}"; do
  # path:lineno:  tag: value
  file="${line%%:*}"
  rest="${line#*:}"
  lineno="${rest%%:*}"
  raw="${rest#*:}"
  value="$(echo "$raw" | sed -E 's/^[[:space:]]*tag:[[:space:]]*//;s/[[:space:]]+#.*//;s/[[:space:]]*$//')"

  if is_prerelease_tag "$value"; then
    offenders+=("$file:$lineno: tag: $value")
  fi
done

if [[ ${#offenders[@]} -gt 0 ]]; then
  echo "ERROR: pre-release or non-release image pins under environments/draven/values/:" >&2
  printf '  %s\n' "${offenders[@]}" >&2
  echo "Draven may only pin product releases. Use a fizz/elise trial PR for pre-releases;" >&2
  echo "promote to draven only after the prod release exists (#40 / #42)." >&2
  exit 1
fi

echo "OK: no pre-release image pins under environments/draven/values/ (${#tag_lines[@]} tag: line(s) checked)."
