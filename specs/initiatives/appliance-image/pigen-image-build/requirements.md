# Phase 7 — Flashable image build (pi-gen) + CI

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 7). One reproducible
standard `.img` that boots into the appliance with zero manual steps. The full build
runs in CI (and is flashed in Phase 8); off-Pi we author and **dry-run-validate** the
rootfs assembly.

## Scope

**In:**
- A pi-gen custom stage that bakes Phases 1–6 into a Bookworm Lite image: installs
  Docker + compose v2 + `yq`, lays down `appliance/rootfs/`, appends the fstab
  fragments, creates the USB mountpoint, enables the first-boot service, and locks the
  default account to key-only.
- `build.sh` to assemble the stage and run pi-gen in Docker.
- A CI workflow that builds the image and publishes it as a release/artifact.
- Top-level README: flashing, the one boot-config folder, the USB requirement.

**Out:** the standard image **ships no application software** (the app comes from the
user's `compose.yml`); an optional baked-in app is a deferred convenience, not here.
Real flash/boot/tunnel smoke is Phase 8.

## Decisions

- **pi-gen, run via its Docker build** — official, reproducible (tech-stack). Our
  stage is self-contained inside the pi-gen tree (its run scripts can't see arbitrary
  host paths), so `build.sh` copies `appliance/rootfs/` + the assembler into the stage.
- **Docker + compose v2 from `get.docker.com`** in-chroot — Debian's `docker.io`
  lacks the compose v2 plugin `compose-up` needs.
- **`yq` installed as a single pinned binary** to `/usr/local/bin`.
- **Assembly logic factored into `lib/assemble-rootfs.sh`** — the same script the
  pi-gen stage runs and the off-Pi test runs, so the copy/fstab/mountpoint logic is
  actually validated.
- **No default credential:** the first user's password is locked in-chroot; access is
  via `setup.txt` at first boot (Phase 5).

## Context

- "Flash and go" turnkey, one published app-agnostic image, per [`../../../mission.md`](../../../mission.md)/tech-stack.
- The author can only hardware-test on macOS; the image build itself is
  CI/Linux-only, so this phase is **structurally** validated here and built in CI.

## Dependencies

- All of Phases 1–6 (`appliance/rootfs/`).
- External: pi-gen, Docker/binfmt (CI), GitHub Actions.
