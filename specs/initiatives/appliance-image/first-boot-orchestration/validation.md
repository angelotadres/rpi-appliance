# Phase 6 — Validation

## Agent validates (autonomous)

`appliance/tests/phase6-firstboot.sh`:

- **Happy path:** with `wifi.txt` + a pubkey `setup.txt` + the Candle `compose.yml`
  and a temp USB, `first-boot` produces `setup.log` on the boot partition containing
  `[ OK ]` lines for network, auth, and app, plus a "setup complete" marker, and the
  app container is running (noVNC reachable on loopback).
- **Failure path:** with the USB absent, `setup.log` shows `[FAIL]` for the app step
  with a USB reason, has no "setup complete" marker, and no app container is started.
- `first-boot` and `join-network` pass `bash -n`; the systemd unit references
  `first-boot` and is `Type=oneshot`/`RemainAfterExit=yes`.

Net/auth steps are stubbed off-Pi (covered for real in Phases 5/8); the app step and
the log itself are exercised for real.

## Human validates (judgment required)

- **On hardware (Phase 8):** real Wi-Fi join from `wifi.txt`; the unit runs once on a
  real boot; `setup.log` is readable by pulling the SD into another computer.

## Definition of done

- [ ] Task group 1: `join-network` (Wi-Fi/Ethernet/off-Pi paths).
- [ ] Task group 2: `first-boot` orchestrator + systemd unit.
- [ ] Task group 3: phase6 test passes (happy + failure); docs + `wifi.txt` sample.
- [ ] Agent checks green and reported.
- [ ] Mark the Phase 6 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
