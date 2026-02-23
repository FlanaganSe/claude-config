---
name: verify
description: Run verification checks and report results without fixing failures.
---
Read verification scope from user context.
If no scope is provided, use current milestone verification steps from `.plans/plan.md`.

If the `verifier` role is configured and multi-agent is enabled, delegate to that role.
Otherwise, run checks directly.

Process:
1. Run each listed check (typecheck, lint, tests, etc.).
2. If all pass: report success with one concise line per check.
3. If any fail: report the exact failing check and relevant error lines.

Rules:
- Do not fix failures in this skill.
- Do not run unrelated commands.
