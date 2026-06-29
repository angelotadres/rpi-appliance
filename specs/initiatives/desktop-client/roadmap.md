# Desktop Client Roadmap

**Goal:** The cross-platform desktop client from [`specs/mission.md`](../../mission.md) /
[`specs/tech-stack.md`](../../tech-stack.md) — a Tauri app (Rust + OS webview, shelling
out to the OS `ssh`) that makes daily use "open an app": it opens the SSH tunnel
silently and renders the appliance's noVNC GUI as a native window, and also drives
first-time setup and shutdown over the same SSH channel. This is the consumer of the
`appliance-image` initiative (its sshd/setup/lockdown machinery).

Built and **hardware-tested on macOS only**; Windows/Linux are built in CI and flagged
unverified until someone confirms them (per tech-stack Testing Strategy). Where a step
needs a live appliance, it is exercised against a local SSH+noVNC stand-in off-Pi.

## Phase 1: Connect + tunnel + render (MVP)

**Goal:** Replace the manual `ssh -L` — connect to an appliance and see its GUI in a
native window.

- [x] Tauri app scaffold (lean: OS webview, vanilla frontend) that builds on macOS.
- [x] Settings: host, user, private-key path, remote noVNC port, local port.
- [x] Open a background tunnel via the OS `ssh` (`-L`, `-N`, key, host-key TOFU),
      wait for the local port, then render `http://localhost:<localport>` in the webview.
- [x] Disconnect tears the tunnel down; quitting the app kills the ssh child.
- [x] Tests: unit-test the `ssh` argv builder + port-wait; integration-test the tunnel
      against a local SSH→noVNC stand-in (off-Pi). (4 unit + 3 integration checks pass.
      Live render against a real appliance = end-of-initiative checklist.)

## Phase 2: First-time setup (key provisioning)

**Goal:** From a fresh appliance to key-only access without manual key editing.

- [ ] Generate a client keypair (or pick an existing key).
- [ ] Push the public key using the one-off setup password (writes `setup.txt`/
      `authorized_keys` per appliance Phase 5), then run `lockdown` over SSH.
- [ ] Surface the appliance's `setup.log`/results; handle the password→key transition.
- [ ] Tests: provisioning logic against the appliance `sshd` test fixture.

## Phase 3: Shutdown + resilience + settings persistence

**Goal:** One-action daily use that remembers you and fails gracefully.

- [ ] Shutdown action (`ssh … poweroff`) and clean disconnect.
- [ ] Persist settings (host/port/key path) between runs; never store the private key.
- [ ] Reconnect / clear error states (tunnel drop, host down, auth failure).
- [ ] Tests: settings round-trip; error-state mapping.

## Phase 4: Cross-platform build + CI

**Goal:** Installable builds for all three desktops.

- [ ] Tauri bundles for macOS, Windows, Linux built in CI; artifacts published.
- [ ] Document unsigned first-launch steps (code-signing deferred per tech-stack).
- [ ] Verify: macOS bundle runs locally; Windows/Linux built in CI (unverified until
      community-confirmed).
