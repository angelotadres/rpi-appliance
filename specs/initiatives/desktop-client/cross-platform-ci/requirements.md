# Client Phase 4 — Cross-platform build + CI

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 4). Installable bundles
for macOS, Windows, and Linux, built in CI.

## Scope

**In:**
- A CI workflow that builds the Tauri app on macOS, Windows, and Linux and uploads the
  bundles as artifacts (and attaches them to a release on a client tag).
- Documented unsigned first-launch steps (Gatekeeper / SmartScreen).
- Local proof the macOS bundle builds.

**Out:** code-signing / notarization (deferred per tech-stack — ship unsigned with
documented steps); auto-update.

## Decisions

- **GitHub Actions matrix** (`macos-latest`, `windows-latest`, `ubuntu-latest`) with
  the standard Tauri v2 setup (Rust + Node/pnpm + Linux webkit deps) — builds the same
  app three ways.
- **Unsigned bundles** with first-launch instructions — code-signing is a known,
  deferred one-off (tech-stack risk flag).
- **macOS is the only hardware-verified target**; Windows/Linux are CI-built and
  flagged unverified until community-confirmed (tech-stack Testing Strategy).
- Client release tags are namespaced `client-v*` so they don't collide with the image
  tags (`v*` / `1.0.0-*`).

## Context

- "Lean… built for all three in CI" and the macOS-only hardware-test caveat from
  [`../../../mission.md`](../../../mission.md)/tech-stack.

## Dependencies

- Phases 1–3 (the app). GitHub Actions; the Tauri build toolchain per OS.
