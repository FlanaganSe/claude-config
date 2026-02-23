---
name: plan
description: Generate an implementation plan from PRD and research.
---
Read:
- `.plans/prd.md` (requirements)
- `.plans/research.md` (investigation findings)

Then read the relevant source files to understand the current state.

Write to `.plans/plan.md`:

1. Summary - one paragraph on the approach
2. Files to change - each file with what changes and why
3. Files to create - each new file with its purpose
4. Steps - numbered and ordered, each with:
   - Step N: [description]
   - Files: [which files]
   - Verify: [command to confirm correctness]
5. Risks - what could go wrong
6. Open questions - anything needing human input

Do not implement. Write the plan and stop for human review.
