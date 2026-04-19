---
name: orchestrate
description: "Meta-orchestrator — refine intent → plan phases → route across the full skill library → execute → verify → commit → deploy. Configurable gates. 'go' is the approval password. Supersedes /project-orchestrator. Triggers on: orchestrate, meta-orchestrate, do this end-to-end, full pipeline, /orchestrate."
argument-hint: "<intent> [--gated | --autonomous | --approve-at=<phases>] [--budget=<usd>] [--as-routine '<cron>'] [--resume <run-id>] [--list] [--show <run-id>]"
user-invocable: true
context: fork
model: opus
effort: high
alwaysThinkingEnabled: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - Monitor
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - Skill
  - WebSearch
  - WebFetch
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Skill: { destructiveHint: false, idempotentHint: false }
  Agent: { destructiveHint: false, idempotentHint: false }
orchestrate-config:
  default-mode: gated
  budget-warn-usd: 10
  budget-cap-usd: 50
  approval-password: "go"
  always-gated-phases:
    - deploy-production
    - destructive-git
    - db-migration
    - budget-breach
    - cross-repo
  max-phase-retries: 3
  context-handoff-threshold: 0.80
  v1-repo-lock: example-project
  router:
    model: opus
    effort: xhigh
    confidence-threshold: 0.75
    fallback: qmd
  fanout:
    gated: sequential
    autonomous: parallel
    approve-at: parallel-between-gates
  routines:
    first-class: true
    delegate-to: schedule
---

# `/orchestrate` — Meta-Orchestrator

`/orchestrate` composes the existing 83-skill library into end-to-end runs. It never reimplements a skill. Its only new logic is: intent refinement, dynamic routing, approval gating, per-phase state, budget enforcement, and final reporting.

**v1 scope (locked 2026-04-17):**
- ExampleProject single-repo only
- Budget $10 warn / $50 hard cap per run
- Approval password: the literal word `go`
- Sequential fan-out in `--gated`, parallel fan-out in `--autonomous`
- Routines first-class via `--as-routine`
- Full 83-skill catalog + qmd/mem-search fallback
- Lives in private `~/.claude-setup/skills/orchestrate/` only

---

## Invocation

```bash
# Default — gated at every phase boundary, type 'go' to approve
/orchestrate "implement dark mode toggle"

# Fully autonomous — no gates except always-gated floor
/orchestrate "run daily GEO strategy check" --autonomous

# Granular — only gate before plan and before deploy
/orchestrate "ship the uncommitted changes" --approve-at=plan,deploy

# Budget override (default: warn $10, cap $50)
/orchestrate "deep-research the agent browser market" --budget=15

# Register as a scheduled Routine
/orchestrate "run /chief-geo daily at 8am BRT" --as-routine "0 8 * * *"

# Resume an interrupted run
/orchestrate --resume 2026-04-17-abc123

# Inspect or list runs
/orchestrate --show 2026-04-17-abc123
/orchestrate --list
```

---

## Pre-Flight (always run first)

1. **Repo lock check** — `git remote get-url origin` must match ExampleProject's origin. If not, refuse with: `v1 is ExampleProject-only. Run /orchestrate inside the ExampleProject repo, or wait for v2 multi-repo support.`
2. **Flag validation** — reject conflicting flags (`--gated` + `--autonomous`, etc.).
3. **Budget bounds** — cap must be 1 ≤ cap ≤ 200; warn must be ≤ cap.
4. **Catalog regen** — run `~/.claude-setup/skills/orchestrate/build-catalog.sh` to produce fresh `skill-catalog.json` from `~/.claude-setup/skills/*/SKILL.md`. Skills with `user-invocable: false` are excluded.
5. **Print startup summary** (below) and confirm.

### Startup Summary

```
╔════════════════════════════════════════════════════════════╗
║ /orchestrate                                                ║
╠════════════════════════════════════════════════════════════╣
║ Intent : {first 100 chars}                                  ║
║ Mode   : {gated | autonomous | approve-at=<phases>}         ║
║ Budget : warn $10 / cap $50 (or overrides)                  ║
║ Run ID : {yyyy-mm-dd-<6char>}                               ║
║ Dir    : .orchestrate/{run-id}/                             ║
╠════════════════════════════════════════════════════════════╣
║ Always-gated regardless of mode:                            ║
║  · production deploys                                        ║
║  · destructive git ops (--force, reset --hard, branch -D)    ║
║  · DB migrations and data destructive SQL                    ║
║  · budget breaches (warn / cap)                              ║
║ Approval password: type 'go' (case-insensitive, whole word)  ║
╚════════════════════════════════════════════════════════════╝
Reply 'go' to proceed, or describe a change to mode/budget/intent.
```

---

## The 9-Phase State Machine

Each phase writes exactly one artifact to `.orchestrate/<run-id>/`. Phases resume independently.

### Phase 1: Intent Capture
- Parse flags → `intent.json { raw, mode, approveAt, budgetWarn, budgetCap, asRoutine, runId, startedAt }`.
- If `--as-routine <cron>` is set, jump to **Routine Registration** (below) instead of executing now.
- Write `intent.json`.

### Phase 2: Refine
- `~/.claude-setup/tools/mem-search "<keywords>"` — max 2 calls.
- `qmd` for skill/pattern hits — max 1 call.
- Invoke `/primer` if resuming or stale.
- Ask up to 3 `AskUserQuestion` prompts (budget: 5k orchestrator tokens).
- Write `refined-intent.md` — goal, scope, acceptance criteria, constraints, prior hits.

### Phase 3: Plan
Invoke the router (see `router.md`). Produces `phase-plan.md`:
```markdown
# Phase Plan: <run-id>
## Phase 5.1 — /deep-plan
  Rationale : ...
  Args      : ...
  Gate      : yes (deep-plan HARD-GATE) | no
  Parallel  : false
  Est mins  : 10
  Est cost  : $2.40
  Success   : plan.md approved
## Phase 5.2 — /ship
  ...
```

The router **must** include for each sub-phase: `parallel: true|false` (enables fan-out), `requires_gate: true|false`, `cost_estimate_usd`.

### Phase 4: Approve (conditional)
Triggers per mode:
- `--gated` → always gate at Phase 4 (whole-plan approval).
- `--autonomous` → skip unless any sub-phase is in always-gated list.
- `--approve-at=plan,...` → gate if `plan` in list.

Gate UX:
```
Plan summary:
  1. /deep-plan — "dark mode toggle using Zustand persist"
  2. /ship — resume-from-plan-md
  3. /verify + /qa-cycle
  4. /cpr — feat(dark-mode): implement toggle
  5. [no deploy]

Estimated cost: $8.20 / cap $50
Estimated time: 45-70 min

Type 'go' to approve, or describe changes (max 2 revise loops).
```

If user replies anything other than `go` (case-insensitive whole-word match on `\bgo\b`), treat as revise. After 2 revisions without `go`, save state and exit.

### Phase 5: Execute
Iterate `phase-plan.md`. For each sub-phase:
1. **Gate check** — gate if `--gated`, or the sub-phase's `requires_gate: true`, or projected cost would cross the warn or cap threshold.
2. **Fan-out decision** — per mode:
   - `--gated` → sequential, one at a time.
   - `--autonomous` → if the next N sub-phases have `parallel: true` and no shared files, dispatch all N in a single tool-call batch (parallel-first.md).
   - `--approve-at=<list>` → between gates, fan out per autonomous policy.
3. **Invoke** via the Skill tool (preferred, same context) or Agent tool (fork, for parallel). Delegated skill inherits its own model tier from its SKILL.md.
4. **Parse exit status** — STATUS line protocol (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED), per `/ship` v5.1.0.
5. **Write** `phase-NN/summary.md` + update `state.json` + update `budget.json`.
6. **Context check** — if orchestrator context ≥ 80%, write `handoff.md`, exit cleanly.

**Fan-out instruction injected into Opus 4.7 calls** (required per `opus-4-7-prompting.md`):
> Do not spawn a subagent for work you can complete directly in a single response. Spawn multiple subagents in the same turn when fanning out across independent phases.

### Phase 6: Verify
- `/verify` (typecheck + tests + build).
- Project-specific QA: `/qa-cycle` (ExampleProject v1), else `/qa-cycle`.
- On failure:
  - typecheck/test → `/test-and-fix` ×3, then `/codex:rescue`, then escalate.
  - QA → `/qa-fix` ×3 + ``, then `/codex:rescue`, then escalate.
- Write `verify-report.md`.

### Phase 7: Ship
- `/review-changes` → `/cpr` (or `/sc` alias).
- Skip if no uncommitted work.
- Write `ship-log.md` with commit SHAs + PR URL.

### Phase 8: Deploy (always gated)
- Runs only if intent/plan mentioned deploy.
- **Hard-gated regardless of mode.** User must reply `go`.
- Project detect → `/deploy-staging` | `/deploy-production` | `/deploy-full`.
- Guardian first: `/guardian`.
- Post-deploy health in the deploy skill.
- Prod failure → offer `/revert-track`. Never auto-retry prod.
- Write `deploy-log.md`.

### Phase 9: Report + Learn
- Write `REPORT.md` — per-phase outcomes, files, SHAs, PR, deploys, cost, duration, attention items.
- Auto-invoke `/meditate` if run > 30 min OR run used ≥3 distinct skills in a sequence. Pass `run-id` and `phase-plan.md` path so `/meditate` Phase 6a can detect chain novelty/repetition and propose new skills or canonical chains.
- `/meditate` Phase 6a may return a skill/chain proposal. If yes, display to user and require `go` to save (never auto-commit).
- `--pdf` flag → render REPORT via `/officecli`.

---

## Approval Password (the word `go`)

All gates use the same matcher:
```
APPROVED  ⟺  user reply matches /\bgo\b/i
REVISE    ⟺  any other non-empty reply
TIMEOUT   ⟺  30 min idle → save state, exit
```
Partial matches like "going", "ago", "google" do **not** match (the `\b` word boundaries prevent it).

Approvals logged to `.orchestrate/<run-id>/approvals.log` with: timestamp, phase, exact user reply, token count.

---

## Always-Gated Floor (mode-independent)

Enforced at the heuristic pre-filter layer before the LLM router runs:

| Trigger | Detection |
|---|---|
| Production deploy | skill name matches `/deploy-.*-production/` or `/deploy-full/` in prod mode |
| Destructive git | bash args contain `push --force`, `reset --hard origin/*`, `branch -D <protected>`, `checkout --`, `clean -f` |
| DB migration | commands touching `alembic upgrade`, `prisma migrate`, `supabase db push`, or SQL with `DROP`, `TRUNCATE`, `DELETE FROM` without `WHERE` |
| Budget breach | projected next-phase cost would push total ≥ warn ($10) or ≥ cap ($50) |
| Cross-repo | file path outside current repo root |
| Secret ops | reads/writes to Keychain, `*.env`, `.env*`, credentials files |

Any trigger forces `requires_gate: true` on that sub-phase.

---

## Fan-Out Policy (locked)

| Mode | Policy |
|---|---|
| `--gated` | Strictly sequential. One sub-phase at a time. |
| `--autonomous` | Parallel when dependency graph allows. Serialized when a sub-phase writes files another reads. |
| `--approve-at=<list>` | Parallel between consecutive gates, sequential across gates. |

Dependency detection: sub-phases are independent if their `artifacts_in` and `artifacts_out` do not intersect and they don't target the same deploy env.

---

## Routines (first-class)

`--as-routine "<cron>"` registers the run as a scheduled Claude Code Routine by delegating to `/schedule`.

Behavior:
- Skips Phase 5+ immediately.
- Writes `routine.json` with intent, mode, budget, cron.
- Invokes `/schedule` with the materialized `/orchestrate` invocation (without `--as-routine`).
- Returns the Routine ID.

Routine runs enforce:
- Mode must be `--autonomous` or `--approve-at=<list>` (pure `--gated` is incompatible with scheduled execution — nobody to gate).
- Always-gated floors still apply: on a prod-deploy trigger, the Routine posts to the configured Discord/Slack channel and waits for a `go` reply before proceeding. If no reply within 60 min, aborts.
- Budget cap enforced per-invocation.
- Model tier R (Opus 4.7 xhigh) per `model-tier-strategy.md`.

---

## Budget Enforcement

Tracked in `.orchestrate/<run-id>/budget.json`:
```json
{
  "warn_usd": 10,
  "cap_usd": 50,
  "spent_usd": 0,
  "breakdown": {
    "orchestrator_tokens": 0,
    "delegated_skills": [],
    "web_calls": 0,
    "external_apis": []
  },
  "projections": {
    "next_phase_usd": 0,
    "remaining_phases_usd": 0
  }
}
```

Thresholds:
- projected ≥ `warn` → inject a `requires_gate: true` on the next sub-phase + warn in log.
- projected ≥ `cap` → hard-stop, user prompt: `go` to extend by another $cap, any other reply to abort with state saved.
- actual ≥ `cap` → immediate hard-stop regardless of projection.

Token cost inputs: Anthropic pricing table cached at `~/.claude-setup/skills/orchestrate/pricing.json`, refreshed weekly.

---

## State Directory

```
.orchestrate/<run-id>/
  state.json              # state machine
  intent.json             # Phase 1
  refined-intent.md       # Phase 2
  shared-context.md       # pre-computed for all downstream phases
  phase-plan.md           # Phase 3
  approval.json           # Phase 4
  phase-01/ phase-02/ ... # Phase 5 sub-phase artifacts
  verify-report.md        # Phase 6
  ship-log.md             # Phase 7
  deploy-log.md           # Phase 8
  handoff.md              # only on context pressure
  approvals.log           # every gate + user reply
  budget.json             # running cost
  learnings.json          # append-only
  REPORT.md               # Phase 9
  routine.json            # only if --as-routine
```

---

## Resume Protocol

`/orchestrate --resume <run-id>`:
1. Read `state.json`. Identify last-complete phase.
2. If `handoff.md` exists, read it first.
3. Read only artifacts needed for next phase.
4. Continue. Delete `handoff.md` on successful resume.

---

## Fallback Behavior

| Condition | Behavior |
|---|---|
| Skill missing from catalog | Regenerate catalog, retry. If still missing, qmd fallback, else user prompt. |
| Skill errors on invocation | Sub-phase BLOCKED. 3-strikes. Try `/codex:rescue`. Then escalate. |
| Plugin skill absent | Non-plugin equivalent if one exists; else escalate. |
| Zero matches in catalog + qmd | User picks manually or aborts. |
| Router confidence < 0.75 | qmd fallback. Still < 0.75 → user picks from top-3 alternatives. |

---

## Composition Patterns (canonical chains)

Router pattern-matches these before firing the LLM classifier:

1. **feature_build** → `/deep-plan` → `/ship` → `/verify` → `/cpr`
2. **release** → `/review-changes` → `/verify` → `/cpr` → `/deploy-staging` (gated) → `/deploy-production` (gated)
3. **complex_feature_with_research** → `/deep-research` → `/deep-plan` → `/ship` → `/verify` → `/cpr` → deploy chain
4. **parallel_batch** → `/architect` (in-place) or `/parallel-dev` (worktree) → `/verify` → `/cpr`
5. **full_product** → `/cpo` (handles most internally) → deploy chain
6. **audit** → `/cto` (swarm) → optional `/qa-fix` + ``
7. **investigate_then_fix** → `/first-principles` → optional `/fulltest-skill` repro → `/deep-plan` → `/ship` → `/verify` → `/cpr`

Pattern-matchers live in `~/.claude-setup/skills/orchestrate/patterns.json`.

---

## Model Tiering (per model-tier-strategy.md)

- **Orchestrator:** Opus 4.7 `xhigh` (Tier R).
- **Router LLM classifier:** Opus 4.7 `xhigh` for v1 (advisor pattern optional in v2 for cost).
- **Delegated skills:** inherit from their own SKILL.md. `/orchestrate` never overrides.
- **Explore/search helpers:** Haiku.

---

## Failure Matrix

| Failure | Handler |
|---|---|
| Sub-phase BLOCKED ×3 | `/codex:rescue` → user |
| Verify fails ×3 | `/test-and-fix` ×3 → `/codex:rescue` → user |
| QA fails ×3 | `/qa-fix` + `` ×3 → `/codex:rescue` → user |
| Deploy health fail | Offer `/revert-track` + re-deploy previous SHA |
| Context ≥ 80% | `handoff.md` + clean exit |
| Budget projected ≥ cap | Hard-stop + `go`-to-extend prompt |
| Idle on gate > 30 min | Save state, exit, resumable |
| Same error ×3 in a row | Hard-stop, preserve state, escalate |
| Remote push rejected | Pull + retry ×1 → escalate |
| Unknown skill referenced | Catalog regen → qmd → user |

---

## Companion Files (in this directory)

- `SKILL.md` — this file
- `build-catalog.sh` — regenerates `skill-catalog.json` from `~/.claude-setup/skills/*/SKILL.md`
- `skill-catalog.json` — generated, ~14KB of skill metadata for router prompt
- `router.md` — router prompt template (JSON schema + rules)
- `patterns.json` — 7 canonical chains
- `pricing.json` — Anthropic pricing for budget estimator
- `VERSION.md` — changelog

---

## Version

**v1.0.0** — Shipping 2026-04-17. All 8 decisions from overnight strategic plan locked. Supersedes `/project-orchestrator` (deleted same day).
