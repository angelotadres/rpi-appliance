#!/usr/bin/env bash
# Client Phase 2 integration: exercise the provisioning path (push key via the one-off
# password, verify key login, lockdown) against an appliance stand-in in setup-password
# mode. Mirrors the ssh invocations in client/src-tauri/src/setup.rs (keep in sync).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$HERE/../.."
IMG=rpi-appliance/test-setup:dev
NAME=client-setup-test
PORT=2222
PW='setup-pass-123'
keydir="$(mktemp -d)"

pass=0 fail=0
ok()  { echo "  ok: $1"; pass=$((pass+1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }
cleanup() { docker rm -f "$NAME" >/dev/null 2>&1; rm -rf "$keydir"; }
trap cleanup EXIT

# askpass helper (same idea as setup.rs).
cat > "$keydir/askpass.sh" <<'EOF'
#!/bin/sh
printf '%s' "$RPI_SETUP_PW"
EOF
chmod 700 "$keydir/askpass.sh"

pw_ssh() {  # password session
  SSH_ASKPASS="$keydir/askpass.sh" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 RPI_SETUP_PW="$PW" \
  ssh -T -p "$PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 \
    pi@127.0.0.1 "$@"
}
key_ssh() {  # key session: key_ssh <keyfile> <remote-cmd>
  ssh -i "$1" -T -p "$PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o BatchMode=yes \
    pi@127.0.0.1 "$2"
}
sshd_t() { docker exec "$NAME" sshd -T 2>/dev/null; }

echo "== build setup fixture =="
docker build -q -t "$IMG" -f "$HERE/fixtures/appliance-setup/Dockerfile" "$REPO" >/dev/null || { echo "build failed"; exit 1; }

ssh-keygen -t ed25519 -N '' -f "$keydir/id" -q
ssh-keygen -t ed25519 -N '' -f "$keydir/other" -q   # an unauthorized key for the guard test

echo "== start fixture (password window open) =="
docker run -d --name "$NAME" -p "127.0.0.1:${PORT}:22" "$IMG" >/dev/null
sleep 2
grep -qi '^passwordauthentication yes' <<<"$(sshd_t)" && ok "setup window: password auth ON" || bad "password window not open"

echo "== push public key over the password session =="
if pw_ssh 'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys' < "$keydir/id.pub"; then
  ok "key pushed with setup password"
else
  bad "key push failed (askpass/password path)"
fi

echo "== key-only login now works =="
[ "$(key_ssh "$keydir/id" 'echo verified' 2>/dev/null)" = "verified" ] && ok "key login verified" || bad "key login failed"

echo "== lockout guard: an UNauthorized key is rejected =="
key_ssh "$keydir/other" 'echo nope' >/dev/null 2>&1 && bad "unauthorized key was accepted" || ok "unauthorized key rejected (guard precondition)"

echo "== lockdown over the key session =="
if key_ssh "$keydir/id" 'sudo -n /opt/appliance/bin/lockdown' >/dev/null 2>&1; then
  ok "lockdown ran via NOPASSWD sudo"
else
  bad "lockdown failed"
fi
docker exec "$NAME" kill -HUP 1; sleep 1

echo "== after lockdown: password off, key on, account locked =="
grep -qi '^passwordauthentication no' <<<"$(sshd_t)" && ok "password auth OFF" || bad "password still on"
pw_ssh 'echo should-not-work' >/dev/null 2>&1 && bad "password login still works" || ok "password login refused"
[ "$(key_ssh "$keydir/id" 'echo still-ok' 2>/dev/null)" = "still-ok" ] && ok "key login still works" || bad "key login broke"
[ "$(docker exec "$NAME" passwd -S pi 2>/dev/null | awk '{print $2}')" = "L" ] && ok "account locked" || bad "account not locked"

echo
echo "client setup-it: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
