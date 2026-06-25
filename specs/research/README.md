# Research

Investigations, comparisons, and technical memos that inform decisions before a phase is scoped.

## What goes here

- Comparisons between possible approaches ("Postgres vs. SQLite for persistence").
- Research on external services, libraries, or APIs under consideration.
- Cost, performance, or compliance investigations.
- Any writeup that will influence a future `specs/initiatives/<initiative>/<phase>/requirements.md` decision.

## What does not go here

- Active phase specs — those live in `specs/initiatives/<initiative-name>/<phase-name>/`.
- Decisions already made — those live in `specs/tech-stack.md` or `specs/mission.md`.
- Bugs, polish, or task ideas — those go to GitHub Issues (`gh issue create`).

## Naming

`YYYY-MM-DD-<topic>.md` — date first so files sort chronologically.

Example: `2026-04-18-postgres-vs-sqlite.md`.

## Lifecycle

When a research memo produces a decision, the decision is promoted to `specs/tech-stack.md` (or whichever constitution doc is relevant). The memo stays here as the audit trail — don't delete, archive in place.
