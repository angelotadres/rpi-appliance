# Phase 6 — Headless first-boot orchestration + setup log

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 6). One first-boot
flow joins the network, applies setup auth, brings up the app, and writes a
boot-partition setup log — each step ✓/FAILED with a reason — so a headless box is
diagnosable by pulling the SD.

## Scope

**In:**
- `join-network` — apply `wifi.txt` (Wi-Fi); Ethernet needs no config.
- `first-boot` — orchestrate Phases 2–5 in order, writing `setup.log` to the boot
  partition (each step OK/FAIL + reason), scoped to setup only.
- A systemd oneshot unit that runs `first-boot` once on boot.
- Off-Pi dry-run tests of orchestration, logging, and a failure path.

**Out:** pi-gen packaging + enabling the unit in the image (Phase 7); real Wi-Fi
join and on-Pi behavior (Phase 8). Read-only-root enablement is the *last* setup
step (it requires a reboot), gated off by default and exercised on hardware.

## Decisions

- **Order: network → setup auth → app start** (→ optional read-only-root enable +
  reboot, gated by `APPLIANCE_ENABLE_READONLY`, default off). First boot runs on a
  *writable* root so `authorized_keys` persists into the overlay's lower layer before
  read-only is turned on.
- **`setup.log` is truncated each run** and lives on the FAT boot partition (readable
  on any computer). Runtime logs are NOT here — they come from journald/`docker logs`
  (constitution), so the log is setup-scoped.
- **Network failure is logged but non-fatal** (Ethernet may still work); **auth or
  app failure aborts** setup with the reason logged.
- **Step commands are overridable via env** (`APPLIANCE_NET_CMD`/`AUTH_CMD`/`APP_CMD`)
  so the orchestration + logging are testable off-Pi without the root/Pi-only bits
  (which their own phases already cover).
- **`wifi.txt` keys:** `SSID=`, `PSK=` (or `PASSWORD=`), `COUNTRY=`; applied via
  `nmcli` on Pi OS Bookworm. Absent file → Ethernet path, logged as skipped.

## Context

- Turnkey + headless, per [`../../../mission.md`](../../../mission.md): the box configures itself from the one boot
  folder and tells you what happened via the setup log when you can't yet connect.

## Dependencies

- Phases 2–5 scripts (`compose-up`, `usb-preflight`, `apply-setup-auth`).
- External: `nmcli`/systemd on Pi (guarded off-Pi); Docker for the real app step.
