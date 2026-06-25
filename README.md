# Agentic Project Template

A GitHub template for agentic projects that use **spec-driven development (SDD)**.

- **Bootstrap skill** — drafts the project's constitution (mission, tech stack, first initiative) on a fresh repo, or documents an existing one.
- **Per-initiative roadmaps** — multiple agents (or people) can work in parallel without colliding on the constitution.
- **Phase-sized work** — phases are closed increments that fit one agent context window; no stub-then-finish pairs.
- **Agent-agnostic** — the workflow lives in `AGENTS.md`, so any agent or IDE that reads it (Claude Code, Cursor, Codex, etc.) works the same way.

## Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`) — required for issue tracking. Run `gh auth login` after installing.

## Quick start

### Greenfield project

Click **Use this template** on GitHub to create a new repo with this structure already in place. Then:

#### 1. Bootstrap the constitution

```text
Bootstrap the project. My project is about: [one sentence].
```

The `bootstrap` skill will interview you and draft `specs/mission.md`, `specs/tech-stack.md`, and the first initiative under `specs/initiatives/` together with you.

#### 2. Start a phase

```text
Start the next phase of [initiative name].
```

The `feature-spec` skill will read the initiative's roadmap, consult the constitution, fill any gaps with you, and produce the spec trio before any code is written.

### Brownfield project

To adopt this workflow in an existing repo:

1. Copy the following into your project root: `AGENTS.md`, `CLAUDE.md`, `.claude/`, and the `specs/` folder (without the scaffold content — just the structure).
2. Run `gh auth login` if needed.
3. Run the bootstrap skill — it will interview you about your existing project and fill in the constitution based on what's already built, not what you're starting from scratch.

The bootstrap skill is designed to document reality, not invent it. Point it at an existing codebase and it will produce a constitution that reflects what's there.

## What bootstrap produces

Running the `bootstrap` skill on a fresh template fills in the constitution and creates the first initiative. A typical post-bootstrap repo looks like this:

```text
my-project/
├── AGENTS.md
├── CLAUDE.md
├── README.md
└── specs/
    ├── mission.md          ← what the project does, who uses it, success criteria
    ├── tech-stack.md       ← architecture, stack choices, interfaces, testing
    ├── initiatives/
    │   └── <first-initiative>/
    │       └── roadmap.md  ← phases for this initiative
    └── research/
```

From there, `Start the next phase of <initiative>` runs the `feature-spec` skill, which produces the spec trio (requirements, plan, validation) for the next phase before any code is written.

## What's in the box

- **`AGENTS.md`** — agent-agnostic workflow documentation.
- **`CLAUDE.md`** — Claude Code entry point that points at `AGENTS.md`.
- **`specs/`** — constitution files (mission, tech stack) plus `initiatives/` and `research/`.
- **`.claude/skills/bootstrap/`** — interviews you to draft the constitution and first initiative on a fresh repo.
- **`.claude/skills/feature-spec/`** — automates new-phase kickoff (constitution consult + spec trio generation).
- **`.claude/skills/coding-discipline/`** — behavioral guardrails applied while implementing a phase (think before coding, simplicity first, surgical changes, verifiable goals), derived from [Andrej Karpathy's observations on LLM coding pitfalls](https://x.com/karpathy/status/2015883857489522876).
- **`LICENSE`**, **`.gitignore`** — standard project hygiene.

## Who this is for

This template is designed for a solo developer or a small team coordinating with one or more agents. The documentation is written primarily for agents to consume — humans benefit from it too, but the structure is deliberately machine-readable so agents can pick up context without being told what to read.

It is not a team coordination tool, a project management system, or a replacement for a task tracker. It is an opinionated repo layout that keeps specs and code honest with each other.

## Assumptions

The template is designed around two assumptions. When they hold, the workflow is frictionless. When they don't, you will feel friction:

1. **Phases within an initiative are sequential.** One phase completes before the next starts. Different people (or agents) can work on different initiatives simultaneously — each initiative lives in its own folder with no file overlap.
2. **One person owns the constitution.** Someone has final authority over `specs/mission.md` and `specs/tech-stack.md`. Changes to those files should be deliberate and visible to everyone, not silently merged from a feature branch.

## By design

These are deliberate constraints, not gaps:

**Parallel multi-person work causes merge friction.** The constitution files (`mission.md`, `tech-stack.md`) are shared. Changes to them from multiple branches will require merge resolution. This is intentional — constitution changes are significant and should be visible, not silently merged.

**Team coordination relies on git and PRs.** There is no assignment mechanism, no phase lock, no spec review gate beyond what GitHub PRs provide. For a small team, that is enough. Branch creation signals that someone has claimed a phase; the PR is the review gate.

**The SDD workflow is not a bug tracker.** Simple bugs and polish items belong in GitHub Issues, not in specs. The only exception: a bug that requires a multi-phase redesign should be treated as a new initiative.

## Issue tracking

Non-blocking bugs, polish, and small improvements that surface during implementation go to **GitHub Issues**, not into the spec workflow. The convention:

- The agent notices something worth tracking and surfaces it ("I noticed X — should I file an issue?")
- The human authorizes
- The agent creates it: `gh issue create --label bug` or `--label enhancement`

Before starting a new phase, the agent runs `gh issue list` to surface any open issues relevant to the current initiative.

## Why spec-driven

Specs are durable; code is disposable. When the agent (or the human) changes, the specs don't. This template bakes that assumption into the repo layout so any agent can pick up where another left off.

Specs here are also deliberately short. Every spec is an approval gate, and the gate only works if the human actually reads what they approve — a spec too long to read thoroughly gets rubber-stamped, which is worse than no spec at all because it creates the illusion of review. The skills enforce a brevity budget and surface the riskiest decisions explicitly at approval time, so human attention lands where it matters.

See `AGENTS.md` for the full workflow.

## Acknowledgements

The conceptual core of this workflow — write specs before code, keep them in the repo, organize them as a constitution plus a per-phase spec trio — comes from [DeepLearning.AI's short course on Spec-Driven Development with Coding Agents](https://www.deeplearning.ai/short-courses/spec-driven-development-with-coding-agents/). This template builds on those ideas and adds what a reusable starting point needs: the bootstrap skill, per-initiative roadmaps, phase-sizing and closure rules, agent-agnostic instructions, and the brevity, testing, and coding-discipline conventions.

## License

MIT — see [LICENSE](LICENSE).
