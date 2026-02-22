# claude-config

A reusable Claude Code configuration template. Copy `.claude/` and `CLAUDE.md` into a new project to get a structured AI workflow out of the box.

---

## What this gives you

A six-step workflow for building features with Claude:

```
/prd "description"   → writes .claude/plans/prd.md
/research            → researcher agent investigates codebase
/plan                → generates implementation plan
  ↓ you review plan.md and approve
/milestone           → splits plan, executes milestone by milestone
/verify              → run tests via verifier agent
/review              → fresh-context code review via reviewer agent
```

Each step produces a file. The next step reads it. You control when to advance.

---

## Directory structure

```
.claude/
├── agents/
│   ├── researcher.md    # Read-only investigation, writes research.md
│   ├── reviewer.md      # Fresh-context code review after implementation
│   └── verifier.md      # Runs tests and reports results, never fixes
├── skills/
│   ├── prd/             # /prd — generate product requirements doc
│   ├── research/        # /research — trigger researcher agent
│   ├── plan/            # /plan — generate implementation plan
│   ├── milestone/       # /milestone — split plan and execute
│   ├── verify/          # /verify — trigger verifier agent manually
│   └── review/          # /review — trigger reviewer agent manually
├── rules/
│   ├── immutable.md     # Non-negotiable rules (always loaded)
│   ├── conventions.md   # Code style and established patterns
│   └── stack.md         # Technology choices
├── hooks/
│   └── block-dangerous-commands.sh   # Blocks rm -rf, push to main
├── plans/               # Ephemeral working artifacts (gitignored)
├── settings.json        # Shared permissions and hooks
└── settings.local.json  # Personal overrides (gitignored)
CLAUDE.md                # Project instructions loaded every session
```

---

## Setting up a new project

1. Copy `.claude/` and `CLAUDE.md` into your project root.
2. Fill in `CLAUDE.md` — project name, commands, description.
3. Fill in `.claude/rules/stack.md` — your actual runtime, database, test runner.
4. Add real rules to `.claude/rules/immutable.md` as you discover them.
5. Create `.gitignore` entries (or add to existing):
   ```
   .claude/plans/*.md
   .claude/settings.local.json
   ```

---

## How the workflow runs

**Planning phase** (you control each step):

- `/prd "add user auth"` — Claude writes a requirements doc. Read it, edit it if needed.
- Optionally paste external research (Gemini, ChatGPT, docs) into `.claude/plans/research.md` first.
- `/research` — researcher agent reads the PRD, investigates your codebase, appends findings.
- `/plan` — Claude reads PRD + research, writes a step-by-step implementation plan. **Review this before proceeding.**

**Execution phase** (Claude runs autonomously per milestone):

- `/milestone` — Claude splits the plan into small committable milestones and starts executing. After each:
  - Runs verification commands
  - Spawns verifier agent for test confirmation
  - Commits
  - Spawns reviewer agent for bug check
  - Fixes any critical issues before moving on

**Between milestones:** run `/clear` to reset context. Auto memory preserves what matters; stale implementation details don't carry over.

---

## Agents vs. skills

**Agents** (`.claude/agents/`) are subprocesses Claude spawns via `Task(...)`. Each gets isolated context, specific tools, and a defined role. Researcher, reviewer, and verifier are agents because their outputs should not contaminate the main context window.

**Skills** (`.claude/skills/`) are slash commands you invoke. Workflow skills (`/prd`, `/plan`, `/milestone`) have `disable-model-invocation: true` — Claude cannot trigger them automatically. You control when each phase begins.

---

## Permissions

`settings.json` sets conservative team defaults:

| Tier | What's there |
|---|---|
| `allow` | Read, search, pnpm, git status/diff/log |
| `ask` | Edit, Write, git add/commit |
| `deny` | .env files, secrets dirs, git push, rm -rf, curl/wget |

`settings.local.json` (gitignored) promotes Edit/Write/commit to `allow` for personal use. The hook also blocks `rm -rf` and pushes to main/master as a hard safety layer.

---

## Model tiering

| Agent | Model | Why |
|---|---|---|
| verifier | haiku | Runs commands and reports output — no deep reasoning needed |
| researcher | sonnet | Needs solid reasoning for codebase analysis |
| reviewer | sonnet | Needs solid reasoning for bug detection |
| main agent | your subscription default | Full task orchestration |
