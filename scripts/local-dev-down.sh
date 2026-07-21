#!/usr/bin/env bash
# Delete the local kind cluster (and optionally leave images in DinD).
set -euo pipefail

cluster_name="${KIND_CLUSTER_NAME:-fairagro-local}"

if ! command -v kind >/dev/null 2>&1; then
  echo "ERROR: kind is not installed." >&2
  exit 1
fi

if ! kind get clusters 2>/dev/null | grep -qx "$cluster_name"; then
  echo "kind cluster '$cluster_name' does not exist."
  exit 0
fi

echo "Deleting kind cluster '$cluster_name' ..."
kind delete cluster --name "$cluster_name"
echo "Done."
