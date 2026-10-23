#!/usr/bin/env bash
# One-shot GitOps bootstrap: create/upsert the Root Application that syncs
# environments/<env>/argocd/ from main (Path A). The wrapper Application YAML
# in that directory is then adopted/updated by Argo — this script no longer
# creates the umbrella wrapper directly.
#
# Usage: ./scripts/setup_project_in_argocd.sh <environment>
#   environment: fizz | elise | draven
#
# Requires: argocd CLI, sops, GPG/age access to
#   environments/<env>/credentials/argocd_secrets.enc.yaml
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
SECRET_FILE="$ROOT/environments/$ENV/credentials/argocd_secrets.enc.yaml"
ARGOCD_DIR="$ROOT/environments/$ENV/argocd"

if [[ ! -f "$SECRET_FILE" ]]; then
  echo "Missing SOPS secrets file: $SECRET_FILE" >&2
  exit 1
fi
if [[ ! -d "$ARGOCD_DIR" ]]; then
  echo "Missing argocd manifests directory: $ARGOCD_DIR" >&2
  exit 1
fi

# Login session persists for subsequent argocd commands (same as previous script).
sops exec-env "$SECRET_FILE" \
  'argocd login "$ARGOCD_SERVER" --insecure --grpc-web-root-path "$ARGOCD_PREFIX" --username="$ARGOCD_ADMIN_USER" --password="$ARGOCD_ADMIN_PASSWORD"'

# Ensure AppProject exists (same destination/source scope as live clusters).
argocd proj create fairagro-m42 \
  --description "FAIRagro m4.2 applications" \
  --src https://github.com/fairagro/m4.2_infrastructure.git \
  --dest https://kubernetes.default.svc,\* \
  --upsert || true

# Root Application: always tracks main → environments/<env>/argocd/
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
echo "Migration: old script created 'fairagro-m42-application-wrapper'; git wrapper is"
echo "  'fairagro-m42-applications'. After Root sync, delete the old wrapper if both exist."
