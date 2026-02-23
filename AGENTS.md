# Project Name

One-line description.

## Commands
```bash
pnpm dev              # Local dev
pnpm test             # Unit tests
pnpm ci               # Full CI: typecheck, lint, test
```

## Rules
- `.agents/rules/immutable.md`
- `.agents/rules/conventions.md`
- `.agents/rules/stack.md`

## Architecture
- `docs/architecture.md`

## Decisions
- `docs/decisions.md`

## Workflow Skills
- `$prd "description"` -> writes `.plans/prd.md`
- `$research` -> investigates and writes `.plans/research.md`
- `$plan` -> writes `.plans/plan.md`
- Review and approve `plan.md` before execution.
- `$milestone` -> executes the plan milestone by milestone.
- `$verify` -> runs verification checks without fixing failures.
- `$review` -> runs a fresh-context, bug-focused review.

## Escalation Policy
- If a test or typecheck fails 3 times after attempted fixes, stop and report what was tried.
- If a plan step is ambiguous, ask before implementing.
- If you discover a new invariant, add it to `.agents/rules/immutable.md`.

## Safety Notes
- Respect `.codex/rules/*.rules` when requesting escalated commands.
- Do not read `.env*` or `**/secrets/**` unless the user explicitly asks.
- Treat `.agents/` and `.codex/` as instruction/config paths; write workflow artifacts to `.plans/`.
