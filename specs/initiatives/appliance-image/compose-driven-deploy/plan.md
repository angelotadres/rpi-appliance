# Phase 2 — Plan

Host-side files install to the image root under `appliance/rootfs/` (pi-gen copies
this onto the image in Phase 7). Tests live under `appliance/tests/`.

## 1. compose-up script + loopback sanitize

- [ ] `appliance/rootfs/opt/appliance/bin/compose-up` — resolve `$APPLIANCE_CONFIG_DIR`
      (default `/boot/firmware/appliance`), require `compose.yml`, produce a sanitized
      runtime compose at `/run/appliance/compose.yml`, `docker compose ... up -d`.
- [ ] `appliance/rootfs/opt/appliance/lib/sanitize-compose.sh` — the `yq` transform:
      pick the GUI service (label `appliance.gui=true`, else sole service, else
      error); strip all `ports`; republish GUI as `127.0.0.1:${WEB_PORT:-5800}:5800`.
- [ ] `yq` resolver: use host `yq` if present, else `docker run --rm -i mikefarah/yq`.
- [ ] Unit test `appliance/tests/sanitize.bats`-style shell test: feed sample composes
      (0.0.0.0 ports, multiple services, long+short port syntax) and assert the
      sanitized output binds only `127.0.0.1` and keeps `devices`/`privileged`.

## 2. Off-Pi integration test (swap app + no LAN exposure)

- [ ] Fixtures: `appliance/tests/fixtures/app-candle/compose.yml` (uses Phase 1
      image, declares a `0.0.0.0:5800` port to prove it gets overridden) and
      `appliance/tests/fixtures/app-alt/` (a tiny different app — xterm on
      baseimage-gui — to prove app-swap).
- [ ] `appliance/tests/phase2-deploy.sh` — for each fixture: run `compose-up`, assert
      noVNC 200 on `127.0.0.1:5800`, assert refused on a non-loopback IP, assert the
      running image/APP_NAME matches the fixture (proves swap). Tear down between.

## 3. Docs + tech-stack note

- [ ] `appliance/rootfs/opt/appliance/README.md` — what `compose-up` does, the GUI
      label contract, the `WEB_PORT` knob, and the passthrough pass-through rule.
- [ ] Note the chosen enforcement mechanism in `specs/tech-stack.md` Open Questions
      (resolve the "compose security enforcement" item) and add `yq` to Dependencies.
