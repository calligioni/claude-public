# Continuous Virtual User QA Cycle - Implementation Plan

**Date:** 2026-02-12
**Status:** Draft - Awaiting Approval
**Scope:** Contably production application

---

## 1. Vision

A persistent, database-backed QA cycle where 5 virtual user personas continuously test the application, discover bugs, track them through resolution, and verify fixes — creating an ever-running feedback loop across the product development lifecycle.

**Key difference from current approach:** Today's virtual-user-testing produces throwaway markdown reports. This system creates a **living issue database** with full lifecycle tracking, persona memory, regression detection, and automated fix-verify cycles.

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    QA Cycle Orchestrator                      │
│              (skill: /qa-cycle or /virtual-user-testing)      │
└──────────┬──────────────┬──────────────┬────────────────────┘
           │              │              │
    ┌──────▼──────┐ ┌────▼────┐ ┌──────▼──────┐
    │  DISCOVER   │ │   FIX   │ │   VERIFY    │
    │  Phase      │ │  Phase  │ │   Phase     │
    │             │ │         │ │             │
    │ 5 Persona   │ │ CTO/Dev │ │ Re-test     │
    │ agents test │ │ agents  │ │ agents run  │
    │ app via     │ │ read DB │ │ repro steps │
    │ browser     │ │ fix PRs │ │ via browser │
    └──────┬──────┘ └────┬────┘ └──────┬──────┘
           │              │              │
           ▼              ▼              ▼
    ┌─────────────────────────────────────────┐
    │         PostgreSQL (qa schema)           │
    │                                          │
    │  qa_issues  qa_sessions  qa_personas     │
    │  qa_persona_sessions  qa_verifications   │
    │  qa_issue_comments                       │
    └──────────────┬──────────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────────┐
    │     QA Manager CLI (Python script)       │
    │     apps/api/scripts/qa_manager.py       │
    │                                          │
    │  Agents invoke via Bash for writes       │
    │  Reads via script or mcp__postgres       │
    └─────────────────────────────────────────┘
```

---

## 3. Database Schema

**Location:** `qa` schema in Contably's PostgreSQL (same DB, isolated schema)
**Migration:** New Alembic migration `029_qa_schema`

### 3.1 `qa_personas`

Stores persona definitions and their accumulated experience.

```sql
CREATE TABLE qa.personas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,           -- "Maria Silva"
    slug VARCHAR(50) UNIQUE NOT NULL,     -- "maria"
    role VARCHAR(100) NOT NULL,           -- "AF Master Admin"
    app VARCHAR(20) NOT NULL,             -- "admin" or "portal"
    email VARCHAR(255) NOT NULL,          -- login credential
    description TEXT,                     -- persona background
    test_focus JSONB,                     -- ["navigation","company-switching","admin-management"]
    total_sessions INTEGER DEFAULT 0,
    total_bugs_found INTEGER DEFAULT 0,
    total_bugs_verified INTEGER DEFAULT 0,
    satisfaction_trend JSONB,             -- [{date, score}] last 10 sessions
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.2 `qa_issues`

Full lifecycle issue tracking with rich reproduction data.

```sql
CREATE TABLE qa.issues (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,

    -- Classification
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('p0-critical','p1-high','p2-medium','p3-low')),
    category VARCHAR(50) NOT NULL,        -- "auth","navigation","api","ui","data","performance"
    status VARCHAR(30) NOT NULL DEFAULT 'open' CHECK (status IN (
        'open','assigned','in_progress','pr_created','testing','verified','closed',
        'wont_fix','duplicate','by_design','regression'
    )),

    -- Discovery
    discovered_by VARCHAR(50) NOT NULL,   -- persona slug
    discovered_in_session UUID,           -- FK to qa_sessions
    discovered_at TIMESTAMPTZ DEFAULT now(),

    -- Technical details
    endpoint VARCHAR(500),                -- "/api/v1/client/auth/login"
    http_status INTEGER,                  -- 500
    error_message TEXT,                   -- "Internal server error"
    console_errors TEXT[],                -- array of console error strings
    reproduction_steps JSONB NOT NULL,    -- [{step: 1, action: "...", expected: "...", actual: "..."}]
    expected_behavior TEXT NOT NULL,
    actual_behavior TEXT NOT NULL,
    screenshot_url TEXT,
    network_log JSONB,                    -- captured request/response pairs

    -- Affected scope
    affected_personas TEXT[] NOT NULL,    -- ["renata","joao"]
    affected_page VARCHAR(500),           -- "/login"
    affected_app VARCHAR(20),             -- "admin" or "portal"

    -- Resolution
    fix_pr_url TEXT,
    fix_commit VARCHAR(40),
    fixed_by VARCHAR(100),               -- agent or human name
    fixed_at TIMESTAMPTZ,

    -- Verification
    verified_by VARCHAR(50),             -- persona slug who verified
    verified_at TIMESTAMPTZ,
    verification_session UUID,           -- FK to qa_sessions
    verification_notes TEXT,

    -- Regression tracking
    original_issue_id INTEGER,           -- if this is a regression, points to original
    regression_count INTEGER DEFAULT 0,

    -- Metadata
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_qa_issues_status ON qa.issues(status);
CREATE INDEX idx_qa_issues_severity ON qa.issues(severity);
CREATE INDEX idx_qa_issues_discovered_by ON qa.issues(discovered_by);
CREATE INDEX idx_qa_issues_endpoint ON qa.issues(endpoint);
```

### 3.3 `qa_sessions`

Each orchestrator run = one session.

```sql
CREATE TABLE qa.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    started_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    environment VARCHAR(50) DEFAULT 'production',
    trigger VARCHAR(50),                  -- "manual","scheduled","post-deploy","regression"

    -- Results
    personas_tested TEXT[],
    issues_found INTEGER DEFAULT 0,
    issues_verified INTEGER DEFAULT 0,
    issues_regressed INTEGER DEFAULT 0,

    -- Phase tracking
    discovery_completed BOOLEAN DEFAULT false,
    fix_phase_completed BOOLEAN DEFAULT false,
    verify_phase_completed BOOLEAN DEFAULT false,

    summary TEXT,
    cto_report_path TEXT,
    cpo_report_path TEXT,

    created_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.4 `qa_persona_sessions`

Per-persona results within a session.

```sql
CREATE TABLE qa.persona_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES qa.sessions(id),
    persona_slug VARCHAR(50) NOT NULL,

    started_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,

    -- What they tested
    pages_visited TEXT[],
    workflows_tested TEXT[],

    -- Results
    issues_found INTEGER DEFAULT 0,
    issues_verified INTEGER DEFAULT 0,
    satisfaction_score INTEGER,           -- 1-10

    -- Observations (not bugs, just UX notes)
    ux_observations JSONB,               -- [{page, observation, sentiment}]
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.5 `qa_issue_comments`

Activity log on each issue (status changes, notes, etc).

```sql
CREATE TABLE qa.issue_comments (
    id SERIAL PRIMARY KEY,
    issue_id INTEGER NOT NULL REFERENCES qa.issues(id),
    author VARCHAR(100) NOT NULL,         -- persona slug, agent name, or human
    comment TEXT NOT NULL,
    comment_type VARCHAR(30) DEFAULT 'note', -- "note","status_change","verification","fix","regression"
    metadata JSONB,                       -- {old_status, new_status, pr_url, etc}
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.6 `qa_verification_results`

Each verification attempt (a persona re-testing a fixed bug).

```sql
CREATE TABLE qa.verification_results (
    id SERIAL PRIMARY KEY,
    issue_id INTEGER NOT NULL REFERENCES qa.issues(id),
    session_id UUID NOT NULL REFERENCES qa.sessions(id),
    persona_slug VARCHAR(50) NOT NULL,

    passed BOOLEAN NOT NULL,
    notes TEXT,
    screenshot_url TEXT,

    tested_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 4. QA Manager CLI

**File:** `apps/api/scripts/qa_manager.py`

A Python CLI script that agents invoke via Bash for all DB writes. Uses the same SQLAlchemy models and DB connection as the API.

### Commands

```bash
# Issue management
python qa_manager.py issue create --title "..." --severity p0-critical --persona maria --endpoint "/api/v1/..." --steps '[...]' --expected "..." --actual "..."
python qa_manager.py issue update --id 42 --status in_progress --assigned-to "cto-agent"
python qa_manager.py issue close --id 42 --fixed-by "cto-agent" --commit abc123 --pr "https://..."
python qa_manager.py issue verify --id 42 --persona renata --passed true --notes "Login works now"

# Session management
python qa_manager.py session start --trigger manual --personas maria,carlos,renata,joao,pedro
python qa_manager.py session complete --id <uuid> --summary "..."

# Persona session tracking
python qa_manager.py persona-session start --session-id <uuid> --persona maria
python qa_manager.py persona-session complete --id <uuid> --satisfaction 8 --pages '[...]'

# Queries (for agents to read)
python qa_manager.py query open-issues --severity p0-critical,p1-high
python qa_manager.py query persona-history --persona renata --limit 5
python qa_manager.py query duplicate-check --endpoint "/api/v1/client/auth/login" --http-status 500
python qa_manager.py query regression-check --persona maria
python qa_manager.py query session-summary --session-id <uuid>

# Reports
python qa_manager.py report cto --session-id <uuid>
python qa_manager.py report cpo --session-id <uuid>

# Comments
python qa_manager.py comment add --issue-id 42 --author "maria" --type verification --comment "Still broken"
```

### How Agents Use It

Persona agents (haiku) invoke via Bash:

```bash
python /path/to/qa_manager.py issue create --title "Client portal login returns 500" ...
```

CTO/fixer agents read open issues:

```bash
python /path/to/qa_manager.py query open-issues --severity p0-critical,p1-high
```

Verification agents update issue status:

```bash
python /path/to/qa_manager.py issue verify --id 42 --persona renata --passed true
```

---

## 5. Issue Lifecycle

```
                    ┌──────────┐
         discover   │   OPEN   │
         ────────►  │          │
                    └────┬─────┘
                         │ assign to fixer
                    ┌────▼─────┐
                    │ ASSIGNED │
                    └────┬─────┘
                         │ fixer starts
                    ┌────▼──────────┐
                    │  IN_PROGRESS  │
                    └────┬──────────┘
                         │ PR created
                    ┌────▼──────────┐
                    │  PR_CREATED   │
                    └────┬──────────┘
                         │ deploy + re-test
                    ┌────▼─────┐
                    │ TESTING  │
                    └────┬─────┘
                    ┌────┴─────┐
               pass │          │ fail
               ┌────▼─────┐ ┌─▼──────────┐
               │ VERIFIED  │ │ IN_PROGRESS │ (back to fixer)
               └────┬──────┘ └────────────┘
                    │ next session confirms
               ┌────▼─────┐
               │  CLOSED   │
               └───────────┘

Side statuses: WONT_FIX, DUPLICATE, BY_DESIGN

Regression: CLOSED → REGRESSION (auto-escalated to P0)
```

---

## 6. Cycle Phases

### Phase 1: DISCOVER

The enhanced virtual-user-testing skill runs all 5 personas.

Each persona agent:

1. **Loads history**: `qa_manager.py query persona-history --persona {slug}` — sees past bugs, past sessions, satisfaction trend
2. **Loads open issues**: `qa_manager.py query open-issues` — knows what's already reported (avoids duplicates)
3. **Loads verification queue**: `qa_manager.py query regression-check --persona {slug}` — gets list of recently-fixed bugs to verify
4. **Tests the app** via Chrome DevTools MCP (same as today)
5. **For each bug found**:
   - Checks for duplicates: `qa_manager.py query duplicate-check --endpoint ... --http-status ...`
   - If new: `qa_manager.py issue create ...`
   - If duplicate: `qa_manager.py comment add --issue-id ... --comment "Still reproducing"`
6. **Verifies fixed bugs** from the queue:
   - `qa_manager.py issue verify --id ... --passed true/false`
7. **Completes session**: `qa_manager.py persona-session complete --satisfaction 7 --pages '[...]'`

### Phase 2: REPORT

After all personas complete, the orchestrator:

1. `qa_manager.py report cto --session-id <uuid>` → generates CTO report with issue IDs, severities, trends
2. `qa_manager.py report cpo --session-id <uuid>` → generates CPO report with UX observations, satisfaction trends
3. Reports reference DB issue IDs so they're actionable

### Phase 3: FIX

A CTO/fixer agent (or the `/cto` skill):

1. Reads prioritized open issues: `qa_manager.py query open-issues --severity p0-critical,p1-high`
2. For each issue:
   - Reads reproduction steps and technical details from DB
   - Investigates the codebase
   - Creates a fix
   - Updates issue: `qa_manager.py issue update --id 42 --status pr_created --pr "https://..."`
3. Deploys fix (or creates PR for human review)

### Phase 4: VERIFY

After fixes are deployed, run discovery again with verification focus:

1. Personas prioritize verifying recently-fixed bugs
2. Each verification result recorded: `qa_manager.py issue verify --id 42 --passed true`
3. If all verifications pass → status moves to VERIFIED
4. Next session with no regression → CLOSED

### Phase 5: REGRESSION DETECTION

On every discovery run:

1. Personas re-test a sample of CLOSED issues (rotating subset)
2. If a closed bug reappears:
   - `qa_manager.py issue create --title "REGRESSION: ..." --original-issue-id 42`
   - Auto-escalated to P0
   - Original issue linked

---

## 7. Skill Modifications

### 7.1 Enhanced `virtual-user-testing` Skill

Changes to the existing skill:

1. **Session initialization**: Create DB session at start, pass session ID to all persona agents
2. **Persona agent prompt enhancement**: Include DB history, open issues, verification queue in each persona's prompt
3. **Bug reporting**: Replace MCP memory writes with `qa_manager.py issue create` calls
4. **Verification phase**: After discovery, each persona verifies their assigned fixed bugs
5. **Session completion**: Write summary to DB, generate reports from DB data

### 7.2 New `/qa-fix` Skill (or mode of `/cto`)

A skill that reads open issues from DB and creates fixes:

```
/qa-fix                    # Fix top priority issues
/qa-fix --issue 42         # Fix specific issue
/qa-fix --severity p0      # Fix all P0 issues
```

### 7.3 New `/qa-verify` Skill

A lightweight version of virtual-user-testing focused on verification:

```
/qa-verify                 # Verify all TESTING status issues
/qa-verify --issue 42      # Verify specific issue
```

### 7.4 New `/qa-cycle` Skill (Full Orchestrator)

Runs the complete cycle:

```
/qa-cycle                  # Full: discover → report → fix → verify
/qa-cycle --discover-only  # Just run personas
/qa-cycle --fix-only       # Just fix open issues
/qa-cycle --verify-only    # Just verify fixed issues
/qa-cycle --report         # Generate reports from current DB state
```

---

## 8. Duplicate Detection Strategy

Before creating a new issue, agents check for duplicates:

```python
# Exact match: same endpoint + same HTTP status + same error message
existing = qa_manager.py query duplicate-check \
    --endpoint "/api/v1/client/auth/login" \
    --http-status 500 \
    --error-message "Internal server error"

if existing:
    # Add comment to existing instead of creating new
    qa_manager.py comment add --issue-id {existing.id} \
        --author {persona} \
        --comment "Still reproducing as of {date}"
else:
    # Create new issue
    qa_manager.py issue create ...
```

Fuzzy matching for UI bugs:

- Same page + similar description → flag as potential duplicate
- Agent decides whether to merge or create new

---

## 9. Persona Memory & Continuity

Each persona accumulates context across sessions:

1. **Session history**: "Last 5 sessions I tested these pages and found these bugs"
2. **Satisfaction trend**: "My satisfaction went from 3/10 → 7/10 over 4 sessions as bugs were fixed"
3. **Known issues**: "I know about 12 open bugs, 3 were fixed since my last session"
4. **Test coverage**: "I've tested /login, /dashboard, /documents but never /messages — I should test /messages today"
5. **Regression awareness**: "Bug #7 was closed 2 sessions ago — I should spot-check it"

This context is loaded at the start of each session from the DB and injected into the persona agent's prompt.

---

## 10. Implementation Phases

### Phase 1: Database Schema (Day 1)

- [ ] Create Alembic migration `029_qa_schema`
- [ ] Create all 6 tables in `qa` schema
- [ ] Seed 5 personas
- [ ] Run migration on production

### Phase 2: QA Manager CLI (Day 1-2)

- [ ] Create `apps/api/scripts/qa_manager.py`
- [ ] Implement all CRUD commands
- [ ] Implement query commands
- [ ] Implement report generation
- [ ] Test locally

### Phase 3: Enhanced Virtual User Testing (Day 2-3)

- [ ] Modify skill to create DB session at start
- [ ] Add persona history loading
- [ ] Replace markdown bug reporting with DB writes
- [ ] Add verification queue processing
- [ ] Add duplicate detection before issue creation
- [ ] Test full discovery cycle

### Phase 4: QA Fix Skill (Day 3-4)

- [ ] Create `/qa-fix` skill
- [ ] Read open issues from DB
- [ ] Integrate with CTO/autonomous-dev for fixes
- [ ] Update issue status in DB after fix

### Phase 5: QA Verify Skill (Day 4-5)

- [ ] Create `/qa-verify` skill
- [ ] Load TESTING status issues
- [ ] Run targeted browser verification
- [ ] Update verification results in DB

### Phase 6: Full Cycle Orchestrator (Day 5)

- [ ] Create `/qa-cycle` skill
- [ ] Orchestrate: discover → report → fix → verify
- [ ] Add regression detection logic
- [ ] Add scheduled trigger support

---

## 11. Key Design Decisions

| Decision            | Choice                                      | Rationale                                         |
| ------------------- | ------------------------------------------- | ------------------------------------------------- |
| Database            | Contably's PostgreSQL with `qa` schema      | Same infra, no new services, isolated via schema  |
| Write mechanism     | Python CLI script via Bash                  | MCP postgres is read-only; script uses SQLAlchemy |
| Read mechanism      | CLI script (or MCP postgres if reconnected) | Flexible — works either way                       |
| Issue IDs           | Sequential integers                         | Easy to reference in conversation: "Bug #42"      |
| Session IDs         | UUIDs                                       | No collision risk across parallel runs            |
| Persona memory      | DB queries at session start                 | Persistent, structured, queryable                 |
| Duplicate detection | Endpoint + HTTP status + error message      | Simple, effective for API bugs                    |
| Regression tracking | Link to original issue                      | Full history preserved                            |

---

## 12. MVP Scope (First Implementation)

For v1, focus on:

1. **Database schema** — all 6 tables
2. **QA Manager CLI** — issue create, update, verify, query, persona-session tracking
3. **Enhanced discovery** — personas write bugs to DB, load history, check duplicates
4. **Basic reporting** — generate CTO report from DB data
5. **Manual fix flow** — developer reads DB issues, fixes, marks as fixed

Defer to v2:

- Automated fix phase (CTO agent reads DB and auto-fixes)
- Automated verify phase (re-test after deploy)
- Full cycle orchestrator
- Scheduled runs
- Regression sampling of closed issues
