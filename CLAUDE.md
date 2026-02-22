# Project Name

One-line description.

## Commands
```bash
pnpm dev              # Local dev
pnpm test             # Unit tests
pnpm ci               # Full CI: typecheck, lint, test
```

## Rules
@.claude/rules/immutable.md
@.claude/rules/conventions.md
@.claude/rules/stack.md

## Architecture
<!-- Uncomment when docs exist: @docs/architecture.md -->

## Decisions
<!-- Uncomment when docs exist: @docs/decisions.md -->

## Escalation Policy
- If a test or typecheck fails 3 times after attempted fixes, STOP and report what you've tried.
- If a plan step is ambiguous, ask before implementing — don't guess.
- If you discover a new invariant, add it to .claude/rules/immutable.md.
