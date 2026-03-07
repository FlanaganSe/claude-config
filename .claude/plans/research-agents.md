# Research: Claude Code Agent Orchestration, Custom Agents, Skills, and Hooks (March 2026)

## Current State

This project already has a working three-agent pipeline:

- `.claude/agents/researcher.md` — read-only + WebSearch, writes to `.claude/plans/research.md`, model: sonnet, maxTurns: 30
- `.claude/agents/reviewer.md` — Read/Grep/Glob/Bash, fresh-context review after implementation, model: sonnet, maxTurns: 20
- `.claude/agents/verifier.md` — Read/Grep/Glob/Bash, runs checks, model: haiku, maxTurns: 15

Six skills wire the pipeline together:

- `.claude/skills/prd/SKILL.md` — generates PRD to `.claude/plans/prd.md`, `disable-model-invocation: true`
- `.claude/skills/research/SKILL.md` — triggers researcher subagent, `disable-model-invocation: true`
- `.claude/skills/plan/SKILL.md` — generates impl plan from PRD + research, `disable-model-invocation: true`
- `.claude/skills/milestone/SKILL.md` — splits plan and begins execution, `disable-model-invocation: true`
- `.claude/skills/review/SKILL.md` — triggers reviewer subagent, `disable-model-invocation: true`
- `.claude/skills/verify/SKILL.md` — triggers verifier subagent, `disable-model-invocation: true`

One hook is active in `.claude/settings.json:81-93`: `PreToolUse` on `Bash`, running `.claude/hooks/block-dangerous-commands.sh`. The settings file has a duplicate allow-list block (lines 3-15 are repeated in lines 15-63) that should be cleaned up.

---

## Official API Surface (as of March 2026)

Source: https://code.claude.com/docs/en/sub-agents

### Subagent frontmatter fields (complete)

| Field | Required | Notes |
|---|---|---|
| `name` | Yes | lowercase + hyphens |
| `description` | Yes | Claude uses this to decide when to delegate |
| `tools` | No | allowlist; inherits all if omitted |
| `disallowedTools` | No | denylist subtracted from inherited |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` (default) |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | cap on agentic turns |
| `skills` | No | skills injected at startup (full content, not just descriptions) |
| `mcpServers` | No | MCP servers available to this agent |
| `hooks` | No | lifecycle hooks scoped to this agent only |
| `memory` | No | `user`, `project`, or `local` — gives agent a persistent MEMORY.md |
| `background` | No | `true` makes it always run as background task |
| `isolation` | No | `worktree` — runs in temporary git worktree, auto-cleaned if no changes |

### SKILL.md frontmatter fields (complete)

Source: https://code.claude.com/docs/en/skills

| Field | Required | Notes |
|---|---|---|
| `name` | No | directory name used if omitted |
| `description` | Recommended | Claude uses this to decide when to invoke |
| `argument-hint` | No | shown in autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation` | No | `true` = user-only invocation |
| `user-invocable` | No | `false` = Claude-only invocation, hidden from `/` menu |
| `allowed-tools` | No | tools permitted without approval when skill is active |
| `model` | No | model to use while skill is active |
| `context` | No | `fork` = runs in isolated subagent |
| `agent` | No | which agent to use when `context: fork` (default: `general-purpose`) |
| `hooks` | No | lifecycle hooks scoped to this skill |

String substitutions available in skill content: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`.

Dynamic shell injection: `!`command`` runs before Claude sees the content; output replaces the placeholder.

### Hook events (complete list)

Source: https://code.claude.com/docs/en/hooks

| Event | Blockable | When |
|---|---|---|
| `SessionStart` | No | Session begins or resumes |
| `InstructionsLoaded` | No | CLAUDE.md or rules/*.md loaded |
| `UserPromptSubmit` | Yes | Before Claude processes a prompt |
| `PreToolUse` | Yes | Before a tool runs |
| `PermissionRequest` | Yes | Before a permission dialog |
| `PostToolUse` | No | After tool succeeds |
| `PostToolUseFailure` | No | After tool fails |
| `SubagentStart` | No | When a subagent is spawned |
| `SubagentStop` | Yes | When a subagent finishes |
| `Stop` | Yes | When Claude finishes responding |
| `TeammateIdle` | Yes | When an agent team member goes idle |
| `TaskCompleted` | Yes | When a task is marked complete |
| `ConfigChange` | Yes | When a config file changes mid-session |
| `WorktreeCreate` | Yes | When a worktree is being created |
| `WorktreeRemove` | No | When a worktree is being removed |
| `PreCompact` | No | Before context compaction |
| `SessionEnd` | No | When session terminates |

Hook handler types: `command` (shell), `http` (POST to endpoint), `prompt` (LLM single-turn eval), `agent` (spawns a subagent).

Exit code behavior: `0` = allow (parse stdout for JSON), `2` = blocking error (stderr fed to Claude), other = non-blocking error.

Matcher syntax is regex. Tool events match on `tool_name`. `mcp__<server>__<tool>` patterns available for MCP tools.

Hook locations in priority order: managed policy > `~/.claude/settings.json` > `.claude/settings.json` > `.claude/settings.local.json` > plugin `hooks/hooks.json` > skill/agent frontmatter.

---

## What Agents Exist Beyond Researcher/Reviewer/Verifier

### From the official docs (built-in)

- **Explore** — Haiku, read-only tools, codebase search/analysis
- **Plan** — inherits model, read-only, pre-planning research in plan mode
- **General-purpose** — inherits model, all tools, complex multi-step tasks
- **Bash** — runs terminal commands in separate context
- **statusline-setup** — Sonnet, invoked by `/statusline`
- **Claude Code Guide** — Haiku, answers Claude Code feature questions

### From the community (patterns observed)

Source: https://github.com/wshobson/agents (112 agents across 72 plugins)

**Architecture & Documentation tier:**
- `architect-review` — evaluates system design, Opus-tier (critical decisions)
- `documentation` plugin — "code docs, API specs, diagrams, C4 architecture"
- `pm-spec` — writes acceptance criteria and working notes to `docs/claude/working-notes/<slug>.md`
- `architect` — generates ADRs to `docs/claude/decisions/ADR-<slug>.md`

**Model assignment strategy in wshobson/agents:**
- Tier 1 (Opus): 42 agents — architecture, security, code review
- Tier 2 (Inherit): 42 agents — general purpose workers
- Tier 3 (Sonnet): 51 agents — support-focused
- Tier 4 (Haiku): 18 agents — operational/fast tasks

**Other specialized agents seen in the wild:**
- `security-auditor` — vulnerability assessment, read-only
- `data-scientist` — SQL/BigQuery analysis, Sonnet
- `db-reader` — read-only SQL via hook validation
- `debugger` — root cause analysis with Edit access
- `deployment-engineer` — manages release pipelines
- `observability-engineer` — monitoring setup
- `test-automator` — QA workflows
- `frontend-developer` — UI/UX tasks
- `coordinator` — orchestrates other agents using `Agent(worker, researcher)` syntax

Sources: https://github.com/wshobson/agents, https://code.claude.com/docs/en/sub-agents#example-subagents, https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/

---

## Documentation Lifecycle Patterns

### Pattern 1: Slug-based artifact tracking (PubNub / wshobson)

Source: https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/

Three sequential agents with strict handoffs:
1. **pm-spec agent** — writes `docs/claude/working-notes/<slug>.md` (acceptance criteria)
2. **architect agent** — writes `docs/claude/decisions/ADR-<slug>.md` (architecture decision record)
3. **implementer agent** — updates docs and creates audit trails via commit messages

Status transitions tracked in a queue file (`enhancements/_queue.json`):
`BACKLOG` → `READY_FOR_ARCH` → `READY_FOR_BUILD` → `DONE`

Hooks suggest next steps at each handoff, creating visible transition points.

### Pattern 2: Docusaurus doc-updater agent (self-updating docs)

Source: https://medium.com/@dan.avila7/automated-documentation-with-claude-code-building-self-updating-docs-using-docusaurus-agent-2c85d3ec0e19

A dedicated documentation agent analyzes code changes and updates project docs automatically. Triggered via CI/CD integration to keep docs synchronized with the codebase. The agent detects what changed (via `git diff`), reads the affected code, and updates the corresponding Docusaurus pages.

### Pattern 3: PostToolUse hook for doc sync

After any `Write|Edit` to source files, a hook inspects the changed file path and conditionally queues or runs a documentation update. Implementation:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": ".claude/hooks/maybe-update-docs.sh" }]
      }
    ]
  }
}
```

The script checks if the edited file is in `src/` and if a corresponding doc exists in `docs/`, then flags it for update.

### Pattern 4: PRD/Architecture auto-generation agent

Source: https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development, https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/

A `product-overview` agent that reads the full codebase and generates a structured product overview doc. Typically runs with `isolation: worktree` so it can scan without affecting working state. Output written to `docs/PRODUCT_OVERVIEW.md` or similar.

---

## Hooks for Automation (Patterns Observed in the Wild)

Source: https://aiorg.dev/blog/claude-code-hooks, https://dev.to/lukaszfryc/claude-code-hooks-complete-guide-with-20-ready-to-use-examples-2026-dcg, https://code.claude.com/docs/en/hooks

**Auto-lint on every file edit:**
```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "pnpm lint --fix $CLAUDE_FILE_PATH" }] }
    ]
  }
}
```

**Block dangerous commands (already in this project):**
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/block-dangerous-commands.sh" }] }
    ]
  }
}
```

**Session context injection via SessionStart:**
```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": ".claude/hooks/load-context.sh" }] }
    ]
  }
}
```
`load-context.sh` can output JSON with `additionalContext` — that text goes into Claude's context at session start.

**Auto-approve safe bash commands (Dippy pattern):**
Uses `PermissionRequest` hook with AST parsing to auto-approve safe commands and prompt only for destructive ones. Source: https://github.com/hesreallyhim/awesome-claude-code

**Security scanning on tool use (Trail of Bits pattern):**
`PostToolUse` hooks running CodeQL/Semgrep after Write/Edit. Source: https://github.com/hesreallyhim/awesome-claude-code

**Stop hook to block premature exits:**
```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": ".claude/hooks/require-tests-pass.sh" }] }
    ]
  }
}
```
Exit 2 from this hook prevents Claude from stopping — forces test-fix loop.

**Async hooks (non-blocking, added January 2026):**
```json
{ "type": "command", "command": ".claude/hooks/log-session.sh", "async": true }
```
Runs in background without delaying the agentic loop. Useful for logging, metrics, notifications.

**WorktreeCreate/WorktreeRemove hooks:**
Fires when `isolation: worktree` creates or removes a worktree. Can customize VCS setup (e.g., install deps, set environment). `WorktreeCreate` hook's stdout sets the worktree path.

---

## Orchestration Patterns

Source: https://code.claude.com/docs/en/sub-agents, https://claudefa.st/blog/guide/agents/sub-agent-best-practices, https://dev.to/bredmond1019/multi-agent-orchestration-running-10-claude-instances-in-parallel-part-3-29da

### Sequential chaining (current project's pattern)

`/prd` → `/research` → `/plan` → `/milestone` → verifier/reviewer

Each skill invokes the next stage's agent. The plan file is the shared state. This matches "chain subagents" in the official docs.

### Parallel dispatch

Requires: 3+ independent tasks, no shared state, clear file boundaries.

```
Research the authentication, database, and API modules in parallel using separate subagents
```

Each subagent returns a summary; the main context synthesizes. Produces significant context consumption — use agent teams for sustained parallelism.

### Orchestrator/Worker (coordinator agent)

The `coordinator` agent uses `Agent(worker, researcher)` syntax to restrict which subagents it can spawn:

```yaml
---
name: coordinator
tools: Agent(worker, researcher), Read, Bash
---
```

This is an allowlist — attempts to spawn any other agent type fail.

### Agent teams (vs subagents)

Subagents work within a single session; teams coordinate across separate sessions. Teams have their own independent context windows. The `TeammateIdle` hook lets one teammate signal another.

Source: https://code.claude.com/docs/en/sub-agents (Note box at top of page)

### Model assignment cost strategy

- Main session: Opus (complex reasoning, orchestration)
- Workers: Sonnet (focused implementation tasks)
- Fast/cheap checks: Haiku (verification, exploration)
- Override subagent model: `export CLAUDE_CODE_SUBAGENT_MODEL="claude-sonnet-4-5-20250929"`

Source: https://claudefa.st/blog/guide/agents/sub-agent-best-practices

### Worktree isolation

Add `isolation: worktree` to an agent's frontmatter. Agent runs in a temp git worktree, auto-cleaned if no changes. Useful for research agents that should not contaminate working state. Requires a git repo.

The `/batch` built-in skill uses one worktree per parallel unit: spawns 5-30 background agents, each in an isolated worktree, each opening its own PR.

---

## Skills: Must-Have Patterns (2026)

Source: https://code.claude.com/docs/en/skills, https://github.com/anthropics/skills/

### Bundled skills (ship with Claude Code)

- `/simplify` — spawns 3 parallel review agents (code reuse, quality, efficiency), applies fixes
- `/batch <instruction>` — large-scale parallel change across codebase, 5-30 worktree agents, each opens PR
- `/debug` — reads session debug log
- `/loop [interval] <prompt>` — recurring scheduled task
- `/claude-api` — loads Claude API reference

### Anthropic's official skills repo

Source: https://github.com/anthropics/skills/

Document skills: `docx`, `pdf`, `pptx`, `xlsx` — production-grade, source-available.
Plugin install: `/plugin install document-skills@anthropic-agent-skills`

### Community must-haves observed

- `codebase-visualizer` — interactive HTML tree view, bundled Python script
- `explain-code` — analogies + ASCII diagrams for code explanation
- `pr-summary` — fetches live PR diff via `!`gh pr diff`` injection, runs in Explore agent
- `fix-issue` — takes GitHub issue number as argument, `disable-model-invocation: true`
- `deep-research` — runs in forked Explore agent with `context: fork, agent: Explore`

### Key SKILL.md design principles

1. **Progressive disclosure** — `SKILL.md` under 500 lines; move detail to `reference.md`, `examples.md`
2. **`disable-model-invocation: true`** for anything with side effects (deploy, commit, send message)
3. **`user-invocable: false`** for background knowledge Claude should have but users shouldn't invoke
4. **`context: fork`** when the skill needs isolation (research, large analysis)
5. **`!`command`` injection** for dynamic context (live git data, env state, PR diffs)
6. **`allowed-tools`** to lock down what Claude can do while the skill is active

---

## Agent Tool Restrictions: Best Practices

Source: https://code.claude.com/docs/en/sub-agents, https://claudefa.st/blog/guide/agents/sub-agent-best-practices

**Allowlist approach (explicit `tools` field):**
```yaml
tools: Read, Grep, Glob, Bash
```
Subagent can only use those tools. MCP tools NOT inherited unless listed explicitly.

**Denylist approach (`disallowedTools`):**
```yaml
disallowedTools: Write, Edit
```
Subtracts from inherited tools. Use when you want most tools but need to block specific ones.

**Conditional validation via PreToolUse hook in frontmatter:**
```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
```
The script reads stdin JSON (`.tool_input.command`), exits 2 to block. Use when you need finer control than `tools` provides (e.g., allow Bash but only for SELECT queries).

**Restrict spawnable subagents:**
```yaml
tools: Agent(worker, researcher), Read, Bash
```
Only `worker` and `researcher` agents can be spawned. Omitting `Agent` entirely blocks all spawning.

**Disable specific agents globally (settings.json):**
```json
{
  "permissions": {
    "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
  }
}
```

---

## Persistent Memory for Agents

Source: https://code.claude.com/docs/en/sub-agents

Three scopes:
- `memory: user` → `~/.claude/agent-memory/<agent-name>/` (across all projects)
- `memory: project` → `.claude/agent-memory/<agent-name>/` (project-specific, committable)
- `memory: local` → `.claude/agent-memory-local/<agent-name>/` (project-specific, gitignored)

When enabled, agent gets a `MEMORY.md` auto-included in context (first 200 lines). Agent is instructed to curate it as knowledge accumulates.

Best use: code reviewer that remembers recurring patterns, architectural decisions, and codebase conventions across sessions.

Pattern: instruct the agent to update memory after completing a task — "save what you learned." Builds institutional knowledge over time.

---

## Agent/Skill Invocation Control

Source: https://code.claude.com/docs/en/skills

| Control | Effect |
|---|---|
| `disable-model-invocation: true` | Claude cannot trigger; user-only via `/name` |
| `user-invocable: false` | Hidden from `/` menu; Claude-only trigger |
| Both false (default) | Both Claude and user can invoke |
| `Skill(name)` in permissions deny | Blocks that skill entirely |
| `Skill(deploy *)` in permissions deny | Blocks skill with prefix match |

---

## Gaps in the Current Project

Comparing what exists against best practices:

1. **No `memory` field on any agent** — the reviewer and researcher could accumulate codebase knowledge across sessions. Low cost, high value for long-lived projects.

2. **No `isolation: worktree` on researcher** — researcher currently runs in the same working tree. Adding `isolation: worktree` would prevent any accidental writes and make research side-effect-free.

3. **No doc-updater agent** — no agent exists to keep `CLAUDE.md`, architecture docs, or a product overview in sync with code changes. The slug-based ADR pattern from wshobson/agents is the most structured approach seen.

4. **No `SessionStart` hook for context injection** — a hook that loads recent git log, open PRs, or current branch state into session context is a common pattern missing here.

5. **No `Stop` hook enforcing test passage** — verifier is invoked manually by the milestone skill. A `Stop` hook could enforce this automatically.

6. **Duplicate allow-list entries** in `.claude/settings.json` (lines 3-15 duplicated in 15-63) — cleanup needed.

7. **No architecture-doc agent** — no agent that reads the codebase and generates/updates `docs/ARCHITECTURE.md` or similar. The wshobson pattern uses an `architect` agent that writes ADRs.

8. **Skills lack `context: fork` for research** — the research skill dispatches to the researcher subagent, but the skill itself doesn't use `context: fork`. This is intentional in the current design but worth noting — the skills-to-subagent bridging pattern is correct.

---

## Sources

- Official subagents docs: https://code.claude.com/docs/en/sub-agents
- Official skills docs: https://code.claude.com/docs/en/skills
- Official hooks reference: https://code.claude.com/docs/en/hooks
- Anthropic skills repo: https://github.com/anthropics/skills/
- wshobson agents collection (112 agents): https://github.com/wshobson/agents
- Awesome claude-code collection: https://github.com/hesreallyhim/awesome-claude-code
- PubNub subagent best practices (slug/ADR pattern): https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/
- Claudefast agent teams guide: https://claudefa.st/blog/guide/agents/agent-teams
- Claudefast subagent best practices: https://claudefa.st/blog/guide/agents/sub-agent-best-practices
- Shipyard multi-agent orchestration 2026: https://shipyard.build/blog/claude-code-multi-agent/
- Hooks guide (20+ examples): https://aiorg.dev/blog/claude-code-hooks
- DEV.to hooks guide Feb 2026: https://dev.to/lukaszfryc/claude-code-hooks-complete-guide-with-20-ready-to-use-examples-2026-dcg
- AI OS blueprint 2026: https://dev.to/jan_lucasandmann_bb9257c/claude-code-to-ai-os-blueprint-skills-hooks-agents-mcp-setup-in-2026-46gg
- Docusaurus doc-updater agent: https://medium.com/@dan.avila7/automated-documentation-with-claude-code-building-self-updating-docs-using-docusaurus-agent-2c85d3ec0e19
- Claudelog custom agents: https://claudelog.com/mechanics/custom-agents/
- Agent architecture (ZenML): https://www.zenml.io/llmops-database/claude-code-agent-architecture-single-threaded-master-loop-for-autonomous-coding
- Spec-driven development with Claude Code: https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development
