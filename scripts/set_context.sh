(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  echo "ERROR, this script is meant to be sourced."
  exit 1
fi

fail() {
  echo "$1" >&2
  if [ $sourced -eq 1 ]; then
    return 1
  fi
  exit 1
}

environment=$1
age_secret_key=$2

restore_sops_vars() {
    export SOPS_AGE_KEY=$SOPS_AGE_KEY_BACKUP
    unset SOPS_AGE_KEY_BACKUP
}

if test -z ${age_secret_key}
then
    echo "Age secret key for secret decryption is not set. Assuming a private gpg key is available."
else
    echo "Preparing specified age secret key ..."
    export SOPS_AGE_KEY_BACKUP=$SOPS_AGE_KEY
    export SOPS_AGE_KEY=$age_secret_key

    # Ensure we reset the original environment variables after script exits...
    trap 'restore_sops_vars' RETURN
fi

# figure out some paths
mydir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
environment_path="$mydir/../environments/$environment"

# Check that the context is actually known
if [ ! -d "$environment_path" ]; then
    fail "The environment directory for environment $environment does not exist." || return
fi

if [ "$environment" = "local_dev" ]; then
    cluster_name="${KIND_CLUSTER_NAME:-fairagro-local}"
    if ! command -v kind >/dev/null 2>&1; then
        fail "kind is not installed. Rebuild the Dev Container." || return
    fi
    if ! kind get clusters 2>/dev/null | grep -qx "$cluster_name"; then
        fail "kind cluster '$cluster_name' not found. Run ./scripts/local-dev-up.sh first." || return
    fi
    kubeconfig=$(mktemp)
    if ! kind get kubeconfig --name "$cluster_name" > "$kubeconfig"; then
        rm -f "$kubeconfig"
        fail "Failed to get kind kubeconfig for cluster '$cluster_name'." || return
    fi
    export KUBECONFIG="$kubeconfig"
    kubectl config use-context "kind-${cluster_name}" >/dev/null
    echo "Using kind cluster '$cluster_name' (KUBECONFIG=$KUBECONFIG)."
else
    # set KUBECONFIG environment variable to the actual cluster config file
    kubeconfig=$(mktemp)
    if ! sops -d "${environment_path}/credentials/project_admin.enc.yaml" > "$kubeconfig"; then
        rm -f "$kubeconfig"
        fail "Failed to decrypt ${environment_path}/credentials/project_admin.enc.yaml" || return
    fi
    if ! kubectl config view --kubeconfig="$kubeconfig" --minify --raw -o jsonpath='{.users[0].user.client-key-data}' \
        | base64 -d 2>/dev/null | openssl pkey -noout 2>/dev/null; then
        rm -f "$kubeconfig"
        fail "Kubeconfig client-key-data is missing or invalid. Re-encrypt project_admin.enc.yaml with a kubeconfig that embeds client-key-data (not client-key file paths)." || return
    fi
    export KUBECONFIG="$kubeconfig"
fi

# set some environment variables for helm secrets and helmfile
export HELM_SECRETS_SOPS_PATH=$(which sops)
export HELM_SECRETS_HELM_PATH=$(which helm)

# import all public keyfiles into gpg keyring so sops can find them
public_key_path="$environment_path/public_gpg_keys"
shopt -s nullglob
for file in "$public_key_path"/*.asc; do
    gpg --import "$file"
done
shopt -u nullglob

# Create Bash autocompletion for installed tools
source /etc/bash_completion
source <(kubectl completion bash)
source <(helm completion bash)
source <(argocd completion bash)
source <(docker completion bash)
source <(cmctl completion bash)

# Setup aliases
alias k=kubectl
alias d=docker
alias kda="kubectl delete all,pdb,configmap,secret,pvc,ingress,serviceaccount,endpoints --all"
alias kga="kubectl get all,pdb,configmap,secret,pvc,ingress,serviceaccount,endpoints"
alias ksn="kubectl config set-context --current --namespace"

# Set bash completion for aliases
complete -o default -F __start_kubectl k
complete -o default -F __start_docker d

# Set default namespace
#kubectl config use-context $environment