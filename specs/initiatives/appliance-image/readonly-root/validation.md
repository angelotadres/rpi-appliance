# Phase 4 — Validation

## Agent validates (autonomous)

`appliance/tests/phase4-readonly.sh` asserts (all static/off-Pi):

- `journald.conf.d/volatile.conf` sets `Storage=volatile`.
- `fstab.tmpfs.append` declares tmpfs mounts for `/tmp` and `/var/tmp`.
- `enable-readonly-root` is valid bash (`bash -n`) and guards on `raspi-config`
  presence (won't blow up off-Pi).
- Write-routing invariant: `etc/docker/daemon.json` data-root is under
  `/mnt/appliance` — no app-writable path targets the SD.

No behavioral test here: enabling overlayfs requires the Pi kernel and a reboot.

## Human validates (judgment required)

- **On real hardware (Phase 8):** overlayfs actually mounts read-only; app data on
  the USB survives reboot; **repeated hard power cuts leave the system bootable and
  USB data intact.** This is the core resilience claim and can only be proven on a Pi.

## Definition of done

- [ ] Task group 1: `enable-readonly-root`, `fstab.tmpfs.append`, journald drop-in present.
- [ ] Task group 2: `phase4-readonly.sh` passes.
- [ ] Task group 3: README updated.
- [ ] Agent checks green and reported.
- [ ] Mark the Phase 4 checkbox in [`../roadmap.md`](../roadmap.md) as complete
      (real power-cut validation tracked under Phase 8).
