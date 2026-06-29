#!/usr/bin/env bash
# Unit tests for sanitize-compose.sh — no containers run; just the YAML transform.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SANITIZE="$HERE/../rootfs/opt/appliance/lib/sanitize-compose.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass=0 fail=0
ok()   { echo "  ok: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1" >&2; fail=$((fail+1)); }

# Run sanitize on a compose string; echo output, return its exit code.
run() { printf '%s' "$1" | "$SANITIZE" /dev/stdin; }

echo "== case 1: single service, 0.0.0.0 port is pinned to loopback =="
out="$(run 'services:
  app:
    image: demo
    ports:
      - "0.0.0.0:5800:5800"')"
grep -q '127.0.0.1:5800:5800' <<<"$out" && ok "loopback port present" || bad "loopback port missing"
grep -q '0.0.0.0' <<<"$out" && bad "0.0.0.0 still present" || ok "no 0.0.0.0 binding"

echo "== case 2: labelled GUI among many; other ports stripped; passthrough kept =="
out="$(run 'services:
  worker:
    image: side
    ports:
      - "9000:9000"
  gui:
    image: demo
    labels:
      appliance.gui: "true"
    privileged: true
    devices:
      - "/dev/ttyUSB0:/dev/ttyUSB0"
    ports:
      - "0.0.0.0:5800:5800"')"
grep -q '127.0.0.1:5800:5800' <<<"$out" && ok "gui pinned to loopback" || bad "gui not pinned"
grep -q '9000' <<<"$out" && bad "worker port 9000 survived" || ok "worker port stripped"
grep -q 'privileged: true' <<<"$out" && ok "privileged preserved" || bad "privileged lost"
grep -q '/dev/ttyUSB0' <<<"$out" && ok "devices preserved" || bad "devices lost"

echo "== case 3: long-syntax published port is stripped =="
out="$(run 'services:
  app:
    image: demo
    ports:
      - target: 5800
        published: 5800
        host_ip: 0.0.0.0')"
grep -qE 'published:|0\.0\.0\.0' <<<"$out" && bad "long-syntax port survived" || ok "long-syntax port stripped"
grep -q '127.0.0.1:5800:5800' <<<"$out" && ok "loopback port added" || bad "loopback port missing"

echo "== case 4: multiple services, none labelled -> error =="
run 'services:
  a: { image: x }
  b: { image: y }' >/dev/null 2>&1 && bad "should have errored" || ok "errored as expected"

echo "== case 5: custom WEB_PORT honored =="
out="$(WEB_PORT=7900 run 'services:
  app: { image: demo }')"
grep -q '127.0.0.1:7900:5800' <<<"$out" && ok "WEB_PORT=7900 applied" || bad "WEB_PORT not applied"

echo
echo "sanitize: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
