# CLAUDE.md

This project follows a spec-driven development workflow defined in [`AGENTS.md`](./AGENTS.md). Read it first — it describes the constitution, the initiative and phase structure, and the kickoff ritual.

## Claude-specific notes

- Skills live in `.claude/skills/`. The `bootstrap` skill drafts the constitution on a fresh repo; the `feature-spec` skill automates new-phase kickoff from `AGENTS.md`; the `coding-discipline` skill carries the behavioral guardrails to apply while implementing a phase.
- Before starting any work, read `specs/mission.md` and `specs/tech-stack.md`. They are the source of truth for the project. **If they are still empty scaffolds (HTML comments only), invoke the `bootstrap` skill first — even if the user hasn't asked for it by name.**
- Do not write code for a phase before its spec trio exists under `specs/initiatives/<initiative-name>/<phase-name>/`.
