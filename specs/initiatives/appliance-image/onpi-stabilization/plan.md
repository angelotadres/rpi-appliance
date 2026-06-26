# Phase 8 — Plan (on hardware)

All task groups require a physical Pi. Treat each as a checklist run on the device;
fold fixes back into the Phase 1–7 sources and re-run the off-Pi suite.

## 1. Flash + first-boot bring-up

- [ ] Flash the Phase 7 image; boot headless with `wifi.txt`+`setup.txt`(pubkey)+
      `compose.yml` and the labelled ext4 USB.
- [ ] Confirm `setup.log` shows all steps OK; Wi-Fi joined; `ssh -i key` works and
      passwords are refused; only sshd answers on the LAN (every other port loopback).

## 2. USB store + read-only root resilience

- [ ] Confirm the USB auto-mounts by label at `/mnt/appliance`; Docker data + app data
      live there; data survives a clean reboot.
- [ ] Enable read-only root; confirm overlay is active; **repeated hard power cuts**
      (yank power mid-run, ≥10×) leave the system bootable and USB data intact.
- [ ] Confirm the app refuses to start with the USB removed, and `setup.log` says why.

## 3. Passthrough + Carbide acceptance

- [ ] Serial + HID passthrough: `ttyUSB*/ttyACM*` and the keypad enumerate into the
      container (targeted `devices:` first; the `privileged`+`/dev`+`/run/udev` escape
      hatch if enumeration is unstable).
- [ ] **Carbide acceptance:** drop the consumer's Carbide compose (Shapeoko + keypad),
      set up via the client/manual key, and drive the machine remotely through the
      tunnel — the "done enough" bar.
- [ ] Triage perf without emulation; fold all fixes back; re-run `appliance/tests/`.
