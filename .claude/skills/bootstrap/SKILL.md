---
name: bootstrap
description: Interviews the user to draft the project constitution — mission.md, tech-stack.md, and the first initiative — then sets the license, rewrites the README for the new project, and suggests an initial commit. Trigger on a fresh clone of the template when the user says things like "bootstrap the project", "set up the constitution", "fill in mission/tech-stack", "this is a fresh repo — let's start", "help me write the mission", or asks for help writing any of the constitution docs. Can target one doc at a time or run all three back-to-back.
---

# Bootstrap Skill

## When to run

Trigger on a fresh clone, before any phase work. The two constitution docs (`specs/mission.md`, `specs/tech-stack.md`) and at least one initiative under `specs/initiatives/` must be meaningfully filled in before the `feature-spec` skill can do useful work.

If the user asks to fill in only one doc, do just that one. Otherwise run all three parts in order: mission → tech-stack → first initiative. The order matters — each part builds on the previous.

## Before you start

Check the current state of each target file:

- If the file still contains only HTML-comment scaffolding (no real prose), it's safe to replace.
- If the file has real content already, stop and ask: revise, append, or leave alone? Don't silently overwrite the user's work.

## Part 1 — Mission

Ask exactly three questions, one at a time, waiting for each answer before the next:

1. **Purpose & users** — "In one or two paragraphs: what does this project do, who uses it, and what problem does it solve?"
2. **Capabilities & success** — "What are the top 3–7 things the system must do, and how will you know it's working? Prefer measurable criteria."
3. **Scope & philosophy** — "What's explicitly in scope for the first version, what are you deferring (and why), and what non-negotiables shape every downstream decision?"

Synthesize the answers into `specs/mission.md`, preserving the section structure from the scaffold (Core Purpose, Users, Problems Solved, Key Capabilities, Success Metrics, Scope: Included, Scope: Deferred, Design Philosophy). Remove the HTML-comment guidance from sections you've filled in.

Show the draft. Get explicit approval before moving on.

## Part 2 — Tech Stack

Only start after `mission.md` is approved.

Ask exactly three questions, one at a time:

1. **Architecture** — "What's the high-level architecture? Major components and how they talk to each other."
2. **Choices & rationale** — "Language, framework, database, key libraries — each with a one-line reason."
3. **Interfaces, config & testing** — "What are the entry points (API, CLI, UI)? Key environment variables? How will you verify correctness?"

Synthesize into `specs/tech-stack.md`, preserving the scaffold's section structure (System Design, Stack Choices, Data Model Overview, Interfaces, Configuration, Testing Strategy, Dependencies, Open Questions). If the user has unresolved decisions, put them in Open Questions rather than inventing answers.

Show the draft. Get approval.

**After approval:** update `.gitignore` with stack-specific entries derived from the approved stack choices. The commented section at the bottom of `.gitignore` has examples. Add entries there, then show the diff to the user for confirmation before moving on to Part 3.

## Part 3 — First Initiative

Only start after `tech-stack.md` is approved.

Ask exactly three questions, one at a time:

1. **Initiative name and goal** — "What is the first initiative you want to build? Give it a short name and describe its goal in one sentence."
2. **Phase 1** — "What's the smallest closed increment you could ship within this initiative? At the end of Phase 1, main should be in a coherent state — the work is done, not stubbed for a later phase."
3. **Near-term phases** — "What phases come next within this initiative, in rough order? Each phase must satisfy the phase-sizing rule in `AGENTS.md` — a closed increment that fits one agent context window."

Synthesize into `specs/initiatives/<initiative-kebab-name>/roadmap.md`. Use the following format:

```markdown
# <Initiative Name> Roadmap

**Goal:** <One sentence describing what this initiative delivers.>

## Phase 1: <Short phase name>

**Goal:** <One sentence. What does shipping this phase enable?>

- [ ] <Concrete task>
- [ ] <Concrete task>

## Phase 2: <Short phase name>

**Goal:** <One sentence.>

- [ ] <Concrete task>
- [ ] <Concrete task>
```

Enforce the phase-sizing rule from `AGENTS.md` on every proposed phase. Split phases that fail it, refuse scaffold-then-finish pairs, and if no closed-at-each-step seam exists, flag it and propose a research memo before finalizing the roadmap.

Show the draft. Get approval.

## Finish

Once all three parts are approved, wrap up the repo before any phase work:

1. **License.** Ask the user which license the project should use — don't assume MIT. Offer the common choices (MIT, Apache-2.0, BSD-3-Clause, GPL-3.0, proprietary/none) and accept any other. Replace `LICENSE` with the chosen license's text, using the user's name and the current year as the copyright holder. If they choose proprietary/none, delete `LICENSE` and drop the License section from the README.
2. **README.** The template ships a `README.md` describing the *template itself* — it's stale the moment a real project exists. Replace it with a short project README: a one-paragraph intro (what this is, who it's for) plus pointers to the durable sources of truth. Do **not** restate mission or tech-stack content — link to it, so each fact lives in one place. Apply the spec-brevity convention in `AGENTS.md` to the README too. Use this skeleton:

   ```markdown
   # <Project Name>

   <One paragraph: what the project is and who it's for. No feature lists — those live in mission.md.>

   ## Documentation

   This project uses spec-driven development. Durable sources of truth:

   - `specs/mission.md` — what we're building and why.
   - `specs/tech-stack.md` — how we're building it.
   - `AGENTS.md` — the workflow agents follow.

   ## License

   <License name> — see [LICENSE](LICENSE).
   ```

3. **Commit.** Suggest committing the bootstrapped constitution, README, and LICENSE now, so the first phase branches from a clean, known-good main (the clean-working-tree precondition in `AGENTS.md`). Propose the commit and let the user authorize it.
4. Confirm the constitution and first initiative are in place, then tell the user the next step: start the first phase by saying something like *"start the next phase of [initiative name]"* — which will invoke the `feature-spec` skill.

## Constraints

- Three questions per part, always. No mechanical question lists — each question is a macro prompt that invites a rich answer. If an answer is thin, ask a follow-up before moving on.
- Preserve the scaffold's section structure for constitution docs. Don't invent new top-level sections.
- Remove the HTML-comment guidance from sections you fill in — it served its purpose.
- Write specifically. Abstract constitution docs are useless to agents.
- Write briefly. Every draft must be short enough for the user to read fully before approving — apply the spec-brevity convention in `AGENTS.md`. An approval of an unread draft is worthless.
- During the three interview parts, only edit `specs/` files and `.gitignore`. The `LICENSE` and `README.md` are touched only in the Finish step, after the constitution is approved.
- Don't skip parts. If running all three, mission → tech-stack → first initiative in that order. If one fails approval, stop there.
