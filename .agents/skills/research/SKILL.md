---
name: research
description: Investigate codebase and external docs before planning.
---
Read `.plans/prd.md` first.

If `.plans/research.md` already exists (for example from external research),
preserve existing covered areas and focus only on uncovered gaps.

If the `researcher` role is configured and multi-agent is enabled, delegate the investigation to that role.
If not, perform equivalent investigation directly.

Write findings to `.plans/research.md`:
1. Current state - what exists (cite `file:line`)
2. Constraints - what cannot change and why
3. Options - 2-3 approaches with trade-offs
4. Recommendation - preferred approach and rationale

Rules:
- Treat source edits as out of scope for this phase.
- Cite all code claims with `file:line`.
- Cite external references with URLs.
