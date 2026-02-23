---
name: review
description: Run a fresh-context, bug-focused review after implementation.
---
If the `reviewer` role is configured and multi-agent is enabled, delegate to that role.
Otherwise, perform the review directly.

Scope:
- If user provided context, review that scope.
- If no scope was provided, review uncommitted changes via `git diff`.

Output:
- Must fix - production-breaking issues
- Should fix - correctness or reliability risks
- Looks good - if no findings

Avoid style-only nits and broad refactors that do not fix a defect.
