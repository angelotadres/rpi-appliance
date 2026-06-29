# Client Phase 1 — Plan

App lives in `client/` (Tauri v2, scaffolded).

## 1. Rust tunnel backend

- [ ] `client/src-tauri/src/ssh.rs` — `ConnectOpts`, a pure `ssh_args()` builder,
      `wait_for_port()`, `spawn_ssh()`. Unit tests for the argv builder + port-wait.
- [ ] `client/src-tauri/src/lib.rs` — `Tunnel` state (managed child); `connect`
      (tear down any existing, spawn, wait for port, capture ssh stderr on failure) and
      `disconnect` commands; kill the child on window-destroyed.

## 2. Frontend (connect form + render)

- [ ] `client/index.html` + `client/src/main.ts` + styles — a connect form
      (host/user/key/ports), Connect/Disconnect, status line, and a full-window iframe
      that loads the tunnel URL on success and clears on disconnect.
- [ ] Map backend errors to a readable status message.

## 3. Build, test, and off-Pi tunnel integration

- [ ] `pnpm install`; `cargo test` (ssh unit tests) green; `cargo build` compiles.
- [ ] `client/tests/tunnel-it.sh` — bring up the appliance `sshd` fixture wired to the
      Phase 1 noVNC image on a loopback port, install a throwaway key, then drive the
      *same* `ssh -L` invocation the app uses and assert noVNC answers through the
      tunnel (HTTP 200) and the port closes after teardown. Proves the tunnel path
      without a Pi.
