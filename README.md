# codex-config

A reusable Codex configuration template. Copy `.codex/`, `.agents/`, and `AGENTS.md` into a project to get a structured workflow that mirrors the original Claude template in Codex-native format.
Validated against official Codex docs and changelog guidance current as of February 2026.

---

## What this gives you

A six-step workflow for building features with Codex skills:

```
$prd "description"   -> writes .plans/prd.md
$research            -> researcher role investigates codebase
$plan                -> generates implementation plan
  -> you review plan.md and approve
$milestone           -> splits plan, executes milestone by milestone
$verify              -> runs checks via verifier role
$review              -> fresh-context bug review via reviewer role
```

Each step produces a file. The next step reads it. You control when to advance.

---

## Directory structure

```text
.codex/
├── config.toml                 # Team defaults: sandbox, approvals, roles
├── rules/
│   └── default.rules           # Command safety rules for escalated execution
└── agents/
    ├── researcher.toml         # Read-mostly research role
    ├── reviewer.toml           # Fresh-context reviewer role
    └── verifier.toml           # Verification-only role
.agents/
├── skills/
│   ├── prd/                    # $prd
│   ├── research/               # $research
│   ├── plan/                   # $plan
│   ├── milestone/              # $milestone
│   ├── verify/                 # $verify
│   └── review/                 # $review
├── rules/
│   ├── immutable.md            # Non-negotiable rules
│   ├── conventions.md          # Code style and patterns
│   └── stack.md                # Technology choices
.plans/
└── *.md                        # Ephemeral PRD/research/plan artifacts (gitignored)
AGENTS.md                       # Root instructions auto-loaded by Codex
```

---

## Setup in a new project

1. Copy `.codex/`, `.agents/`, and `AGENTS.md` into the target repo.
2. Fill in `AGENTS.md` with real project commands and description.
3. Fill in `.agents/rules/stack.md` with actual runtime/framework/test tooling.
4. Add real invariants to `.agents/rules/immutable.md`.
5. Add these entries to `.gitignore`:
   ```gitignore
   .plans/*.md
   .codex/config.local.toml
   ```
6. Trust the project in Codex so `.codex/config.toml` is applied.

---

## How the workflow runs

Planning phase:
- `$prd "add user auth"` writes a concise PRD.
- Optionally add external notes to `.plans/research.md`.
- `$research` investigates and appends findings.
- `$plan` generates a step-by-step implementation plan. Review before execution.

Execution phase:
- `$milestone` splits the plan into small milestones and executes sequentially.
- After each milestone it runs checks, verifies, reviews, and then proceeds.

Between milestones, use `/clear` to reset context if needed.

---

## Critical translation notes

What stayed near-identical:
- Same PRD -> research -> plan -> milestone -> verify -> review flow.
- Same three specialist roles (researcher, verifier, reviewer).
- Same immutable/conventions/stack docs and plan artifacts model.

What changed for Codex best practice:
- Claude hooks were replaced by `.codex/rules/*.rules` (Codex-native command gating).
- Claude allow/ask/deny permission lists became `approval_policy` + sandbox mode + rules.
- `CLAUDE.md` became root `AGENTS.md` (Codex instruction entry point).
- Role definitions moved from markdown agent files to `.codex/agents/*.toml`.
- Plan artifacts moved from `.agents/plans/` to `.plans/` because `.agents/` is protected read-only in Codex `workspace-write` sandbox.

High-value small defaults added:
- `web_search = "cached"` to keep web lookups deterministic and lower-cost by default.
- `agents.max_threads = 4` to cap multi-agent concurrency and prevent noisy fan-out.
- Ready-to-use security profiles: `strict`, `readonly`, and `full_auto`.

What does not translate directly:
- Per-tool path denylists like `Read(**/.env*)` are not a first-class Codex config primitive.
  They are enforced here via AGENTS policy and should be backed by org-level safeguards.

---

## Local personal overrides

Use user config (`~/.codex/config.toml`) or profiles for personal defaults.  
This template includes `.codex/config.local.toml.example` as a copy source; keep local overrides uncommitted.
