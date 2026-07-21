#!/usr/bin/env bash
# Deploy advanced middleware API + harvester to the local kind cluster via Helm.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cluster_name="${KIND_CLUSTER_NAME:-fairagro-local}"
env_values="${repo_root}/environments/local_dev/values"

api_chart="${repo_root}/helmcharts/fairagro-advanced-middleware"
harvester_chart="${repo_root}/helmcharts/fairagro-advanced-middleware-harvester"

api_ns="fairagro-advanced-middleware"
harvester_ns="fairagro-advanced-middleware-harvester"

fail() { echo "ERROR: $*" >&2; exit 1; }

if ! kind get clusters 2>/dev/null | grep -qx "$cluster_name"; then
  fail "kind cluster '$cluster_name' not found. Run ./scripts/local-dev-up.sh first."
fi

kubectl config use-context "kind-${cluster_name}" >/dev/null

echo "Ensuring namespaces ..."
kubectl create namespace "$api_ns" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$harvester_ns" --dry-run=client -o yaml | kubectl apply -f -

echo "Updating Helm chart dependencies ..."
helm dependency update "$api_chart"
helm dependency update "$harvester_chart"

echo "Deploying fairagro-advanced-middleware ..."
helm upgrade --install fairagro-advanced-middleware "$api_chart" \
  --namespace "$api_ns" \
  --create-namespace \
  -f "${env_values}/fairagro-advanced-middleware.yaml" \
  --wait \
  --timeout 10m

echo "Deploying fairagro-advanced-middleware-harvester ..."
helm upgrade --install fairagro-advanced-middleware-harvester "$harvester_chart" \
  --namespace "$harvester_ns" \
  --create-namespace \
  -f "${env_values}/fairagro-advanced-middleware-harvester.yaml" \
  --wait \
  --timeout 5m

echo
echo "Deployed."
echo "  API ingress host: http://middleware.localtest.me:8080  (kind port-map 8080→80)"
echo "  Trigger harvester: kubectl -n ${harvester_ns} create job --from=cronjob/\$(kubectl -n ${harvester_ns} get cronjob -o jsonpath='{.items[0].metadata.name}') harvest-\$(date +%s)"
echo
echo "Note: sql_to_arc image is built/loaded but not deployed (no umbrella chart in this repo yet)."
