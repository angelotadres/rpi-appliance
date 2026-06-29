# Client Phase 4 — Validation

## Agent validates (autonomous)

- `build-client.yml` is valid YAML and references the standard Tauri steps per OS.
- Locally on macOS: `pnpm tauri build` succeeds and produces a `.app`/`.dmg` under
  `client/src-tauri/target/release/bundle/`.

The Windows/Linux bundles build in CI — not runnable on this machine; called out, not
hidden.

## Human validates (judgment required)

- The CI run produces installable artifacts for all three OSes.
- The macOS bundle launches (Gatekeeper: right-click → Open the first time).
- Windows/Linux bundles run on those platforms (community-verified).

## Definition of done

- [ ] Task group 1: `build-client.yml` matrix builds + uploads artifacts.
- [ ] Task group 2: `client/README.md` (build/run/first-launch); local macOS bundle
      builds.
- [ ] Agent checks green and reported; CI/cross-platform deferral stated.
- [ ] Mark the Phase 4 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
