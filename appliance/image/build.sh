#!/usr/bin/env bash
# Build the standard appliance .img with pi-gen (in Docker). Linux host with Docker +
# binfmt/qemu (e.g. CI). Our stage is made self-contained inside the pi-gen tree
# because pi-gen's run scripts can't see arbitrary host paths.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
IMG_DIR="$REPO/appliance/image"
PIGEN_DIR="${PIGEN_DIR:-$REPO/.pi-gen}"
PIGEN_REF="${PIGEN_REF:-bookworm}"

if [ ! -d "$PIGEN_DIR" ]; then
  echo "build: cloning pi-gen ($PIGEN_REF) -> $PIGEN_DIR"
  git clone --depth 1 --branch "$PIGEN_REF" https://github.com/RPi-Distro/pi-gen "$PIGEN_DIR"
fi

# Assemble a self-contained copy of our stage inside pi-gen.
stage_dst="$PIGEN_DIR/stage-appliance"
rm -rf "$stage_dst"
cp -a "$IMG_DIR/stage-appliance" "$stage_dst"
mkdir -p "$stage_dst/00-appliance/files"
cp -a "$REPO/appliance/rootfs"              "$stage_dst/00-appliance/files/rootfs"
cp -a "$IMG_DIR/lib/assemble-rootfs.sh"     "$stage_dst/00-appliance/files/assemble-rootfs.sh"
find "$stage_dst" -name '*.sh' -exec chmod +x {} +

cp "$IMG_DIR/config" "$PIGEN_DIR/config"

cd "$PIGEN_DIR"
echo "build: running pi-gen..."
exec ./build-docker.sh
