#!/usr/bin/env bash
# Create a one-off harvester Job from the CronJob, safe under Argo CD automated prune
# and still visible in the Argo CD UI under the harvester Application.
#
# Plain `kubectl create job --from=cronjob/...` is pruned because the Job is tracked
# but not in Git desired state. This script:
#   - picks the next free name test01, test02, … (zero-padded)
#   - keeps instance/tracking labels so Argo shows the Job in the app resource tree
#   - sets argocd.argoproj.io/sync-options=Prune=false (do not delete)
#   - sets compare-options=IgnoreExtraneous (app stays Synced; Job still listed)
#
# Usage:
#   ./scripts/create_harvester_test_job.sh
#   ./scripts/create_harvester_test_job.sh -n fairagro-advanced-middleware-harvester
#   PREFIX=manual ./scripts/create_harvester_test_job.sh
#
# Requires: kubectl context pointed at the target cluster (e.g. source scripts/set_context.sh fizz)
set -euo pipefail

NAMESPACE="${NAMESPACE:-fairagro-advanced-middleware-harvester}"
CRONJOB="${CRONJOB:-fairagro-advanced-middleware-harvester}"
PREFIX="${PREFIX:-test}"
PAD="${PAD:-2}"

while getopts "n:c:p:h" opt; do
  case "$opt" in
    n) NAMESPACE="$OPTARG" ;;
    c) CRONJOB="$OPTARG" ;;
    p) PREFIX="$OPTARG" ;;
    h)
      sed -n '2,20p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Usage: $0 [-n namespace] [-c cronjob] [-p name-prefix]" >&2
      exit 2
      ;;
  esac
done

if ! kubectl get "cronjob/${CRONJOB}" -n "${NAMESPACE}" >/dev/null 2>&1; then
  echo "ERROR: CronJob '${CRONJOB}' not found in namespace '${NAMESPACE}'." >&2
  echo "Check kubectl context (e.g. source ./scripts/set_context.sh fizz)." >&2
  exit 1
fi

# Highest existing PREFIX + digits job name → next number (test01, test02, …).
max=0
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  suffix="${name#"${PREFIX}"}"
  if [[ "$suffix" =~ ^[0-9]+$ ]]; then
    # 10# avoids octal interpretation of leading zeros
    num=$((10#$suffix))
    if (( num > max )); then
      max=$num
    fi
  fi
done < <(kubectl get jobs -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true)

next=$((max + 1))
JOB_NAME=$(printf "%s%0${PAD}d" "${PREFIX}" "${next}")

# Collision guard if PAD overflows (e.g. test99 exists and PAD=2 → test100 ok with printf)
while kubectl get "job/${JOB_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; do
  next=$((next + 1))
  JOB_NAME=$(printf "%s%0${PAD}d" "${PREFIX}" "${next}")
done

echo "Creating Job '${JOB_NAME}' from CronJob '${CRONJOB}' in namespace '${NAMESPACE}'..."

kubectl create job "${JOB_NAME}" \
  --from="cronjob/${CRONJOB}" \
  -n "${NAMESPACE}" \
  --dry-run=client -o yaml \
| yq '
  del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")
  | .metadata.annotations."argocd.argoproj.io/sync-options" = "Prune=false"
  | .metadata.annotations."argocd.argoproj.io/compare-options" = "IgnoreExtraneous"
' \
| kubectl apply -f -

echo "Created job/${JOB_NAME}"
echo "Visible in Argo under Application fairagro-advanced-middleware-harvester (not pruned)."
echo "Follow: kubectl -n ${NAMESPACE} logs -f job/${JOB_NAME}"
