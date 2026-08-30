#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root inside Alpine VM."
  exit 1
fi

echo "[1/6] Enabling community repository..."
sed -i 's|^#\(.*\/community\)$|\1|' /etc/apk/repositories

echo "[2/6] Installing packages..."
apk update
apk add sudo docker docker-cli-compose shadow

echo "[3/6] Creating user tim if needed..."
if ! id tim >/dev/null 2>&1; then
  adduser tim
fi

echo "[4/6] Adding tim to docker group and sudoers..."
addgroup tim docker || true
if ! grep -q '^tim ALL=(ALL:ALL) ALL$' /etc/sudoers; then
  printf 'tim ALL=(ALL:ALL) ALL\n' >> /etc/sudoers
fi

echo "[5/6] Enabling and starting Docker..."
rc-update add docker boot || true
rc-service docker start || true

echo "[6/6] Configuring shared mount (re-runnable)..."
mkdir -p /mnt/shared
TIM_UID="$(id -u tim)"
TIM_GID="$(id -g tim)"
MOUNT_OPTS="trans=virtio,version=9p2000.L,msize=262144,uid=${TIM_UID},gid=${TIM_GID},dmode=0775,fmode=0664"

FSTAB_LINE="hostshare /mnt/shared 9p ${MOUNT_OPTS},_netdev 0 0"

sed -i '\|^hostshare[[:space:]]\+/mnt/shared[[:space:]]\+9p[[:space:]]|d' /etc/fstab
printf '%s\n' "${FSTAB_LINE}" >> /etc/fstab

if mount | grep -q ' on /mnt/shared '; then
  mount -o remount -t 9p -o "${MOUNT_OPTS}" hostshare /mnt/shared 2>/dev/null || true
fi

if mount | grep -q ' on /mnt/shared '; then
  umount /mnt/shared 2>/dev/null || true
fi
if mount | grep -q ' on /mnt/shared '; then
  umount -l /mnt/shared 2>/dev/null || true
fi
if mount | grep -q ' on /mnt/shared '; then
  fuser -km /mnt/shared 2>/dev/null || true
  umount /mnt/shared 2>/dev/null || true
  umount -l /mnt/shared 2>/dev/null || true
fi

if ! mount | grep -q ' on /mnt/shared '; then
  mount -t 9p -o "${MOUNT_OPTS}" hostshare /mnt/shared
fi

chmod 755 /mnt
chmod 775 /mnt/shared || true

if ! mount | grep -q ' on /mnt/shared '; then
  echo "ERROR: /mnt/shared is not mounted."
  exit 1
fi

echo "Done."
echo "Now set tim password if not set: passwd tim"
echo "Then verify as tim:"
echo "  su - tim"
echo "  cd /mnt/shared"
echo "  docker run --rm hello-world"
echo "  sudo apk update"
echo "  touch /mnt/shared/test.txt"
