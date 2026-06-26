# Mission

## Core Purpose

`rpi-appliance` turns a Raspberry Pi into a secure, headless appliance that runs
**one containerized GUI application**, served over noVNC and reached from a single
trusted computer. It has two parts: a **flashable Pi image** (the appliance) and a
**cross-platform desktop app** (the client). You flash the image, set up the client
once, and from then on the GUI app appears as a native window on your computer —
wirelessly, with no monitor or keyboard on the Pi, and with nothing exposed on the
network for anyone else to reach.

The "which app" is a parameter, not baked in. This repo is the **generic toolkit**;
a specific app (e.g. a CNC controller) is a separate downstream consumer.

## Users

Makers and Raspberry Pi hobbyists who want to run a desktop-style GUI app on a
headless Pi and reach it securely from the **one computer they already have** — no
extra operator workstation, no trust in the shared LAN, minimal setup.

**Concrete example:** operating a CNC machine over GRBL. The control software is a
desktop GUI app, but bolting a monitor, keyboard, and mouse onto the machine is
impractical — so a headless Pi runs it instead. The maker already has a computer in
the shop and just wants to drive the machine from it, wirelessly and in one click,
while no one else on the network can reach in and disturb a running job. That use
case drives the design — but the toolkit stays generic: the CNC controller is one
app among many a consumer could ship on top of it.

## Problems Solved

- **Open-by-default appliances.** Typical Pi GUI setups expose the GUI (and often
  SSH with a default password) to everyone on the LAN. Here, services bind to
  loopback only and are reachable solely through an authenticated SSH tunnel.
- **Default/shared credentials.** No hardcoded password ever ships; access is
  gated by an SSH key tied to one computer.
- **Setup friction.** The client app handles SSH key generation, key provisioning,
  the tunnel, and rendering the GUI — so the daily experience is "open an app."
- **Headless GUI apps with no screen.** Desktop GUI software runs on a Pi that has
  no monitor, driven from a browser-class webview on the user's machine.

## Key Capabilities

1. Flashable Pi image that auto-boots one containerized GUI app as noVNC.
2. SSH key-only access; all appliance services bound to loopback (never on the LAN).
3. Boot-partition setup: Wi-Fi config plus a one-off setup password **or** a
   pre-placed public key — no default credentials.
4. Desktop client that opens the SSH tunnel silently and renders the GUI as a
   native app (no terminal window).
5. Client-driven first-time setup: generate keypair, push public key, lock the Pi
   to key-only — the setup password becomes single-use.
6. In-GUI web file manager for moving files to/from the appliance over the tunnel.
7. **Power-loss resilient by design:** the SD card root is read-only (overlayfs);
   **a USB drive is required** and is the single writable store for all app data, so
   an abrupt power cut can never corrupt the system or lose data.

## Success Metrics

- A freshly flashed Pi is reachable **only** through the client (no GUI, SSH
  password, or other service answers on the LAN after setup).
- First setup — from flash to GUI-in-the-app — takes a handful of steps and no
  manual key-file editing on the happy path.
- Daily use is one action: open the app → the GUI appears; close it → disconnected.
- The image is app-agnostic: pointing it at a different container yields a working
  appliance with no changes to the security/access machinery.
- **North-star acceptance test:** the generic toolkit is "done enough" when it can
  run the original CNC use case end-to-end — a Shapeoko (GRBL serial) and a USB
  keypad passed through to Carbide Motion, driven remotely and securely from the
  shop computer, exactly as originally planned. Carbide validates the generic design.

## Scope: Included

- The generic noVNC appliance image (pi-gen) with the security/access model.
- The cross-platform desktop client app (tunnel + webview + setup + shutdown).
- Boot-partition config (Wi-Fi + setup auth) and the in-GUI web file manager.
- Read-only SD root plus a **required** USB writable store for all data
  (power-loss resilience).
- First-boot/setup diagnostics written to the boot partition (readable by pulling
  the SD into any computer when you can't yet connect).

## Scope: Deferred

- **App-specific config (e.g. Carbide Motion)** — lives in a separate consumer repo.
- **USB hardware passthrough specifics** (serial/HID for CNC etc.) — a consumer
  concern; the image may expose a generic passthrough toggle only.
- **Code-signing / notarization of the client app** — a known one-off cost, decided
  at release time; ship unsigned with documented first-launch steps until then.
- **Multi-appliance management in the client** — nice-to-have, not v1.

## Design Philosophy

- **Physical presence is trusted; the network is not.** The boundary we enforce is
  *remote* access — someone reaching the appliance over the network without being in
  the room. Anyone physically at the machine (USB ports, power) is already trusted,
  so local device passthrough never conflicts with the security model.
- **Secure by default** — no open services on the LAN, no default credentials.
- **One key, one computer** — the SSH key is the single gate for everything.
- **Offline / LAN-only** — no SaaS, VPN, or cloud control plane.
- **Turnkey** — flash and go; the client app hides the plumbing.
- **Lean** — the client uses the OS webview and the OS `ssh`, not bundled Chromium.
- **Generic** — app-agnostic; a specific app is always a consumer, never baked in.
