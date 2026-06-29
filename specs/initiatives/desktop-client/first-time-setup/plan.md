# Client Phase 2 — Plan

## 1. Appliance dependency: NOPASSWD sudoers

- [ ] `appliance/rootfs/etc/sudoers.d/010-appliance` — appliance user may run
      `/opt/appliance/bin/lockdown` and `poweroff`/`shutdown` without a password.
- [ ] `03-run-chroot.sh` — `chmod 440` the sudoers drop-in (and `visudo -cf` check).

## 2. Rust setup backend

- [ ] `client/src-tauri/src/setup.rs` — `generate_key(path)` (ssh-keygen ed25519, no
      overwrite); `password_ssh()` helper using a temp `SSH_ASKPASS` script; pure
      arg-builders for the password session. Unit tests for the arg builders + the
      askpass script contents.
- [ ] `provision(opts)` command — push pubkey (stdin → `authorized_keys`, deduped),
      verify a pubkey-only login, then `sudo lockdown`; return a step log. Wire
      `generate_key` + `provision` into `lib.rs`.

## 3. Frontend + integration test

- [ ] A "First-time setup" view: host/user/setup-password/key-path → Generate key →
      Set up; on success, prefill the connect form's host/user/key.
- [ ] `client/tests/setup-it.sh` — sshd fixture with a password user, NOPASSWD sudo,
      and the appliance `lockdown` script: run the client's provision path; assert the
      key gets installed, key login works, lockdown turns password auth off and locks
      the account; assert provision **aborts** if the key can't log in (no lockout).
