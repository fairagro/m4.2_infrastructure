#!/usr/bin/env bash

environment=$1
revision=${2:-HEAD}

if [ -z "$environment" ]; then
  echo "Usage: $0 <environment> [git-revision]" >&2
  exit 1
fi

# figure out some paths
mydir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
environment_path="$mydir/../environments/$environment"
repo_root="$(cd "$mydir/.." && pwd)"

if [ ! -f "${environment_path}/values/fairagro-m42-applications.yaml" ]; then
  echo "ERROR: ${environment_path}/values/fairagro-m42-applications.yaml does not exist." >&2
  exit 1
fi

if [ "$revision" = "HEAD" ]; then
  if ! git -C "$repo_root" show "main:environments/${environment}/values/fairagro-m42-applications.yaml" &>/dev/null; then
    current_branch=$(git -C "$repo_root" branch --show-current 2>/dev/null)
    echo "ERROR: environments/${environment} is not on main (ArgoCD revision HEAD tracks main)." >&2
    if [ -n "$current_branch" ] \
      && git -C "$repo_root" show "${current_branch}:environments/${environment}/values/fairagro-m42-applications.yaml" &>/dev/null; then
      echo "Push branch ${current_branch} and run:" >&2
      echo "  $0 ${environment} ${current_branch}" >&2
      echo "Also set *_revision in environments/${environment}/values/fairagro-m42-applications.yaml to that branch." >&2
    fi
    exit 1
  fi
elif ! git -C "$repo_root" show "${revision}:environments/${environment}/values/fairagro-m42-applications.yaml" &>/dev/null; then
  echo "ERROR: environments/${environment} not found at git revision ${revision}." >&2
  exit 1
fi

# Login to argocd
sops exec-env "${environment_path}/credentials/argocd_secrets.enc.yaml" 'argocd login $ARGOCD_SERVER --insecure --grpc-web-root-path $ARGOCD_PREFIX --username=$ARGOCD_ADMIN_USER --password=$ARGOCD_ADMIN_PASSWORD'

echo "Installing FAIRagro applications app on ${environment} (revision ${revision})..."
argocd app create fairagro-m42-application-wrapper \
    --upsert \
    --repo "https://github.com/fairagro/m4.2_infrastructure.git" \
    --revision "${revision}" \
    --path "helmcharts/fairagro-m42-applications" \
    --dest-server "https://kubernetes.default.svc" \
    --project fairagro-m42 \
    --dest-namespace fairagro-m42-applications \
    --values "../../environments/${environment}/values/fairagro-m42-applications.yaml" \
    --sync-option CreateNamespace=true \
    --sync-option Prune=true
