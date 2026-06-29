# Client Phase 3 — Shutdown + resilience + settings persistence

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 3). Make daily use one
action that remembers you and fails gracefully.

## Scope

**In:**
- A shutdown action: `sudo -n poweroff` over the key session (clean disconnect first).
- Persist connection settings (host, user, key **path**, ports) between runs; the
  private key itself is never stored.
- Readable error states (auth/host/tunnel failures already surface as messages);
  reconnect = disconnect + connect.

**Out:** packaging/CI (Phase 4). Auto-reconnect-on-drop and a key-file picker are
nice-to-haves, not required here.

## Decisions

- **Settings live in the app config dir as `settings.json`** via `std::fs` (no extra
  plugin) — only non-secret fields; the private key stays on disk where the user put it,
  referenced by path.
- **Shutdown reuses the key-session helper** from Phase 2 (refactored to take plain
  host/user/port/key), and relies on the NOPASSWD sudoers drop-in already added.
- **Core read/write split from the Tauri command** so settings round-trip is unit-tested
  against a temp file.

## Context

- "Daily use is one action… close it; disconnected" and "the private key never leaves
  this computer" from [`../../../mission.md`](../../../mission.md)/tech-stack.

## Dependencies

- Phase 1 (`ConnectOpts`) and Phase 2 (key session + sudoers).
