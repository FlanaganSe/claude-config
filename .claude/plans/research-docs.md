# Research: Documentation Management in AI-Assisted Codebases (Early 2026)

Researched: 2026-03-06
Scope: Best practices for managing documentation that Claude Code reads, generates, and updates.

---

## Current State

This repo already demonstrates a mature documentation structure:

- `CLAUDE.md:1-27` — project root, 27 lines, uses `@.claude/rules/*` imports for modular rules
- `.claude/rules/immutable.md` — invariants (placeholder content)
- `.claude/rules/conventions.md` — TypeScript conventions (partially filled)
- `.claude/rules/stack.md` — stack choices (placeholder content)
- `docs/architecture.md` — stub with instructions, not yet `@`-imported (line 18 of CLAUDE.md is commented out)
- `docs/decisions.md` — ADR log format defined, append-only, no entries yet; not yet `@`-imported (line 21 commented out)
- `.claude/plans/` — ephemeral workspace: `prd.md`, `research.md`, `plan.md` are written per-task
- `.claude/skills/` — six skills (prd, research, plan, milestone, review, verify), all `disable-model-invocation: true`
- `.claude/agents/` — researcher, reviewer, verifier subagents
- `.claude/plans/research.md` — the existing CLAUDE.md best-practices research

The workflow is: `/prd` -> `/research` -> `/plan` -> `/milestone` -> `/verify` + `/review`.

Plans accumulate in `.claude/plans/` and are not auto-cleaned. This is the primary lifecycle gap in the current setup.

---

## Part 1: The Living vs. Ephemeral Distinction

### What the Research Found

This is the most critical conceptual distinction for documentation hygiene. The field has converged on a clear taxonomy:

**Living documents** — persist indefinitely, must stay synchronized with the codebase, go stale if not updated:
- Architecture docs (`docs/architecture.md`) — describes why the system is shaped the way it is
- Decision logs (`docs/decisions.md`) — append-only ADR log; never edited, only extended
- Rules files (`.claude/rules/*.md`) — invariants, conventions, stack choices
- CLAUDE.md — the navigation hub that loads every session
- Skills (`.claude/skills/*/SKILL.md`) — repeatable workflow definitions

**Ephemeral documents** — created for a task, consumed during that task, expendable afterward:
- PRDs (`.claude/plans/prd.md`) — written before implementation, obsolete after
- Research notes (`.claude/plans/research.md`) — written before planning, consumed by the plan step
- Implementation plans (`.claude/plans/plan.md`) — written before execution, replaced by git history post-merge
- Specs (`.claude/plans/spec.md`) — describe intent for a session; once the session ships, git is the record

The arxiv paper "Codified Context: Infrastructure for AI Agents in a Complex Codebase" (https://arxiv.org/html/2602.20478v1) formalizes this as a three-tier architecture:

- **Tier 1 (Hot Memory / Always Loaded):** A concise "constitution" (~660 lines max) containing conventions, naming standards, build commands, and orchestration rules. This maps to CLAUDE.md + `.claude/rules/` in the Claude Code model.
- **Tier 2 (Specialists / On Demand):** Domain-expert agents embedding project-specific knowledge. In Claude Code terms: `.claude/skills/` and `.claude/agents/`.
- **Tier 3 (Cold Memory / Retrieved On Demand):** A knowledge base of subsystem-specific documents (34 in their case study). In Claude Code terms: `docs/architecture.md`, subsystem READMEs, API docs — loaded via `@` reference or on-demand reads.

Key finding from the paper: **agents trust documentation absolutely**. Outdated specs cause silent failures rather than graceful degradation. An agent will confidently generate syntactically correct but architecturally wrong code if the spec it read was stale.

Sources:
- https://arxiv.org/html/2602.20478v1
- https://packmind.com/evaluate-context-ai-coding-agent/ — "Writing AI coding agent context files is easy. Keeping them accurate isn't."

---

## Part 2: File Organization Patterns

### The Official Claude Code Model (as of early 2026)

Source: https://code.claude.com/docs/en/memory

```
project/
├── CLAUDE.md                   # Navigation hub; <200 lines; always loaded
├── CLAUDE.local.md             # Personal overrides; gitignored; always loaded
├── .claude/
│   ├── CLAUDE.md               # Alternative project location (same priority as root)
│   ├── rules/
│   │   ├── immutable.md        # Always loaded; unconditional invariants
│   │   ├── conventions.md      # Always loaded; code style
│   │   └── stack.md            # Always loaded; technology choices
│   ├── skills/
│   │   └── <skill-name>/
│   │       ├── SKILL.md        # Loaded on demand (description only at startup)
│   │       ├── reference.md    # Loaded when skill references it
│   │       └── scripts/        # Scripts the skill can execute
│   ├── agents/
│   │   └── <agent-name>.md     # Subagent definitions; invoked by skills or directly
│   └── plans/                  # EPHEMERAL workspace; per-task, per-session
│       ├── prd.md
│       ├── research.md
│       └── plan.md
└── docs/
    ├── architecture.md         # Living; loaded on demand via @ reference
    └── decisions.md            # Living; append-only ADR log; loaded on demand
```

**Loading behavior:**
- `CLAUDE.md` files in ancestor directories of the working directory: loaded in full at launch
- `CLAUDE.md` files in subdirectories: loaded on demand when Claude reads files there
- `.claude/rules/*.md`: auto-discovered and loaded at launch (no `@` import needed)
- `@path/to/file` imports: expanded at launch; max 5 hops
- Skill descriptions (YAML frontmatter `name` + `description`): always in context
- Skill full content (`SKILL.md` body): loaded only when invoked or when Claude determines relevance
- `docs/architecture.md`, `docs/decisions.md`: NOT loaded unless `@`-referenced in CLAUDE.md or Claude reads them explicitly

**Size targets from official docs:**
- Under 200 lines per CLAUDE.md file for reliable adherence
- SKILL.md: under 500 lines (move reference material to supporting files)
- Auto memory `MEMORY.md`: only first 200 lines load at session start

---

## Part 3: Architecture Docs, Product Overviews, Decision Logs

### Architecture Documentation

Source: https://arxiv.org/html/2602.20478v1, https://adolfi.dev/blog/ai-generated-adr/

The consensus pattern for `docs/architecture.md`:
- Describes **why** decisions were made, not what files exist (Claude can read the files itself)
- Focuses on non-obvious patterns, constraints, and historical context
- Updated when structural decisions change; treated as living documentation
- Loaded via `@docs/architecture.md` in CLAUDE.md — only uncomment when the doc has real content
- Should include: naming conventions with examples, known failure modes, correctness invariants, explicit file paths for subsystems

What NOT to put in architecture docs:
- File counts, line counts, metrics (these go stale immediately)
- Lists of files (Claude can glob these)
- Self-evident patterns Claude would discover by reading code

The `docs/architecture.md` stub in this repo (`docs/architecture.md:1-5`) correctly instructs: "focus on WHY, not WHAT; store patterns and locations, not counts or metrics." This is aligned with best practice.

### Product Overview Pattern

No standard `product-overview.md` pattern emerged from research as a distinct artifact. The closest patterns found:

1. **AGENTS.md / README as product brief** — human-readable high-level description; AI reads it if `@README.md` appears in CLAUDE.md. The repo's `CLAUDE.md` doesn't currently reference the README.
2. **PRD as session-scoped product spec** — the `/prd` skill in this repo generates `.claude/plans/prd.md`. This is ephemeral (per-task), not a living product overview.
3. **Skills-based domain knowledge** — teams encode product-specific context in SKILL.md files (e.g., a `domain-context` skill with `user-invocable: false` so Claude loads it automatically when relevant).

If a persistent product overview is needed, the best practice is: create `docs/product-overview.md`, write it for the AI reader (concrete, not marketing), and `@`-import it in CLAUDE.md when it contains stable, useful context.

Sources: https://www.aihero.dev/a-complete-guide-to-agents-md, https://addyosmani.com/blog/good-spec/

### Decision Logs (ADRs)

Source: https://adr.github.io/, https://adolfi.dev/blog/ai-generated-adr/

This repo's `docs/decisions.md` follows the correct pattern:
- Append-only; entries are never edited
- Format: `ADR-NNN / Date / Status / Context / Decision / Consequences`
- Status transitions to `superseded by ADR-NNN` when a decision is reversed

The emerging practice is: instruct Claude (via CLAUDE.md or a skill) to **propose an ADR after any implementation that changes the architecture**. The ADR is written to `docs/decisions.md` and reviewed by a human before merge. This keeps the log current without relying on developers to remember.

The current `docs/decisions.md` is not yet `@`-referenced from CLAUDE.md (line 21 is commented out). When it has entries, uncomment the reference so Claude has historical context on decisions during planning.

---

## Part 4: Doc Hygiene — Cleaning Up Stale Plans

### The `.claude/plans/` Lifecycle Problem

Sources: https://github.com/anthropics/claude-code/issues/18434, https://github.com/anthropics/claude-code/issues/11083

There is a documented gap in Claude Code's handling of plan files. Key findings:

**Current behavior (as of early 2026):**
- Plan files in `.claude/plans/` are session-scoped artifacts written by skills (`/prd`, `/research`, `/plan`)
- They are NOT automatically cleaned up when a task completes
- They ARE cleaned up when the parent session is purged via `cleanupPeriodDays` (default: 30 days)
- Manual deletion during an active session is risky: the `ExitPlanMode` tool reads from `plansDirectory`
- GitHub Issue #18434 was closed as "not planned" — no native cleanup automation is forthcoming

**The community workaround pattern:**
- Treat `.claude/plans/` as a working directory; gitignore it or commit selectively
- After a feature ships, manually archive or delete the plan files
- Some teams use a `PostToolUse` hook to move completed plans to an `archive/` subdirectory
- The arxiv paper's pattern: "anything worth keeping is written to a persistent layer before context compression can erase it" — meaning plan files should be promoted to ADRs or architecture docs if they contain lasting decisions

**Recommendation from this research:**
Plans should be deleted (or moved to an archive) after the feature merges. The git history and any ADRs are the permanent record. Stale plans in `.claude/plans/` create noise: when the research skill runs on a future task, it reads the PRD from `prd.md` — if an old PRD exists from a previous task, it will confuse the workflow.

---

## Part 5: CLAUDE.md @-References — What Gets Loaded

### The Loading Decision Framework

Source: https://code.claude.com/docs/en/memory, https://code.claude.com/docs/en/best-practices

The key question for every document: **should this be in context every session, or loaded on demand?**

| Doc type | Load strategy | Rationale |
|---|---|---|
| Build commands | CLAUDE.md always | Claude needs these every session |
| Code style rules | `.claude/rules/conventions.md` always | Non-default rules Claude must always follow |
| Invariants | `.claude/rules/immutable.md` always | Safety constraints; never optional |
| Stack choices | `.claude/rules/stack.md` always | Prevent wrong technology choices |
| Architecture rationale | `@docs/architecture.md` (uncomment when ready) | Loaded every session once doc has real content |
| Decision history | Reference by path description, not always-load | Long logs waste tokens; Claude reads on demand during planning |
| Workflow recipes | `.claude/skills/*/SKILL.md` (on demand) | Loaded only when relevant or invoked |
| PRDs | `.claude/plans/prd.md` (ephemeral, not referenced) | Consumed by `/research` and `/plan`, then discarded |
| Research notes | `.claude/plans/research.md` (ephemeral) | Consumed by `/plan`, then discarded |

**The context economy:** Claude's context window is the primary scarce resource. The official best practices page (https://code.claude.com/docs/en/best-practices) makes this the first principle: "Most best practices are based on one constraint: Claude's context window fills up fast, and performance degrades as it fills."

For reference: skill descriptions consume ~100 tokens each at startup. Full skill content consumes ~2,000 tokens when loaded. A bloated CLAUDE.md consuming 5,000 tokens per session has real cost — both in money and in reduced adherence to rules buried in noise.

The progressive disclosure pattern (community consensus):
- CLAUDE.md: navigation hub, always-present rules, command reference — under 100-150 lines
- `.claude/rules/`: modular, always-loaded rules files, each focused on one topic
- `.claude/skills/`: on-demand workflows and reference content
- `docs/`: living documents loaded on demand via `@` import

Source: https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/ (skills progressive disclosure analysis)

---

## Part 6: Auto-Generating and Auto-Updating Docs

### GitHub Actions Pattern

Source: https://github.com/marketplace/actions/claude-code-automatic-pr-documentation-generator, https://medium.com/@fra.bernhardt/automate-your-documentation-with-claude-code-github-actions-a-step-by-step-guide-2be2d315ed45

Two established automation patterns:

**PR-Triggered Docs Updater:** When a PR is opened or updated with code changes, Claude reviews the diff and updates relevant documentation in the same PR. Implemented as a `.github/workflows/claude-pr-docs.yml` that triggers `claude -p "Review the diff and update any documentation that is now out of date"`.

**Scheduled Docs Maintainer:** Runs on a schedule (e.g., nightly), reviews recent commits, and opens a PR if documentation needs updating.

Both require `ANTHROPIC_API_KEY` in repository secrets and use the `anthropics/claude-code-action` GitHub Action.

### Hooks Pattern (Local Auto-Update)

Source: https://code.claude.com/docs/en/best-practices (hooks section)

Claude Code hooks run deterministically at specific points in the workflow. A `PostToolUse` hook can trigger after every file edit to check if documentation needs updating. Example use case: after editing `src/api/routes.ts`, a hook checks if `docs/architecture.md` mentions the route pattern and flags drift.

The official docs note: "Unlike CLAUDE.md instructions which are advisory, hooks are deterministic and guarantee the action happens."

### The ADR-on-Change Pattern

Source: https://gist.github.com/joshrotenberg/a3ffd160f161c98a61c739392e953764, https://adolfi.dev/blog/ai-generated-adr/

Teams are encoding this in CLAUDE.md or skills:
> "After any implementation that changes the architecture, propose an ADR. Write a draft to `docs/decisions.md` and stop for human review."

This is the most practical "auto-update" pattern: it doesn't fully automate documentation but ensures the agent prompts for it.

### Google Code Wiki (Reference)

Source: https://www.infoq.com/news/2025/11/google-code-wiki/

Google launched Code Wiki (November 2025) — a platform that generates structured wiki for each repository and automatically updates it after every commit. It represents the fully automated end of the spectrum: documentation as a continuous output of CI. Not yet available to the general public, but signals the direction the industry is moving.

---

## Part 7: What Documentation Maximizes Claude's Effectiveness

### Empirical Finding from Agent README Study

Source: https://arxiv.org/html/2511.12884v1 ("Agent READMEs: An Empirical Study of Context Files for Agentic Coding")

A study of 2,500+ agent context files found the most valuable content categories (in order of impact):

1. **Commands with exact syntax** — test commands, build commands, lint commands with flags
2. **Architecture constraints** — where things live, naming conventions, patterns
3. **Explicit prohibitions** — "never commit secrets," "never use `any`," "never edit migrations directly"
4. **Known failure modes** — debugging patterns, common errors and their fixes
5. **Workflow sequencing** — what to do before/after each step

The least valuable (sometimes harmful):
- Marketing-style project descriptions
- File-by-file inventories (Claude reads the files)
- Standard language conventions (Claude knows them)
- Anything Claude would discover by reading the codebase

### The Skills-as-Documentation Pattern

Source: https://dev.to/magnusrodseth/how-claude-skills-replaced-our-documentation-emi

Teams are replacing traditional documentation with Claude Skills:
- Each skill encodes a specific workflow or domain pattern in `SKILL.md`
- Skills include concrete code examples, explicit anti-patterns, and architectural reasoning
- The key insight: humans skim docs and ignore them; Claude reads everything systematically — so documentation written for the AI reader is more consistently followed than documentation written for humans

This is the clearest signal that documentation management in AI-assisted codebases is a different discipline from traditional technical writing.

---

## Part 8: Context Window Management

### Strategies for Large Codebases

Sources: https://code.claude.com/docs/en/best-practices, https://mcpcat.io/guides/managing-claude-code-context/, https://docs.digitalocean.com/products/gradient-ai-platform/concepts/context-management/

**The .claudeignore pattern:** Add generated files, build artifacts, and large data files to `.claudeignore`. Official guidance says a well-configured `.claudeignore` can save 50% of token budget.

**Subagents for investigation:** When researching requires reading many files, delegate to a subagent. The subagent's file reads don't consume the main conversation context. This is why the researcher subagent pattern in this repo (`.claude/agents/researcher.md`) is correct — heavy file reads happen in an isolated context.

**The `/compact` command:** Claude compresses conversation history when approaching context limits. CLAUDE.md can instruct: "When compacting, always preserve the full list of modified files and any verification commands." This ensures critical context survives summarization.

**Session discipline:** Start fresh sessions for each task. Use `claude --continue` only when you need the previous task's context. The "kitchen sink session" (one task, then another, then back) is the most common failure pattern cited in official docs.

---

## Constraints

1. `.claude/plans/*` write restriction applies to this session.
2. Source files are read-only.
3. The existing plans lifecycle (prd -> research -> plan -> milestone) is established; any recommendation must be compatible with it.
4. The `docs/decisions.md` append-only format is defined and must not change.
5. Plans in `.claude/plans/` are NOT auto-cleaned by Claude Code (confirmed by GitHub issue #18434).

---

## Options

### Option A: Minimal — Document the lifecycle, add cleanup instruction to CLAUDE.md

Add a note to CLAUDE.md (or a new `.claude/rules/plans-hygiene.md`) that instructs Claude: "After a feature merges, delete `prd.md`, `research.md`, and `plan.md` from `.claude/plans/`." This is advisory (Claude might ignore it) but low-risk.

Trade-offs:
- No structural change; low disruption
- Depends on Claude following an advisory instruction
- Does not solve the "old PRD confuses new task" problem reliably

### Option B: Enforce lifecycle via a `/complete` skill

Add a `.claude/skills/complete/SKILL.md` that:
1. Promotes any lasting decisions from `plan.md` to `docs/decisions.md` as an ADR
2. Deletes `prd.md`, `research.md`, `plan.md` from `.claude/plans/`
3. Confirms the task is done

This is invoked manually after merge (`/complete`), similar to how `/milestone` is invoked to begin execution.

Trade-offs:
- Deterministic cleanup when invoked
- Requires human to remember to run `/complete`
- Turns the ephemeral/living distinction into an enforced workflow step
- Consistent with `disable-model-invocation: true` pattern already used in this repo

### Option C: Git-based approach — Commit plans on task start, delete on merge

Commit `prd.md`, `research.md`, `plan.md` to a feature branch at task start. On merge, the branch history preserves them forever. Delete from `main`. Add `.claude/plans/*.md` to `.gitignore` on `main` or handle via PR cleanup.

Trade-offs:
- Plans are preserved in git history if needed
- More complex workflow; requires branch discipline
- Doesn't solve the "stale PRD on disk" problem if branches are long-lived

---

## Recommendation

**Option B (add `/complete` skill) is the right answer, with one immediate action.**

**Immediate action:** Uncomment `@docs/architecture.md` and `@docs/decisions.md` in CLAUDE.md once those files have real content. They are stubs now; loading empty stubs wastes tokens without providing value. The current commented-out state is correct for now.

**Add `/complete` skill:** This closes the lifecycle loop. The existing workflow is prd -> research -> plan -> milestone (which loops verify + review). Adding `/complete` as the final step makes the lifecycle:

```
/prd -> /research -> /plan -> /milestone -> ... -> /complete
```

The `/complete` skill should:
1. Read `plan.md` to check all milestones are marked done
2. Draft an ADR to `docs/decisions.md` for any architectural decision made during the task
3. Delete `prd.md`, `research.md`, `plan.md`
4. Print a summary

**For the architecture doc (`docs/architecture.md`):** The current stub instructs correctly. When real content is added (first real architectural decision), uncomment the `@` reference in CLAUDE.md. Keep entries focused on WHY, not WHAT.

**For the decision log (`docs/decisions.md`):** The current format is correct and aligned with ADR best practice. When the first ADR is written, uncomment the `@` reference in CLAUDE.md so future planning sessions have historical context.

**Key numbers:**
- CLAUDE.md target: under 150-200 lines for reliable adherence (official: code.claude.com/docs/en/memory)
- SKILL.md target: under 500 lines
- `.claude/rules/*.md`: auto-discovered, no `@` import needed (current explicit imports are harmless redundancy)
- Plan file cleanup: 30-day default `cleanupPeriodDays` applies; manual cleanup via `/complete` skill is needed for active hygiene

---

## Sources

- Official memory docs: https://code.claude.com/docs/en/memory
- Official best practices: https://code.claude.com/docs/en/best-practices
- Official skills docs: https://code.claude.com/docs/en/skills
- Anthropic blog on CLAUDE.md: https://claude.com/blog/using-claude-md-files
- Codified Context paper (arxiv): https://arxiv.org/html/2602.20478v1
- Agent READMEs empirical study: https://arxiv.org/html/2511.12884v1
- GitHub issue — plan file lifecycle: https://github.com/anthropics/claude-code/issues/18434
- GitHub issue — plan tracking: https://github.com/anthropics/claude-code/issues/11083
- Addy Osmani — writing good specs for AI: https://addyosmani.com/blog/good-spec/
- ADR standard: https://adr.github.io/
- ADR with AI integration: https://gist.github.com/joshrotenberg/a3ffd160f161c98a61c739392e953764
- AI-generated ADRs: https://adolfi.dev/blog/ai-generated-adr/
- Skills replaced documentation: https://dev.to/magnusrodseth/how-claude-skills-replaced-our-documentation-emi
- Skills progressive disclosure analysis: https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/
- PR auto-documentation GitHub Action: https://github.com/marketplace/actions/claude-code-automatic-pr-documentation-generator
- Google Code Wiki (continuous doc sync): https://www.infoq.com/news/2025/11/google-code-wiki/
- Context management guide: https://mcpcat.io/guides/managing-claude-code-context/
- DigitalOcean context management: https://docs.digitalocean.com/products/gradient-ai-platform/concepts/context-management/
- AGENTS.md open standard: https://github.com/agentsmd/agents.md
- Martin Fowler — context engineering for coding agents: https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html
