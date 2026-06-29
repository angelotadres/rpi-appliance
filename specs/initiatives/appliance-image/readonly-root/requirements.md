# Phase 4 — Read-only root and power resilience

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 4). The SD root is
read-only (overlayfs); writes route to USB/tmpfs; an abrupt power cut can't corrupt
the system. **Real power-cut testing is deferred to Phase 8** (needs hardware); this
phase installs and structurally validates the machinery.

## Scope

**In:**
- A script that enables Raspberry Pi OS overlayfs read-only root.
- tmpfs for volatile write paths (`/tmp`, `/var/tmp`) and volatile journald logging,
  so nothing app/runtime writes lands on the SD.
- Structural/off-Pi validation that the config is well-formed and that no
  app-writable path targets the SD (data-root + app data are on the USB, per Phase 3).

**Out:** the actual overlay mount + repeated hard-power-cut resilience (Phase 8,
hardware); pi-gen baking these in (Phase 7); the setup-log writer (Phase 6).

## Decisions

- **Overlayfs via `raspi-config nonint do_overlayfs 0`** — stock Pi OS tooling, the
  documented way to get a RAM-overlay read-only root; no bespoke initramfs.
- **Keep the `/boot` (FAT) partition writable** — *not* read-only. The Phase 6 setup
  log is written there; leaving it writable avoids a remount dance. The write window
  is tiny and first-boot-only; accepted trade-off vs. a remount-rw-per-write scheme.
- **Volatile journald (`Storage=volatile`) + tmpfs `/tmp`,`/var/tmp`** — runtime
  writes go to RAM, not the overlay/SD; logs are ephemeral (runtime logs come from
  `journalctl`/`docker logs`, per the constitution, not persisted).
- **Docker data-root + app data already on USB (Phase 3)** — so enabling a read-only
  root needs no further write-routing for the app.

## Context

- Power-loss resilience by design, per [`../../../mission.md`](../../../mission.md): the SD has nothing writable to
  corrupt; the USB holds all data. This phase makes the SD side read-only.

## Dependencies

- Phase 3 (USB store + Docker data-root on USB) — the writable target.
- Hardware (a Pi) for the real validation in Phase 8.
