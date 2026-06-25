# AGENTS.md

This repository follows a **spec-driven development (SDD)** workflow. Every initiative starts as a spec, not code. These instructions apply to any agent working in this repository.

## Mental model

SDD organizes work into three durable layers:

1. **The Constitution** (`specs/mission.md`, `specs/tech-stack.md`) — the long-lived "why and how" of the project. Edit rarely and deliberately. Changes here affect every initiative.
2. **Initiatives** (`specs/initiatives/<initiative-name>/`) — one folder per initiative. Each contains a `roadmap.md` (the phases for that initiative) and a spec folder per phase (`<phase-name>/` with `requirements.md`, `plan.md`, `validation.md`). Phase order lives in `roadmap.md`, not in the folder name.
3. **Agent skills** (`.claude/skills/`) — reusable procedures. `bootstrap` drafts the constitution and first initiative on a fresh repo; `feature-spec` kicks off new phases.

Multiple initiatives can be active simultaneously — different people or agents work on different initiatives without file overlap. Within a single initiative, phases are sequential.

The pattern is deliberately agent-agnostic. Claude Code picks up `.claude/skills/` natively; other agents can read this file and follow the workflow manually.

## Starting a new project

If the constitution files (`specs/mission.md`, `specs/tech-stack.md`) are still the stock scaffolds — only HTML comments and section headers, no real content — the repo has just been cloned from the template. Before any other work, invoke the `bootstrap` skill to draft them together with the user, even if the user hasn't asked for it by name.

The bootstrap skill runs a three-part interview (mission → tech-stack → first initiative) and produces the filled-in constitution plus the first initiative folder. It then sets the project's license (asking which — it does not default to MIT), rewrites the template `README.md` into a short project README that points at the constitution, and suggests committing before any phase begins. Only after all three are approved does the workflow below apply.

## Starting a new phase

Do not write code before the spec exists. The ritual:

1. **Identify the initiative.** Ask the user which initiative they are working on. Read `specs/initiatives/<initiative-name>/roadmap.md` to find the first incomplete phase. That is the target.
2. **Branch from a clean tree.** A phase starts from a known-good main, so commit or stash any pending changes first — never branch on top of uncommitted work. Then create a git branch named `<initiative-name>/<phase-name>` — for example, `auth-redesign/login-flow`.
3. **Consult the constitution first.** Read `specs/mission.md`, `specs/tech-stack.md`, the initiative's `roadmap.md`, and any memos in `specs/research/` relevant to this initiative. Extract everything already known about scope, decisions, and context. Surface any conflicts before proceeding.
4. **Fill gaps with the user — only what the constitution doesn't already answer.** Present a pre-filled summary of what you know and ask the user to confirm, correct, or add to it. Only ask open questions for dimensions that have no coverage. If all three are fully covered, skip interviewing entirely.
5. **Generate the spec trio** in `specs/initiatives/<initiative-name>/<phase-name>/`:
   - `requirements.md` — scope boundaries, decision rationale, context/tone rules.
   - `plan.md` — numbered task groups, each independently implementable.
   - `validation.md` — automated checks (agent runs), human validation (agent cannot), and definition of done.
6. **Show the user.** Get approval before coding.

## Implementing a phase

Work task group by task group from `plan.md`. Commit in small increments tied to task groups. When a group is done, run the checks in `validation.md`.

Apply the coding discipline in `.claude/skills/coding-discipline/SKILL.md` while implementing: surface assumptions before coding, keep changes minimal and surgical, and turn each task into a verifiable check before writing it.

**Validation principle:** The agent runs every automated check it can — tests, lint, type checks, CLI smoke tests — and reports the results. Only after exhausting automated validation does it ask the human to step in. The human's role is to review the agent's report, perform the checks only a human can (visual UI, business logic judgment, accessibility), and then authorize the commit or PR push. That authorization is the explicit gate.

A phase is *done* when:

- Every task in `plan.md` is checked off.
- Every automated check in `validation.md` passes.
- The human walkthrough in `validation.md` has been performed and authorized.
- The phase checkbox in the initiative's `roadmap.md` is checked off.

## Conventions

- **Initiative folder names:** `<kebab-case-name>` under `specs/initiatives/`.
- **Phase folder names:** `<phase-name>` (kebab-case) inside the initiative folder. Matches the branch name so branch and folder stay in sync. Order lives in `roadmap.md`.
- **Branch names:** `<initiative-name>/<phase-name>` — maps directly to the folder structure.
- **Phase sizing:** A phase must be a **closed increment that fits the agent's context window**.
  - **Closed** — at the end of the phase, main is in a coherent state. Tests green, no dangling wires, no commented-out call sites, no "we'll finish this next phase" stubs. Infra phases count as closed when the infra is actually usable (migration runs, module exports a working API, CI stage is green) — not when it's scaffolded but dead.
  - **Fits context** — the spec trio, touched code, tests, and review can all be loaded into one agent context with headroom. "One human working session" is a rough proxy, not the real constraint.

  If a phase can't meet both tests, it isn't one phase — it's multiple, and each must independently close. The work of splitting is finding real seams where both sides leave main coherent (e.g., Phase A adds a new module with a working API but no callers; Phase B migrates callers). Refuse splits where one side is a stub the other finishes — that violates closure. If no closed-at-each-step seam exists, write a research memo under `specs/research/` to find the seams, or promote the work to a new initiative.
- **Spec brevity:** Specs are approval gates, and the gate only works if the human reads every line before approving. Write only lines worth that reading: don't restate what the constitution or roadmap already says — reference it; prefer a tight bullet over a paragraph; cut hedging and boilerplate. Rough budget: each file of a spec trio fits on a screen or two (~60 lines). A spec too long to read thoroughly gets rubber-stamped, which silently defeats the gate.
- **Testing:** A phase that changes behavior ships with automated tests for that behavior, in the same phase — tests are how `validation.md` gets its teeth, not a follow-up. Pragmatism sets the bar: cover what `requirements.md` promises (observable behavior, not implementation details), and prefer a few high-value tests plus a smoke test over coverage chasing. If a phase genuinely needs no new tests (docs-only, config-only), its `validation.md` says so in one line rather than staying silent.
- **Research memos:** Investigations, comparisons, and technical memos live in `specs/research/YYYY-MM-DD-<topic>.md`. These are documents, not tasks — they inform decisions before a phase is scoped.
- **Issue tracking:** Non-blocking bugs, polish, and small improvements go to GitHub Issues, not into specs. The threshold: if it needs a spec, it is an initiative; if it doesn't, it is an issue. When the agent notices something worth tracking, it surfaces the suggestion and waits for the user to authorize before running `gh issue create`. Before starting a new phase, the agent runs `gh issue list` to surface any open issues relevant to the current initiative.
- **`.gitignore`:** Always kept in sync with `specs/tech-stack.md`. When the stack changes — or is first approved during bootstrap — update `.gitignore` in the same commit.
- **Diagrams:** Use Mermaid (fenced ` ```mermaid ` blocks) for all architecture, flow, and sequence diagrams. They render natively on GitHub and in most AI-assisted editors. Never use ASCII art diagrams.
- **Markdown style:** Use heading levels (`#`, `##`, `###`) to divide documents into sections — never horizontal rules (`---`) for structure. No emojis unless the content explicitly calls for one. Write in plain prose; avoid bullet-point-heavy writing where paragraphs would read better.
- **Doc discipline:** `AGENTS.md` holds decision rules the agent applies while working. Background, rationale, and onboarding prose belong in `README.md`. If a new addition reads like explanation rather than a rule the agent checks, it goes in the README. Target: `AGENTS.md` stays under ~100 lines. The `README.md` follows the same brevity bar as specs — a short, pragmatic narrative, not a wall of text — and it links to the constitution rather than restating it, per the single-source-of-truth rule below.
- **Single source of truth:** Every rule lives in exactly one place — usually this file. Skills and other docs reference a rule by name with a pointer (e.g. "the phase-sizing rule in `AGENTS.md`") instead of restating it. Finding the same rule written out twice is a bug: consolidate and point.

## Replanning

An initiative's roadmap is not immutable. When you learn something important mid-build — a decision was wrong, a dependency surfaced, priorities shifted — stop, update the initiative's `roadmap.md`, and (if needed) revise `mission.md` or `tech-stack.md`. Replanning is cheap when the specs are small. Constitution changes should be surfaced to the user and committed deliberately, not silently folded into a phase branch.

## Files an agent should read first

1. `specs/mission.md` — what we're building and why.
2. `specs/tech-stack.md` — how we're building it.
3. `specs/initiatives/<active-initiative>/roadmap.md` — what's next for the current initiative.
4. The active phase folder inside that initiative (if any).
5. Any relevant memos in `specs/research/`.
