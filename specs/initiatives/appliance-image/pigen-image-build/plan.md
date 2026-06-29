# Phase 7 — Plan

## 1. Reusable rootfs assembler (testable core)

- [ ] `appliance/image/lib/assemble-rootfs.sh <ROOTFS_DIR> <SRC_ROOTFS>` — copy the
      appliance overlay; append `fstab.append` + `fstab.tmpfs.append` to `/etc/fstab`
      (idempotent); create `/mnt/appliance`; install pinned `yq` (skippable via
      `APPLIANCE_SKIP_YQ=1` for tests); set exec bits.
- [ ] `appliance/tests/phase7-assemble.sh` — run the assembler against a temp
      `ROOTFS_DIR` (skip yq); assert the scripts, systemd unit, `daemon.json`, and
      mountpoint land, and `/etc/fstab` has the USB + tmpfs lines.

## 2. pi-gen stage + build script

- [ ] `appliance/image/config` — pi-gen config (Bookworm Lite, hostname `appliance`,
      `ENABLE_SSH=1`, first user, local `STAGE_LIST`).
- [ ] `appliance/image/stage-appliance/` — `prerun.sh`, `00-packages`
      (`ca-certificates`,`curl`), `01-run-chroot.sh` (Docker+compose via get.docker.com),
      `02-run.sh` (calls the assembler on `files/`), `03-run-chroot.sh` (enable
      `appliance-first-boot`+`docker`, add user to `docker`, lock the account).
- [ ] `appliance/image/build.sh` — clone pi-gen, copy `appliance/rootfs/` + assembler
      into `stage-appliance/files/`, drop in `config`, run `./build-docker.sh`.
- [ ] Lint: all stage scripts pass `bash -n`.

## 3. CI + README

- [ ] `.github/workflows/build-image.yml` — on tag/manual: run `build.sh`, upload the
      `.img.xz` artifact and attach to a release.
- [ ] Rewrite the top-level `README.md` flashing section: flash → edit the one
      boot-config folder (`wifi.txt`/`setup.txt`/`compose.yml`) → plug the labelled USB
      → boot; link the constitution.
