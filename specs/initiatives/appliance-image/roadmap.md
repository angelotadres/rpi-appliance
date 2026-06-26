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

- [ ] Auto-mount ext4 USB by label/UUID via `/etc/fstab` at a fixed path.
- [ ] App data and compose volumes routed onto the USB.
- [ ] Missing USB → app does not start; reason captured for the setup log.
- [ ] Verify: with USB, data persists across a container recreate; without it, the
      app halts with a clear reason.

## Phase 4: Read-only root and power resilience

**Goal:** The SD root is read-only; abrupt power loss cannot corrupt the system;
all writes route to USB/tmpfs.

- [ ] Enable overlayfs read-only root; route writes to USB/tmpfs.
- [ ] Confirm app data persists on the USB across reboot.
- [ ] Verify: repeated hard power cuts leave the system bootable and USB data
      intact (emulated where possible; real cuts deferred to Phase 8).

## Phase 5: Secure access (host side)

**Goal:** Key-only SSH, all services loopback-bound, setup auth from the boot
folder — no default credentials, with lockdown supported.

- [ ] `sshd` key-only; all services bound to `127.0.0.1`.
- [ ] `setup.txt`: a pre-placed public key **or** a user-chosen one-off setup
      password mode.
- [ ] Lockdown step: once a key is installed, disable password auth (the setup
      password is then single-use).
- [ ] Verify: with a pre-placed key, password auth is off and only the key works;
      nothing answers on a non-loopback interface. (Automated key push = client
      initiative.)

## Phase 6: Headless first-boot orchestration + setup log

**Goal:** One first-boot flow reads the boot config folder, joins the network,
applies setup auth, brings up the app, and writes a setup log to the boot partition.

- [ ] `wifi.txt` → network join (Wi-Fi; Ethernet works with no config).
- [ ] A systemd first-boot service orchestrates Phases 2–5 in order.
- [ ] Write `setup.log` to the boot partition (each step ✓/FAILED + reason),
      scoped to the setup phase only.
- [ ] Verify (structure, off-Pi via a dry-run): `setup.log` is readable from the
      FAT boot partition after a failed/successful setup.

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
