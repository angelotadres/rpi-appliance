# Phase 1 — Plan

All files live under `appliance/sample-app/`. Order matters: 1 → 2 → 3.

## 1. Container build (the sample GUI app on the base)

- [ ] `appliance/sample-app/Dockerfile` — `FROM jlesage/baseimage-gui:<pinned-tag>`,
      install Candle (build or prebuilt), set `APP_NAME`. Fall back to bCNC if the
      Qt build is too heavy under arm emulation.
- [ ] `appliance/sample-app/startapp.sh` — launches the default app; `chmod +x`.
- [ ] Build succeeds locally: `docker build` produces an image with no errors.

## 2. Compose with loopback binding + file manager

- [ ] `appliance/sample-app/compose.yml` — builds the Dockerfile, publishes
      `127.0.0.1:5800:5800` (and VNC only if needed, also loopback), sets
      `WEB_FILE_MANAGER=1` and a scoped allowed path.
- [ ] Mount a local `./data` dir as the file-manager target so list/upload/delete
      have a real surface.
- [ ] `docker compose up -d` brings the container to healthy; noVNC reachable at
      `http://127.0.0.1:5800`.

## 3. Automated smoke test + docs

- [ ] `appliance/sample-app/smoke-test.sh` — build, up, wait-for-healthy, assert
      `curl 127.0.0.1:5800` → 200, assert the port is **not** reachable on a
      non-loopback host IP (security invariant), then `compose down`. Non-zero exit
      on any failure.
- [ ] `appliance/sample-app/README.md` — one screen: how to run, how to open the
      GUI, how to swap the sample app, and that this is throwaway scaffolding.
</content>
