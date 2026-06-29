# Client Phase 2 — Validation

## Agent validates (autonomous)

- `cargo test` — arg-builders for the password session (PreferredAuthentications,
  the push command, ssh-keygen invocation) and the askpass helper contents.
- `client/tests/setup-it.sh` (Docker) — against an sshd fixture in setup-password mode
  with NOPASSWD sudo + the appliance `lockdown` script:
  - `provision` pushes the public key, a pubkey-only login then succeeds;
  - `lockdown` runs → `sshd -T` shows `passwordauthentication no`, account locked;
  - provision **aborts before lockdown** when the pushed key can't authenticate
    (lockout guard).
- `visudo -cf` accepts `010-appliance`.

## Human validates (judgment required)

- On a real freshly-flashed appliance booted with a `password=` `setup.txt`: run the
  app's First-time setup, confirm key access works afterward and the password no
  longer does. (End-to-end hardware checklist.)

## Definition of done

- [ ] Task group 1: sudoers drop-in + chmod/visudo.
- [ ] Task group 2: `setup.rs` (`generate_key`, `provision`); unit tests pass.
- [ ] Task group 3: setup view; `setup-it.sh` passes (push + lock + lockout guard).
- [ ] Agent checks green and reported.
- [ ] Mark the Phase 2 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
