#!/usr/bin/env bash
# Phase 1 automated smoke test. Proves the off-Pi plumbing:
#   - the container builds and reaches a healthy state
#   - noVNC serves over HTTP on 127.0.0.1:5800
#   - the GUI port is bound to loopback ONLY (never 0.0.0.0 / the LAN)
# The file-manager upload/delete round-trip and GUI rendering are human-validated
# (see validation.md) — too brittle to assert headlessly.
set -euo pipefail

cd "$(dirname "$0")"

PORT=5800
CONTAINER=rpi-sample-app
READY_TIMEOUT=180

cleanup() { docker compose down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== build + up =="
docker compose up -d --build

# The base image defines no Docker HEALTHCHECK, so poll the noVNC endpoint
# directly until it serves HTTP 200 (and bail early if the container exits).
echo "== wait for noVNC to serve on 127.0.0.1:${PORT} (<= ${READY_TIMEOUT}s) =="
deadline=$((SECONDS + READY_TIMEOUT))
while :; do
  state=$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo missing)
  [ "$state" = "running" ] || fail "container is not running (state: ${state}); see 'docker logs ${CONTAINER}'"
  code=$(curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/" 2>/dev/null || true)
  [ "$code" = "200" ] && break
  [ "$SECONDS" -ge "$deadline" ] && fail "timed out waiting for noVNC HTTP 200 (last: ${code:-none})"
  sleep 2
done
echo "ok: noVNC served HTTP 200"

echo "== sample app is running =="
# Candle finishes its software-GL init a few seconds after nginx starts serving.
app_deadline=$((SECONDS + 30))
while :; do
  if docker exec "$CONTAINER" pgrep -f /opt/candle/candle >/dev/null 2>&1; then
    echo "ok: Candle process is up"; break
  fi
  [ "$SECONDS" -ge "$app_deadline" ] && { echo "warn: Candle process not detected (GUI render is human-validated anyway)"; break; }
  sleep 2
done

echo "== port bound to loopback only =="
# Deterministic: the publish HostIp must be 127.0.0.1, never 0.0.0.0.
hostip=$(docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{range $conf}}{{.HostIp}} {{end}}{{end}}' "$CONTAINER")
echo "published HostIp(s): ${hostip}"
echo "$hostip" | grep -q '127.0.0.1' || fail "GUI port is not published on 127.0.0.1"
echo "$hostip" | grep -q '0.0.0.0'  && fail "GUI port is published on 0.0.0.0 (reachable on the LAN!)"
echo "ok: loopback-only binding"

# Best-effort active probe: the port must be REFUSED on a non-loopback IP.
lanip=""
if command -v ipconfig >/dev/null 2>&1; then
  lanip=$(ipconfig getifaddr en0 2>/dev/null || true)
fi
if [ -z "$lanip" ] && command -v hostname >/dev/null 2>&1; then
  lanip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
fi
if [ -n "$lanip" ] && [ "$lanip" != "127.0.0.1" ]; then
  if curl -fsS -o /dev/null --max-time 4 "http://${lanip}:${PORT}/" 2>/dev/null; then
    fail "GUI answered on non-loopback IP ${lanip} — LAN-exposed!"
  fi
  echo "ok: refused on non-loopback IP ${lanip}"
else
  echo "skip: no non-loopback IP discovered (binding assertion above still holds)"
fi

echo
echo "PASS: noVNC served on loopback only; container healthy."
