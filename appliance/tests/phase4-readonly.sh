#!/usr/bin/env bash
# Phase 4 structural validation. Enabling overlayfs needs the Pi kernel + a reboot
# (Phase 8); here we assert the machinery is present and the write-routing invariant
# holds — no app-writable path targets the SD.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../rootfs"
pass=0 fail=0
ok()  { echo "  ok: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }

jc="$ROOT/etc/systemd/journald.conf.d/volatile.conf"
grep -qE '^Storage=volatile' "$jc" && ok "journald Storage=volatile" || bad "journald not volatile"

ft="$ROOT/etc/appliance/fstab.tmpfs.append"
grep -qE '^tmpfs[[:space:]]+/tmp[[:space:]]+tmpfs' "$ft"     && ok "tmpfs /tmp"     || bad "no tmpfs /tmp"
grep -qE '^tmpfs[[:space:]]+/var/tmp[[:space:]]+tmpfs' "$ft" && ok "tmpfs /var/tmp" || bad "no tmpfs /var/tmp"

er="$ROOT/opt/appliance/bin/enable-readonly-root"
bash -n "$er" && ok "enable-readonly-root parses" || bad "enable-readonly-root syntax error"
grep -q 'raspi-config' "$er" && ok "guards on raspi-config" || bad "no raspi-config guard"
grep -q 'do_overlayfs' "$er" && ok "enables overlayfs" || bad "does not call do_overlayfs"

# Write-routing invariant: Docker data-root is on the USB, not the SD.
dr=$(python3 -c 'import json;print(json.load(open("'"$ROOT"'/etc/docker/daemon.json"))["data-root"])')
case "$dr" in
  /mnt/appliance/*) ok "docker data-root on USB ($dr)";;
  *) bad "docker data-root not on USB: $dr";;
esac

echo
echo "phase4-readonly: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
