# Phase 2 — Validation

## Agent validates (autonomous)

- `appliance/tests/sanitize.sh` — unit-level: given composes that publish to
  `0.0.0.0`, use long and short port syntax, and declare devices/privileged, the
  sanitized output (a) binds the GUI to `127.0.0.1:5800` only, (b) contains no
  `0.0.0.0` / non-loopback publish, (c) preserves `devices`/`group_add`/`privileged`.
  Also asserts the multi-service-no-label case errors out.
- `appliance/tests/phase2-deploy.sh` — integration: for both fixtures, `compose-up`
  brings the app up, noVNC serves HTTP 200 on `127.0.0.1:5800`, the port is refused
  on a non-loopback IP, and the running container matches the fixture's app (proving
  swap works without touching the security machinery).

Both scripts exit non-zero on any failure and are runnable on any Docker host.

## Human validates (judgment required)

- None specific to this phase beyond Phase 1's GUI/file-manager walkthrough — the
  enforcement is fully assertable. **But** the loopback-enforcement *mechanism*
  (strip-all-ports + republish GUI on loopback, GUI chosen by label) is a design
  decision resolving a tech-stack open question; review it for soundness during the
  end-of-initiative review.

## Definition of done

- [ ] Task group 1: `compose-up` + `sanitize-compose.sh` written; sanitize unit test
      passes.
- [ ] Task group 2: both fixtures deploy; integration test passes (loopback-only +
      app-swap).
- [ ] Task group 3: README written; `tech-stack.md` open question resolved and `yq`
      added to dependencies.
- [ ] Agent checks above green and reported.
- [ ] Mark the Phase 2 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
