---
name: feature-spec
description: Kicks off a new phase within an initiative by reading the initiative's roadmap, consulting the constitution, filling gaps with the user, and generating the requirements.md + plan.md + validation.md trio. Trigger when the user says "start the next phase", "kick off a phase", "begin the next phase of [initiative]", "write the spec for X", or asks to start any new phase of work. Do not write code before this skill has produced the spec trio.
---

# Feature Spec Skill

## When to run

Trigger this skill at the start of every new phase. Do not write code or create files outside `specs/` before this skill has produced the spec trio and the user has approved it.

## Steps

### 1. Prompt the user to clear context

Before doing any other work, tell the user:

> "Before we start, consider running `/clear` (or `/compact`) to reset the context window. Spec sessions work best with a clean slate — old conversation history adds noise and cost. Let me know when you're ready and I'll pick up from the initiative roadmap."

Wait for confirmation. Do not proceed until the user confirms they're ready.

### 2. Identify the initiative and next phase

Ask the user which initiative they are working on. Then read `specs/initiatives/<initiative-name>/roadmap.md` and find the first phase with at least one unchecked task. That is your target.

If every phase in the initiative is complete, stop and tell the user — they need to add new phases to the initiative's roadmap before starting work.

### 3. Create a branch

First ensure the working tree is clean — commit or stash any pending changes before branching, per the branch-from-a-clean-tree rule in `AGENTS.md`. Then create a git branch named `<initiative-name>/<phase-name>`, where the names are kebab-case and match the initiative folder and phase goal.

Example: initiative "auth-redesign", phase "Login Flow" → `auth-redesign/login-flow`.

Hold onto the phase kebab-name. The spec folder you create in step 6 reuses it: `specs/initiatives/<initiative-name>/<phase-name>/`. Branch and folder names match exactly.

### 4. Consult the constitution first

Read `specs/mission.md`, `specs/tech-stack.md`, the initiative's `roadmap.md`, and any memos in `specs/research/` relevant to this initiative. Extract everything already stated about the three spec dimensions:

- **Scope** — what the phase's goal and task list imply; what mission.md says is in/out of scope.
- **Decisions** — stack choices, libraries, patterns, and data model details from tech-stack.md.
- **Context** — constraints, tone, non-functional requirements, and philosophy from mission.md.

Also check open GitHub Issues: `gh issue list` — surface any that are relevant to this phase before proceeding.

If anything conflicts with the constitution, surface the conflict explicitly before proceeding — don't silently resolve it.

### 5. Fill gaps with the user — only what's missing

Present a concise pre-filled summary of what you already know across all three dimensions. Then ask only about the parts that have no coverage in the constitution:

- If scope is clear from the phase goal in the roadmap, state it and ask the user to confirm or correct — don't re-ask it as an open question.
- If decisions are fully specified in tech-stack.md, list the relevant ones and note they're already decided — don't ask again.
- If context is fully covered by mission.md, summarize it — don't ask.

Only ask an open-ended question for a dimension when it genuinely has a gap. If all three are fully covered, skip interviewing entirely and proceed to step 6.

### 6. Generate the spec trio

Create `specs/initiatives/<initiative-name>/<phase-name>/` with three files. Apply the spec-brevity convention in `AGENTS.md` to all three: reference the constitution instead of restating it, and keep each file short enough that the user will genuinely read every line in step 7.

**`requirements.md`** — what is being built. Sections:

- **Scope** — what's in, what's out.
- **Decisions** — the choices made, each with a one-line rationale.
- **Context** — tone, constraints, non-functional considerations, patterns to follow.
- **Dependencies** — other specs, phases, or external systems this relies on.

**`plan.md`** — how it will be built. Sections:

- Numbered task groups. Common shape: data layer → domain logic → interface (API or UI). Adapt to the project's actual stack.
- Each group contains concrete, independently implementable subtasks as checkboxes.
- Tests live inside the group that introduces the behavior they cover — never as a trailing "tests" group. See the testing convention in `AGENTS.md`.
- Groups should be orderable — later groups can depend on earlier ones, but not vice versa.

**`validation.md`** — how we'll know it's done. Two explicit sections:

- **Agent validates** — everything the agent can run or observe autonomously: automated tests, lint, type checks, CLI smoke tests, API response checks. The agent runs all of these and reports results before involving the human. Name the tests this phase adds or updates (per the testing convention in `AGENTS.md`); if the phase needs none, say why in one line.
- **Human validates** — only what requires human judgment: visual UI correctness, business logic that can't be asserted programmatically, accessibility, UX feel. Keep this list short — if the agent can check it, it belongs in "Agent validates."
- **Definition of done** — explicit checklist that maps 1:1 to the `plan.md` tasks. Always include a final item: "Mark the phase checkbox in the initiative's `roadmap.md` as complete."

### 7. Confirm with the user

Show the three files. Then, separately, call out the decisions and assumptions most likely to be wrong — the ones the user must consciously confirm rather than skim past: anything you inferred without constitution backing, any new dependency or pattern, any scope judgment call. Keep this list to the genuinely risky items (typically 3–5).

Ask for approval or edits before implementation begins. Approval of the risky-items list is the real gate — don't accept a bare "looks good" if the user hasn't addressed them.

## Constraints

- Stay consistent with `specs/tech-stack.md`. Don't introduce new libraries or patterns without calling them out in `requirements.md` under Decisions.
- Enforce the phase-sizing rule in `AGENTS.md` during step 5. If the phase fails either test, stop and propose a roadmap split — and refuse splits that create stub-then-finish pairs.
- Three files, always. `requirements.md`, `plan.md`, `validation.md`. Same names every time.
- Never write code or edit files outside `specs/` from within this skill.
