#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

BASE_DIR="/data/data/com.termux/files/home/development/qemu"
DISK="${BASE_DIR}/alpine.qcow2"
DISK_SIZE="50G"

echo "[1/5] Stopping running QEMU VMs..."
if [ -x "${BASE_DIR}/kill-vm.sh" ]; then
  "${BASE_DIR}/kill-vm.sh" || true
else
  PIDS="$(pgrep -f 'qemu-system-x86_64|qemu-system-aarch64' || true)"
  if [ -n "${PIDS}" ]; then
    kill ${PIDS} || true
    sleep 1
    for pid in ${PIDS}; do
      if kill -0 "${pid}" 2>/dev/null; then
        kill -9 "${pid}" || true
      fi
    done
  fi
fi

echo "[2/5] Removing old VM disk if present..."
rm -f "${DISK}"

echo "[3/5] Recreating fresh ${DISK_SIZE} qcow2 disk..."
qemu-img create -f qcow2 "${DISK}" "${DISK_SIZE}"

echo "[4/5] Disk info:"
qemu-img info "${DISK}"

echo "[5/5] Reset complete."
echo "Next:"
echo "  1) cd \"${BASE_DIR}\""
echo "  2) bash setup-host.sh"
echo "  3) bash start-installer.sh"
echo "  4) In VM: setup-alpine -> install to vda (sys) -> poweroff"
echo "  5) bash start-vm.sh"
