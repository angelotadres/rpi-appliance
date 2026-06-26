# Phase 3 — Validation

## Agent validates (autonomous)

- `appliance/tests/usb-preflight.sh` — a writable mountpoint passes; a missing path,
  a non-mountpoint (with `APPLIANCE_REQUIRE_MOUNT=1`), and a read-only path each fail
  with a non-empty reason on stderr.
- `appliance/tests/phase3-usb.sh` — (a) a file written into the USB data dir survives
  a container delete + recreate (persistence); (b) `compose-up` with the USB absent
  and `REQUIRE_MOUNT=1` exits non-zero, prints a clear reason, and starts no container.
- Static: `daemon.json` is valid JSON; the `fstab.append` line has 6 fields and uses
  `nofail`.

## Human validates (judgment required)

- **On real hardware (Phase 8):** that an ext4 drive labelled `APPLIANCE` actually
  auto-mounts at `/mnt/appliance`, Docker stores data there, and data survives a real
  power cut. Off-Pi we prove the *logic*, not the kernel mount.

## Definition of done

- [ ] Task group 1: `fstab.append` + `daemon.json` present and valid.
- [ ] Task group 2: `usb-preflight` written; `compose-up` calls it and exports
      `APPLIANCE_DATA`; preflight unit test passes.
- [ ] Task group 3: persistence + refusal integration test passes; README + tech-stack
      updated.
- [ ] Agent checks green and reported.
- [ ] Mark the Phase 3 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
