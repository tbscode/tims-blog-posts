#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PIDS="$(pgrep -f 'qemu-system-x86_64|qemu-system-aarch64' || true)"

if [ -z "${PIDS}" ]; then
  echo "No running QEMU VM process found."
  exit 0
fi

echo "Stopping QEMU VM process(es): ${PIDS}"
kill ${PIDS} || true
sleep 1

for pid in ${PIDS}; do
  if kill -0 "${pid}" 2>/dev/null; then
    echo "Force stopping PID ${pid}"
    kill -9 "${pid}" || true
  fi
done

echo "Done."
