#!/usr/bin/env bash
# Build middleware images from deps/ submodules and load them into kind.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cluster_name="${KIND_CLUSTER_NAME:-fairagro-local}"
image_tag="${LOCAL_IMAGE_TAG:-local}"
# Must be PEP 440 (hatch-vcs / packaging); hyphen local versions are invalid.
app_version="${APP_VERSION:-0.0.0+local}"

api_dir="${repo_root}/deps/m4.2_advanced_middleware_api"
harvester_dir="${repo_root}/deps/m4.2_middleware_harvester"
sql_dir="${repo_root}/deps/m4.2_sql_to_arc"

# API chart uses repository:tag (no registry prefix).
api_image="fairagro-advanced-middleware-api:${image_tag}"
# Harvester chart templates as registry/repository:tag (default registry docker.io).
harvester_image="docker.io/fairagro-advanced-middleware-harvester:${image_tag}"
sql_image="fairagro-sql-to-arc:${image_tag}"

fail() { echo "ERROR: $*" >&2; exit 1; }

for dir in "$api_dir" "$harvester_dir" "$sql_dir"; do
  if [ ! -f "$dir/pyproject.toml" ] && [ ! -d "$dir/.git" ]; then
    fail "Missing submodule at $dir — run ./scripts/init-submodules.sh first."
  fi
done

if ! kind get clusters 2>/dev/null | grep -qx "$cluster_name"; then
  fail "kind cluster '$cluster_name' not found. Run ./scripts/local-dev-up.sh first."
fi

echo "Building $api_image ..."
docker build \
  --build-arg "APP_VERSION=${app_version}" \
  -f "${api_dir}/docker/Dockerfile.api" \
  -t "$api_image" \
  "$api_dir"

echo "Building $harvester_image ..."
docker build \
  --build-arg "APP_VERSION=${app_version}" \
  -f "${harvester_dir}/docker/Dockerfile.harvester" \
  -t "$harvester_image" \
  "$harvester_dir"

echo "Building $sql_image ..."
docker build \
  --build-arg "APP_VERSION=${app_version}" \
  -f "${sql_dir}/docker/Dockerfile.sql_to_arc" \
  -t "$sql_image" \
  "$sql_dir"

echo "Loading images into kind cluster '$cluster_name' ..."
kind load docker-image "$api_image" "$harvester_image" "$sql_image" --name "$cluster_name"

echo
echo "Images loaded:"
echo "  $api_image"
echo "  $harvester_image"
echo "  $sql_image"
echo "Next: ./scripts/local-dev-deploy.sh"
