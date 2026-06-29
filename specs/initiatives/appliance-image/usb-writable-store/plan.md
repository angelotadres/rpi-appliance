# Phase 3 — Plan

## 1. Mount + Docker data-root config (image fragments)

- [ ] `appliance/rootfs/etc/appliance/fstab.append` — the line appended to
      `/etc/fstab` (Phase 7): `LABEL=APPLIANCE /mnt/appliance ext4
      defaults,nofail,x-systemd.device-timeout=10s 0 2`.
- [ ] `appliance/rootfs/etc/docker/daemon.json` — `{ "data-root": "/mnt/appliance/docker" }`.

## 2. Preflight + compose-up wiring

- [ ] `appliance/rootfs/opt/appliance/bin/usb-preflight` — assert the mount path is a
      mountpoint (portable check) and writable; on failure print a one-line reason and
      exit non-zero. Knobs: `APPLIANCE_USB_MOUNT` (default `/mnt/appliance`),
      `APPLIANCE_REQUIRE_MOUNT` (default `1`).
- [ ] Extend `compose-up`: run `usb-preflight` first (refuse + reason if it fails),
      then `mkdir -p $APPLIANCE_DATA` and export `APPLIANCE_DATA` for compose
      substitution.
- [ ] `appliance/tests/usb-preflight.sh` — unit: writable mountpoint passes; missing
      dir fails; non-mountpoint (REQUIRE_MOUNT=1) fails with reason; read-only dir fails.

## 3. Persistence integration test + docs

- [ ] `appliance/tests/phase3-usb.sh` — (a) bind-mount a file into the "USB" data dir
      with busybox, recreate the container, assert the file persists; (b) run
      `compose-up` with the USB absent and `REQUIRE_MOUNT=1`, assert it exits non-zero
      with a clear reason and starts no container.
- [ ] Update `appliance/rootfs/opt/appliance/README.md` with the USB mount, data-root,
      and `${APPLIANCE_DATA}` contract.
- [ ] Resolve the USB-store open question in `specs/tech-stack.md` (label, no
      auto-format, data-root on USB).
