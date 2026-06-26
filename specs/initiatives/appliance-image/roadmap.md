# Appliance Image Roadmap

**Goal:** Deliver the standard, app-agnostic, secure, power-resilient flashable
Raspberry Pi image — the foundation the client app later drives. The client app is
a separate initiative; here, the SSH-tunnel/key access is validated manually
(`ssh -L`, manually placed key). Phases 1–6 are checkable under Docker/emulation;
7 builds the image; 8 is on-Pi stabilization.

## Phase 1: Generic noVNC container

**Goal:** A containerized GUI app reachable as noVNC with the web file manager,
bound to loopback — proven off-Pi with a throwaway sample app (no Carbide).

- [x] Run config on `jlesage/baseimage-gui` running a sample GUI app; noVNC + web
      file manager enabled.
- [x] GUI port bound to `127.0.0.1` only.
- [x] Verify on any Docker host: noVNC loads; file manager lists/uploads/deletes.
      (Automated: smoke test asserts noVNC + loopback-only. File-manager
      upload/delete + GUI render pending end-of-initiative human review.)

## Phase 2: Compose-driven app deployment from the boot folder

**Goal:** "Which app" comes from a `compose.yml` in the boot-partition config
folder; the appliance runs it and forces the GUI to loopback regardless of the
compose.

- [x] First-run logic reads `<config-folder>/compose.yml` and brings the stack up.
- [x] Mechanism guaranteeing the GUI binds loopback even if the compose publishes
      ports to `0.0.0.0`.
- [x] USB device passthrough honored from the compose (targeted `devices:` and the
      `privileged`+`/dev`+`/run/udev` escape hatch). (Pass-through by design; full
      device test deferred to Phase 8 hardware.)
- [x] Verify off-Pi: swapping the compose runs a different app; no published port
      reaches a non-loopback interface.

## Phase 3: Required USB writable store

**Goal:** A USB drive is the single writable store; app data and compose volumes
live there; the app refuses to start without it.

- [x] Auto-mount ext4 USB by label/UUID via `/etc/fstab` at a fixed path.
      (`fstab.append`, label `APPLIANCE` → `/mnt/appliance`; real mount tested Phase 8.)
- [x] App data and compose volumes routed onto the USB. (Docker `data-root` on USB +
      `${APPLIANCE_DATA}`.)
- [x] Missing USB → app does not start; reason captured for the setup log.
- [x] Verify: with USB, data persists across a container recreate; without it, the
      app halts with a clear reason.

## Phase 4: Read-only root and power resilience

**Goal:** The SD root is read-only; abrupt power loss cannot corrupt the system;
all writes route to USB/tmpfs.

- [x] Enable overlayfs read-only root; route writes to USB/tmpfs. (`enable-readonly-root`
      + tmpfs/volatile-journald config; machinery in place, mount tested Phase 8.)
- [~] Confirm app data persists on the USB across reboot. (Routing in place;
      real reboot test deferred to Phase 8 hardware.)
- [~] Verify: repeated hard power cuts leave the system bootable and USB data
      intact. (Hardware-only — Phase 8. Structural validation done off-Pi.)

## Phase 5: Secure access (host side)

**Goal:** Key-only SSH, all services loopback-bound, setup auth from the boot
folder — no default credentials, with lockdown supported.

- [x] `sshd` key-only; all services bound to `127.0.0.1`. (sshd hardening drop-in;
      app services already loopback from Phase 2.)
- [x] `setup.txt`: a pre-placed public key **or** a user-chosen one-off setup
      password mode. (`apply-setup-auth`, auto-detected.)
- [x] Lockdown step: once a key is installed, disable password auth (the setup
      password is then single-use). (`lockdown` — password off + `passwd -l` + secret wiped.)
- [x] Verify: with a pre-placed key, password auth is off and only the key works;
      nothing answers on a non-loopback interface. (Real sshd integration test, 11
      checks. LAN-interface check on hardware = Phase 8.)

## Phase 6: Headless first-boot orchestration + setup log

**Goal:** One first-boot flow reads the boot config folder, joins the network,
applies setup auth, brings up the app, and writes a setup log to the boot partition.

- [x] `wifi.txt` → network join (Wi-Fi; Ethernet works with no config). (`join-network`;
      real Wi-Fi join = Phase 8.)
- [x] A systemd first-boot service orchestrates Phases 2–5 in order.
      (`appliance-first-boot.service` → `first-boot`.)
- [x] Write `setup.log` to the boot partition (each step ✓/FAILED + reason),
      scoped to the setup phase only.
- [x] Verify (structure, off-Pi via a dry-run): `setup.log` is readable from the
      FAT boot partition after a failed/successful setup. (phase6 test: 15 checks,
      happy + failure paths.)

## Phase 7: Flashable image build (pi-gen) + CI

**Goal:** A single reproducible standard `.img` that boots into the appliance with
zero manual steps — the deliverable.

- [ ] pi-gen config (run in Docker) baking Phases 1–6 into the standard image.
- [ ] CI builds the image and publishes a release artifact.
- [ ] README: flashing, the one config folder (`wifi.txt`/`setup.txt`/`compose.yml`),
      and the USB requirement.
- [ ] Verify: flash → boot → (manual `ssh -L` tunnel) GUI in the browser; full
      smoke path deferred to Phase 8.

## Phase 8: On-Pi stabilization + Carbide acceptance

**Goal:** Shake out hardware-only issues and prove the north-star test on real
hardware.

- [ ] Triage on-Pi smoke issues (USB enumeration, file ownership, performance,
      hard power cuts).
- [ ] **Carbide acceptance:** drop a Carbide compose (Shapeoko + keypad passthrough),
      set up, and drive the machine remotely — the "done enough" bar.
- [ ] Fold any fixes back into the first-boot/provisioning source of truth.
