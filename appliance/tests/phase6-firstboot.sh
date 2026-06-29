#!/usr/bin/env bash
# Phase 6: first-boot orchestration + setup log. Net/auth steps are stubbed off-Pi
# (covered for real in Phases 5/8); the app step and the setup.log are exercised for
# real. Runs on any Docker host.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HERE/../rootfs/opt/appliance/bin"
FIRSTBOOT="$BIN/first-boot"
PORT=5800
CONTAINER=appliance-gui
export APPLIANCE_PROJECT=appliance

pass=0 fail=0
ok()  { echo "  ok: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }

# Stub net/auth so the test needs no root/Pi; keep the app step real.
stub="$(mktemp -d)/stub-ok"; printf '#!/bin/sh\necho stubbed-ok\n' > "$stub"; chmod +x "$stub"
export APPLIANCE_NET_CMD="$stub" APPLIANCE_AUTH_CMD="$stub"

teardown() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; }
trap teardown EXIT

bash -n "$FIRSTBOOT" && ok "first-boot parses" || bad "first-boot syntax error"
bash -n "$BIN/join-network" && ok "join-network parses" || bad "join-network syntax error"
unit="$HERE/../rootfs/etc/systemd/system/appliance-first-boot.service"
grep -q 'ExecStart=/opt/appliance/bin/first-boot' "$unit" && ok "unit runs first-boot" || bad "unit ExecStart wrong"
grep -q 'Type=oneshot' "$unit" && grep -q 'RemainAfterExit=yes' "$unit" && ok "unit is oneshot/RemainAfterExit" || bad "unit type wrong"

# Build the config folder the user would drop on the boot partition.
make_config() {
  local dir="$1"
  cp "$HERE/fixtures/app-candle/compose.yml" "$dir/compose.yml"
  printf 'SSID=demo\nPSK=secret\nCOUNTRY=US\n' > "$dir/wifi.txt"
  printf 'ssh-ed25519 AAAAExampleKey demo@host\n' > "$dir/setup.txt"
}

echo "== happy path: network + auth + app all OK =="
cfg="$(mktemp -d)"; make_config "$cfg"
teardown
APPLIANCE_CONFIG_DIR="$cfg" \
  APPLIANCE_RUNTIME_DIR="$(mktemp -d)" \
  APPLIANCE_USB_MOUNT="$(mktemp -d)" APPLIANCE_REQUIRE_MOUNT=0 \
  "$FIRSTBOOT"
sl="$cfg/setup.log"
[ -f "$sl" ] && ok "setup.log written to boot folder" || bad "no setup.log"
grep -q '\[ OK \] network join' "$sl" && ok "network logged OK" || bad "network not OK in log"
grep -q '\[ OK \] setup auth'   "$sl" && ok "auth logged OK"    || bad "auth not OK in log"
grep -q '\[ OK \] app start'    "$sl" && ok "app logged OK"     || bad "app not OK in log"
grep -q 'setup complete'        "$sl" && ok "setup complete marker" || bad "no completion marker"
# compose-up returns once the container is created; noVNC takes a few seconds more.
code=000; deadline=$((SECONDS + 60))
while [ "$SECONDS" -lt "$deadline" ]; do
  code=$(curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/" 2>/dev/null || true)
  [ "$code" = "200" ] && break; sleep 2
done
[ "$code" = "200" ] && ok "app is up (noVNC 200)" || bad "app not serving (got '$code')"
teardown

echo "== failure path: USB absent -> app step FAILs, no completion =="
cfg2="$(mktemp -d)"; make_config "$cfg2"
APPLIANCE_CONFIG_DIR="$cfg2" \
  APPLIANCE_RUNTIME_DIR="$(mktemp -d)" \
  APPLIANCE_USB_MOUNT="$(mktemp -d)/never" APPLIANCE_REQUIRE_MOUNT=1 \
  "$FIRSTBOOT"
rc=$?
sl2="$cfg2/setup.log"
[ "$rc" -ne 0 ] && ok "first-boot exited non-zero" || bad "should have failed"
grep -q '\[FAIL\] app start' "$sl2" && ok "app FAIL logged" || bad "no app FAIL in log"
grep -qi 'usb' "$sl2" && ok "USB reason captured" || bad "no USB reason in log"
grep -q 'setup complete' "$sl2" && bad "completion marker present on failure" || ok "no false completion"
docker inspect "$CONTAINER" >/dev/null 2>&1 && bad "app started despite failure" || ok "no app started"

echo
echo "phase6-firstboot: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
