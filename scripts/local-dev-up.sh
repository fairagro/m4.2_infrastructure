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

# Always target kind explicitly. The Dev Container bashrc sources set_context.sh fizz,
# which sets KUBECONFIG to a remote cluster — do not rely on the ambient context.
kubeconfig="$(mktemp)"
trap 'rm -f "$kubeconfig"' EXIT
kind get kubeconfig --name "$cluster_name" > "$kubeconfig"
export KUBECONFIG="$kubeconfig"

echo "Using kind cluster '$cluster_name' (KUBECONFIG=$KUBECONFIG)."
kubectl cluster-info >/dev/null

if kubectl get ns ingress-nginx >/dev/null 2>&1; then
  echo "ingress-nginx namespace already present."
else
  echo "Installing ingress-nginx for kind ..."
  kubectl apply -f "$ingress_manifest"
fi

echo "Waiting for ingress-nginx controller ..."
# rollout status waits for the Deployment to create pods; kubectl wait --selector
# fails immediately with "no matching resources found" if the pod is not listed yet.
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s

# Zalando Postgres Operator (required by fairagro-advanced-middleware-sql-to-arc)
if kubectl get crd postgresqls.acid.zalan.do >/dev/null 2>&1 \
  && kubectl get deploy -A -l app.kubernetes.io/name=postgres-operator -o name 2>/dev/null | grep -q .; then
  echo "postgres-operator already present."
else
  echo "Installing Zalando postgres-operator (Helm) ..."
  helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator >/dev/null
  helm repo update postgres-operator-charts >/dev/null
  # Allow teamId "fairagro" used by DataHUB / sql-to-arc CRs
  helm upgrade --install postgres-operator postgres-operator-charts/postgres-operator \
    --namespace postgres-operator \
    --create-namespace \
    --set configGeneral.team_api_url="" \
    --set configKubernetes.watched_namespace="*" \
    --wait \
    --timeout 5m
  echo "Waiting for postgres-operator CRD ..."
  kubectl wait --for=condition=Established crd/postgresqls.acid.zalan.do --timeout=120s
fi

echo
echo "Local kind cluster is ready."
echo "  source ${repo_root}/scripts/set_context.sh local_dev"
echo "  ${repo_root}/scripts/local-dev-build.sh"
echo "  ${repo_root}/scripts/local-dev-deploy.sh"
