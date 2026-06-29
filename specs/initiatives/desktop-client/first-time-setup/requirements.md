# Client Phase 2 — First-time setup (key provisioning)

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 2). Take a fresh
appliance (booted in setup-password mode) to key-only access with no manual key
editing: generate/choose a key, push the public key over the one-off password
session, then run `lockdown` to make the password single-use.

## Scope

**In:**
- `generate_key` — create an ed25519 keypair via the OS `ssh-keygen` (or accept an
  existing key path).
- `provision` — using the **one-off setup password**, append the public key to the
  appliance's `authorized_keys`, verify a key-only login works, then run the
  appliance's `lockdown` over SSH.
- A small appliance dependency added here: a sudoers drop-in so the appliance user can
  run `lockdown` (and, for Phase 3, `poweroff`) without a password.
- Off-Pi integration test against an sshd fixture that mirrors appliance Phase 5.

**Out:** rendering/tunnel (Phase 1); shutdown UI + settings persistence (Phase 3);
packaging (Phase 4).

## Decisions

- **Password auth via `SSH_ASKPASS` + `SSH_ASKPASS_REQUIRE=force`** — keeps the
  "OS `ssh`, no bundled SSH stack" rule (tech-stack) while supplying the one-off
  password non-interactively (OpenSSH ≥8.4; macOS ships 9.x). The password is passed
  through a short-lived askpass helper, never on argv.
- **Push, then verify, then lock** — append the key, confirm a `PreferredAuthentications=publickey`
  login succeeds, and only then `sudo lockdown`; abort if the key doesn't work (so we
  never disable passwords while locked out). Mirrors appliance Phase 5.
- **`lockdown`/`poweroff` via NOPASSWD sudoers** (`/etc/sudoers.d/010-appliance`) —
  the locked account still needs to run these as root; NOPASSWD is unaffected by the
  locked password.

## Context

- "Client-driven first-time setup… the setup password becomes single-use" and "no
  manual key-file editing on the happy path" from [`../../../mission.md`](../../../mission.md).
- Validated on macOS + the Linux sshd fixture (cross-OS path); real first-boot
  password mode is in the end-to-end hardware checklist.

## Dependencies

- Appliance Phase 5 (`apply-setup-auth`, `lockdown`) — the server side.
- OS `ssh`/`ssh-keygen`.
