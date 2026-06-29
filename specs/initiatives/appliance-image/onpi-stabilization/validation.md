# Phase 8 — Validation

## Agent validates (autonomous)

- None on hardware — the agent has no Pi. The agent's role here is limited to
  re-running the off-Pi suite (`appliance/tests/`) after any fix is folded back, and
  keeping the Phase 1–7 sources consistent.

## Human validates (judgment required — all of it)

This phase is human-on-hardware end to end:

- Flash → headless boot → `setup.log` all-OK → key-only SSH on the LAN, everything
  else loopback.
- Real ext4 USB auto-mount; data persists across reboot; **≥10 hard power cuts leave
  the system bootable and USB data intact**.
- Serial + HID passthrough enumerate into the container.
- **Carbide acceptance:** a Shapeoko + keypad driven remotely and securely from the
  shop computer through the tunnel.

## Definition of done

- [ ] Task groups 1–3 performed on a Pi and signed off by the human.
- [ ] All fixes folded back into Phases 1–7; off-Pi `appliance/tests/` still green.
- [ ] Carbide north-star test passes on hardware.
- [ ] Mark the Phase 8 checkbox in [`../roadmap.md`](../roadmap.md) as complete.

> Status: **blocked on hardware.** Spec is ready; nothing here can be checked off
> until the Pi + Shapeoko + Carbide are available.
