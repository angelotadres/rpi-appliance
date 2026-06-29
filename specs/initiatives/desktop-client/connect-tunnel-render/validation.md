# Client Phase 1 — Validation

## Agent validates (autonomous)

- `cargo test` in `client/src-tauri` — `ssh_args()` builds the expected `-L`/`-N`/key/
  `user@host`/hardening options; `wait_for_port()` times out on a closed port.
- `cargo build` compiles the app (Rust side) cleanly.
- `client/tests/tunnel-it.sh` — using the *same* ssh invocation the app issues, a real
  tunnel to the local SSH→noVNC stand-in serves noVNC (HTTP 200) on the local port, and
  the port is closed after disconnect. Runs on any Docker host.

## Human validates (judgment required)

- `pnpm tauri dev`: the connect form renders; entering a real appliance's host/user/key
  and clicking **Connect** shows the noVNC GUI in the window; **Disconnect** clears it;
  quitting kills the tunnel. (Needs a reachable appliance — folds into the end-to-end
  hardware checklist.)

## Definition of done

- [ ] Task group 1: `ssh.rs` + `lib.rs` commands; unit tests pass.
- [ ] Task group 2: connect form + iframe render wired to the commands.
- [ ] Task group 3: `cargo build` clean; tunnel integration test passes.
- [ ] Agent checks green and reported.
- [ ] Mark the Phase 1 checkbox in [`../roadmap.md`](../roadmap.md) as complete (the
      live render against a real appliance is in the end-of-initiative checklist).
