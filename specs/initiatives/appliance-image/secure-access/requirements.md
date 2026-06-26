# Phase 5 — Secure access (host side)

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 5). Key-only SSH,
setup auth from the boot folder, no default credentials, lockdown supported. The SSH
tunnel is the sole access path; SSH is the one service that listens on the network
(everything else is loopback, per Phase 2). Automated key *push* is the client
initiative — here we prove the host side with a manual key.

## Scope

**In:**
- A hardened `sshd` drop-in: key-only, no root login, no passwords by default,
  TCP-forwarding kept on (the tunnel needs `-L`).
- `apply-setup-auth`: read `<config>/setup.txt` — a pre-placed **public key** (→
  key-only immediately) **or** a one-off **setup password** (→ a temporary password
  window for first contact).
- `lockdown`: once a key is installed, disable password auth and invalidate the
  setup password (single-use), wiping the password line from `setup.txt`.
- Off-Pi integration test running real `sshd` in a container.

**Out:** automated key generation/push (client initiative); Wi-Fi join + the systemd
orchestration that *calls* these (Phase 6); pi-gen user creation (Phase 7).

## Decisions

- **`setup.txt` is auto-detected:** a line starting with an SSH key type
  (`ssh-ed25519`/`ssh-rsa`/`ecdsa-…`) is a public key; a line `password=…` (or
  `password: …`) is setup-password mode; anything else is an error to the setup log.
- **Baseline `PasswordAuthentication no`;** password mode adds a *temporary* drop-in
  enabling it, removed at lockdown. No default credential ever ships.
- **Lockdown is belt-and-suspenders:** set `PasswordAuthentication no`, `passwd -l`
  the user (OS password unusable), and strip the password line from `setup.txt` —
  resolving the setup-password-lifecycle open question.
- **`AllowTcpForwarding yes` retained** — the client's local port-forward depends on
  it; disabling it would break the tunnel.
- **Configurable user/paths** (`APPLIANCE_USER`, drop-in path) so the logic is
  testable off-Pi without touching the host.

## Context

- "One key, one computer"; secure-by-default; physical presence trusted, network not
  — from [`../../../mission.md`](../../../mission.md). The brief setup-password window is LAN-only, user-chosen,
  single-use (a known, accepted risk in tech-stack.md).

## Dependencies

- External: `openssh-server` (run in a container for the test); host `ssh`/`ssh-keygen`.
- Phase 2 already binds the app to loopback; this phase doesn't touch that.
