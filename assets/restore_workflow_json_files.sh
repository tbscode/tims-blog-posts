#!/usr/bin/env bash
set -euo pipefail

# === Config / Args ===
NAMESPACE="n8n"
SRC_DIR="${1:-}"

if [[ -z "${SRC_DIR}" || ! -d "${SRC_DIR}" ]]; then
  echo "Usage: $0 /path/to/workflows_folder"
  exit 1
fi

echo "Source folder: ${SRC_DIR}"

# --- find a running n8n pod ---
pick_pod() {
  local pod
  pod="$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=n8n \
          --field-selector=status.phase=Running \
          -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  [[ -z "${pod}" ]] && pod="$(kubectl get pods -n "${NAMESPACE}" -l app=n8n \
          --field-selector=status.phase=Running \
          -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  [[ -z "${pod}" ]] && pod="$(kubectl get pods -n "${NAMESPACE}" --field-selector=status.phase=Running \
          -o jsonpath="{.items[?(@.metadata.name =~ /^(n8n-).*/)].metadata.name}" 2>/dev/null || true)"
  echo -n "${pod%% *}"
}
POD="$(pick_pod)"
if [[ -z "${POD}" ]]; then
  echo "Error: no running n8n pod found in namespace '${NAMESPACE}'."
  exit 1
fi
CONTAINER="$(kubectl get pod "${POD}" -n "${NAMESPACE}" -o jsonpath='{.spec.containers[0].name}')"
echo "Using pod: ${POD} (container: ${CONTAINER}) in namespace: ${NAMESPACE}"

# --- sanity: ensure there are *.json files ---
mapfile -d '' FILES < <(find "${SRC_DIR}" -type f -name '*.json' -print0)
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No *.json files found under ${SRC_DIR}"
  exit 1
fi
echo "Found ${#FILES[@]} JSON file(s) to import."

# --- create remote dir ---
STAMP="$(date +%s)"
REMOTE_DIR="/tmp/n8n-import-${STAMP}"
echo "Creating remote dir: ${REMOTE_DIR}"
kubectl exec -n "${NAMESPACE}" -c "${CONTAINER}" "${POD}" -- sh -lc "mkdir -p '${REMOTE_DIR}'"

# --- upload via tar stream (more reliable than kubectl cp) ---
echo "Uploading files via tar stream..."
# pack only *.json; keep basenames (no subdirs) for simplicity
tar -C "${SRC_DIR}" -cf - $(printf "%s\n" "${FILES[@]}" | xargs -I{} basename "{}") 2>/dev/null \
| kubectl exec -i -n "${NAMESPACE}" -c "${CONTAINER}" "${POD}" -- tar -C "${REMOTE_DIR}" -xf -

echo "Files now in pod:"
kubectl exec -n "${NAMESPACE}" -c "${CONTAINER}" "${POD}" -- sh -lc "ls -1 '${REMOTE_DIR}' | sed 's/^/  /'"

# --- import inside the pod, one-by-one ---
echo "Starting imports..."
set +e
kubectl exec -n "${NAMESPACE}" -c "${CONTAINER}" "${POD}" -- sh -lc "
set -e
if ! command -v n8n >/dev/null 2>&1; then
  echo 'Error: n8n CLI not found in PATH' >&2
  exit 127
fi
ok=0; fail=0
for f in '${REMOTE_DIR}'/*.json; do
  [ -e \"\$f\" ] || continue
  echo \"-- Importing \${f}\"
  if n8n import:workflow --input=\"\$f\"; then
    echo \"   OK\"
    ok=\$((ok+1))
  else
    echo \"   FAILED: \${f}\" >&2
    fail=\$((fail+1))
  fi
done
echo \"Summary: \${ok} succeeded, \${fail} failed\"
test \"\$fail\" -eq 0
"
RC=$?
set -e

# --- cleanup ---
echo "Cleaning up ${REMOTE_DIR}..."
kubectl exec -n "${NAMESPACE}" -c "${CONTAINER}" "${POD}" -- rm -rf "${REMOTE_DIR}" || true

if [[ $RC -ne 0 ]]; then
  echo "Completed with some failures. Check output above for details."
  exit $RC
fi

echo "Done: all workflows imported."