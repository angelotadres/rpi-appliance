# Client Phase 3 — Validation

## Agent validates (autonomous)

- `cargo test` — settings round-trip (write → read returns equal struct), defaults are
  sane (user `pi`, ports 5800/5800/22, no key), and the key-session arg builder still
  produces a key-only invocation after the refactor.
- `cargo build` compiles cleanly with the new commands.
- Shutdown reuses the Phase 2 key session, which `setup-it.sh` already exercises
  (NOPASSWD sudo over the key session) — no separate container test needed; a real
  poweroff is in the hardware checklist.

## Human validates (judgment required)

- Settings persist across app restarts; the form is prefilled.
- "Shut down" powers the appliance off and returns to the connect screen.
- Error messages are understandable on bad host/key/password. (Hardware checklist.)

## Definition of done

- [ ] Task group 1: key-session refactor + `shutdown` command.
- [ ] Task group 2: `settings.rs` + load/save commands; round-trip unit test passes.
- [ ] Task group 3: prefill + save + shutdown button wired.
- [ ] Agent checks green and reported.
- [ ] Mark the Phase 3 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
