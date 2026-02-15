---
name: qa-cycle
description: "Master QA orchestrator: project-agnostic opus-powered autonomous agent. Detects project, checks for existing /qa-{project} skill (delegates if found), or runs full discovery + QA cycle from scratch and generates the skill for next time. Manages its own task list. Only stops for destructive actions. Delivers a fully working app. Triggers on: qa cycle, full qa, run qa, continuous qa, qa pipeline."
user-invocable: true
context: fork
model: opus
allowed-tools:
  - Task(agent_type=general-purpose)
  - Task(agent_type=Explore)
  - Skill
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeamCreate
  - TeamDelete
  - SendMessage
  - AskUserQuestion
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - mcp__chrome-devtools__*
  - mcp__memory__*
  - mcp__postgres__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__chrome-devtools__click: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__fill: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__navigate_page:
    { readOnlyHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
  SendMessage: { openWorldHint: true, idempotentHint: false }
  TeamDelete: { destructiveHint: true, idempotentHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
---

# QA Cycle — Autonomous Master Orchestrator (v3.0)

Opus-powered project-agnostic QA commander. Runs the entire QA lifecycle autonomously from detection to delivery. Manages its own task list, coordinates sub-agents, and loops until the app is fully working. Only pauses for destructive operations that could cause data loss.

## Core Principle

**Deliver a fully working app.** Do not stop for non-critical issues. Fix them. Only ask the user when you need to:

- Drop a database table
- Delete files or directories
- Force-push / rewrite git history
- Modify production infrastructure destructively
- Spend significant money (new services, paid APIs)

Everything else — you decide, you execute, you verify.

## Architecture

```
/qa-cycle [flags]
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    OPUS ORCHESTRATOR                          │
│                                                              │
│  Owns the task list. Makes all decisions. Delegates work.    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              PHASE 0: DETECT + ROUTE                 │    │
│  │                                                      │    │
│  │  1. Identify project (cwd, package.json, git)        │    │
│  │  2. Check for /qa-{project} skill                    │    │
│  │     ├─ FOUND → Skill("qa-{project}") → DONE         │    │
│  │     └─ NOT FOUND → continue to Phase 1               │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              PHASE 1: DISCOVER PROJECT               │    │
│  │                                                      │    │
│  │  Parallel sub-agents (sonnet/haiku):                  │    │
│  │  ├─ Tech stack, frameworks, DB, auth                  │    │
│  │  ├─ Routes, features, API endpoints                   │    │
│  │  ├─ User roles, permissions                           │    │
│  │  ├─ URLs (prod, staging, local)                       │    │
│  │  └─ Deployment platform + commands                    │    │
│  │                                                      │    │
│  │  Opus synthesizes → project profile + persona design  │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              PHASE 2: SETUP QA INFRA                  │    │
│  │                                                      │    │
│  │  ├─ Create QA tables in project DB                    │    │
│  │  ├─ Create QA session                                 │    │
│  │  ├─ Seed feature coverage matrix                      │    │
│  │  └─ Verify test credentials exist                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │          PHASE 3-8: QA CYCLE (LOOPS)                  │    │
│  │                                                      │    │
│  │  3. DISCOVER — persona swarm (haiku × N, parallel)    │    │
│  │  4. REPORT — CTO/CPO from DB (sonnet)                 │    │
│  │  5. TRIAGE — prioritize + group (opus decides)        │    │
│  │  6. FIX — code changes (sonnet per fix group)         │    │
│  │  7. VERIFY — browser re-test (haiku)                  │    │
│  │  8. DEPLOY — commit, push, verify endpoints           │    │
│  │                                                      │    │
│  │  Loop: open issues or blocked features? → new cycle   │    │
│  │  Stop: 100% coverage + 0 open issues, or cycle = 10  │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │          PHASE 9: GENERATE /qa-{project} SKILL        │    │
│  │                                                      │    │
│  │  Write complete project-specific skill file           │    │
│  │  Save trail in memory graph                           │    │
│  │  Next time → instant delegation                       │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Usage

```
/qa-cycle                      # Full autonomous cycle for current project
/qa-cycle --discover-only      # Only discover + report (no fix/deploy)
/qa-cycle --fix-only           # Only fix open issues from DB
/qa-cycle --verify-only        # Only verify issues in TESTING status
/qa-cycle --report             # Generate reports from current DB state
/qa-cycle --severity p0        # Full cycle, P0 issues only
/qa-cycle --skip-fix           # Discover + report + verify (no fix)
/qa-cycle --url URL            # Override target URL
/qa-cycle --regenerate         # Force re-discovery even if skill exists
```

---

## Phase 0: Detect + Route

### 0a. Identify the Project

```bash
# 1. package.json name
PROJECT_NAME=$(cat package.json 2>/dev/null | grep '"name"' | head -1 | sed 's/.*"name".*"//;s/".*//')

# 2. git remote
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME=$(basename $(git remote get-url origin 2>/dev/null) .git 2>/dev/null)
fi

# 3. directory name
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME=$(basename $(pwd))
fi

# Normalize
PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
```

**Canonical aliases** (use these, not variants):

- `contably*` → delegate to `/qa-conta` (Contably has its own dedicated skill)
- `sourcerank*` → `sourcerank`
- Otherwise use shortest meaningful name

### 0b. Check for Existing Skill

```bash
SKILLS_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup/skills"
```

Check in order:

1. `$SKILLS_DIR/qa-$PROJECT_NAME/SKILL.md` — exact match
2. Memory graph: `mcp__memory__search_nodes({ query: "qa-project:$PROJECT_NAME" })` — trail from previous run
3. Known aliases: contably → `/qa-conta`, sourcerank → `/qa-sourcerank`

### 0c. Delegate or Continue

**If skill found** (and no `--regenerate` flag):

```
Skill(skill: "qa-{project}", args: "{original_flags}")
```

Done. Orchestrator exits.

**If Contably detected:**

```
Skill(skill: "qa-conta", args: "{original_flags}")
```

Done. Contably has its own dedicated skill.

**If no skill found** → continue to Phase 1.

---

## Phase 1: Discover Project

Create the task list to track progress:

```
TaskCreate({ subject: "Discover project tech stack", ... })
TaskCreate({ subject: "Discover routes and features", ... })
TaskCreate({ subject: "Design test personas", ... })
TaskCreate({ subject: "Setup QA database", ... })
TaskCreate({ subject: "Run QA discovery cycle", ... })
TaskCreate({ subject: "Generate /qa-{project} skill", ... })
```

### 1a. Tech Stack + Routes (Parallel)

Spawn two explore agents simultaneously:

```
Task({
  subagent_type: "Explore",
  model: "sonnet",
  prompt: "Analyze {cwd}. Return JSON:
    tech_stack: { language, framework, package_manager, monorepo, db, orm, auth, css }
    structure: { key_dirs, routes_dir, api_dir, tests_dir }
    urls: { production, staging, local_port }
    deployment: { platform, method, config_files }
    database: { type, connection_pattern, migrations, existing_qa_tables }"
})

Task({
  subagent_type: "Explore",
  model: "sonnet",
  prompt: "Analyze {cwd}. Extract ALL user-facing features. Return JSON:
    routes: [{ path, purpose, auth_required, role_required }]
    api_endpoints: [{ method, path, resource }]
    features: [{ key, name, route, workflows_total, required_role, description }]
    roles: [{ name, permissions, is_admin }]
    Target: 20-50 features."
})
```

### 1b. Synthesize + Design Personas

Opus reviews both results and designs personas. No sub-agent needed — opus does this directly because it requires judgment about:

- How many personas (3-5 based on role count and feature count)
- Which persona covers which features (maximize coverage, minimize overlap)
- Realistic backgrounds that match the product domain
- Test credential strategy

For each persona, define:

- `name`, `slug`, `role_description`, `background`
- `system_role` (maps to app role)
- `assigned_features` (list of feature keys)
- `test_routes`, `test_workflows`
- `credentials` (email/password — may need to create test accounts)

**Rule: Every feature must be covered by at least one persona.**

---

## Phase 2: Setup QA Infrastructure

### 2a. Create QA Tables

Use the standard schema (see appendix). Choose access method based on project:

| Project DB        | Access Method                                     |
| ----------------- | ------------------------------------------------- |
| Supabase (remote) | `psql "$DB_URL"` via Bash                         |
| Local PostgreSQL  | `mcp__postgres__query` or `psql`                  |
| Has qa_manager.py | Use that CLI tool                                 |
| No PostgreSQL     | Create SQLite or use mcp\_\_postgres if available |

### 2b. Create Session + Seed Coverage

```sql
-- Create session
INSERT INTO qa_sessions (trigger, personas)
VALUES ('qa-cycle', ARRAY['{slugs}'])
RETURNING id;

-- Seed feature coverage (one row per feature × persona)
INSERT INTO qa_feature_coverage (session_id, feature_key, feature_name, persona, route, workflows_total)
VALUES
  ('{sid}', '{key}', '{name}', '{persona}', '{route}', {count}),
  ...
ON CONFLICT (session_id, feature_key, persona) DO NOTHING;
```

### 2c. Verify Test Credentials

Check if test users exist in the project's auth system. If not:

- Try to create them (sign-up flow or DB insert)
- If creation requires email verification or external service, ask the user once for credentials
- Document the credentials in the generated skill

---

## Phase 3: Discover (Persona Swarm)

### 3a. Create QA Team

```
TeamCreate({
  team_name: "qa-{project}-{session_short}",
  description: "QA swarm for {project}"
})
```

### 3b. Load Shared Context

Query DB once for:

- Open issues (duplicate avoidance)
- Verification queue (issues in TESTING status)
- Previous session data (regression detection)

### 3c. Spawn ALL Personas in Parallel

**One message, N parallel Task calls.** Each persona is `model: "haiku"`:

```
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  name: "{slug}-tester",
  team_name: "qa-{project}-{session_short}",
  prompt: "{full persona prompt with all context, credentials, DB access, feature list}"
})
```

Each persona:

1. Starts persona session in DB
2. Tests every assigned feature via Chrome DevTools MCP
3. Marks features as `approved` or `blocked` (with blocking issue IDs)
4. Creates issues in DB (with duplicate check first)
5. Broadcasts failures to team
6. Verifies fixed bugs from queue
7. Sends final report to orchestrator

### 3d. Cross-Persona Detection

As personas report back, opus watches for:

- **Systemic bugs** — same page/endpoint broken for 2+ personas
- **Permission leaks** — member accessing admin features → P0
- **Performance bottlenecks** — multiple personas report slow loads
- **Data inconsistencies** — different roles see different data for same entity
- **Regressions** — previously CLOSED issues reappearing → P0

---

## Phase 4: Report

Generate from DB data (opus or sonnet inline):

**CTO Report**: issues by severity, systemic patterns, API errors, regressions, trend vs previous sessions

**CPO Report**: persona satisfaction, UX issues, satisfaction trends, product recommendations

**Coverage Report**: feature × persona matrix, overall %, blocked features with blocking issue IDs

---

## Phase 5: Triage

Opus reviews all discovered issues and decides:

1. **Real bugs vs artifacts** — test environment issues, expected behavior, flaky tests
2. **Priority order** — dependencies between issues, severity, blast radius
3. **Root cause grouping** — which issues share a root cause → fix together
4. **Skip list** — issues that are infra/deployment problems, not code bugs

Output: structured fix plan with groups, priority order, and approach per group.

---

## Phase 6: Fix

For each fix group (by priority), spawn a sub-agent:

```
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  prompt: "Fix these QA issues in {cwd}:
    Root cause: {root_cause}
    Issues: {issue_details}
    Approach: {approach}

    1. Claim issues in DB (status = 'assigned')
    2. Investigate codebase
    3. Apply minimal fix
    4. Update DB (status = 'testing')
    5. Return summary of changes"
})
```

**Parallel when independent, sequential when shared files.**

If a fix is particularly complex (architectural, cross-cutting), opus handles it directly instead of delegating.

---

## Phase 7: Verify

Spawn haiku verification agents to re-test fixed issues via browser:

```
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  prompt: "Verify these issues are fixed on {url}:
    {issues_in_testing_status}
    For each: navigate, follow reproduction steps, record pass/fail in DB"
})
```

Update coverage: unblock features whose blocking issues are now resolved.

---

## Phase 8: Deploy

Based on the project's deployment method:

| Platform | Deploy Command                         |
| -------- | -------------------------------------- |
| Render   | `git push origin master` (auto-deploy) |
| Railway  | `railway up` or `git push`             |
| Vercel   | `git push` (auto-deploy via GitHub)    |
| OKE/K8s  | `docker build` + `kubectl set image`   |
| Custom   | Whatever the project uses              |

Post-deploy:

1. Wait for deploy to complete
2. Verify production endpoints (health checks, HTTP status)
3. If deploy fails → rollback (`git revert HEAD --no-edit && git push`)

---

## Cycle Loop

After Phase 8, check:

```sql
SELECT
  COUNT(*) FILTER (WHERE status != 'approved') as unapproved,
  (SELECT COUNT(*) FROM qa_issues WHERE session_id = '{sid}' AND status NOT IN ('closed', 'verified')) as open_issues
FROM qa_feature_coverage
WHERE session_id = '{sid}';
```

- **unapproved = 0 AND open_issues = 0** → DONE, go to Phase 9
- **cycle >= 10** → DONE (cap reached), go to Phase 9 with remaining issues noted
- **Otherwise** → Start new cycle
  - Reset blocked features to `untested` where blocking issues are resolved
  - Only re-spawn personas that have unapproved features
  - Focus on progressively lower severity each cycle

### Cycle Log

```
Cycle 1: 37 features → 28 approved, 9 blocked. Fixed 6 P0+P1. Deployed.
Cycle 2: Re-tested 9 → 7 approved, 2 blocked. Fixed 2 P2. Deployed.
Cycle 3: Re-tested 2 → 2 approved. 100% coverage. DONE.
```

---

## Phase 9: Generate /qa-{project} Skill

After the QA cycle completes, generate a self-contained project-specific skill so next time `/qa-cycle` instantly delegates.

### 9a. Create Skill Directory + File

```bash
mkdir -p "$SKILLS_DIR/qa-{project}"
```

Write `$SKILLS_DIR/qa-{project}/SKILL.md` using `/qa-sourcerank/SKILL.md` as the structural template. Read it first:

```
Read("$SKILLS_DIR/qa-sourcerank/SKILL.md")
```

The generated skill must include:

1. **YAML frontmatter** — same tools/annotations as qa-sourcerank, name = `qa-{project}`
2. **About section** — tech stack, structure, URLs (all discovered data)
3. **Database access** — connection pattern (psql, mcp\_\_postgres, qa_manager.py)
4. **Full QA schema** — standard CREATE TABLE statements
5. **Feature registry** — complete matrix: persona × feature × route × workflow_count
6. **Seeding SQL** — INSERT statements for qa_feature_coverage
7. **Persona definitions** — full backgrounds, routes, workflows, credentials
8. **Execution flow** — phases with project-specific commands
9. **Deployment** — project-specific deploy/rollback
10. **Autonomous rules** — same across all projects
11. **Swarm protocol** — broadcast, direct messages
12. **Flags** — same table

**The generated skill must be fully self-contained.** It should not reference `/qa-cycle`. A future run of `/qa-{project}` should work independently.

### 9b. Memory Trail

```javascript
mcp__memory__create_entities({
  entities: [
    {
      name: "qa-project:{project}",
      entityType: "qa-project-config",
      observations: [
        "Discovered: {date}",
        "Project: {project}",
        "Skill: qa-{project}/SKILL.md",
        "Features: {count}",
        "Personas: {names}",
        "DB: {type}",
        "Deploy: {platform}",
        "URL: {prod_url}",
        "First session: {session_id}",
      ],
    },
  ],
});

mcp__memory__create_relations({
  relations: [
    {
      from: "qa-project:{project}",
      relationType: "generated_by",
      to: "skill:qa-cycle",
    },
  ],
});
```

---

## Autonomous Operation Rules

### Never Stop For

- Non-critical bugs — fix them
- Test failures — investigate and fix
- Missing test credentials — create them or ask once
- Deployment issues — rollback and retry
- Flaky tests — mark as flaky, continue
- Minor code quality issues — fix inline
- Missing dependencies — install them
- Port conflicts — find another port
- Stale caches — clear them

### Only Stop For (ask user)

- **Destructive database operations** — DROP TABLE, DELETE FROM without WHERE, TRUNCATE
- **Destructive file operations** — `rm -rf`, deleting user files/directories
- **Git history rewriting** — force push, rebase published history
- **Production infrastructure changes** — scaling, service deletion, DNS changes
- **Spending money** — creating paid services, new API subscriptions
- **Credential issues that can't be resolved** — need user's password, OAuth consent

### Task Management

Opus maintains its own task list throughout the cycle:

```
TaskCreate → for each phase and sub-task
TaskUpdate(status: "in_progress") → when starting
TaskUpdate(status: "completed") → when done
TaskList → after each phase to decide next action
```

The task list serves as:

1. **Progress tracker** — user can see what's happening
2. **Decision log** — each task records what was decided
3. **Resumability** — if context clears, tasks show where we left off

### Model Delegation

Opus is the brain. It delegates execution to cheaper models:

| Role                    | Model  | What It Does                                         |
| ----------------------- | ------ | ---------------------------------------------------- |
| **Orchestrator**        | opus   | All decisions, triage, persona design, complex fixes |
| **Discovery agents**    | haiku  | Browser testing, bug reporting, verification         |
| **Fix agents**          | sonnet | Code investigation, writing fixes                    |
| **Report generation**   | sonnet | CTO/CPO reports from DB data                         |
| **Verification agents** | haiku  | Re-testing fixed issues                              |

**Rule: Opus never does browser navigation or writes boilerplate. Opus thinks, decides, and delegates.**

---

## Standard QA Schema

```sql
CREATE TABLE IF NOT EXISTS qa_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  trigger VARCHAR(50) NOT NULL DEFAULT 'manual',
  status VARCHAR(20) NOT NULL DEFAULT 'started',
  personas TEXT[] DEFAULT '{}',
  summary TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS qa_issues (
  id SERIAL PRIMARY KEY,
  session_id UUID REFERENCES qa_sessions(id),
  title TEXT NOT NULL,
  severity VARCHAR(20) NOT NULL DEFAULT 'p2-medium',
  status VARCHAR(30) NOT NULL DEFAULT 'open',
  category VARCHAR(30),
  persona VARCHAR(50),
  endpoint TEXT,
  http_status INTEGER,
  error_message TEXT,
  expected TEXT,
  actual TEXT,
  affected_page TEXT,
  reproduction_steps JSONB DEFAULT '[]',
  assigned_to VARCHAR(100),
  fixed_by VARCHAR(100),
  commit_hash VARCHAR(40),
  original_issue_id INTEGER REFERENCES qa_issues(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS qa_issue_comments (
  id SERIAL PRIMARY KEY,
  issue_id INTEGER REFERENCES qa_issues(id),
  author VARCHAR(100) NOT NULL,
  comment_type VARCHAR(20) DEFAULT 'note',
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS qa_verifications (
  id SERIAL PRIMARY KEY,
  issue_id INTEGER REFERENCES qa_issues(id),
  session_id UUID REFERENCES qa_sessions(id),
  persona VARCHAR(50),
  passed BOOLEAN NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS qa_persona_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID REFERENCES qa_sessions(id),
  persona VARCHAR(50) NOT NULL,
  satisfaction INTEGER CHECK (satisfaction BETWEEN 1 AND 10),
  pages_visited TEXT[] DEFAULT '{}',
  workflows_tested TEXT[] DEFAULT '{}',
  observations TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS qa_feature_coverage (
  id SERIAL PRIMARY KEY,
  session_id UUID REFERENCES qa_sessions(id),
  feature_key VARCHAR(60) NOT NULL,
  feature_name TEXT NOT NULL,
  persona VARCHAR(50) NOT NULL,
  route TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'untested',
  workflows_total INTEGER NOT NULL DEFAULT 0,
  workflows_passed INTEGER NOT NULL DEFAULT 0,
  workflows_failed INTEGER NOT NULL DEFAULT 0,
  blocking_issue_ids INTEGER[] DEFAULT '{}',
  tested_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  notes TEXT,
  UNIQUE(session_id, feature_key, persona)
);

CREATE INDEX IF NOT EXISTS idx_qa_issues_session ON qa_issues(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_issues_status ON qa_issues(status);
CREATE INDEX IF NOT EXISTS idx_qa_issues_severity ON qa_issues(severity);
CREATE INDEX IF NOT EXISTS idx_qa_verifications_issue ON qa_verifications(issue_id);
CREATE INDEX IF NOT EXISTS idx_qa_persona_sessions_session ON qa_persona_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_feature_coverage_session ON qa_feature_coverage(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_feature_coverage_status ON qa_feature_coverage(status);
```

---

## Known Project Skills

These already exist — delegate immediately:

| Project    | Skill            | Notes                             |
| ---------- | ---------------- | --------------------------------- |
| Contably   | `/qa-conta`      | Dedicated Contably QA (VPS-based) |
| SourceRank | `/qa-sourcerank` | Swarm QA with 4 personas          |

---

## Completion Signal

```json
{
  "status": "complete",
  "project": "{project}",
  "firstRun": true,
  "skillGenerated": "qa-{project}",
  "cycles": 3,
  "coverage": { "total": 37, "approved": 37, "pct": 100 },
  "issues": { "found": 12, "fixed": 12, "verified": 12 },
  "deployed": true,
  "memoryTrail": "qa-project:{project}"
}
```

---

## Version

**Current Version:** 3.0.0
**Last Updated:** February 2026

### Changelog

- **3.0.0**: Autonomous opus orchestrator
  - Opus runs the show — all decisions, triage, persona design, complex fixes
  - Manages its own task list (TaskCreate/Update/List)
  - Only stops for destructive actions (DB drops, file deletion, force push)
  - Delegates execution: haiku for discovery/verify, sonnet for fixes/reports
  - Detects Contably → delegates to `/qa-conta` (not `/qa-contably`)
  - No Contably-specific code in this skill
  - Full cycle loop until 100% coverage or 10 cycles
  - Generates self-contained `/qa-{project}` skills using qa-sourcerank as template
  - Memory trail for instant routing on subsequent runs
- **2.0.0**: Project-agnostic master (sonnet orchestrator)
- **1.0.0**: Contably-specific QA cycle
