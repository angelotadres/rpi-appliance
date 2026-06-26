#!/usr/bin/env bash
# assemble-rootfs.sh <ROOTFS_DIR> <SRC_ROOTFS>
#
# Lay the appliance overlay onto an image root. Used by BOTH the pi-gen stage and the
# off-Pi assembly test, so the copy/fstab/mountpoint logic is actually exercised.
#
#   APPLIANCE_SKIP_YQ=1  skip the yq download (tests, offline)
#   YQ_VERSION / YQ_ARCH override the pinned yq (default v4.44.3 / arm64 for the Pi)
set -euo pipefail

ROOTFS_DIR="${1:?usage: assemble-rootfs.sh <ROOTFS_DIR> <SRC_ROOTFS>}"
SRC="${2:?usage: assemble-rootfs.sh <ROOTFS_DIR> <SRC_ROOTFS>}"
YQ_VERSION="${YQ_VERSION:-v4.44.3}"
YQ_ARCH="${YQ_ARCH:-arm64}"

# 1. Copy the appliance filesystem overlay (scripts, sshd/journald/docker config, units).
cp -a "$SRC/." "$ROOTFS_DIR/"

# 2. Append fstab fragments once (USB writable store + tmpfs write paths).
fstab="$ROOTFS_DIR/etc/fstab"; touch "$fstab"
grep -q 'LABEL=APPLIANCE' "$fstab" || cat "$SRC/etc/appliance/fstab.append"       >> "$fstab"
grep -q '/var/tmp'        "$fstab" || cat "$SRC/etc/appliance/fstab.tmpfs.append" >> "$fstab"

# 3. USB mountpoint.
install -d "$ROOTFS_DIR/mnt/appliance"

# 4. Executable bits on the appliance scripts.
chmod +x "$ROOTFS_DIR/opt/appliance/bin/"* 2>/dev/null || true

# 5. yq single binary (skippable offline / in tests).
if [ "${APPLIANCE_SKIP_YQ:-0}" != "1" ]; then
  install -d "$ROOTFS_DIR/usr/local/bin"
  curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}" \
    -o "$ROOTFS_DIR/usr/local/bin/yq"
  chmod +x "$ROOTFS_DIR/usr/local/bin/yq"
fi

echo "assemble-rootfs: laid appliance overlay into $ROOTFS_DIR"
