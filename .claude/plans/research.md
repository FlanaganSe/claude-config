# Research: CLAUDE.md Best Practices (Early 2026)

## Current State

This repo already applies the @-import pattern correctly. The root `CLAUDE.md` (project:1-27) is 27 lines, imports three rules files, and stubs out architecture and decisions references. The three rules files are populated with correct YAML frontmatter and placeholder content:

- `CLAUDE.md:1-27` — project root, uses `@.claude/rules/*` imports
- `.claude/rules/immutable.md:1-11` — frontmatter `description:` present, rules are placeholders
- `.claude/rules/conventions.md:1-13` — frontmatter present, TypeScript conventions filled in
- `.claude/rules/stack.md:1-14` — frontmatter present, stack fields are placeholders
- `docs/decisions.md:1-17` — ADR log format defined, no entries yet
- `~/.claude/CLAUDE.md:1-5` — two global preferences, no structure beyond a header

The `docs/architecture.md` file does not exist yet (the `@docs/architecture.md` line in `CLAUDE.md:18` is commented out). The `docs/decisions.md` exists but is not yet referenced from `CLAUDE.md` (line 21 is also commented out).

---

## What the Official Docs Say

Source: https://code.claude.com/docs/en/memory (fetched 2026-03-06)

### File hierarchy (four scopes, most-specific wins)

| Scope | Location | Shared with |
|---|---|---|
| Managed policy | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | All org users |
| Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team via git |
| User | `~/.claude/CLAUDE.md` | You, all projects |
| Local | `./CLAUDE.local.md` | You, current project only |

User-level rules at `~/.claude/rules/` load before project rules, giving project rules higher effective priority.

### How files load

- CLAUDE.md files in ancestor directories of the working directory load in full at launch.
- CLAUDE.md files in subdirectories load on demand when Claude reads files in those directories.
- `@path/to/file` imports are expanded at launch. Relative paths resolve from the file containing the import. Max depth: 5 hops.

### `.claude/rules/` directory

All `.md` files under `.claude/rules/` are loaded at launch with the same priority as `.claude/CLAUDE.md`. No `@` import is needed — they are discovered automatically and recursively. YAML frontmatter `paths:` field scopes a rule to glob patterns, so it only loads when Claude opens a matching file.

Path-scoped rule example:
```markdown
---
paths:
  - "src/api/**/*.ts"
---
# API Rules
```

Rules without `paths` frontmatter load unconditionally every session.

### Size guidance

- Target under 200 lines per file. Beyond that, adherence degrades.
- Files over 200 lines consume more context and may cause Claude to miss rules.
- Use `@imports` or `.claude/rules/` to split large files.

### Writing instructions that work

From https://code.claude.com/docs/en/best-practices (fetched 2026-03-06):

- Concrete over abstract: "Run `npm test` before committing" not "test your changes."
- Two rules that contradict each other: Claude picks one arbitrarily. Review periodically.
- "IMPORTANT" and "YOU MUST" measurably improve compliance on critical rules — use sparingly.
- Treat CLAUDE.md like code: prune when Claude ignores rules (file is too long) or asks questions already answered (phrasing is ambiguous).

### What to include vs. exclude

Include:
- Bash commands Claude cannot guess
- Non-default code style rules
- Test runner and test commands
- Repo conventions (branch naming, PR rules)
- Architecture decisions specific to the project
- Developer environment quirks (required env vars, local URLs)
- Common gotchas and non-obvious behaviors

Exclude:
- Standard language conventions (Claude knows them)
- Detailed API documentation (link to docs instead)
- Information that changes frequently
- Self-evident practices ("write clean code")
- File-by-file descriptions of the codebase

### Auto memory (complementary system)

Auto memory lives at `~/.claude/projects/<project>/memory/MEMORY.md`. The first 200 lines of `MEMORY.md` load every session. Claude writes to this automatically — it captures build commands, debugging insights, preferences discovered during sessions. It is per-machine and per-git-repo. CLAUDE.md is for stable instructions you write; auto memory is for learnings Claude accumulates. Both load every session.

---

## Community Patterns (2026)

Sources: https://www.humanlayer.dev/blog/writing-a-good-claude-md, https://dev.to/cleverhoods/claudemd-best-practices-from-basic-to-adaptive-9lm, https://www.morphllm.com/claude-code-best-practices, https://www.builder.io/blog/claude-md-guide

### Progressive disclosure (the most important community pattern)

Do not put everything you might ever need into CLAUDE.md. Instead, put the always-applicable rules in CLAUDE.md and tell Claude where to find task-specific knowledge. Example: `agent_docs/building_the_project.md` for build specifics, `agent_docs/running_tests.md` for test specifics. CLAUDE.md lists these files with one-line descriptions so Claude can pull them when relevant without bloating every session.

This is the difference between:
- "Context you load whether you need it or not" (bad — wastes tokens, buries rules)
- "Context you know how to find" (good — minimal always-present surface)

Skills (`.claude/skills/`) are the official mechanism for this pattern. Skills load on demand when Claude determines they are relevant or when you invoke them by name. CLAUDE.md should reference skills for non-universal workflows rather than inlining their content.

### Maturity levels (community model from DEV Community)

L1: File exists in version control.
L2: Explicit MUSTs and MUST NOTs.
L3: External references split by concern (architecture, conventions, stack).
L4: Path-scoped rules — different rules for different parts of the codebase.
L5: L4 with staleness tracking and regular reviews.
L6: Adaptive — skills load on task, MCP servers for external integrations.

Most projects sit at L1-L2. The repo in this directory is already at L3 (imported rules files with frontmatter). The gap to L4 is path frontmatter on rules files.

### Global vs. project CLAUDE.md — the key distinction

`~/.claude/CLAUDE.md` — personal workflow preferences that apply to every project you touch. Should be minimal. Things like: preferred code style defaults, personal tooling shortcuts, global prohibitions ("never use default exports"). It never contains project-specific commands or architecture.

`./CLAUDE.md` — team standards checked into git. Contains the commands, architecture pointers, conventions, and escalation policies specific to this codebase. Anything here is shared with the entire team via git.

`./CLAUDE.local.md` — personal project-specific preferences, gitignored. Sandbox URLs, preferred test data, local credentials references. Never committed.

The current `~/.claude/CLAUDE.md` (5 lines, 2 rules) is correctly scoped — TypeScript preferences and early-return preference apply universally. The project `CLAUDE.md` is correctly scoped to team conventions.

### Inline rules vs. @-referenced files

The community consensus matches the official docs:
- CLAUDE.md root: navigation hub, commands, escalation policy. Under 100 lines.
- `.claude/rules/*.md`: one topic per file. Each file under 200 lines.
- `@imports`: use for referencing existing docs (README, package.json, architecture docs) that Claude needs to read but you do not want to duplicate.
- Skills (`.claude/skills/*/SKILL.md`): for workflow recipes invoked on demand, not loaded every session.

The current project structure already applies this. The `@.claude/rules/immutable.md`, `@.claude/rules/conventions.md`, and `@.claude/rules/stack.md` pattern in `CLAUDE.md:13-15` is correct. However: the official docs say `.claude/rules/` files are auto-discovered without needing `@` imports. The explicit imports are not wrong (they are redundant but harmless and provide navigational clarity).

### Living docs vs. stable docs

Stable (rarely changes):
- Immutable rules (`immutable.md`) — invariants that, if violated, break the system
- Stack (`stack.md`) — technology choices; change only with deliberate ADR
- Conventions (`conventions.md`) — code style; change slowly, never silently

Living (actively updated):
- Auto memory (`~/.claude/projects/.../MEMORY.md`) — Claude writes this automatically
- ADR log (`docs/decisions.md`) — append-only, never edited
- Architecture doc (`docs/architecture.md`) — updated when structure changes

The pattern the community uses: reference stable docs by `@` in CLAUDE.md so they load as context. Reference living docs by path description ("see `docs/decisions.md` for rationale on past decisions") so Claude reads them on demand rather than every session.

### Handling auto-update vs. stable documentation

The official docs identify this split explicitly: CLAUDE.md is what you write (stable instructions); auto memory is what Claude writes (discovered facts). The practical implication: do not put things in CLAUDE.md that Claude should discover itself (build commands, test runner output formats, debugging patterns). Put those things in auto memory by telling Claude "remember that..." or letting it learn naturally. Put things in CLAUDE.md that you want enforced even in fresh sessions where auto memory has not yet accumulated.

### Large/complex project patterns

For monorepos:
- Root `CLAUDE.md`: shared commands, git workflow, escalation policy
- Package `CLAUDE.md` (loaded on demand): package-specific stack, commands, conventions
- `claudeMdExcludes` in `.claude/settings.local.json` to skip irrelevant sibling team files
- Use `@~/.claude/my-project-instructions.md` for personal preferences that should follow across worktrees (worktree-safe pattern)

For large single-repo projects:
- Path-scoped rules in `.claude/rules/` with YAML `paths:` frontmatter to avoid loading frontend rules when working in backend directories
- Skills for workflows that are only invoked sometimes (`/deploy-staging`, `/review-pr`)
- Subagent definitions in `.claude/agents/` for isolated, context-heavy tasks (security review, test generation)

---

## Constraints

1. The `.claude/plans/*` write restriction applies — this file is the only output.
2. Source files (CLAUDE.md, rules files) must not be modified.
3. The `@.claude/rules/immutable.md` pattern is already established — any recommendation must be compatible with it.
4. The existing `docs/decisions.md` format (ADR log, append-only) is defined and must be preserved.
5. CLAUDE.md is loaded into every session — any additions directly increase token cost per session. This creates a hard economic constraint on verbosity.

---

## Options

### Option A: Minimal additions to current structure

Keep the root `CLAUDE.md` as-is. Populate the placeholder rules files with real content as the project gains a real stack. Uncomment the `@docs/architecture.md` and `@docs/decisions.md` references when those docs exist.

Trade-offs:
- No disruption to current structure, which is already L3.
- Placeholder content in `stack.md` and `immutable.md` means Claude gets no signal from those files today.
- Leaves the `~/.claude/CLAUDE.md` (5 lines, no structure) as-is even though it could benefit from organizing personal preferences.

### Option B: Add path-scoped frontmatter to rules files (reach L4)

Keep existing structure. Add YAML `paths:` frontmatter to any rules that only apply to specific file types (e.g., TypeScript-specific conventions only when working in `.ts` files). This reduces noise when Claude is working in non-matching directories.

Trade-offs:
- Moves the project from L3 to L4 without touching the root CLAUDE.md.
- `immutable.md` already has `description:` frontmatter — it just needs `paths:` added if scoping is desired. But immutable rules should load unconditionally, so no `paths:` needed there.
- `conventions.md` and `stack.md` are currently unconditional — appropriate for a single-stack project. Path-scoping adds value in monorepos or projects with mixed stacks.
- Low risk, incremental.

### Option C: Add skills for task-specific workflows + restructure global CLAUDE.md

Add `.claude/skills/` entries for repeatable workflows (e.g., PR review, deployment). Restructure `~/.claude/CLAUDE.md` to have explicit sections (Code Preferences, Workflow Preferences, Prohibitions). Add `CLAUDE.local.md` to gitignore for personal project-specific overrides.

Trade-offs:
- Skills are the right home for workflow recipes that bloat CLAUDE.md today (if any exist).
- A structured global CLAUDE.md (with headers) is more readable and maintainable as preferences accumulate.
- Requires creating new files and a gitignore entry — more change surface.
- Most valuable when the project has real workflows to document; premature if there are none yet.

---

## Recommendation

**Option B now; Option C when real workflows emerge.**

The current structure is already well above community average (L3). The biggest gap is that `stack.md`, `immutable.md`, and the root `CLAUDE.md` contain placeholder content — the rules files convey no real signal to Claude. Reaching L4 via path frontmatter is a minor, low-risk improvement worth doing when the stack is defined.

The more actionable finding is about the global `~/.claude/CLAUDE.md`: it has two rules with no sectional structure. It works, but as preferences grow across multiple projects it will become hard to maintain. Adding explicit headers (# Code Preferences, # Workflow Preferences) before it grows is cheaper than reorganizing it later.

The progressive disclosure finding is the highest-leverage takeaway for future development: when documentation grows, do not put it inline in CLAUDE.md. Create `docs/` or `agent_docs/` files and reference them by path. Let Claude read them on demand. Only content that must be present in every session belongs directly in CLAUDE.md or an unconditional rule file.

**Key numbers to remember:**
- Under 200 lines per file for reliable adherence (official doc: code.claude.com/docs/en/memory)
- `.claude/rules/` files are auto-discovered — explicit `@` imports are redundant but harmless
- Auto memory MEMORY.md: only first 200 lines load; Claude writes it, you do not
- Max `@import` depth: 5 hops

---

## Sources

- Official memory docs: https://code.claude.com/docs/en/memory
- Official best practices: https://code.claude.com/docs/en/best-practices
- Anthropic blog on CLAUDE.md files: https://claude.com/blog/using-claude-md-files
- HumanLayer guide: https://www.humanlayer.dev/blog/writing-a-good-claude-md
- Builder.io guide: https://www.builder.io/blog/claude-md-guide
- DEV Community maturity levels: https://dev.to/cleverhoods/claudemd-best-practices-from-basic-to-adaptive-9lm
- Morph 2026 best practices: https://www.morphllm.com/claude-code-best-practices
- Awesome Claude Code (community patterns): https://github.com/hesreallyhim/awesome-claude-code
- Gend.co 2026 guide: https://www.gend.co/blog/claude-skills-claude-md-guide
