(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
  echo "ERROR, this script is meant to be sourced."
  exit 1
fi

# Load Environment Script
# Sets up aliases, completions, and Docker config for the devcontainer.

mydir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# DevPod credsStore is host-only; DinD needs a container-local Docker config.
# shellcheck source=/dev/null
source "${mydir}/setup-container-docker.sh"

# Setup aliases (completions: static files in image + bash-completion lazy-load)
alias k=kubectl
alias d=docker
alias kda="kubectl delete all,pdb,configmap,secret,pvc,ingress,serviceaccount,endpoints --all"
alias kga="kubectl get all,pdb,configmap,secret,pvc,ingress,serviceaccount,endpoints"
alias ksn="kubectl config set-context --current --namespace"

# Set bash completion for aliases
declare -F __start_kubectl &>/dev/null && complete -o default -F __start_kubectl k
declare -F __start_docker &>/dev/null && complete -o default -F __start_docker d

# Helm secrets integration
export HELM_SECRETS_SOPS_PATH=$(which sops)
export HELM_SECRETS_HELM_PATH=$(which helm)
