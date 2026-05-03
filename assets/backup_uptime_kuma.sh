#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG="${KUBECONFIG:-./kubeconfig.yaml}"
NAMESPACE="${NAMESPACE:-monitoring}"
RELEASE="${RELEASE:-uptime-kuma}"
OUTDIR="${OUTDIR:-./uptime-kuma-backups/$(date +%Y%m%d-%H%M%S)}"
DRY_RUN="${DRY_RUN:-false}"

KUBECTL=(kubectl --kubeconfig "$KUBECONFIG")
HELM=(helm --kubeconfig "$KUBECONFIG")

HELPER_POD=""
WORKLOAD_KIND=""
WORKLOAD_NAME=""
ORIGINAL_REPLICAS=""
SCALED_DOWN="false"

log() {
  printf '[backup] %s\n' "$*"
}

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

detect_workload() {
  local deployment
  local statefulset

  deployment="$(${KUBECTL[@]} -n "$NAMESPACE" get deployment -l "app.kubernetes.io/instance=${RELEASE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [[ -n "$deployment" ]]; then
    WORKLOAD_KIND="deployment"
    WORKLOAD_NAME="$deployment"
    return 0
  fi

  statefulset="$(${KUBECTL[@]} -n "$NAMESPACE" get statefulset -l "app.kubernetes.io/instance=${RELEASE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [[ -n "$statefulset" ]]; then
    WORKLOAD_KIND="statefulset"
    WORKLOAD_NAME="$statefulset"
    return 0
  fi

  printf 'Could not find deployment/statefulset for release %s in namespace %s\n' "$RELEASE" "$NAMESPACE" >&2
  exit 1
}

cleanup() {
  if [[ -n "$HELPER_POD" ]]; then
    ${KUBECTL[@]} -n "$NAMESPACE" delete pod "$HELPER_POD" --ignore-not-found >/dev/null 2>&1 || true
  fi

  if [[ "$SCALED_DOWN" == "true" && "$DRY_RUN" != "true" ]]; then
    log "Restoring ${WORKLOAD_KIND}/${WORKLOAD_NAME} replicas to ${ORIGINAL_REPLICAS}"
    ${KUBECTL[@]} -n "$NAMESPACE" scale "${WORKLOAD_KIND}/${WORKLOAD_NAME}" --replicas="$ORIGINAL_REPLICAS" >/dev/null
    ${KUBECTL[@]} -n "$NAMESPACE" rollout status "${WORKLOAD_KIND}/${WORKLOAD_NAME}" --timeout=300s >/dev/null
  fi
}

trap cleanup EXIT

require_cmd kubectl
require_cmd helm
require_cmd tar
require_cmd sha256sum

log "Validating release ${RELEASE} in namespace ${NAMESPACE}"
${HELM[@]} status "$RELEASE" -n "$NAMESPACE" >/dev/null

mkdir -p "$OUTDIR"
log "Writing snapshot files to ${OUTDIR}"

${HELM[@]} get values "$RELEASE" -n "$NAMESPACE" > "${OUTDIR}/values-user.yaml"
${HELM[@]} get values "$RELEASE" -n "$NAMESPACE" --all > "${OUTDIR}/values-computed.yaml"
${HELM[@]} get manifest "$RELEASE" -n "$NAMESPACE" > "${OUTDIR}/manifest.yaml"
${HELM[@]} status "$RELEASE" -n "$NAMESPACE" > "${OUTDIR}/helm-status.txt"
${KUBECTL[@]} -n "$NAMESPACE" get all,ingress,configmap,secret,pvc -l "app.kubernetes.io/instance=${RELEASE}" -o yaml > "${OUTDIR}/k8s-resources.yaml"

detect_workload
ORIGINAL_REPLICAS="$(${KUBECTL[@]} -n "$NAMESPACE" get "${WORKLOAD_KIND}/${WORKLOAD_NAME}" -o jsonpath='{.spec.replicas}')"

PVC_NAME="$(${KUBECTL[@]} -n "$NAMESPACE" get pvc -l "app.kubernetes.io/instance=${RELEASE}" -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$PVC_NAME" ]]; then
  printf 'Could not find PVC for release %s in namespace %s\n' "$RELEASE" "$NAMESPACE" >&2
  exit 1
fi

CHART_VERSION=""
if command -v python3 >/dev/null 2>&1; then
  CHART_VERSION="$(${HELM[@]} list -n "$NAMESPACE" -f "^${RELEASE}$" -o json | python3 -c 'import json,sys; data=json.load(sys.stdin); print((data[0].get("chart","").split("uptime-kuma-")[-1]) if data else "")')"
fi
printf '%s\n' "$CHART_VERSION" > "${OUTDIR}/chart-version.txt"

log "Workload=${WORKLOAD_KIND}/${WORKLOAD_NAME}, replicas=${ORIGINAL_REPLICAS}, pvc=${PVC_NAME}, chartVersion=${CHART_VERSION}"

if [[ "$ORIGINAL_REPLICAS" != "0" ]]; then
  log "Scaling ${WORKLOAD_KIND}/${WORKLOAD_NAME} to 0 for consistent backup"
  run ${KUBECTL[@]} -n "$NAMESPACE" scale "${WORKLOAD_KIND}/${WORKLOAD_NAME}" --replicas=0
  if [[ "$DRY_RUN" != "true" ]]; then
    ${KUBECTL[@]} -n "$NAMESPACE" wait --for=delete pod -l "app.kubernetes.io/instance=${RELEASE}" --timeout=300s || true
  fi
  SCALED_DOWN="true"
fi

HELPER_POD="uptime-kuma-backup-helper"
log "Creating helper pod ${HELPER_POD}"
if [[ "$DRY_RUN" == "true" ]]; then
  printf '[dry-run] create helper pod mounting pvc %s\n' "$PVC_NAME"
else
  ${KUBECTL[@]} -n "$NAMESPACE" apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${HELPER_POD}
  labels:
    app.kubernetes.io/name: uptime-kuma-backup-helper
spec:
  restartPolicy: Never
  containers:
    - name: helper
      image: alpine:3.20
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /source
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: ${PVC_NAME}
EOF
  ${KUBECTL[@]} -n "$NAMESPACE" wait --for=condition=Ready pod/${HELPER_POD} --timeout=120s >/dev/null
fi

log "Creating data archive"
if [[ "$DRY_RUN" == "true" ]]; then
  printf '[dry-run] kubectl exec %s -- tar czf - -C /source . > %s/uptime-kuma-data.tar.gz\n' "$HELPER_POD" "$OUTDIR"
else
  ${KUBECTL[@]} -n "$NAMESPACE" exec "$HELPER_POD" -- tar czf - -C /source . > "${OUTDIR}/uptime-kuma-data.tar.gz"
  sha256sum "${OUTDIR}/uptime-kuma-data.tar.gz" > "${OUTDIR}/uptime-kuma-data.tar.gz.sha256"
fi

log "Backup completed: ${OUTDIR}"
