# Phase 7 — Validation

## Agent validates (autonomous)

- `appliance/tests/phase7-assemble.sh` — runs the **real** `assemble-rootfs.sh`
  against a temp root (yq skipped) and asserts: `opt/appliance/bin/first-boot` (exec)
  and the other scripts, `etc/systemd/system/appliance-first-boot.service`,
  `etc/docker/daemon.json`, and `/mnt/appliance` are present; `/etc/fstab` gained the
  `LABEL=APPLIANCE` line and the tmpfs lines (and re-running doesn't duplicate them).
- Lint: every `stage-appliance` script + `build.sh` passes `bash -n`; the CI workflow
  is valid YAML.

The full pi-gen image build is **not** run here (Linux/CI-only, ~GB, ARM emulation);
it runs in CI and is flashed in Phase 8. This is called out, not hidden.

## Human validates (judgment required)

- **CI:** the `build-image.yml` run actually produces a flashable `.img.xz`.
- **On hardware (Phase 8):** flash → boot → manual `ssh -L` tunnel → GUI in the
  browser. The full smoke path is Phase 8.

## Definition of done

- [ ] Task group 1: assembler + `phase7-assemble.sh` passes.
- [ ] Task group 2: pi-gen `config`, `stage-appliance/*`, `build.sh`; all lint clean.
- [ ] Task group 3: CI workflow + README flashing section.
- [ ] Agent checks green and reported; image-build deferral stated.
- [ ] Mark the Phase 7 checkbox in [`../roadmap.md`](../roadmap.md) as complete
      (CI image build + hardware smoke tracked into Phase 8).
