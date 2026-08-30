#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

qemu-system-x86_64 \
  -machine q35,accel=tcg \
  -cpu max \
  -m 4096 \
  -smp 4 \
  -drive file=alpine.qcow2,if=virtio,format=qcow2 \
  -cdrom alpine-virt-3.20.2-x86_64.iso \
  -boot d \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080 \
  -device virtio-net-pci,netdev=n1 \
  -virtfs local,path=${HOME}/docker_shared,mount_tag=hostshare,security_model=none,id=hostshare \
  -nographic
