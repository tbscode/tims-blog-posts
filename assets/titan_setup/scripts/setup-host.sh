#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(pwd)"
ISO_NAME="alpine-virt-3.20.2-x86_64.iso"
ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/${ISO_NAME}"
DISK_NAME="alpine.qcow2"
DISK_SIZE="50G"
SHARE_DIR="${HOME}/docker_shared"

echo "[1/6] Installing Termux host packages..."
pkg update -y
pkg install -y qemu-system-x86-64 qemu-utils wget

echo "[2/6] Ensuring shared directory exists at ${SHARE_DIR}..."
mkdir -p "${SHARE_DIR}"

echo "[3/6] Ensuring VM disk exists at ${ROOT_DIR}/${DISK_NAME}..."
if [ ! -f "${ROOT_DIR}/${DISK_NAME}" ]; then
  qemu-img create -f qcow2 "${ROOT_DIR}/${DISK_NAME}" "${DISK_SIZE}"
fi

echo "[4/6] Downloading Alpine ISO if missing..."
if [ ! -f "${ROOT_DIR}/${ISO_NAME}" ]; then
  wget -O "${ROOT_DIR}/${ISO_NAME}" "${ISO_URL}"
fi

echo "[5/6] Making helper scripts executable..."
chmod +x "${ROOT_DIR}/start-installer.sh" "${ROOT_DIR}/start-vm.sh" "${ROOT_DIR}/postinstall-alpine.sh"

echo "[6/6] Host setup complete."
echo "Next steps:"
echo "  1) ./start-installer.sh"
echo "  2) In VM run: setup-alpine (install to vda as sys), then poweroff"
echo "  3) ./start-vm.sh"
echo "  4) In VM as root run: /mnt/shared/postinstall-alpine.sh or paste script contents"
