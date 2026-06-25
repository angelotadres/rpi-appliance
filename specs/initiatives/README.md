# Initiatives

One folder per initiative. Each initiative folder contains a `roadmap.md` (the phases for that initiative) and a spec folder per phase.

## Structure

```text
initiatives/
└── initiative-name/
    ├── roadmap.md
    └── phase-name/
        ├── requirements.md
        ├── plan.md
        └── validation.md
```

## Naming

Initiative folders use kebab-case: `auth-redesign`, `payment-flow`, `onboarding-v2`.

Phase folders use `<phase-name>` (kebab-case) and match the branch name exactly. Phase order is tracked in `roadmap.md`, not in the folder name.

## Threshold

If work needs a spec, it is an initiative. If it doesn't, it is a GitHub Issue.
