# Client Phase 1 — Connect + tunnel + render (MVP)

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 1). Replace the manual
`ssh -L`: connect to an appliance and see its noVNC GUI in a native window.

## Scope

**In:**
- A Tauri v2 app (`client/`) that builds on macOS.
- A connect form: host, user, private-key path, remote noVNC port (5800), local port,
  SSH port (22).
- A Rust backend that opens a background tunnel via the **OS `ssh`** (`-L`, `-N`,
  key-only/BatchMode, host-key TOFU), waits for the local port, and reports the URL.
- The webview renders `http://localhost:<localport>` (noVNC) in an iframe; Disconnect
  tears the tunnel down; quitting the app kills the ssh child.

**Out:** key generation/push + lockdown (Phase 2); shutdown + settings persistence +
reconnect (Phase 3); Windows/Linux bundles + CI (Phase 4). A file-picker for the key
and code-signing are later.

## Decisions

- **Shell out to the OS `ssh`** via `std::process::Command` (not a bundled SSH stack,
  not the Tauri shell plugin) — matches tech-stack ("uses the OS `ssh`"), keeps it lean,
  and the child is managed in Tauri state.
- **`BatchMode=yes` + `StrictHostKeyChecking=accept-new` + `ExitOnForwardFailure=yes`**
  — key-only (no hanging password prompt), TOFU host key, and fail fast if the forward
  can't bind. `ServerAlive*` keeps the tunnel from silently wedging.
- **Render noVNC in an `<iframe>`** pointing at the local tunnel port; `csp: null`
  (scaffold default) is acceptable for the MVP and tightened later.
- **Vanilla-TS frontend** (no UI framework) — lean, per the constitution.

## Context

- "Turnkey / open an app" and "lean (OS webview + OS ssh)" from [`../../../mission.md`](../../../mission.md). Daily
  use is one action: connect → GUI appears; disconnect → gone.
- Hardware-tested on macOS only; the tunnel is integration-tested off-Pi against a
  local SSH→noVNC stand-in (the appliance `sshd` fixture + a noVNC container).

## Dependencies

- Rust/Tauri toolchain (installed); OS `ssh`; the appliance's key-only sshd (Phase 5)
  as the real target. Off-Pi stand-in reuses `appliance/tests/fixtures/sshd` + the
  Phase 1 sample-app image for noVNC.
