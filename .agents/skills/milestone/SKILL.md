---
name: milestone
description: Split an approved plan into milestones and execute them safely.
---
Read the approved plan at `.plans/plan.md`.

Split the implementation into milestones. Each milestone must be:
- Independently verifiable (clear done check)
- Committable (repo remains valid after completion)
- Small (1-5 steps)

Update `.plans/plan.md` with a `## Milestones` section:

### M1: [name]
- [ ] Step 1 - [desc] -> verify: [command]
- [ ] Step 2 - [desc] -> verify: [command]
Suggested commit: "[type]: [description]"

### M2: [name]
- [ ] ...

Then begin executing M1.

After each milestone:
1. Check off completed steps in `.plans/plan.md`.
2. Run each verification command.
3. If `verifier` role is configured, delegate final pass/fail confirmation to it; otherwise report check results directly.
4. If `reviewer` role is configured, delegate a bug-focused review to it; otherwise self-review with bug focus.
5. If review finds must-fix issues, fix them before proceeding.
6. Only create a git commit when the user has asked for commits in this task.
