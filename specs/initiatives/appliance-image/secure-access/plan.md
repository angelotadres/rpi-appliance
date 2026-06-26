# Phase 5 — Plan

## 1. sshd hardening + setup-auth script

- [ ] `appliance/rootfs/etc/ssh/sshd_config.d/10-appliance.conf` — key-only baseline:
      `PasswordAuthentication no`, `PubkeyAuthentication yes`, `PermitRootLogin no`,
      `KbdInteractiveAuthentication no`, `X11Forwarding no`, `AllowTcpForwarding yes`.
- [ ] `appliance/rootfs/opt/appliance/bin/apply-setup-auth` — parse `setup.txt`;
      pubkey → install `authorized_keys` (correct perms/owner) + password-off drop-in;
      `password=…` → set the user password + temporary password-on drop-in; unknown →
      error with reason. Knobs: `APPLIANCE_CONFIG_DIR`, `APPLIANCE_USER`,
      `SSHD_SETUP_DROPIN`.

## 2. Lockdown

- [ ] `appliance/rootfs/opt/appliance/bin/lockdown` — refuse if no `authorized_keys`
      key (don't lock yourself out); else write password-off drop-in, `passwd -l` the
      user, strip the `password=` line from `setup.txt`, reload sshd if running.

## 3. Off-Pi SSH integration test + docs

- [ ] `appliance/tests/fixtures/sshd/Dockerfile` — debian + `openssh-server` + the
      drop-in + `opt/appliance/bin` + a test user.
- [ ] `appliance/tests/phase5-ssh.sh` — pubkey mode: real `ssh -i` login succeeds,
      password method is refused; password mode: `sshd -T` shows password auth on,
      then `lockdown` turns it off + locks the account, and key login still works.
- [ ] Document the `setup.txt` formats and lockdown in the boot-folder docs and
      resolve the setup-password-lifecycle open question in `tech-stack.md`.
