#!/usr/bin/env bash
# Client Phase 1 integration: prove the app's `ssh -L` tunnel actually renders noVNC,
# without a Pi. We build an "appliance" stand-in = the Phase 1 sample-app image (noVNC
# on the container's loopback :5800, NOT published) + sshd. Then we drive the SAME ssh
# invocation client/src-tauri/src/ssh.rs builds and assert noVNC answers through the
# tunnel, and that the local port closes on teardown.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$HERE/../.."
APP_IMG=rpi-appliance/sample-app:dev
NAME=client-tunnel-test
SSH_PORT=2222
LOCAL_PORT=5901       # forward target on the app side is 127.0.0.1:5800 (loopback noVNC)
keydir="$(mktemp -d)"
sshpid=""

pass=0 fail=0
ok()  { echo "  ok: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }
cleanup() {
  [ -n "$sshpid" ] && kill "$sshpid" 2>/dev/null
  docker rm -f "$NAME" >/dev/null 2>&1
  rm -rf "$keydir"
}
trap cleanup EXIT

# Same options as ssh_args() in client/src-tauri/src/ssh.rs (keep in sync).
ssh_tunnel() {
  ssh -i "$keydir/id" -N -T \
    -L "${LOCAL_PORT}:127.0.0.1:5800" -o IdentitiesOnly=yes \
    -p "$SSH_PORT" \
    -o ExitOnForwardFailure=yes \
    -o StrictHostKeyChecking=accept-new \
    -o UserKnownHostsFile=/dev/null \
    -o BatchMode=yes \
    -o ServerAliveInterval=15 \
    pi@127.0.0.1 &
  sshpid=$!
}

echo "== ensure sample-app image (noVNC) exists =="
if ! docker image inspect "$APP_IMG" >/dev/null 2>&1; then
  docker build -q -t "$APP_IMG" "$REPO/appliance/sample-app" >/dev/null || { echo "build failed"; exit 1; }
fi

ssh-keygen -t ed25519 -N '' -f "$keydir/id" -q
pub="$(cat "$keydir/id.pub")"

echo "== start appliance stand-in (noVNC on loopback only) + sshd =="
# noVNC port is intentionally NOT published — reachable ONLY through the tunnel.
docker run -d --name "$NAME" -p "127.0.0.1:${SSH_PORT}:22" "$APP_IMG" >/dev/null
# Wait for noVNC to be up inside the container.
for _ in $(seq 1 60); do
  docker exec "$NAME" sh -c 'curl -fsS -o /dev/null http://127.0.0.1:5800/' 2>/dev/null && break
  sleep 2
done
# Add sshd + the test key (runtime install; this is a test rig, not the appliance).
docker exec "$NAME" sh -c "
  add-pkg openssh-server curl >/dev/null 2>&1 || apt-get install -y openssh-server curl >/dev/null 2>&1
  mkdir -p /run/sshd && ssh-keygen -A >/dev/null 2>&1
  id pi >/dev/null 2>&1 || useradd -m -s /bin/sh pi
  mkdir -p /home/pi/.ssh && printf '%s\n' '$pub' > /home/pi/.ssh/authorized_keys
  chown -R pi:pi /home/pi/.ssh && chmod 700 /home/pi/.ssh && chmod 600 /home/pi/.ssh/authorized_keys
" || bad "could not provision sshd in stand-in"
docker exec -d "$NAME" /usr/sbin/sshd -D
sleep 2

echo "== confirm noVNC is NOT directly reachable from host =="
curl -fsS -o /dev/null --max-time 3 "http://127.0.0.1:5800/" 2>/dev/null \
  && bad "noVNC answered on host without the tunnel" || ok "noVNC not exposed without tunnel"

echo "== open the tunnel (same ssh args as the app) =="
ssh_tunnel
code=000
for _ in $(seq 1 20); do
  code=$(curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${LOCAL_PORT}/" 2>/dev/null || true)
  [ "$code" = "200" ] && break; sleep 1
done
[ "$code" = "200" ] && ok "noVNC served HTTP 200 through the tunnel" || bad "no noVNC through tunnel (got '$code')"

echo "== teardown closes the local port =="
kill "$sshpid" 2>/dev/null; sshpid=""; sleep 2
curl -fsS -o /dev/null --max-time 3 "http://127.0.0.1:${LOCAL_PORT}/" 2>/dev/null \
  && bad "local port still open after disconnect" || ok "local port closed after disconnect"

echo
echo "client tunnel-it: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
