# Phase 6 — Plan

## 1. Network join

- [ ] `appliance/rootfs/opt/appliance/bin/join-network` — parse `$CONFIG/wifi.txt`
      (`SSID=`, `PSK=`/`PASSWORD=`, `COUNTRY=`); apply via `nmcli` on Pi. No `wifi.txt`
      → Ethernet path (success, "no wifi.txt — assuming Ethernet"). No `nmcli` (off-Pi)
      → skip with a clear message. Never print the PSK.

## 2. Orchestrator + setup log

- [ ] `appliance/rootfs/opt/appliance/bin/first-boot` — truncate `setup.log` on the
      boot partition, then run network → auth → app, logging `[ OK ]`/`[FAIL]` + reason
      per step (UTC timestamps). Network failure non-fatal; auth/app failure aborts.
      Optional final step: `enable-readonly-root` + reboot when `APPLIANCE_ENABLE_READONLY=1`.
      Step commands overridable via `APPLIANCE_NET_CMD`/`AUTH_CMD`/`APP_CMD`.
- [ ] `appliance/rootfs/etc/systemd/system/appliance-first-boot.service` — oneshot,
      `After=network-online.target docker.service`, `RemainAfterExit=yes`, runs
      `first-boot`.

## 3. Tests + docs

- [ ] `appliance/tests/phase6-firstboot.sh` — happy path: config dir with
      `wifi.txt`+`setup.txt`+`compose.yml`, temp USB; stub net/auth, **real** app step;
      assert `setup.log` exists on the boot dir with `[ OK ]` for network/auth/app and
      "setup complete", and the app is running. Failure path: USB absent → `setup.log`
      shows `[FAIL]` for app with a USB reason and no "setup complete"; app not up.
- [ ] `appliance/rootfs/opt/appliance/bin` README section + a `wifi.txt` sample under
      docs; note the systemd unit is enabled by pi-gen in Phase 7.
