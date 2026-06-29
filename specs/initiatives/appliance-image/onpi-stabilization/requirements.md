# Phase 8 — On-Pi stabilization + Carbide acceptance

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 8). Shake out
hardware-only issues and prove the north-star test on real hardware. **This phase
cannot be completed without physical hardware** — it is the deferred home for
everything Phases 1–7 marked "validated on hardware in Phase 8".

## Scope

**In (requires hardware):**
- Flash the standard image to a Pi; boot headless; confirm first-boot setup +
  `setup.log`, Wi-Fi join, key-only SSH on the LAN with all else loopback.
- USB writable store: real ext4 auto-mount by label; data survives reboot; **repeated
  hard power cuts** leave the system bootable and USB data intact (overlayfs proof).
- USB peripheral passthrough: serial + HID enumeration into the container.
- **Carbide acceptance:** drop a Carbide compose (Shapeoko GRBL serial + USB keypad),
  set up via `setup.txt`, and drive the machine remotely through the tunnel.
- Fold any fixes back into the Phase 1–7 source of truth (and re-run the off-Pi tests).

**Out:** the desktop client (separate initiative). Carbide Motion itself is
proprietary and **consumer-supplied** — never committed here.

## Decisions

- **Carbide is validated with the real proprietary app** the consumer supplies; the
  open Candle sample proves the same GRBL-serial + passthrough *mechanics* off-Pi, so
  hardware bring-up isn't the first time the path runs.
- **Collected, not piecemeal:** items deferred from earlier phases (real overlay
  mount, power cuts, Wi-Fi, LAN-interface checks, image flash/boot) are validated
  here as one hardware pass, per the roadmap's design.

## Context

- The north-star acceptance test from [`../../../mission.md`](../../../mission.md): a Shapeoko + keypad passed
  through to the controller, driven remotely and securely from the shop computer —
  the "done enough" bar for the generic toolkit.

## Dependencies

- A Raspberry Pi, an ext4 USB drive, a Shapeoko (GRBL serial) + USB keypad, and the
  consumer's Carbide Motion container. The CI-built image from Phase 7.
