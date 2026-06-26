# Phase 2 — Compose-driven app deployment from the boot folder

See the roadmap goal in [`../roadmap.md`](../roadmap.md) (Phase 2). "Which app"
comes from a `compose.yml` in the boot-partition config folder; the appliance runs
it and **forces the GUI to loopback regardless of what the compose declares**.
Proven off-Pi.

## Scope

**In:**
- A host-side `compose-up` script that reads `<config-dir>/compose.yml` and brings
  the stack up with `docker compose`.
- A deterministic mechanism that guarantees the GUI is published on `127.0.0.1`
  only, even if the user's compose publishes to `0.0.0.0`.
- Device passthrough (`devices:`, `group_add`, `privileged`, `/run/udev`) honored
  by passing those keys through untouched.
- Off-Pi tests with compose fixtures.

**Out:** USB writable store (Phase 3), read-only root (Phase 4), SSH/lockdown
(Phase 5), the systemd first-boot service + Wi-Fi + setup log that *invokes*
`compose-up` (Phase 6), pi-gen packaging (Phase 7). This phase delivers the script
and its enforcement, invoked manually/in tests; Phase 6 wires it to boot.

## Decisions

- **Enforcement = port sanitize, not compose override.** Compose's `ports` lists
  merge additively, so an override file can't *remove* a user's `0.0.0.0` mapping.
  Instead `compose-up` produces a sanitized runtime compose: **strip every
  service's `ports`, then republish only the GUI service as `127.0.0.1:<WEB_PORT>:5800`.**
  Nothing the user declares can reach the LAN; everything else passes through.
- **GUI service identified by label** `appliance.gui: "true"`; if absent and there
  is exactly one service, that one is the GUI; multiple unlabeled services → error.
  The GUI service exposes the base image's web port `5800`.
- **YAML transform via `yq`** (mikefarah, single Go binary) — reliable YAML editing
  vs. fragile bash/sed. New dependency, baked into the image in Phase 7; tests use a
  dockerized `yq` so they need no host install. (Adds `yq` to tech-stack deps.)
- **Config dir is `$APPLIANCE_CONFIG_DIR`**, default `/boot/firmware/appliance`
  (the Pi OS FAT boot partition). Tests point it at a fixture dir.
- **Only `ports` are rewritten.** `devices`/`group_add`/`privileged`/`volumes`/
  `environment` are untouched, so passthrough is honored for free.

## Context

- Secure-by-default and app-agnostic, per [`../../../mission.md`](../../../mission.md): the loopback guarantee is the
  appliance's, not the user's. Passthrough is local-only and orthogonal to the
  network boundary.
- The enforcement mechanism resolves an open question in `tech-stack.md` — flag it
  for end-of-initiative human review.

## Dependencies

- Phase 1's sample-app image (used as a fixture).
- External: Docker + Compose v2; `yq` (dockerized in tests).
