# Appliance host scripts (`/opt/appliance`)

Host-side logic baked into the image (pi-gen copies `appliance/rootfs/` onto the
image root in Phase 7). The first-boot service (Phase 6) calls these.

## `bin/compose-up`

Runs the USB preflight, enforces the loopback invariant, and brings the app stack up.

- `APPLIANCE_CONFIG_DIR` — where `compose.yml` lives (default `/boot/firmware/appliance`).
- `APPLIANCE_RUNTIME_DIR` — where the sanitized compose is written (default `/run/appliance`).
- `APPLIANCE_USB_MOUNT` — required USB writable store (default `/mnt/appliance`).
- `WEB_PORT` — host loopback port for the GUI (default `5800`).

It exports `APPLIANCE_DATA` (default `/mnt/appliance/data`) before running compose, so
user composes can place bind mounts on the USB via `${APPLIANCE_DATA}/...`.

## `bin/usb-preflight` — the required writable store

The USB drive (ext4, labelled `APPLIANCE`, mounted at `/mnt/appliance`) is the single
writable store. `compose-up` calls this first and **refuses to start the app** if the
drive is missing or unwritable, printing a one-line reason (captured by the Phase 6
setup log). Docker's `data-root` is relocated onto the USB (`etc/docker/daemon.json`)
so all images and named volumes live there too — required once the SD root goes
read-only (Phase 4). The drive must be pre-formatted ext4; the appliance never
auto-formats.

It runs `docker compose` with `--project-directory $APPLIANCE_CONFIG_DIR`, so the
user's relative build contexts and bind-mount paths still resolve.

## `lib/sanitize-compose.sh` — the loopback guarantee

The appliance, not the user, guarantees the GUI is never on the LAN. The transform:

1. **Strips every service's `ports`** — nothing the compose declares can publish to
   the host/LAN (even `0.0.0.0:...`).
2. **Republishes only the GUI service** as `127.0.0.1:${WEB_PORT}:5800`.

Everything else — `devices`, `group_add`, `privileged`, `volumes`, `environment` —
passes through untouched, so USB passthrough is honored for free.

### GUI service contract

The user's `compose.yml` must let the appliance find the GUI service:

- Label it `appliance.gui: "true"` (labels in **map** form), **or**
- have exactly one service (then it is the GUI).

Multiple services with none labelled is an error. The GUI service must expose the
base image's web port `5800` (true for anything built on `jlesage/baseimage-gui`).

Uses [`yq`](https://github.com/mikefarah/yq) for the YAML edit; falls back to a
dockerized `yq` when no host binary is present (so dev hosts/CI need no install).
