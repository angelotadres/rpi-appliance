# Sample app (Phase 1)

Throwaway, replaceable scaffolding that proves the GUI-over-web plumbing **off-Pi**:
the [`jlesage/baseimage-gui`](https://github.com/jlesage/docker-baseimage-gui) base
serving an app as noVNC plus a web file manager, bound to loopback only. See
[`../../specs/initiatives/appliance-image/generic-novnc-container/`](../../specs/initiatives/appliance-image/generic-novnc-container/).

The default app is **Candle** (open-source GPL-3.0 GRBL G-code sender) — the open
analog of the north-star CNC case. It is built from source in the `Dockerfile`, not
vendored, so this repo's recipe stays MIT. **Carbide is never the default** (it's
proprietary and consumer-supplied; see `specs/tech-stack.md` licensing).

## Run it

```sh
docker compose up -d --build
```

Open <http://127.0.0.1:5800> — Candle renders in noVNC. The web file manager browses
`./data` (drop `.gcode`/`.nc` files there). Stop with `docker compose down`.

## Verify (automated)

```sh
./smoke-test.sh
```

Builds, waits for health, asserts noVNC serves HTTP 200, and asserts the GUI port is
published on `127.0.0.1` only (never the LAN). Exits non-zero on any failure.

## Swap the app

Edit the `Dockerfile` (install a different app) and `startapp.sh` (launch it). This
container is a demo only — Phase 2 replaces it with the boot-folder `compose.yml`
deployment mechanism, and the standard image ships no app at all.
