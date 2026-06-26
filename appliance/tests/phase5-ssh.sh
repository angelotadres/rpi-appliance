#!/usr/bin/env bash
# Phase 5 integration: run a real sshd in a container and exercise key-only auth,
# the setup-password window, and lockdown. Runs on any Docker host.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
APPLIANCE_DIR="$HERE/.."
IMG=rpi-appliance/test-sshd:dev
NAME=appliance-sshd-test
PORT=2222
cfg="$(mktemp -d)"; keydir="$(mktemp -d)"
SSHOPT=(-p "$PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5)

pass=0 fail=0
ok()  { echo "  ok: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; rm -rf "$cfg" "$keydir"; }
trap cleanup EXIT

dexec() { docker exec -e APPLIANCE_CONFIG_DIR=/cfg -e APPLIANCE_USER=pi "$NAME" "$@"; }
reload_sshd() { docker exec "$NAME" kill -HUP 1; sleep 1; }
sshd_t() { docker exec "$NAME" sshd -T 2>/dev/null; }

echo "== build sshd test image =="
docker build -q -t "$IMG" -f "$HERE/fixtures/sshd/Dockerfile" "$APPLIANCE_DIR" >/dev/null || { echo "build failed" >&2; exit 1; }

ssh-keygen -t ed25519 -N '' -f "$keydir/id" -q
pub="$(cat "$keydir/id.pub")"

echo "== start container =="
docker run -d --name "$NAME" -p "127.0.0.1:${PORT}:22" -v "$cfg:/cfg" "$IMG" >/dev/null
sleep 2

echo "== pubkey mode =="
printf '%s\n' "$pub" > "$cfg/setup.txt"
dexec /opt/appliance/bin/apply-setup-auth >/dev/null || bad "apply-setup-auth (pubkey) failed"
reload_sshd
t="$(sshd_t)"
grep -qi '^passwordauthentication no'  <<<"$t" && ok "passwordauthentication no" || bad "password auth not off"
grep -qi '^pubkeyauthentication yes'   <<<"$t" && ok "pubkeyauthentication yes"  || bad "pubkey auth not on"
grep -qi '^permitrootlogin no'         <<<"$t" && ok "permitrootlogin no"        || bad "root login not disabled"
grep -qi '^allowtcpforwarding no'      <<<"$t" && bad "tcp forwarding disabled (breaks tunnel)" || ok "tcp forwarding kept (tunnel intact)"

out="$(ssh "${SSHOPT[@]}" -i "$keydir/id" -o BatchMode=yes pi@127.0.0.1 'echo LOGIN_OK' 2>/dev/null)"
[ "$out" = "LOGIN_OK" ] && ok "key login works" || bad "key login failed (got '$out')"

ssh "${SSHOPT[@]}" -o PreferredAuthentications=password -o PubkeyAuthentication=no -o BatchMode=yes \
  pi@127.0.0.1 'echo NOPE' >/dev/null 2>&1 && bad "password method was accepted" || ok "password method refused"

echo "== password mode (setup window) =="
printf 'password=hunter2trial\n' > "$cfg/setup.txt"
dexec /opt/appliance/bin/apply-setup-auth >/dev/null || bad "apply-setup-auth (password) failed"
reload_sshd
grep -qi '^passwordauthentication yes' <<<"$(sshd_t)" && ok "setup window: password auth ON" || bad "password window not opened"

echo "== lockdown (single-use) =="
# authorized_keys from the pubkey step is still present, so lockdown won't refuse.
dexec /opt/appliance/bin/lockdown >/dev/null || bad "lockdown failed"
reload_sshd
grep -qi '^passwordauthentication no' <<<"$(sshd_t)" && ok "post-lockdown: password auth OFF" || bad "password auth still on"
state="$(docker exec "$NAME" passwd -S pi 2>/dev/null | awk '{print $2}')"
[ "$state" = "L" ] && ok "account password locked (passwd -S: L)" || bad "account not locked (passwd -S: $state)"
grep -qiE '^[[:space:]]*password[:=]' "$cfg/setup.txt" && bad "password line still in setup.txt" || ok "setup password wiped from setup.txt"
out="$(ssh "${SSHOPT[@]}" -i "$keydir/id" -o BatchMode=yes pi@127.0.0.1 'echo STILL_OK' 2>/dev/null)"
[ "$out" = "STILL_OK" ] && ok "key login still works after lockdown" || bad "key login broke after lockdown"

echo
echo "phase5-ssh: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
