#!/usr/bin/env bash
# Phase 3 integration: data on the USB store persists across container recreate, and
# the app refuses to start when the USB is absent. Runs on any Docker host.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_UP="$HERE/../rootfs/opt/appliance/bin/compose-up"
fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== persistence: a file on the USB data dir survives container recreate =="
usb="$(mktemp -d)"; data="$usb/data"; mkdir -p "$data"
docker run --rm -v "$data:/data" busybox sh -c 'echo persisted-ok > /data/marker.txt' \
  || fail "could not write to data dir"
# Different container, same on-USB dir.
got=$(docker run --rm -v "$data:/data" busybox cat /data/marker.txt 2>/dev/null || true)
[ "$got" = "persisted-ok" ] && echo "  ok: data survived recreate" || fail "data did not persist (got '$got')"
rm -rf "$usb"

echo "== refusal: USB absent -> compose-up exits non-zero, starts no container =="
docker rm -f appliance-gui >/dev/null 2>&1 || true
export APPLIANCE_CONFIG_DIR="$HERE/fixtures/app-candle"
export APPLIANCE_RUNTIME_DIR="$(mktemp -d)"
export APPLIANCE_USB_MOUNT="$(mktemp -d)/never-mounted"   # exists? no -> fails preflight
export APPLIANCE_REQUIRE_MOUNT=1
if out=$("$COMPOSE_UP" 2>&1); then
  fail "compose-up should have refused, but succeeded"
fi
echo "$out" | grep -qi usb && echo "  ok: refused with USB reason" || fail "no USB reason in output: $out"
docker inspect appliance-gui >/dev/null 2>&1 && fail "a container was started despite refusal" \
  || echo "  ok: no container started"
rm -rf "$APPLIANCE_RUNTIME_DIR"

echo
echo "PASS: USB data persists; app refuses to start without the USB store."
