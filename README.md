# claude-config

A reusable Claude Code configuration template. Scaffold into any project with `/init-new-proj`.

---

## What this gives you

A seven-step workflow for building features with Claude:

```
/prd "description"   → writes .claude/plans/prd.md
/research            → researcher agent investigates codebase
/plan                → generates implementation plan
  ↓ you review plan.md and approve
/milestone           → splits plan, executes milestone by milestone
/verify              → run tests via verifier agent
/review              → fresh-context code review via reviewer agent
/complete            → promotes decisions to ADR, cleans up plan files
```

Each step produces a file. The next step reads it. You control when to advance.

---

## Directory structure

```
CLAUDE.md                    # Thin hub (<35 lines). Loaded every session.
CLAUDE.local.md              # Personal overrides (gitignored)
.gitignore

.claude/
├── agents/
│   ├── researcher.md        # Read-only investigation (memory: project)
│   ├── reviewer.md          # Fresh-context code review (memory: project)
│   └── verifier.md          # Runs tests, reports results, never fixes
├── skills/
│   ├── prd/                 # /prd — generate product requirements doc
│   ├── research/            # /research — trigger researcher agent
│   ├── plan/                # /plan — generate implementation plan
│   ├── milestone/           # /milestone — split plan and execute
│   ├── verify/              # /verify — trigger verifier agent
│   ├── review/              # /review — trigger reviewer agent
│   └── complete/            # /complete — close task, promote ADRs, cleanup
├── rules/
│   ├── immutable.md         # Non-negotiable rules (always loaded)
│   ├── conventions.md       # Code style and established patterns
│   └── stack.md             # Technology choices
├── hooks/
│   ├── block-dangerous-commands.sh   # Blocks rm -rf, push to main
│   └── auto-format.sh               # Auto-formats on every file edit
├── plans/                   # Ephemeral working artifacts
└── settings.json            # Shared permissions and hooks

docs/
├── SYSTEM.md                # Domain + architecture + constraints (curated)
└── decisions.md             # Append-only ADR log
```

---

## Setting up a new project

From any directory, run `/init-new-proj [project-type]`. The global skill reads this template, adapts it for your stack, and writes all files.

Or manually:

1. Copy `.claude/`, `CLAUDE.md`, `docs/`, and `.gitignore` into your project root.
2. Fill in `CLAUDE.md` — project name, commands, description.
3. Fill in `.claude/rules/stack.md` — your actual runtime, database, test runner.
4. Add real rules to `.claude/rules/immutable.md` as you discover them.
5. Fill in `docs/SYSTEM.md` when you have real architecture to document.

---

## How the workflow runs

**Planning phase** (you control each step):

- `/prd "add user auth"` — Claude writes requirements. Read it, edit if needed.
- Optionally paste external research into `.claude/plans/research.md` first.
- `/research` — researcher agent investigates codebase, appends findings.
- `/plan` — reads PRD + research, writes step-by-step plan. **Review before proceeding.**

**Execution phase** (Claude runs autonomously per milestone):

- `/milestone` — splits plan into small committable milestones and executes. After each:
  - Runs verification commands via verifier agent
  - Commits
  - Runs code review via reviewer agent
  - Fixes critical issues before moving on

**Completion phase:**

- `/complete` — promotes any architectural decisions to `docs/decisions.md` as ADRs, deletes ephemeral plan files.

---

## What's global vs. project

| Location | Scope | Contains |
|----------|-------|----------|
| `~/.claude/CLAUDE.md` | All projects | Personal code preferences, workflow habits |
| `~/.claude/settings.json` | All projects | Credential denies, notification hooks, effort level |
| `~/.claude/skills/` | All projects | `/init-new-proj`, `/product-overview`, `/doc-clean`, `/summary` |
| `.claude/settings.json` | This project (team) | Permission tiers, project hooks, env vars |
| `.claude/rules/` | This project (team) | Conventions, stack, invariants |
| `.claude/agents/` | This project (team) | Researcher, reviewer, verifier (with project memory) |
| `.claude/skills/` | This project (team) | Workflow pipeline skills |
| `CLAUDE.local.md` | This project (you) | Personal overrides, gitignored |

---

## Agents

| Agent | Model | Memory | Purpose |
|-------|-------|--------|---------|
| researcher | sonnet | project | Codebase + web research before planning |
| reviewer | sonnet | project | Bug detection after implementation |
| verifier | haiku | — | Run checks, report pass/fail |

Researcher and reviewer accumulate project knowledge across sessions via `memory: project`.

---

## Permissions

`settings.json` sets conservative team defaults:

| Tier | What's there |
|---|---|
| `allow` | Read, search, pnpm/npx, git status/diff/log, common CLI tools |
| `ask` | Edit, Write, git add/commit, curl |
| `deny` | .env files, secrets dirs, git push, rm -rf, wget |

Global `~/.claude/settings.json` adds credential protection (deny reads to `~/.ssh`, `~/.aws`, `~/.kube`, etc.).

---

## Hooks

| Hook | Event | What it does |
|------|-------|-------------|
| `block-dangerous-commands.sh` | PreToolUse (Bash) | Blocks `rm -rf` and push to main/master |
| `auto-format.sh` | PostToolUse (Edit/Write) | Auto-detects and runs project formatter |
