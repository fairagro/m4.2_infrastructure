#!/usr/bin/env bash
# Create (or reuse) the local kind cluster and install ingress-nginx.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cluster_name="${KIND_CLUSTER_NAME:-fairagro-local}"
kind_config="${repo_root}/environments/local_dev/kind-config.yaml"
ingress_manifest="${INGRESS_NGINX_MANIFEST:-https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml}"

if ! command -v kind >/dev/null 2>&1; then
  echo "ERROR: kind is not installed. Rebuild the Dev Container (Dockerfile installs kind)." >&2
  exit 1
fi
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not available (DinD required)." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "ERROR: cannot talk to the Docker daemon. Is DinD running?" >&2
  exit 1
fi

if kind get clusters 2>/dev/null | grep -qx "$cluster_name"; then
  echo "kind cluster '$cluster_name' already exists."
else
  echo "Creating kind cluster '$cluster_name' ..."
  kind create cluster --config "$kind_config"
fi

echo "Setting kubectl context to kind-${cluster_name} ..."
kubectl cluster-info --context "kind-${cluster_name}" >/dev/null

if kubectl get ns ingress-nginx >/dev/null 2>&1; then
  echo "ingress-nginx namespace already present."
else
  echo "Installing ingress-nginx for kind ..."
  kubectl apply -f "$ingress_manifest"
fi

echo "Waiting for ingress-nginx controller ..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo
echo "Local kind cluster is ready."
echo "  source ${repo_root}/scripts/set_context.sh local_dev"
echo "  ${repo_root}/scripts/local-dev-build.sh"
echo "  ${repo_root}/scripts/local-dev-deploy.sh"
