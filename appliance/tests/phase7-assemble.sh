#!/usr/bin/env bash
# Phase 7: exercise the real rootfs assembler against a temp image root (yq skipped).
# The full pi-gen build is CI/Linux-only and not run here.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ASSEMBLE="$HERE/../image/lib/assemble-rootfs.sh"
SRC="$HERE/../rootfs"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

pass=0 fail=0
ok()  { echo "  ok: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }

mkdir -p "$root/etc"; printf 'proc /proc proc defaults 0 0\n' > "$root/etc/fstab"

APPLIANCE_SKIP_YQ=1 bash "$ASSEMBLE" "$root" "$SRC" >/dev/null || bad "assembler errored"

[ -x "$root/opt/appliance/bin/first-boot" ]      && ok "first-boot present + exec" || bad "first-boot missing/not exec"
[ -x "$root/opt/appliance/bin/compose-up" ]      && ok "compose-up present + exec" || bad "compose-up missing"
[ -f "$root/etc/systemd/system/appliance-first-boot.service" ] && ok "first-boot unit present" || bad "unit missing"
[ -f "$root/etc/docker/daemon.json" ]            && ok "daemon.json present" || bad "daemon.json missing"
[ -f "$root/etc/ssh/sshd_config.d/10-appliance.conf" ] && ok "sshd hardening present" || bad "sshd drop-in missing"
[ -d "$root/mnt/appliance" ]                     && ok "/mnt/appliance mountpoint" || bad "mountpoint missing"
grep -q 'LABEL=APPLIANCE' "$root/etc/fstab"      && ok "fstab has USB store line" || bad "fstab missing USB line"
grep -q 'tmpfs /tmp'      "$root/etc/fstab"       && ok "fstab has tmpfs line" || bad "fstab missing tmpfs"

# Idempotence: re-run must not duplicate fstab lines.
APPLIANCE_SKIP_YQ=1 bash "$ASSEMBLE" "$root" "$SRC" >/dev/null
n=$(grep -c 'LABEL=APPLIANCE' "$root/etc/fstab")
[ "$n" -eq 1 ] && ok "fstab USB line not duplicated on re-run" || bad "fstab duplicated ($n)"

echo
echo "== lint pi-gen stage + build scripts =="
for f in "$HERE/../image/build.sh" "$HERE/../image/stage-appliance"/*.sh "$HERE/../image/stage-appliance"/*/*.sh; do
  [ -f "$f" ] || continue
  bash -n "$f" && ok "bash -n $(basename "$f")" || bad "syntax: $f"
done

echo
echo "phase7-assemble: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
