# Test checklist (image + app)

What's **already automated and passing** vs. what **needs you** (hardware + human
judgment). Everything in Part A the agent runs; Parts B–D require a real Pi, a real
appliance, and your eyes.

## Part A — Automated, already green (re-run anytime)

```sh
appliance/tests/run-all.sh                                   # appliance Phases 1-7
cargo test --manifest-path client/src-tauri/Cargo.toml       # client unit tests
client/tests/tunnel-it.sh                                    # client tunnel render
client/tests/setup-it.sh                                     # client key push + lockdown
```

These cover: loopback enforcement, compose deploy + app swap, USB preflight + refusal,
read-only-root config, key-only sshd + setup + lockdown, first-boot + setup.log, image
assembly, the ssh tunnel rendering noVNC, and key push/lockdown. **No action needed
unless one fails.**

## Part B — Appliance image on real hardware (Phase 8)

Flash the `1.0.0-beta*` image; ext4 USB labelled `APPLIANCE`; boot folder has
`wifi.txt` + `setup.txt` (your public key) + a `compose.yml` pointing at a **pullable**
app image.

- [ ] Boots headless; `setup.log` on the boot partition shows every step `[ OK ]`.
- [ ] Wi-Fi joins from `wifi.txt` (or Ethernet works with the file removed).
- [ ] `ssh -i key pi@appliance.local` works; **password auth is refused**.
- [ ] **Nothing but SSH answers on the LAN** — e.g. `nmap appliance.local` shows only 22
      (noVNC 5800 is NOT reachable off the device).
- [ ] USB auto-mounts at `/mnt/appliance`; the app starts; app data is on the USB.
- [ ] Remove the USB → the app refuses to start and `setup.log` says why.
- [ ] Data persists across a clean reboot.
- [ ] Enable read-only root (`sudo /opt/appliance/bin/enable-readonly-root`, reboot);
      then **≥10 hard power cuts** leave it bootable and USB data intact.
- [ ] USB passthrough: a serial/HID device enumerates into the container.

## Part C — Desktop client against a real appliance

Build/install the app (`pnpm tauri build`, or the CI bundle). macOS first-launch:
right-click → **Open** (unsigned).

- [ ] **First-time setup:** with a freshly flashed appliance booted in `password=`
      mode, run setup (host/user/setup-password/key) → finishes, and afterwards the key
      works and the password no longer does.
- [ ] **Connect:** enter host/user/key → **Connect** → the appliance GUI renders in the
      window (this is the live noVNC render that off-Pi tests can't do).
- [ ] **File manager:** open the noVNC web file manager; upload and delete a file under
      the USB data dir.
- [ ] **Shut down:** the Shut down button powers the appliance off.
- [ ] **Settings persist:** relaunch the app; the form is prefilled.
- [ ] Bad host/key/password give understandable error messages.

## Part D — Cross-platform (community)

- [ ] Windows bundle (`.msi`) installs and the app launches (SmartScreen → Run anyway).
- [ ] Linux bundle (`.deb`/AppImage) installs and the app launches.

## The north star (Phase 8 acceptance)

- [ ] Drop a Carbide compose (Shapeoko GRBL serial + USB keypad), set up via the
      client, and drive the machine remotely through the tunnel. This is the
      "done enough" bar for the whole toolkit.

## Reporting

File anything that fails as a GitHub issue (or just paste me the `setup.log` /
the app's error text). Per our agreement, surfaced issues become a follow-up
bug-fixing pass.
