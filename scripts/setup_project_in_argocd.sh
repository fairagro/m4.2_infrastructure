#!/usr/bin/env bash

environment=$1

# figure out some paths
mydir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
environment_path="$mydir/../environments/$environment"

# Login to argocd
sops exec-env "${environment_path}/credentials/argocd_secrets.enc.yaml" 'argocd login $ARGOCD_SERVER --insecure --grpc-web-root-path $ARGOCD_PREFIX --username=$ARGOCD_ADMIN_USER --password=$ARGOCD_ADMIN_PASSWORD'

echo "Installing FAIRagro applications app on ${environment}..."
argocd app create fairagro-m42-application-wrapper \
    --upsert \
    --repo "git@github.com:fairagro/m42_infrastructure.git" \
    --revision HAED \
    --path "helmcharts/fairagro-applications" \
    --dest-server "https://kubernetes.default.svc" \
    --project fairagro \
    --dest-namespace fairagro-m42-applications \
    --values "../../environments/${environment}/values/fairagro-m42-applications.yaml" \
    --sync-option CreateNamespace=true \
    --sync-option Prune=true
