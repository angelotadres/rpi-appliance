# Phase 3 — Required USB writable store

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 3). A USB drive is
the single writable store; app data and Docker live there; the app refuses to start
without it. Logic proven off-Pi; the real mount is hardware-tested in Phase 8.

## Scope

**In:**
- An `/etc/fstab` entry auto-mounting an ext4 USB by **label** at a fixed path.
- Docker's `data-root` relocated onto the USB (so images, named volumes, and
  containers all live on the writable store — essential once the SD root goes
  read-only in Phase 4).
- A `${APPLIANCE_DATA}` base path on the USB that user composes reference for bind
  mounts.
- A preflight that refuses to start the app when the USB is missing/unwritable and
  emits a clear reason (consumed by the Phase 6 setup log).

**Out:** read-only SD root (Phase 4) — it's the reason data-root must move now;
first-boot orchestration + the actual setup log file (Phase 6); pi-gen wiring of
fstab/daemon.json into the image (Phase 7); real USB enumeration (Phase 8).

## Decisions

- **Mount by LABEL `APPLIANCE` at `/mnt/appliance`** — friendlier than a UUID the
  user can't know in advance; resolves the label-vs-UUID open question.
- **Require a pre-formatted ext4 drive; never auto-format** — auto-formatting risks
  wiping the wrong disk. The user formats ext4, labels it `APPLIANCE`. Resolves the
  format open question.
- **fstab uses `nofail`** — a missing USB must not wedge boot; the system still
  boots so you can SSH in / read the setup log. The *app* refusal is enforced
  separately by the preflight.
- **Docker `data-root = /mnt/appliance/docker`** via `/etc/docker/daemon.json` —
  routes all volumes/images onto the USB with stock Docker, no per-compose changes.
- **`${APPLIANCE_DATA} = /mnt/appliance/data`**, exported by `compose-up` so user
  composes can put bind mounts on the USB via env substitution.
- **Preflight = mountpoint + writability check** (`usb-preflight`), called first by
  `compose-up`. Portable mountpoint detection so it's testable off-Pi.

## Context

- Power-loss resilience and "USB is the single writable store" from [`../../../mission.md`](../../../mission.md);
  this phase sets up the writable surface that Phase 4's read-only root depends on.

## Dependencies

- Phase 2's `compose-up` (extended to call the preflight and export `APPLIANCE_DATA`).
- External: Docker; a busybox image for the off-Pi persistence test.
