# Client Phase 3 — Plan

## 1. Reusable key session + shutdown

- [ ] Refactor `setup.rs` so the key-session arg builder/runner take plain
      `host/user/ssh_port/key_path` (not `SetupOpts`); update `provision`.
- [ ] `setup::shutdown(host, user, ssh_port, key_path)` → `sudo -n poweroff`; wire a
      `shutdown` command (takes `ConnectOpts`) in `lib.rs`.

## 2. Settings persistence

- [ ] `client/src-tauri/src/settings.rs` — `Settings` (host/user/key_path/ports, sane
      defaults, no secrets); `read_settings(path)`/`write_settings(path)`. Unit test the
      round-trip + defaults.
- [ ] `load_settings`/`save_settings` commands using the app config dir.

## 3. Frontend wiring

- [ ] On launch, `load_settings` prefills the connect (and setup) forms.
- [ ] On successful connect, `save_settings`.
- [ ] A "Shut down" button in the viewer bar (uses the current connection fields);
      confirm, then call `shutdown` and return to the connect panel.
