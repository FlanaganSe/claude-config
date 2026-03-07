# Research: Real-World Advanced Claude Code Configurations (Early 2026)

Research completed: 2026-03-06

---

## 1. Current State of This Repo

The `.claude/` directory is already a solid baseline (L3 on the community maturity scale). Key files:

- `.claude/settings.json:1-97` — permissions (allow/ask/deny), one PreToolUse hook, env vars
- `.claude/hooks/block-dangerous-commands.sh:1-33` — blocks `rm -rf` and push to main via JSON `permissionDecision`
- `.claude/agents/researcher.md`, `reviewer.md`, `verifier.md` — three focused subagents
- `.claude/skills/` — six skills: `milestone`, `plan`, `prd`, `research`, `review`, `verify`
- `.claude/rules/` — three rules files with YAML frontmatter
- No GitHub Actions workflows
- No MCP server configuration
- No `PostToolUse` hooks (auto-format, lint, test)
- No multi-environment or CI configuration
- One hook event type (PreToolUse only)

The skills use `disable-model-invocation: true` on some entries (e.g., `plan/SKILL.md:4`), meaning they are prompt templates rather than autonomous agents.

---

## 2. What Production Teams' .claude/ Directories Look Like

### Representative directory structures

**ChrisWiles/claude-code-showcase** (https://github.com/ChrisWiles/claude-code-showcase):
```
.claude/
├── settings.json
├── settings.local.json
├── agents/code-reviewer.md
├── commands/onboard.md, pr-review.md, ticket.md
├── hooks/skill-eval.sh, skill-eval.js, skill-rules.json
└── skills/testing-patterns/, graphql-schema/, core-components/
.github/workflows/
├── pr-claude-code-review.yml
├── scheduled-claude-code-docs-sync.yml
├── scheduled-claude-code-quality.yml
└── scheduled-claude-code-dependency-audit.yml
```

**albertsikkema/claude-config-template** (https://github.com/albertsikkema/claude-config-template):
```
.claude/
├── agents/          # 16 specialized agents
├── commands/        # 18 slash commands
├── hooks/           # 3-layer security defense
├── helpers/         # utility scripts
├── settings.json
└── settings.local.json
memories/
├── templates/
├── best_practices/
├── technical_docs/
├── security_rules/  # 108 Codeguard OWASP rules
└── shared/plans/, research/, project/
```

**serpro69/claude-starter-kit** (https://github.com/serpro69/claude-starter-kit):
```
.claude/
├── settings.json
├── skills/          # 7 skills
├── agents/          # 3 agents (orchestrator, executor, checker)
├── commands/        # 47 Task Master commands + 2 CoVe commands
└── hooks/
.taskmaster/config.json    # AI model role assignments
.serena/project.yml        # LSP-based code analysis config
```

**shinpr/claude-code-workflows** (https://github.com/shinpr/claude-code-workflows):
```
.claude-plugin/
agents/              # 14+ specialized agents per phase
skills/              # coding-principles, testing-principles, etc.
backend/, frontend/  # plugin variants
```

Pattern: production configs typically have 10-20 agents, 10-50 slash commands, 3-10 hook scripts, and 1-4 GitHub Actions workflows. MCP configuration is in `~/.claude.json` (user-level, not committed).

---

## 3. Custom Skills Beyond plan/prd/research/review/verify

The community has far more variety than the five-skill baseline in this repo.

### Development workflow skills
- `recipe-implement` — end-to-end feature development with PRD, design, plan, build, review phases (shinpr/claude-code-workflows)
- `recipe-diagnose` — problem investigation and solutions
- `recipe-reverse-engineer` — generate docs from code
- `analysis-process` — converts specs into PRDs and design docs (serpro69/claude-starter-kit)
- `implementation-process` — TDD execution with review checkpoints
- `documentation-process` — updates ARCHITECTURE.md and ADRs after implementation
- `cove` — Chain-of-Verification prompting for high-stakes tasks (standard or isolated sub-agent mode)

### Quality skills
- `solid-code-review` — SOLID principles, security, language-specific checklists (Go, Java, JS/TS, Kotlin, Python)
- `testing-process` — guidelines for test coverage including table-driven tests, mocking, benchmarks
- `/security` — 108 OWASP Codeguard rules applied to code review
- `/vulnerability-check` — OSV, GitHub, CISA, NCSC scanning across multiple sources

### Integration skills
- `/ticket` — reads JIRA/Linear, implements, updates status (requires MCP)
- `/pr` — PR description generation from diff
- `/build-c4-docs` — C4 architecture diagram generation
- `/deploy` — automated deployment preparation
- `/fetch-technical-docs` — LLM-optimized docs from context7.com or similar

### Context management skills
- `/index-codebase` — language-specific codebase indexing (Python, JS/TS, Go, C/C++)
- `/cleanup` — documents learnings, updates best_practices/, commits, creates PR

The key gap versus this repo's skill set: no integration skills (ticket, PR, deploy), no OWASP security skill, no Chain-of-Verification skill, no cleanup/documentation skill.

Source: https://github.com/shinpr/claude-code-workflows, https://github.com/albertsikkema/claude-config-template, https://github.com/serpro69/claude-starter-kit, https://github.com/hesreallyhim/awesome-claude-code

---

## 4. Hooks People Use Beyond Blocking Dangerous Commands

As of February 2026, Claude Code supports 14 lifecycle events across 3 handler types (command, prompt, agent). The existing hook in this repo uses only PreToolUse with a command handler.

### All 14 lifecycle events (source: https://smartscope.blog/en/generative-ai/claude/claude-code-hooks-guide/)
1. SessionStart
2. SessionEnd
3. UserPromptSubmit
4. PreToolUse
5. PermissionRequest
6. PostToolUse
7. PostToolUseFailure
8. Notification
9. Stop
10. SubagentStart
11. SubagentStop
12. PreCompact
13. TeammateIdle
14. TaskCompleted

### Production hook patterns in the wild

**PostToolUse — Auto-format on every write:**
Run `npx prettier --write` or language-specific formatter on the edited file path extracted via `jq`. Guarantees AI-generated code matches style guide without relying on Claude to remember.

**PostToolUse — ESLint auto-fix:**
Run `npx eslint --fix` on TypeScript/JavaScript files after any Write or Edit. Exit code non-2 so failures are non-blocking.

**PostToolUse — TypeScript type check:**
Run `npx tsc --noEmit` with a 30-second timeout after TypeScript file edits. Show first 20 error lines.

**PostToolUse — Auto-run tests:**
Async hook (`"async": true`) running `npx vitest run` when test files (`.test.*`, `.spec.*`) are written. 30-second timeout.

**PostToolUse — MCP audit log:**
Matcher `mcp__.*` logs tool names and timestamps to `.claude/mcp-audit.log`.

**Stop — Enforce test coverage:**
Verify `npm test` passes before session ends. Uses `stop_hook_active` environment variable check to prevent infinite loops.

**Stop — Prompt handler for task completion:**
LLM evaluates whether user request was actually completed. If `{"ok": false}`, Claude continues working. (Prompt-type handler, not command-type.)

**Stop — Agent handler for multi-step verification:**
Multi-turn subagent runs test suite, checks TypeScript errors, scans for leftover `console.log`s — up to 50 tool turns.

**SessionStart — Inject context after compaction:**
Matcher `compact` displays branch info and commit history when session resumes from compaction.

**SessionStart — Set environment variables:**
Append project-specific env vars to `$CLAUDE_ENV_FILE` at session start.

**Notification — Desktop notifications:**
macOS: `osascript -e 'display notification...'` when permission prompt appears or task completes. Linux: `notify-send`.

**PreToolUse — Auto-approve safe reads:**
Return `permissionDecision: "allow"` for `Read|Glob|Grep` matchers to eliminate constant dialogs.

**PreToolUse — Rate-limit MCP tools:**
Count calls within 60-second window; block if threshold exceeded.

Source: https://dev.to/lukaszfryc/claude-code-hooks-complete-guide-with-20-ready-to-use-examples-2026-dcg, https://github.com/trailofbits/claude-code-config

### Trail of Bits production hook patterns (source: https://github.com/trailofbits/claude-code-config)
- Block credential reads: `~/.ssh`, `~/.aws`, `~/.kube`, `~/.docker/config.json`, `~/.npmrc`, `~/.pypirc`, `~/.git-credentials`
- Block shell config edits: `.bashrc`, `.zshrc`, `.profile`
- Block direct push to main/master (require feature branches) — this repo already does this
- Stop hook that forces continuation if Claude is rationalizing incomplete work
- Statusline hook showing model, folder, branch, context usage bar, cost, elapsed time, prompt cache hit rate

---

## 5. CI/CD Integration Patterns

This repo has no CI/CD integration. The community has converged on two patterns.

### Pattern A: `@claude` mention in PR/issue comments (reactive)
Trigger: `issue_comment` or `pull_request_review_comment` events when comment body contains `@claude`.
Action: `anthropics/claude-code-action@v1`
Use: ad hoc implementation, question answering, bug fixing in PRs.

Minimal workflow:
```yaml
name: Claude Code
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
jobs:
  claude:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```
Source: https://code.claude.com/docs/en/github-actions

### Pattern B: Scheduled automation (proactive)
Trigger: `schedule` cron or PR open event with `prompt` parameter.
Use: automated PR review, weekly code quality scans, monthly docs sync, biweekly dependency audits.

Examples from ChrisWiles/claude-code-showcase:
- `pr-claude-code-review.yml` — fires on PR open, runs `/review` skill
- `scheduled-claude-code-docs-sync.yml` — monthly documentation alignment
- `scheduled-claude-code-quality.yml` — weekly code quality scan
- `scheduled-claude-code-dependency-audit.yml` — biweekly dependency updates with testing

Key action parameters (v1.0 GA as of 2025):
- `prompt` — instructions for Claude (replaces `direct_prompt` from beta)
- `claude_args` — passthrough CLI flags: `--max-turns 5`, `--model claude-sonnet-4-6`, `--append-system-prompt`
- `use_bedrock: "true"` or `use_vertex: "true"` for enterprise cloud routing

Security guidance: pin actions by commit SHA, use OIDC (not static keys) for AWS/GCP, limit permissions to `contents: write`, `pull-requests: write`, `issues: write`.

Source: https://code.claude.com/docs/en/github-actions, https://github.com/anthropics/claude-code-action

### Production case study metrics
A monorepo team (backend, frontend, mobile, infrastructure) using Claude Code for 4 months reported:
- 5,947 average net lines of code per week (vs. 2,590 pre-Claude)
- 50 average commits per week (vs. 30)
- 2,043 average test lines added weekly (vs. 434)

Their configuration: 25+ skills encoding atomic operations, custom YouTrack MCP server, two workflow speeds (fast for simple tasks, full for complex with subtask decomposition), and review subagents per platform.

Source: https://dev.to/dzianiskarviha/integrating-claude-code-into-production-workflows-lbn

---

## 6. Agent Architectures and Orchestration Patterns

### Built-in subagents (official, as of early 2026)
Source: https://code.claude.com/docs/en/sub-agents

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| Explore | Haiku | Read-only | Fast codebase search |
| Plan | Inherits | Read-only | Planning mode research |
| General-purpose | Inherits | All | Complex multi-step tasks |
| Bash | Inherits | Bash | Terminal in separate context |
| statusline-setup | Sonnet | — | `/statusline` config |
| Claude Code Guide | Haiku | — | Feature questions |

### Subagent frontmatter fields (complete spec)
Source: https://code.claude.com/docs/en/sub-agents

```yaml
---
name: agent-identifier          # required, lowercase + hyphens
description: When to use this   # required, Claude uses for delegation decisions
tools: Read, Grep, Glob, Bash   # allowlist; omit = inherits all
disallowedTools: Write, Edit    # denylist
model: sonnet|opus|haiku|inherit # defaults to inherit
permissionMode: default|acceptEdits|dontAsk|bypassPermissions|plan
maxTurns: 20                    # max agentic turns
skills: [api-conventions, ...]  # preloaded skill content
mcpServers: [slack, github]     # MCP servers available to this agent
hooks: { PreToolUse: [...] }    # lifecycle hooks scoped to this agent
memory: user|project|local      # persistent cross-session memory
background: true                # always run as background task
isolation: worktree             # run in temporary git worktree
---
System prompt here...
```

Key finding: `memory` field enables a subagent to maintain a persistent `MEMORY.md` in `~/.claude/agent-memory/<name>/` or `.claude/agent-memory/<name>/`. First 200 lines load each session. This is an undocumented-in-CLAUDE.md mechanism that the existing agents in this repo do not use.

### Community agent tier patterns
Source: https://github.com/wshobson/agents (112 agents, 72 plugins)

**Tier by model:**
- Opus: architect-review, code-reviewer, security-auditor, language-specific pros (42 agents)
- Sonnet: complex task handlers, domain experts (42 agents)
- Haiku: fast operational tasks — SEO, deployment, simple docs (18 agents)

**Tier by orchestration pattern:**

Sequential pipeline (shinpr/claude-code-workflows):
`requirement-analyzer → prd-creator → technical-designer → acceptance-test-generator → work-planner → task-decomposer → task-executor → quality-fixer → code-reviewer`

Parallel investigation:
`security-auditor + performance-analyst + compatibility-checker` all running simultaneously, results synthesized by orchestrator

**Git worktree isolation:**
Run multiple Claude instances in parallel worktrees — each working on a different feature branch with complete filesystem isolation. Subagents can use `isolation: worktree` frontmatter for automatic worktree creation and cleanup.

### The serpro69 three-agent orchestration model
Source: https://github.com/serpro69/claude-starter-kit

- `task-orchestrator` (Opus): analyzes dependencies, identifies parallelization opportunities
- `task-executor` (Sonnet): implements individual tasks with progress tracking
- `task-checker` (Sonnet): QA verification, test execution before marking complete

This pattern keeps the expensive Opus model at the planning layer only.

---

## 7. Context Priming and Warm-Starting Patterns

### Memory bank multi-file pattern
Source: https://github.com/centminmod/my-claude-code-setup

Four-file memory bank that Claude maintains across sessions:
- `CLAUDE-activeContext.md` — current session: what's in progress, recent decisions
- `CLAUDE-patterns.md` — reusable architectural patterns (22+ indexed)
- `CLAUDE-decisions.md` — ADRs, prevents recurring architectural debates
- `CLAUDE-troubleshooting.md` — issues, solutions, workarounds

Claude updates these files at end of each session via `/update memory bank` command. Enables session recovery without repeating context.

### The three-layer memory system
Source: Community pattern from https://github.com/doobidoo/mcp-memory-service/wiki/CLAUDE.md-MEMORY-PATTERN

- Layer 1: Version-controlled `CLAUDE.md` — stable instructions (you write)
- Layer 2: Local `CLAUDE_MEMORY.md` — per-machine session notes (gitignored)
- Layer 3: MCP Memory Service — full-text search of past sessions

### SessionStart hook for context injection
After compaction or session resume, inject branch info and recent git history automatically. Prevents Claude from operating without understanding where in the project lifecycle work is.

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "compact|resume",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/inject-context.sh"}]
    }]
  }
}
```

### Subagent persistent memory
Source: https://code.claude.com/docs/en/sub-agents

The `memory` frontmatter field in agent definitions enables cross-session learning without manual file management. Reviewer agents accumulate knowledge of codebase patterns; debugger agents remember previously seen error signatures. First 200 lines of `MEMORY.md` inject automatically at subagent start.

### Context efficiency principles (from production teams)
- Under 200 lines per CLAUDE.md file — beyond this adherence degrades (official docs)
- At 50K+ lines of code, a single agent uses 80-90% context just loading files — split into multiple agents each at ~40% usage
- Use `additionalDirectories` in settings.json to grant access to sibling repos without bloating CLAUDE.md
- Subagents keep verbose output (test runs, log analysis) out of main conversation context
- `/clear` between unrelated tasks; don't carry stale context from previous work

---

## 8. Permission Configurations Advanced Users Prefer

### Trail of Bits hardened baseline
Source: https://github.com/trailofbits/claude-code-config

**Deny list (credential protection):**
```json
"deny": [
  "Read(~/.ssh/**)",
  "Read(~/.aws/**)",
  "Read(~/.kube/**)",
  "Read(~/.docker/config.json)",
  "Read(~/.npmrc)",
  "Read(~/.pypirc)",
  "Read(~/.git-credentials)",
  "Edit(~/.bashrc)",
  "Edit(~/.zshrc)",
  "Edit(~/.profile)"
]
```

**Sandbox configuration:**
```json
"sandbox": {
  "enabled": true,
  "filesystem": {
    "denyRead": ["~/.aws/credentials", "~/.ssh"]
  },
  "network": {
    "allowedDomains": ["github.com", "*.npmjs.org", "pypi.org"]
  }
}
```

**Enterprise privacy settings (env vars):**
- `DISABLE_TELEMETRY=1` — disables Statsig analytics
- `DISABLE_ERROR_REPORTING=1` — disables Sentry
- `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1` — disables in-session surveys

**Permission bypass for sandboxed workflows:**
`alias claude-yolo="claude --dangerously-skip-permissions"` — maximum throughput with zero prompts, only safe inside a sandbox or container.

### This repo's current permission posture
`.claude/settings.json:1-97` — safe read operations in `allow`, edits and commits in `ask`, env files and destructive ops in `deny`. The allow list is long (40+ entries) and has duplicate entries (lines 3-14 are a subset of lines 15-62). The deny list blocks `.env` reads, secrets directories, push to main, `rm -rf`, and wget. No sandbox configuration.

### The `enableAllProjectMcpServers: false` default
Production teams explicitly keep this `false` to prevent malicious MCP servers from being auto-approved when pulling a repo. Servers are approved individually via `enabledMcpjsonServers: ["memory", "github"]`.

---

## 9. Managing Multiple Environments / Deployment Targets

### The `settings.local.json` pattern
`.claude/settings.local.json` (gitignored) holds per-machine or per-environment configuration that should not be committed:
- Personal permission overrides
- Local dev URLs and ports
- Environment-specific MCP server credentials

This is the recommended escape hatch for environment differences without forking the shared config.

### Multi-environment via env vars in settings.json
```json
{
  "env": {
    "NODE_ENV": "development",
    "DATABASE_URL": "${LOCAL_DATABASE_URL}"
  }
}
```
Environment variable expansion via `${VAR}` or `${VAR:-default}` in both settings.json and `.mcp.json`.

### Worktree-based parallel environments
Run separate Claude sessions in separate git worktrees, each with its own `.claude/` context. Each session sees a different branch and filesystem state. Combined with `isolation: worktree` on subagents, this enables true parallel feature development.

### Remote devcontainer isolation
For maximum separation: devcontainer configuration exposes only project files to Claude, not the host filesystem. Remote droplets via dropkit (https://github.com/anthropics/claude-code-config mentions dropkit) provide complete separation from the local machine.

---

## 10. Patterns for Maximizing Value in a Codebase

### The RIPER enforcement pattern
Source: https://github.com/hesreallyhim/awesome-claude-code (listed workflow)

Five phases enforced via hooks and skills:
1. Research — read-only exploration
2. Innovate — brainstorm without building
3. Plan — write plan to file, stop
4. Execute — implement from approved plan only
5. Review — fresh-context code review

This matches what this repo already does with researcher/plan/review agents. The innovation: hooks enforce phase gates so Claude cannot skip to Execute without passing through Plan.

### Complexity-driven workflow routing
Source: https://github.com/shinpr/claude-code-workflows

`requirement-analyzer` agent evaluates incoming task and routes to appropriate workflow depth:
- Simple task: direct `task-executor`
- Medium task: `work-planner → task-executor`
- Complex task: `prd-creator → technical-designer → acceptance-test-generator → work-planner → task-decomposer → task-executor`

### 25+ atomic skills for consistent operations
Source: https://dev.to/dzianiskarviha/integrating-claude-code-into-production-workflows-lbn

Rather than generic "implement this feature" prompts, encode domain-specific atomic operations as skills: entity creation, controller implementation, migration generation, test setup. Each skill is a precise recipe Claude executes consistently. The result is less variance in output quality.

### The cleanup/commit skill as mandatory phase
Source: https://github.com/albertsikkema/claude-config-template

Every workflow ends with a mandatory cleanup step:
1. Document what was learned in `memories/best_practices/`
2. Update `memories/project/done.md`
3. Commit with formatted message
4. Create PR description

Teams that skip this accumulate context debt — the next session has no record of what was decided or why.

### SuperClaude cognitive persona pattern
Source: https://github.com/hesreallyhim/awesome-claude-code

Different system prompts for different cognitive modes: "architect" for system design, "security" for vulnerability analysis, "performance" for optimization. Implemented as separate agents or as skill-activated persona shifts.

---

## 11. MCP Server Patterns

Production teams consistently use MCP for external integrations rather than embedding credentials in CLAUDE.md or using Bash workarounds.

### Common MCP server configurations (source: ChrisWiles/claude-code-showcase)
```json
{
  "mcpServers": {
    "jira": { "type": "stdio", "command": "npx", "args": ["-y", "@anthropic/mcp-server-jira"], "env": { "JIRA_TOKEN": "${JIRA_TOKEN}" } },
    "github": { "type": "stdio", "command": "npx", "args": ["-y", "@anthropic/mcp-server-github"], "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" } },
    "postgres": { "type": "stdio", "command": "npx", "args": ["-y", "@anthropic/mcp-server-postgres"], "env": { "DATABASE_URL": "${DATABASE_URL}" } },
    "sentry": { "type": "stdio", "command": "npx", "args": ["-y", "@anthropic/mcp-server-sentry"], "env": { "SENTRY_TOKEN": "${SENTRY_TOKEN}" } }
  }
}
```

### User-level MCP (not committed) via `~/.claude.json`
API keys never go in project `.mcp.json`. Project file only lists server names and command; credentials come from user-level config or env vars. serpro69/claude-starter-kit: "MCP servers must be configured in `~/.claude.json` (not in the repo) to keep API keys safe."

### Context7 (no API key)
Most commonly cited free MCP server: current library documentation. No API key required. Install: Context7 MCP server provides up-to-date library docs Claude would otherwise hallucinate.

### Serena (LSP-based code analysis)
Source: https://github.com/serpro69/claude-starter-kit

Language-aware semantic analysis via Language Server Protocol. Gives Claude go-to-definition, find-references, and symbol search without grepping. Works for Python, TypeScript, Go, etc.

---

## 12. Key Gaps in This Repo vs. Production Patterns

| Pattern | This Repo | Production Norm |
|---------|-----------|----------------|
| PostToolUse auto-format | Missing | Universal |
| PostToolUse type-check | Missing | Common |
| Stop hook (test gate) | Missing | Common |
| SessionStart context injection | Missing | Common |
| Desktop notifications | Missing | Common |
| GitHub Actions PR review | Missing | Very common |
| GitHub Actions scheduled quality | Missing | Common |
| MCP server config | Missing | Common |
| Subagent `memory` field | Missing | Available, underused |
| Credential deny rules | Partial (no ~/.ssh, ~/.aws) | Full credential protection |
| Duplicate allow rules in settings.json | Present (lines 3-14 repeat 15-27) | Should be cleaned |
| Cleanup/commit skill | Missing | Present in mature setups |
| Complexity-routing agent | Missing | Present in advanced setups |
| Chain-of-Verification skill | Missing | Present for high-stakes work |
| `settings.local.json` pattern | Not documented | Used universally |

---

## Sources

- https://github.com/hesreallyhim/awesome-claude-code — primary community aggregator
- https://github.com/trailofbits/claude-code-config — security-focused baseline
- https://github.com/ChrisWiles/claude-code-showcase — hooks + GitHub Actions showcase
- https://github.com/serpro69/claude-starter-kit — MCP + multi-agent orchestration starter
- https://github.com/albertsikkema/claude-config-template — 16 agents, 18 commands, 3-layer security
- https://github.com/shinpr/claude-code-workflows — complexity-routing pipeline
- https://github.com/wshobson/agents — 112 agents across 72 plugins with tier model
- https://github.com/centminmod/my-claude-code-setup — memory bank multi-file pattern
- https://github.com/rohitg00/awesome-claude-code-toolkit — 135 agents, 42 commands, 19 hooks
- https://code.claude.com/docs/en/sub-agents — official subagent specification
- https://code.claude.com/docs/en/settings — complete settings.json reference
- https://code.claude.com/docs/en/github-actions — official CI/CD integration docs
- https://smartscope.blog/en/generative-ai/claude/claude-code-hooks-guide/ — 14 events, 3 handler types (February 2026)
- https://dev.to/lukaszfryc/claude-code-hooks-complete-guide-with-20-ready-to-use-examples-2026-dcg — 22 hook examples
- https://dev.to/dzianiskarviha/integrating-claude-code-into-production-workflows-lbn — production case study (40% productivity gain)
- https://joseparreogarcia.substack.com/p/claude-code-memory-explained — memory architecture deep dive
- https://www.builder.io/blog/claude-code — power user workflow tips
- https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are — creator workflow
