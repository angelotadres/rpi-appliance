#!/bin/bash -e
# Host-context: lay the appliance overlay onto the image root. build.sh has populated
# ./files/ with the repo's rootfs and the shared assembler.
HERE="$(cd "$(dirname "$0")" && pwd)"
"${HERE}/files/assemble-rootfs.sh" "${ROOTFS_DIR}" "${HERE}/files/rootfs"
