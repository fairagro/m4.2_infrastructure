#!/usr/bin/env bash
# Render umbrella + leaf charts for fizz and draven (PR quality gate).
# Uses ci/helm-ci-overrides.yaml instead of SOPS .enc.yaml (TLS off / stub auth).
# Leaf renders are piped to kubeconform (#75); umbrella (Argo Application CRDs) stays
# helm-template-only — Argo YAML is covered by argocd-yaml-parse.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OVERRIDES="$ROOT/ci/helm-ci-overrides.yaml"
KUBECONFORM_WRAPPER="$ROOT/scripts/run-kubeconform.sh"
# Ignore CRDs we do not ship schemas for (e.g. cert-manager Issuer, chart CRDs).
KUBECONFORM_FLAGS=(-summary -ignore-missing-schemas)
ENVS=(fizz draven)
LEAF_CHARTS=(
  fairagro-advanced-middleware
  fairagro-advanced-middleware-harvester
  fairagro-advanced-middleware-sql-to-arc
  fairagro-basic-middleware
)

render_leaf() {
  local chart_dir="$1"
  local values_file="$2"
  local label="$3"
  echo "==> helm template + kubeconform: $label"
  helm dependency build "$chart_dir" >/dev/null
  helm template "ci-${label//\//-}" "$chart_dir" \
    -f "$values_file" \
    -f "$OVERRIDES" \
    | bash "$KUBECONFORM_WRAPPER" "${KUBECONFORM_FLAGS[@]}"
}

for env in "${ENVS[@]}"; do
  apps_values="$ROOT/environments/$env/values/fairagro-m42-applications.yaml"
  if [[ -f "$apps_values" ]]; then
    echo "==> helm template: m42-applications/$env (no kubeconform; Argo Application CRDs)"
    helm template "ci-apps-$env" "$ROOT/charts/fairagro-m42-applications" \
      -f "$apps_values" \
      >/dev/null
  fi

  for chart in "${LEAF_CHARTS[@]}"; do
    values="$ROOT/environments/$env/values/${chart}.yaml"
    if [[ -f "$values" ]]; then
      render_leaf "$ROOT/charts/$chart" "$values" "${chart}/${env}"
    else
      echo "==> skip ${chart}/${env} (no values file)"
    fi
  done
done

echo "OK: helm template matrix (fizz+draven) + leaf kubeconform succeeded."
