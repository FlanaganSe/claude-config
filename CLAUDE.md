# Project Name

One-line description.

## Commands
```bash
pnpm dev              # Local dev
pnpm test             # Unit tests
pnpm ci               # Full CI: typecheck, lint, test
```

## Rules
<!-- Auto-discovered from .claude/rules/ — listed here for visibility -->
@.claude/rules/immutable.md
@.claude/rules/conventions.md
@.claude/rules/stack.md

## System
<!-- Uncomment when SYSTEM.md has real content: -->
<!-- @docs/SYSTEM.md -->

## Decisions
See `docs/decisions.md` — append-only ADR log. Read during planning, not loaded every session.

## Personal Overrides
Create `CLAUDE.local.md` (gitignored) for personal, project-specific preferences.

## Workflow
`/prd` → `/research` → `/plan` → `/milestone` → `/verify` + `/review` → `/complete`

## Escalation Policy
- If a test or typecheck fails 3 times after attempted fixes, STOP and report what you've tried.
- If a plan step is ambiguous, ask before implementing — don't guess.
- If you discover a new invariant, add it to `.claude/rules/immutable.md`.
- After completing a feature, run `/complete` to clean up plans and log decisions.
