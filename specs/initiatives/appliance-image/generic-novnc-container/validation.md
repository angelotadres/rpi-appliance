# Phase 1 — Validation

## Agent validates (autonomous)

Run `appliance/sample-app/smoke-test.sh` and report output. It asserts:

- Image builds and the container reaches a healthy/running state.
- `curl http://127.0.0.1:5800` returns HTTP 200 (noVNC web UI served).
- The GUI port is bound to loopback only: it is reachable on `127.0.0.1` and
  **refused** on the host's non-loopback IP (the secure-by-default invariant).
- `docker port` / compose config shows the publish address as `127.0.0.1`, never
  `0.0.0.0`.

This script is the test this phase adds; there is no application code to unit-test.

## Human validates (judgment required)

- Open `http://127.0.0.1:5800` in a browser: the sample GUI app renders in noVNC
  and is interactive (click/type).
- Open the web file manager and confirm it **lists, uploads, and deletes** a file
  in the mounted data path — the upload/delete round-trip can't be meaningfully
  asserted headlessly.

## Definition of done

- [ ] Task group 1 complete: Dockerfile + startapp.sh build cleanly.
- [ ] Task group 2 complete: compose runs the app, GUI on `127.0.0.1:5800`, file
      manager enabled.
- [ ] Task group 3 complete: smoke test passes; README written.
- [ ] Agent checks above all green and reported.
- [ ] Human walkthrough (GUI render + file manager round-trip) performed and authorized.
- [ ] Mark the Phase 1 checkbox in [`../roadmap.md`](../roadmap.md) as complete.
</content>
