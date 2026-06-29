# Development guide

How to build, test, and work on `rpi-appliance`. The project has two halves, each its
own initiative under [`specs/initiatives/`](../specs/initiatives/):

- **`appliance/`** — the Raspberry Pi image (host scripts + pi-gen build).
- **`client/`** — the cross-platform Tauri desktop app.

Read [`AGENTS.md`](../AGENTS.md) for the spec-driven workflow and
[`specs/`](../specs/) for the mission, tech stack, and roadmaps before changing
behavior.

## Repo layout

```
appliance/
  sample-app/        dev noVNC container (Candle) for off-Pi testing
  rootfs/            files laid onto the Pi image (/opt/appliance, /etc, systemd units)
  image/             pi-gen stage + build.sh + assemble-rootfs.sh
  boot-config-sample/ sample wifi.txt / setup.txt / compose.yml
  tests/             off-Pi test suite (run-all.sh)
client/
  src/               frontend (vanilla TS)
  src-tauri/         Rust backend (ssh tunnel, setup, settings)
  tests/             tunnel + setup integration tests (Docker)
.github/workflows/   build-image.yml, build-client.yml
specs/               constitution + initiatives (the source of truth)
docs/                this guide + the test checklist
```

## Prerequisites

- **Docker** (with Compose v2) — runs the whole off-Pi appliance test suite and the
  client integration tests.
- **Rust** (stable, via rustup) + **Node 20+** + **pnpm** — for the client.
- Tauri v2 system deps for your OS — https://tauri.app/start/prerequisites/ (Linux
  needs `libwebkit2gtk-4.1-dev` and friends; see `.github/workflows/build-client.yml`).
- **OpenSSH** on PATH (built into macOS/Linux, Windows 10+).
- For building the Pi image locally: a **Linux host** with Docker + binfmt/qemu (the
  image build is otherwise done in CI).

## Appliance (the image)

Everything except the final `.img` build runs off-Pi on any Docker host.

```sh
# Run the dev noVNC app (Candle) and see it in a browser:
cd appliance/sample-app && docker compose up -d --build   # http://127.0.0.1:5800

# Run the full off-Pi test suite (Phases 1-7):
appliance/tests/run-all.sh
```

Individual tests live in `appliance/tests/` (compose sanitize/deploy, USB preflight,
read-only-root config, sshd secure-access, first-boot orchestration, image assembly).

### Build the flashable image

Done in CI (`build-image.yml`) on a version tag (`v*` or `1.0.0-*`). Locally on Linux:

```sh
appliance/image/build.sh        # clones pi-gen, runs it in Docker -> .pi-gen/deploy/*.img.xz
```

## Client (the app)

```sh
cd client
pnpm install
pnpm tauri dev                  # hot-reload dev build

cargo test --manifest-path src-tauri/Cargo.toml   # unit tests
./tests/tunnel-it.sh            # tunnel renders noVNC (Docker)
./tests/setup-it.sh             # key push + lockdown (Docker)

pnpm tauri build                # bundle -> src-tauri/target/release/bundle/
```

CI (`build-client.yml`) builds macOS/Windows/Linux bundles; a `client-v*` tag attaches
them to a release. The app is unsigned for now — see `client/README.md` for first-launch
steps.

## How the two halves connect

The client shells out to the OS `ssh`:

1. **Tunnel** — `ssh -L <local>:127.0.0.1:5800 user@host` to the appliance's
   loopback-only noVNC, rendered in the webview.
2. **First-time setup** — pushes your public key over the one-off setup password
   (`SSH_ASKPASS`), verifies a key-only login, then runs the appliance `lockdown`.
3. **Shutdown** — `sudo -n poweroff` over the key session (NOPASSWD sudoers).

The appliance guarantees the security invariants regardless of the client: services
loopback-bound, key-only SSH, no default credentials.

## Conventions

Spec-driven: no code before a phase's spec trio exists; one commit per phase; off-Pi
tests are the teeth of each `validation.md`. Hardware-only checks (real Pi, power cuts,
Carbide, live GUI render) are collected in the [test checklist](test-checklist.md).
