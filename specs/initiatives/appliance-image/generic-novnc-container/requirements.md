# Phase 1 — Generic noVNC container

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 1). This phase
proves the GUI-over-web plumbing **off-Pi**, with a throwaway sample app.

## Scope

**In:**
- A self-contained container build on `jlesage/baseimage-gui` that runs the default
  sample app, with noVNC and the web file manager enabled.
- A `compose.yml` that publishes the GUI web port to `127.0.0.1` **only**.
- An automated smoke test runnable on any Docker host (no Pi, no hardware).

**Out** (later phases, do not touch): boot-folder compose wiring (Phase 2), USB
writable store (Phase 3), read-only root (Phase 4), SSH/lockdown (Phase 5),
first-boot orchestration (Phase 6), pi-gen image + CI (Phase 7). This Phase-1
container is the **default sample**, replaceable later; it is **not** the
deployment mechanism (that is Phase 2's boot-folder compose). The default app is an
**open** GRBL sender, never proprietary Carbide — Carbide is the consumer-supplied
Phase 8 acceptance app and never lives in this repo (per tech-stack.md licensing).
**Phase 1 itself exercises only render + file manager + loopback**; serial is not
wired until Phase 2 — the serial-capable app is chosen now to avoid re-picking it.

## Decisions

- **Base `jlesage/baseimage-gui`** — fixed by [`../../../tech-stack.md`](../../../tech-stack.md); we inherit noVNC + web file manager rather than build it.
- **Default app = Candle** (open-source GPL-3.0 GRBL G-code sender), installed via a
  `Dockerfile` with a `startapp.sh`. Chosen as the open analog of the north-star
  Carbide case: opens `.gcode`/`.nc` files (stresses the file manager), 3D
  visualizer (stresses noVNC rendering), and serial GRBL connect (stresses Phase 2+
  passthrough). Built at image-build time — **not vendored** — so the recipe stays
  MIT while the image may contain GPL software (the jlesage/distro model). Swappable
  by editing the Dockerfile.
- **Fallback = bCNC** (pip-installable Python/Tk GRBL sender) if Candle's Qt build
  proves too heavy/fragile under arm emulation in CI — same use cases, lighter.
- **Web file manager on** via the base image's env toggle (`WEB_FILE_MANAGER=1`),
  scoped to a sample data path mounted into the container.
- **Loopback binding in compose** (`127.0.0.1:5800:5800`) — the secure-by-default
  invariant from [`../../../mission.md`](../../../mission.md); nothing answers on the LAN.
- **Smoke test is a shell script** driving `docker compose` + `curl` — matches the
  inner-loop testing strategy in tech-stack.md; no new test framework introduced.

## Context

- Secure-by-default and generic/app-agnostic, per mission.md — the loopback bind is
  a hard requirement to assert here, not a Phase 5 concern.
- Lean: a minimal Dockerfile, no extra tooling beyond Docker + curl.
- Pin the base image to a specific tag (not `latest`) for reproducibility.

## Dependencies

- External: Docker (with Compose v2) on the dev host; the `jlesage/baseimage-gui`
  image; the sample app's apt/apk package.
- Internal: none — this is the first phase; it stands alone.
</content>
