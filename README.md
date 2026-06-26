# rpi-appliance

Turn a Raspberry Pi into a **secure, headless appliance** that runs one
containerized GUI app — reachable from a single trusted computer, over an
authenticated SSH tunnel, with **nothing exposed on your network**.

It comes in two parts:

- **A flashable Pi image** — standard and app-agnostic. You pick the app *after*
  flashing by dropping a `compose.yml` into one config folder; the image stays the
  same for everyone.
- **A cross-platform desktop client** — opens the SSH tunnel in the background and
  renders the app's GUI as a native window. One click in, one click out.

> **Status:** early development. The design (constitution) is set under
> [`specs/`](specs/); implementation is proceeding phase by phase per the
> [appliance-image roadmap](specs/initiatives/appliance-image/roadmap.md). Flashing
> and usage instructions will land here as the phases that build them ship.

## Why

Plenty of great desktop GUI apps would be useful on a headless Pi — but the usual
setups leave the GUI (and often SSH with a default password) open to everyone on the
LAN. `rpi-appliance` flips that: services bind to loopback only, SSH is key-only,
and the **one computer holding the key** is the only thing that can reach in.

**Motivating example — operating a CNC machine over GRBL.** The control software is
a desktop GUI app, but bolting a monitor/keyboard onto the machine is impractical,
so a headless Pi runs it. You drive it wirelessly from the shop computer you already
have, in one click — while no one else on the network can pause, stop, or disturb a
running job. The toolkit stays generic, though: the CNC controller is just one app
you could run on top of it.

## How it works

```
Your computer                          Raspberry Pi (headless, read-only SD)
┌─────────────────────┐                ┌─────────────────────────────────────┐
│ Desktop client app  │   SSH tunnel   │ sshd (key-only)                      │
│  (webview + ssh)    │ ─────key────▶  │   └▶ 127.0.0.1 : noVNC (loopback)    │
└─────────────────────┘                │        └▶ your app (Docker Compose)  │
                                        │ USB drive = the only writable store  │
                                        └─────────────────────────────────────┘
```

- **One key, one computer.** The SSH key is the single gate — for the GUI, files,
  and shutdown alike. No web password, no open ports, no default credentials.
- **Physical presence is trusted; the network is not.** Anyone at the machine (USB,
  power) is already trusted; the boundary we enforce is *remote* access.
- **Power-loss resilient.** The SD root is read-only; a **required USB drive** holds
  all data, so a yanked power cord can't corrupt the system or lose your work.
- **Customize after flashing.** One boot-partition folder holds everything you edit:
  `wifi.txt`, `setup.txt` (your one-off setup password or public key), and
  `compose.yml` (the app to run, including any USB device passthrough).

## Client app platforms

The desktop client targets **macOS, Windows, and Linux** and is built for all three
in CI. Note: the author can currently hardware-test only on **macOS** — Windows and
Linux are best-effort / community-validated until confirmed.

## License & third-party software

This project is **MIT licensed** (see [LICENSE](LICENSE)). Its dependencies are
permissively licensed (`jlesage/baseimage-gui` MIT; Tauri MIT/Apache-2.0; pi-gen
produces redistributable Raspberry Pi OS).

**The standard image ships no application software.** The app you run is supplied at
runtime via your own `compose.yml`. If that app is proprietary (for example, Carbide
Motion), its license is **your responsibility** — it is never bundled in or
distributed by this repo.

## Development

This repo follows spec-driven development; see [`AGENTS.md`](AGENTS.md) for the
workflow and [`specs/`](specs/) for the mission, tech stack, and roadmap.
