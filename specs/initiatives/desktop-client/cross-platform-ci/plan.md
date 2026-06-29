# Client Phase 4 — Plan

## 1. CI workflow

- [ ] `.github/workflows/build-client.yml` — matrix (macOS/Windows/Linux): checkout,
      Node+pnpm, Rust (+ cache), Linux webkit deps, `pnpm install`, `pnpm tauri build`;
      upload `client/src-tauri/target/release/bundle/**` as per-OS artifacts; on a
      `client-v*` tag, attach bundles to a release. Triggers: push/PR (build check on
      client changes), tag, manual.

## 2. Docs + local verification

- [ ] Replace the scaffold `client/README.md` with build/run + unsigned first-launch
      steps (macOS Gatekeeper, Windows SmartScreen).
- [ ] Locally run `pnpm tauri build` on macOS to confirm the bundle builds; report the
      artifact path. (Windows/Linux are CI-only/unverified.)
