# rpi-appliance desktop client

A lean Tauri app (Rust + OS webview) that opens the SSH tunnel to your appliance and
renders its noVNC GUI as a native window — plus first-time setup (key push + lockdown)
and shutdown. It shells out to the **OS `ssh`/`ssh-keygen`** (no bundled SSH stack).

See the initiative specs under
[`specs/initiatives/desktop-client/`](../specs/initiatives/desktop-client/) and the
[development guide](../docs/development.md).

## Prerequisites

- Rust (stable) + the [Tauri v2 system deps](https://tauri.app/start/prerequisites/)
  for your OS (Linux needs `libwebkit2gtk-4.1-dev` et al — see `build-client.yml`).
- Node 20+ and `pnpm`.
- OpenSSH on PATH (`ssh`, `ssh-keygen`) — built into macOS/Linux and Windows 10+.

## Develop

```sh
pnpm install
pnpm tauri dev      # hot-reload dev build
```

## Build a bundle

```sh
pnpm tauri build    # -> src-tauri/target/release/bundle/ (.app/.dmg, .msi, .deb/.AppImage)
```

CI (`.github/workflows/build-client.yml`) builds all three OSes; a `client-v*` tag
attaches the bundles to a release.

## First launch (unsigned)

The app ships **unsigned** for now (code-signing is deferred), so the OS will warn on
first launch:

- **macOS:** right-click the app → **Open**, then confirm (or
  `xattr -dr com.apple.quarantine "rpi-appliance.app"`).
- **Windows:** SmartScreen → **More info** → **Run anyway**.
- **Linux:** mark the AppImage executable (`chmod +x`) or install the `.deb`.

## Tests

```sh
cargo test --manifest-path src-tauri/Cargo.toml   # unit tests (ssh args, setup, settings)
./tests/tunnel-it.sh                              # tunnel render (Docker)
./tests/setup-it.sh                               # key push + lockdown (Docker)
```
