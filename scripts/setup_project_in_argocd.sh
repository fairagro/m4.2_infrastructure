#!/usr/bin/env bash
# One-shot GitOps bootstrap: upsert the wrapper Application from the checked-in
# manifest at environments/<env>/argocd/fairagro-m42-applications.yaml (Path A).
# No Root Application — the wrapper YAML changes rarely; re-run this script (or
# kubectl/argocd apply -f) when it does. Pins for workloads live in
# environments/<env>/values/ (child *_revision and image tags).
#
# Usage: ./scripts/setup_project_in_argocd.sh <environment>
#   environment: fizz | elise | draven
#
# Requires: argocd CLI, sops, GPG/age access to
#   environments/<env>/credentials/argocd_secrets.enc.yaml
# Idempotent: safe to re-run (upsert project + wrapper).
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
    echo "local_dev remains helm/kind-only — no Argo bootstrap required." >&2
    exit 1
    ;;
  *)
    echo "Unknown environment: $ENV (expected fizz, elise, or draven)" >&2
    exit 1
    ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRET_FILE="$ROOT/environments/$ENV/credentials/argocd_secrets.enc.yaml"
WRAPPER_MANIFEST="$ROOT/environments/$ENV/argocd/fairagro-m42-applications.yaml"

if [[ ! -f "$SECRET_FILE" ]]; then
  echo "Missing SOPS secrets file: $SECRET_FILE" >&2
  exit 1
fi
if [[ ! -f "$WRAPPER_MANIFEST" ]]; then
  echo "Missing wrapper Application manifest: $WRAPPER_MANIFEST" >&2
  exit 1
fi

# Login session persists for subsequent argocd commands.
sops exec-env "$SECRET_FILE" \
  'argocd login "$ARGOCD_SERVER" --insecure --grpc-web-root-path "$ARGOCD_PREFIX" --username="$ARGOCD_ADMIN_USER" --password="$ARGOCD_ADMIN_PASSWORD"'

argocd proj create fairagro-m42 \
  --description "FAIRagro m4.2 applications" \
  --src https://github.com/fairagro/m4.2_infrastructure.git \
  --dest https://kubernetes.default.svc,\* \
  --upsert || true

# Apply checked-in wrapper (App-of-Apps → child Applications from umbrella chart).
argocd app create --upsert -f "$WRAPPER_MANIFEST"

echo
echo "Wrapper Application upserted from $WRAPPER_MANIFEST (env=$ENV)."
echo "Next: argocd app sync fairagro-m42-applications"
echo "  fizz/elise → targetRevision=main (auto-sync in manifest)"
echo "  draven     → targetRevision='*'"
echo "Migration: if 'fairagro-m42-application-wrapper' or 'fairagro-m42-root' still"
echo "  exist, delete them after the new wrapper is healthy — they are obsolete."
