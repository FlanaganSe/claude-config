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

---

## Example processes

### 1. Brand new project (greenfield)

You're starting from scratch. No code, no config.

```
mkdir my-app && cd my-app
git init
```

Then in Claude Code:

```
/init-new-proj next.js saas
```

This scaffolds everything — CLAUDE.md, .claude/, docs/, .gitignore — adapted for your stack. The skill fills in `stack.md` with real values, sets the right commands in CLAUDE.md, and writes permissions for your toolchain.

**What to do next:**

1. Skim the generated `CLAUDE.md` — make sure the commands are right.
2. Start building. For your first real feature:

```
/prd "user authentication with email/password and OAuth"
```

3. Read `prd.md`. Edit anything that's wrong. Then:

```
/research
/plan
```

4. Read `plan.md`. This is your checkpoint — approve or ask for changes. When satisfied:

```
/milestone
```

5. Claude executes, verifies, reviews, commits per milestone. After the last one:

```
/complete
```

6. As invariants emerge ("never access the DB directly from route handlers"), add them to `.claude/rules/immutable.md`. They'll load in every future session.

7. Once your architecture has real shape, fill in `docs/SYSTEM.md` and uncomment `@docs/SYSTEM.md` in CLAUDE.md so it loads every session.

---

### 2. Existing project without this configuration (brownfield adoption)

You have an existing codebase with code but no Claude Code config (or just a basic CLAUDE.md).

```
cd existing-project
```

In Claude Code:

```
/init-new-proj python fastapi
```

The skill detects existing files and asks before overwriting anything. It adapts the template for your stack.

**What to do next:**

1. **Merge with existing config.** If you had a CLAUDE.md already, compare the generated one with yours. Keep any project-specific instructions and merge them into the new structure.

2. **Fill in what you already know.** You have an existing codebase, so you can immediately populate:
   - `stack.md` — you know your stack
   - `conventions.md` — you know your patterns
   - `immutable.md` — you know your invariants ("never mutate state in reducers", "all API responses go through the serializer")

3. **Generate a system doc.** Run `/product-overview` — it reads your entire codebase and writes a comprehensive overview to `docs/product-overview.md`. Use this to bootstrap `docs/SYSTEM.md` by extracting the architecture and constraints sections.

4. **Use the workflow for your next feature.** Don't try to retroactively document everything. Start using `/prd` → `/plan` → `/milestone` → `/complete` on your next task. The researcher agent will learn the codebase organically, and its project memory accumulates across sessions.

---

### 3. Existing project with this configuration (day-to-day building)

You have this config set up and you're building features.

**For a substantial feature (new module, API, major change):**

```
/prd "add Stripe billing integration"
```

Review the PRD. If you've done external research (reading Stripe docs, checking examples), paste it into `.claude/plans/research.md` before the next step.

```
/research
```

The researcher reads the PRD, investigates your codebase (it remembers past investigations via project memory), and writes findings. Then:

```
/plan
```

**Read the plan carefully.** This is where you catch architectural mistakes before any code is written. Check: does it touch the right files? Does it respect your immutable rules? Are the milestones small enough?

When satisfied:

```
/milestone
```

Claude works through each milestone autonomously — implementing, verifying, committing, reviewing. If the reviewer flags a critical issue, Claude fixes it before moving on. After the last milestone, it prompts you to run:

```
/complete
```

This promotes any architectural decisions (e.g., "chose Stripe webhooks over polling") to `docs/decisions.md` as ADRs, then cleans up the ephemeral plan files.

**For a small change (bug fix, tweak, quick addition):**

Skip the pipeline. Just describe what you need directly:

```
Fix the race condition in the checkout flow — the cart total updates after the payment intent is created
```

Claude works on it. After it's done, optionally:

```
/review
```

for a fresh-context code review. No need for the full /prd → /complete cycle on small tasks.

**Periodic maintenance:**

- Run `/product-overview` after major milestones to keep the system overview current.
- Run `/doc-clean` to prune stale plans or research notes that accumulated.
- Add new invariants to `immutable.md` when you discover them ("all dates must be UTC", "never use raw SQL outside the repository layer").

---

### 4. Migrating from existing Claude Code config

You have a project with some Claude Code setup (maybe a CLAUDE.md, maybe some custom skills) and want to adopt this structure.

**Don't blow away what you have.** Instead:

1. **Audit your current setup.** Check what exists:
   - Do you have a CLAUDE.md? What's in it?
   - Do you have `.claude/settings.json`? What permissions are set?
   - Any existing skills, agents, hooks, or rules?

2. **Scaffold alongside.** Run `/init-new-proj [your-stack]` in the project. When it asks about overwriting existing files, say no. It will create the files that don't exist yet and skip the ones that do.

3. **Merge manually.** For each file that already existed:
   - **CLAUDE.md** — Take the new template structure (thin hub, rules refs, workflow line, escalation policy). Move any project-specific instructions from your old CLAUDE.md into the appropriate location:
     - Build commands → CLAUDE.md Commands section
     - Code style rules → `.claude/rules/conventions.md`
     - Architecture notes → `docs/SYSTEM.md`
     - Technology choices → `.claude/rules/stack.md`
     - Hard rules/invariants → `.claude/rules/immutable.md`
   - **settings.json** — Merge your existing permissions with the template. Keep your project-specific allow/deny rules. Add the hooks (PreToolUse for safety, PostToolUse for auto-format).
   - **Existing skills** — If you have custom skills, keep them. The template skills won't conflict — they use distinct names (`prd`, `research`, `plan`, `milestone`, `verify`, `review`, `complete`).

4. **Adopt the workflow gradually.** You don't have to use every skill immediately. Start with the parts that help most:
   - `/review` after implementation — immediate value, no setup needed
   - `/research` before planning — helps Claude understand your codebase
   - `/prd` → `/plan` → `/milestone` for the next substantial feature
   - `/complete` to keep plans from accumulating

5. **Fill in SYSTEM.md.** Run `/product-overview` to generate a comprehensive overview, then curate the architecture and constraints into `docs/SYSTEM.md`. Uncomment `@docs/SYSTEM.md` in CLAUDE.md once it has real content.
