# Phase 5 — Validation

## Agent validates (autonomous)

`appliance/tests/phase5-ssh.sh` runs real `sshd` in a container and asserts:

- **Pubkey mode:** after `apply-setup-auth` with a public-key `setup.txt`, a real
  `ssh -i <key>` login runs a command successfully, and a password-method attempt
  (`-o PreferredAuthentications=password -o PubkeyAuthentication=no`) is refused.
- **Config:** `sshd -T` reports `passwordauthentication no`, `pubkeyauthentication
  yes`, `permitrootlogin no`, `allowtcpforwarding` not `no` (tunnel intact).
- **Password mode:** after `apply-setup-auth` with `password=…`, `sshd -T` reports
  `passwordauthentication yes` (the setup window).
- **Lockdown:** after `lockdown`, `sshd -T` reports `passwordauthentication no`, the
  account password is locked, the `password=` line is gone from `setup.txt`, and key
  login still works.

Exits non-zero on any failure; runs on any Docker host.

## Human validates (judgment required)

- **On hardware (Phase 8):** that sshd answers on the LAN interface (the gateway)
  while every *other* service stays loopback-only, end-to-end through the client.

## Definition of done

- [ ] Task group 1: hardening drop-in + `apply-setup-auth` (both modes).
- [ ] Task group 2: `lockdown` (key-required, password-off, account locked, secret wiped).
- [ ] Task group 3: SSH integration test passes; docs + tech-stack updated.
- [ ] Agent checks green and reported.
- [ ] Mark the Phase 5 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
