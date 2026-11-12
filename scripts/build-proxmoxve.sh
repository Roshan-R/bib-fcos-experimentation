#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SOURCE_IMAGE=quay.io/fedora/fedora-coreos:rawhide
IBC_IMAGE=$(yq -r '.image-builder-cli' "$ROOT/image-builder-config.yaml")
BUILDER_IMAGE=$(yq -r '.builder-image' "$ROOT/image-builder-config.yaml")
OUTPUT_DIR="$ROOT/output/proxmoxve"

if [ "$EUID" -ne 0 ] || [ "$(uname -m)" != x86_64 ]; then
  echo "Run with sudo on an x86_64 host" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
BASE="$OUTPUT_DIR/fedora-coreos-proxmoxve"

[ ! -e "$BASE.qcow2" ] && [ ! -e "$BASE.uncompressed.qcow2" ] || {
  echo "Output exists; move the previous artifacts before rebuilding" >&2; exit 1;
}

podman pull "$SOURCE_IMAGE"
podman pull "$BUILDER_IMAGE"
podman tag "$SOURCE_IMAGE" localhost/bib-proxmoxve-source:local
podman tag "$BUILDER_IMAGE" localhost/bib-proxmoxve-builder:local

# The pinned CLI's default disk size is 10 GiB, matching FCOS cloud images.
podman run --rm --privileged \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$ROOT:/repo:ro" -v "$OUTPUT_DIR:/output" \
  "$IBC_IMAGE" build qcow2 \
  --bootc-ref localhost/bib-proxmoxve-source:local \
  --bootc-build-ref localhost/bib-proxmoxve-builder:local \
  --bootc-no-default-kernel-args \
  --blueprint /repo/blueprints/generated/proxmoxve-x86_64.toml \
  --output-dir /output --output-name fedora-coreos-proxmoxve \
  --with-buildlog --with-manifest

# Work around the pinned CLI writing console.cfg outside the boot partition.
# See https://github.com/joelcapitao/bib-fcos-experimentation/issues/166
export LIBGUESTFS_BACKEND=direct
BOOT=$(guestfish --ro -a "$BASE.qcow2" run : findfs-label boot)
guestfish --rw -a "$BASE.qcow2" -m "$BOOT" write /grub2/console.cfg \
  $'serial --speed=115200\nterminal_input serial console\nterminal_output serial console\n'

# Match coreos-assembler: compat 1.1 without internal QCOW2 compression.
qemu-img convert -f qcow2 -O qcow2 -o compat=1.1 \
  "$BASE.qcow2" "$BASE.uncompressed.qcow2"
mv "$BASE.uncompressed.qcow2" "$BASE.qcow2"
chown "${SUDO_UID:-0}:${SUDO_GID:-0}" "$BASE.qcow2"
