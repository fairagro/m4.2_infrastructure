#!/usr/bin/env bash
# Create a one-off harvester Job from the CronJob, safe under Argo CD automated prune.
#
# Plain `kubectl create job --from=cronjob/...` copies app.kubernetes.io/instance (and
# related) labels, so Argo treats the Job as managed and prunes it. This script:
#   - picks the next free name test01, test02, … (zero-padded)
#   - strips Argo/Helm instance tracking labels from Job + Pod template
#   - sets argocd.argoproj.io/sync-options=Prune=false (+ IgnoreExtraneous)
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
      sed -n '2,18p' "$0" | sed 's/^# \?//'
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
  del(.metadata.labels."app.kubernetes.io/instance")
  | del(.metadata.labels."app.kubernetes.io/managed-by")
  | del(.metadata.annotations."argocd.argoproj.io/tracking-id")
  | del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")
  | del(.spec.template.metadata.labels."app.kubernetes.io/instance")
  | del(.spec.template.metadata.labels."app.kubernetes.io/managed-by")
  | del(.spec.template.metadata.annotations."argocd.argoproj.io/tracking-id")
  | .metadata.annotations."argocd.argoproj.io/sync-options" = "Prune=false"
  | .metadata.annotations."argocd.argoproj.io/compare-options" = "IgnoreExtraneous"
' \
| kubectl apply -f -

echo "Created job/${JOB_NAME}"
echo "Follow: kubectl -n ${NAMESPACE} logs -f job/${JOB_NAME}"
