#!/usr/bin/env bash
# Unit tests for usb-preflight — no containers; just the mount/writability logic.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PREFLIGHT="$HERE/../rootfs/opt/appliance/bin/usb-preflight"
tmp="$(mktemp -d)"
trap 'chmod -R u+w "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT

pass=0 fail=0
ok()  { echo "  ok: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }

echo "== writable dir, mount not required -> pass =="
if APPLIANCE_USB_MOUNT="$tmp" APPLIANCE_REQUIRE_MOUNT=0 "$PREFLIGHT" >/dev/null 2>&1; then
  ok "passed"; else bad "should have passed"; fi

echo "== missing path -> fail with reason =="
err=$(APPLIANCE_USB_MOUNT="$tmp/nope" APPLIANCE_REQUIRE_MOUNT=0 "$PREFLIGHT" 2>&1 >/dev/null) && bad "should have failed" || {
  [ -n "$err" ] && ok "failed with reason: $err" || bad "no reason printed"; }

echo "== not a mountpoint, mount required -> fail =="
err=$(APPLIANCE_USB_MOUNT="$tmp" APPLIANCE_REQUIRE_MOUNT=1 "$PREFLIGHT" 2>&1 >/dev/null) && bad "should have failed" || {
  echo "$err" | grep -qi mountpoint && ok "failed: $err" || bad "wrong/empty reason: $err"; }

echo "== read-only dir -> fail =="
ro="$tmp/ro"; mkdir -p "$ro"; chmod 555 "$ro"
err=$(APPLIANCE_USB_MOUNT="$ro" APPLIANCE_REQUIRE_MOUNT=0 "$PREFLIGHT" 2>&1 >/dev/null) && bad "should have failed (writable?)" || {
  echo "$err" | grep -qi writable && ok "failed: $err" || bad "wrong/empty reason: $err"; }
chmod 755 "$ro"

echo
echo "usb-preflight: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
