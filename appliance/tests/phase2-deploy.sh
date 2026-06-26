#!/usr/bin/env bash
# Integration test for Phase 2: compose-up reads a boot-folder compose, enforces
# loopback, and runs whatever app the compose names. Runs on any Docker host.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_UP="$HERE/../rootfs/opt/appliance/bin/compose-up"
PORT=5800
CONTAINER=appliance-gui
PROJECT=appliance
export APPLIANCE_PROJECT="$PROJECT"
export APPLIANCE_RUNTIME_DIR="$(mktemp -d)"

fail() { echo "FAIL: $*" >&2; teardown; exit 1; }

teardown() {
  docker compose -p "$PROJECT" -f "$APPLIANCE_RUNTIME_DIR/compose.yml" down -v >/dev/null 2>&1 || true
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}
trap 'rm -rf "$APPLIANCE_RUNTIME_DIR"' EXIT

# Phase 1 image is a prerequisite for the candle fixture.
if ! docker image inspect rpi-appliance/sample-app:dev >/dev/null 2>&1; then
  echo "== building Phase 1 image (prereq) =="
  docker build -q -t rpi-appliance/sample-app:dev "$HERE/../sample-app" >/dev/null
fi

wait_for_novnc() {
  local deadline=$((SECONDS + 180))
  while :; do
    [ "$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo missing)" = "running" ] \
      || fail "container not running; see 'docker logs $CONTAINER'"
    [ "$(curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/" 2>/dev/null || true)" = "200" ] && return 0
    [ "$SECONDS" -ge "$deadline" ] && fail "timed out waiting for noVNC"
    sleep 2
  done
}

assert_loopback_only() {
  local hostip
  hostip=$(docker inspect -f '{{range $p,$c := .NetworkSettings.Ports}}{{range $c}}{{.HostIp}} {{end}}{{end}}' "$CONTAINER")
  echo "  published HostIp(s): ${hostip}"
  echo "$hostip" | grep -q '127.0.0.1' || fail "GUI not published on 127.0.0.1"
  echo "$hostip" | grep -q '0.0.0.0'  && fail "GUI published on 0.0.0.0 (LAN-exposed!)"
  local lanip=""
  command -v ipconfig >/dev/null 2>&1 && lanip=$(ipconfig getifaddr en0 2>/dev/null || true)
  [ -z "$lanip" ] && command -v hostname >/dev/null 2>&1 && lanip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
  if [ -n "$lanip" ] && [ "$lanip" != "127.0.0.1" ]; then
    curl -fsS -o /dev/null --max-time 4 "http://${lanip}:${PORT}/" 2>/dev/null \
      && fail "GUI answered on non-loopback IP ${lanip}" || echo "  ok: refused on ${lanip}"
  fi
}

deploy_case() {
  local name="$1" fixture="$2" expect_image="$3"
  echo "== case: ${name} =="
  export APPLIANCE_CONFIG_DIR="$fixture"
  teardown
  "$COMPOSE_UP" >/dev/null || fail "compose-up failed for ${name}"
  wait_for_novnc
  echo "  ok: noVNC 200 on 127.0.0.1:${PORT}"
  assert_loopback_only
  local img; img=$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")
  [ "$img" = "$expect_image" ] && echo "  ok: running expected app image ($img)" \
    || fail "expected image ${expect_image}, got ${img}"
  teardown
}

deploy_case "candle (0.0.0.0 port overridden)" "$HERE/fixtures/app-candle" "rpi-appliance/sample-app:dev"
deploy_case "alt app (xterm — proves swap)"    "$HERE/fixtures/app-alt"    "rpi-appliance/alt-app:dev"

echo
echo "PASS: both apps deployed loopback-only; swapping the compose swapped the app."
