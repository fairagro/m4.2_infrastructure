#!/usr/bin/env bash
# One-shot GitOps bootstrap: create/upsert the Root Application that syncs
# environments/<env>/argocd/ from main (Path A). The wrapper Application YAML
# in that directory is then adopted/updated by Argo — this script no longer
# creates the umbrella wrapper directly.
#
# Usage: ./scripts/setup_project_in_argocd.sh <environment>
#   environment: fizz | elise | draven
#
# Requires: argocd CLI, sops, GPG access to environments/<env>/secrets/argocd.enc.env
# Idempotent: safe to re-run (upsert Root + project).
set -euo pipefail

ENV="${1:-}"
if [[ -z "$ENV" ]]; then
  echo "Usage: $0 <environment>" >&2
  echo "  environment: fizz | elise | draven" >&2
  echo "  local_dev is helm/kind-only and does not use this script." >&2
  exit 1
fi

case "$ENV" in
  fizz|elise|draven) ;;
  local_dev)
    echo "local_dev remains helm/kind-only — no Argo Root required." >&2
    exit 1
    ;;
  *)
    echo "Unknown environment: $ENV (expected fizz, elise, or draven)" >&2
    exit 1
    ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRET_FILE="$ROOT/environments/$ENV/secrets/argocd.enc.env"
ARGOCD_DIR="$ROOT/environments/$ENV/argocd"

if [[ ! -f "$SECRET_FILE" ]]; then
  echo "Missing SOPS secrets file: $SECRET_FILE" >&2
  exit 1
fi
if [[ ! -d "$ARGOCD_DIR" ]]; then
  echo "Missing argocd manifests directory: $ARGOCD_DIR" >&2
  exit 1
fi

# shellcheck disable=SC1090
source <(sops -d "$SECRET_FILE")

: "${ARGOCD_SERVER:?ARGOCD_SERVER missing from decrypted secrets}"
: "${ARGOCD_USERNAME:?ARGOCD_USERNAME missing from decrypted secrets}"
: "${ARGOCD_PASSWORD:?ARGOCD_PASSWORD missing from decrypted secrets}"

export ARGOCD_SERVER
argocd login "$ARGOCD_SERVER" --username "$ARGOCD_USERNAME" --password "$ARGOCD_PASSWORD" --grpc-web

# Ensure AppProject exists (same as previous bootstrap).
argocd proj create fairagro-m42 \
  --description "FAIRagro m4.2 applications" \
  --src https://github.com/fairagro/m4.2_infrastructure.git \
  --dest https://kubernetes.default.svc,\* \
  --upsert || true

# Root Application: always tracks main → environments/<env>/argocd/
# Upsert adopts an existing Root or creates a new one. After sync, Argo applies
# the wrapper Application (fairagro-m42-applications) from git — replacing the
# old script-created wrapper of the same name/namespace when present.
ROOT_APP=fairagro-m42-root
argocd app create "$ROOT_APP" \
  --project fairagro-m42 \
  --repo https://github.com/fairagro/m4.2_infrastructure.git \
  --path "environments/${ENV}/argocd" \
  --revision main \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace fairagro-m42-applications \
  --sync-option CreateNamespace=true \
  --sync-option Prune=true \
  --upsert

argocd app set "$ROOT_APP" --sync-policy automated --auto-prune --self-heal

echo
echo "Root Application '$ROOT_APP' upserted for env=$ENV (path=environments/${ENV}/argocd, revision=main)."
echo "Next: argocd app sync $ROOT_APP   # then confirm wrapper fairagro-m42-applications"
echo "  fizz/elise → wrapper targetRevision=main"
echo "  draven     → wrapper targetRevision='*'"
echo "Migration: if a live wrapper was created by the old script, Root sync adopts"
echo "  the same name/namespace from git (no manual delete required in normal cases)."
