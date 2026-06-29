# Phase 4 — Plan

## 1. Read-only-root machinery (image config)

- [ ] `appliance/rootfs/opt/appliance/bin/enable-readonly-root` — enable overlayfs via
      `raspi-config nonint do_overlayfs 0`; idempotent; no-op with a clear message when
      `raspi-config` is absent (off-Pi). Leaves `/boot` writable by design.
- [ ] `appliance/rootfs/etc/appliance/fstab.tmpfs.append` — tmpfs lines for `/tmp` and
      `/var/tmp` (appended to `/etc/fstab` in Phase 7).
- [ ] `appliance/rootfs/etc/systemd/journald.conf.d/volatile.conf` — `Storage=volatile`.

## 2. Structural validation

- [ ] `appliance/tests/phase4-readonly.sh` — assert: the journald drop-in sets
      `Storage=volatile`; `fstab.tmpfs.append` declares tmpfs for `/tmp` and `/var/tmp`;
      `enable-readonly-root` passes `bash -n` and guards on `raspi-config`; and the
      write-routing invariant holds — `daemon.json` data-root is under `/mnt/appliance`
      (USB), i.e. no app-writable path targets the SD.

## 3. Docs

- [ ] Extend `appliance/rootfs/opt/appliance/README.md` with the read-only-root model
      (overlay root, writable `/boot`, tmpfs/volatile logs, all data on USB) and the
      note that power-cut resilience is hardware-validated in Phase 8.
