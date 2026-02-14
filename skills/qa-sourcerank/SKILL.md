---
name: qa-sourcerank
description: "Full QA cycle for SourceRank AI: discover bugs via virtual user personas on production, fix issues, verify fixes via browser testing. Personas simulate CMOs, SEO managers, agency owners, and brand managers testing the AI visibility platform. Uses psql for QA issue tracking in SourceRank Supabase DB. Triggers on: qa sourcerank, sourcerank qa, test sourcerank, qa cycle sourcerank."
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Task(agent_type=general-purpose)
  - Task(agent_type=Explore)
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeamCreate
  - TeamDelete
  - SendMessage
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - mcp__chrome-devtools__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__chrome-devtools__click: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__fill: { destructiveHint: false, idempotentHint: false }
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

# QA SourceRank Skill (v1.0)

Full QA lifecycle for SourceRank AI: discover bugs via virtual user personas on the production site, generate reports, fix issues, verify fixes via browser testing. Adapted from the Contably qa-cycle for the SourceRank AI visibility intelligence platform.

## What It Does

When you run `/qa-sourcerank`, it orchestrates:

1. **DISCOVER** - Spawn persona agents that test the production app and report bugs to the QA DB
2. **REPORT** - Generate a summary report from QA data
3. **FIX** - Read open issues from DB, investigate codebase, create fixes
4. **VERIFY** - Verify fixes via Chrome DevTools browser testing on production
5. **REGRESSION CHECK** - Compare with previous sessions

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  QA SOURCERANK ORCHESTRATOR                       │
│                                                                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐   │
│  │ DISCOVER │ ──▶│  REPORT  │ ──▶│   FIX    │ ──▶│  VERIFY  │   │
│  │          │    │          │    │          │    │          │   │
│  │ 4 persona│    │ Summary  │    │ Read DB  │    │ Browser  │   │
│  │ agents   │    │ from DB  │    │ fix code │    │ re-test  │   │
│  │ test app │    │ report   │    │ update DB│    │ update DB│   │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘   │
│       │               │               │               │          │
│       ▼               ▼               ▼               ▼          │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │         PostgreSQL via mcp__postgres__query               │    │
│  │    qa_sessions | qa_issues | qa_verifications              │    │
│  └──────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

```
/qa-sourcerank                     # Full cycle: discover → report → fix → verify
/qa-sourcerank --discover-only     # Only run persona discovery
/qa-sourcerank --fix-only          # Only fix open issues from DB
/qa-sourcerank --verify-only       # Only verify issues in TESTING status
/qa-sourcerank --report            # Generate report from current DB state
/qa-sourcerank --severity p0       # Full cycle but only for P0 issues
```

## About SourceRank AI

SourceRank is an enterprise B2B SaaS platform that monitors brand mentions across AI assistants (ChatGPT, Claude, Perplexity, Gemini, Google SGE) and provides competitive analysis, content quality assessment, and reputation management.

**Tech Stack:**

- Frontend: Next.js 14, React 18, TailwindCSS, Radix UI (shadcn/ui)
- Backend: Fastify 4.25, Node.js, TypeScript
- Database: PostgreSQL (Supabase), Drizzle ORM
- Auth: Supabase Auth (JWT)
- Queue: BullMQ, Redis
- Deployment: Render.com
- Package manager: pnpm (turborepo monorepo)

**Monorepo Structure:**

```
apps/
  web/          # Next.js frontend (port 3000)
  api/          # Fastify backend (port 4000)
  worker/       # BullMQ worker
packages/
  database/     # Drizzle ORM schema + migrations
  shared/       # Shared types and utilities
```

**Production URLs:**

- Web app: https://sourcerank-web.onrender.com
- API: https://sourcerank-api.onrender.com

**Key Routes (Next.js app router at `apps/web/app/[locale]/`):**

Public:

- `/` - Landing page
- `/about` - About page
- `/solutions` - Solutions page
- `/blog/innovation` - Blog
- `/sign-in` - Login
- `/sign-up` - Registration

Dashboard (authenticated):

- `/dashboard` - Main dashboard overview
- `/dashboard/brands` - Brand management
- `/dashboard/brands/[id]` - Brand detail
- `/dashboard/brands/[id]/facts` - Brand facts
- `/dashboard/monitor` - AI monitoring
- `/dashboard/content` - Content analysis
- `/dashboard/competitive` - Competitive analysis
- `/dashboard/competitive-intelligence` - Competitive intelligence
- `/dashboard/competitors` - Competitor tracking
- `/dashboard/authority` - Authority scoring
- `/dashboard/alerts` - Alerts center
- `/dashboard/alerts/hallucinations` - Hallucination detection
- `/dashboard/recommendations` - AI recommendations
- `/dashboard/quality` - Content quality
- `/dashboard/intelligence` - Intelligence hub
- `/dashboard/reports` - Reports
- `/dashboard/integrations` - Integrations (CMS, etc.)
- `/dashboard/integrations/[id]` - Integration detail
- `/dashboard/team` - Team management
- `/dashboard/settings` - Settings
- `/dashboard/settings/white-label` - White label config
- `/dashboard/holding` - Holding/portfolio view
- `/dashboard/agency` - Agency mode
- `/dashboard/agency/clients` - Agency clients
- `/dashboard/agency/clients/[clientId]` - Agency client detail
- `/dashboard/agency/revenue` - Agency revenue
- `/dashboard/agency/margins` - Agency margins
- `/accept-invitation` - Team invitation acceptance

**API Routes (Fastify at `apps/api/src/routes/`):**
brands, monitoring, content, intelligence, reports, alerts, billing, competitors, authority, organizations, users, competitive, recommendations, holdings, tokens, cms, agency, white-label, stream, analytics, platform, public, ai

## QA Database Schema

Before first run, create the QA schema. Run this via `mcp__postgres__query`:

```sql
-- QA Sessions
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

-- QA Issues
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

-- QA Issue Comments
CREATE TABLE IF NOT EXISTS qa_issue_comments (
  id SERIAL PRIMARY KEY,
  issue_id INTEGER REFERENCES qa_issues(id),
  author VARCHAR(100) NOT NULL,
  comment_type VARCHAR(20) DEFAULT 'note',
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- QA Verifications
CREATE TABLE IF NOT EXISTS qa_verifications (
  id SERIAL PRIMARY KEY,
  issue_id INTEGER REFERENCES qa_issues(id),
  session_id UUID REFERENCES qa_sessions(id),
  persona VARCHAR(50),
  passed BOOLEAN NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- QA Persona Sessions
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_qa_issues_session ON qa_issues(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_issues_status ON qa_issues(status);
CREATE INDEX IF NOT EXISTS idx_qa_issues_severity ON qa_issues(severity);
CREATE INDEX IF NOT EXISTS idx_qa_verifications_issue ON qa_verifications(issue_id);
CREATE INDEX IF NOT EXISTS idx_qa_persona_sessions_session ON qa_persona_sessions(session_id);
```

**IMPORTANT:** The QA schema has already been created in the SourceRank Supabase database. No need to run migration again.

## Database Access

The `mcp__postgres__query` tool is connected to a DIFFERENT database (Contably/Claudia), NOT SourceRank. For ALL database operations in this skill, use `psql` via Bash.

**Connection pattern for ALL SQL queries:**

```bash
# Set connection string shortcut at session start:
export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

# For SELECT queries (clean output, no headers):
psql "$SRDB" -t -A -c "SELECT id, title FROM qa_issues WHERE status = 'open'"

# For JSON output (recommended for structured data):
psql "$SRDB" -t -A -c "SELECT json_agg(t) FROM (SELECT id, title FROM qa_issues) t"

# For INSERT/UPDATE with RETURNING:
psql "$SRDB" -t -A -c "INSERT INTO qa_sessions (trigger, personas) VALUES ('qa-sourcerank', ARRAY['sarah','marcus','diana','alex']) RETURNING id"
```

**CRITICAL:**

- Always use `-t -A` flags for clean output (no headers, no alignment)
- Use `-c` for single queries
- Escape single quotes in values by doubling them (`''`)
- DO NOT use `mcp__postgres__query` — it points to the wrong database
- Always set `SRDB` env var at the start of the session for convenience

## SourceRank User Personas

### Persona 1: Sarah Chen - CMO / Head of Marketing

**Role:** Organization admin, primary decision-maker
**Background:** CMO at a mid-size SaaS company (200 employees). Needs to understand how AI assistants recommend their product vs. competitors.
**Goals:** Track brand visibility across AI platforms, monitor competitive landscape, report to board
**Tech comfort:** Medium - uses dashboards daily, expects clear data visualization
**Frustration triggers:** Slow loading charts, unclear metrics, missing data, confusing navigation

**Test Routes:**

- `/` - Landing page (evaluate messaging clarity)
- `/sign-in` - Login flow
- `/dashboard` - Overview KPIs and widgets
- `/dashboard/brands` - Brand management and overview
- `/dashboard/brands/[id]` - Brand detail with AI mention data
- `/dashboard/competitive` - Competitive analysis
- `/dashboard/competitive-intelligence` - Deep competitive intel
- `/dashboard/reports` - Report generation and export
- `/dashboard/alerts` - Alert configuration and review
- `/dashboard/team` - Team management
- `/dashboard/settings` - Organization settings

**Test Workflows:**

1. Login → Dashboard → Check all KPI widgets load → Verify data freshness
2. Navigate to Brands → Select a brand → Review AI mention data → Check competitor comparison
3. Open Competitive Intelligence → Review Share of Voice → Verify charts render
4. Generate a report → Download PDF → Verify content accuracy
5. Check alerts → Review hallucination alerts → Mark as reviewed
6. Manage team → Invite new member → Verify invitation flow
7. Navigate settings → Update organization details → Verify persistence

---

### Persona 2: Marcus Rivera - SEO/Content Manager

**Role:** Organization member, daily active user
**Background:** Senior SEO manager responsible for optimizing content for both traditional search and AI discovery. Power user who logs in daily.
**Goals:** Monitor brand mentions, analyze content quality, track authority scores, optimize AI visibility
**Tech comfort:** High - power user, expects keyboard shortcuts and fast navigation
**Frustration triggers:** Slow page loads, too many clicks for common tasks, broken filters, stale data

**Test Routes:**

- `/dashboard` - Daily overview
- `/dashboard/monitor` - AI monitoring setup and results
- `/dashboard/content` - Content analysis and optimization
- `/dashboard/authority` - Authority scoring and citation tracking
- `/dashboard/quality` - Content quality scores
- `/dashboard/recommendations` - AI-generated recommendations
- `/dashboard/brands/[id]/facts` - Brand facts management
- `/dashboard/intelligence` - Intelligence hub
- `/dashboard/integrations` - CMS integrations

**Test Workflows:**

1. Login → Dashboard → Monitor page → Check latest AI mentions across platforms
2. Navigate to Content → Review content quality scores → Filter by platform → Sort by score
3. Check Authority → Review citation network → Verify scores update
4. View Recommendations → Check actionable items → Verify relevance
5. Manage Brand Facts → Add/edit facts → Verify they persist
6. Check Integrations → Review connected CMS → Verify sync status
7. Navigate to Intelligence → Review insights → Verify data accuracy

---

### Persona 3: Diana Foster - Agency Owner

**Role:** Agency admin, manages multiple client brands
**Background:** Runs a digital marketing agency with 15 client accounts. Uses SourceRank to provide AI visibility reports to clients.
**Goals:** Manage multiple brands efficiently, generate client reports, track revenue, white-label the platform
**Tech comfort:** Medium-high - comfortable with SaaS tools, expects multi-account workflows
**Frustration triggers:** Slow brand switching, can't bulk-operate, missing client-facing features

**Test Routes:**

- `/dashboard/agency` - Agency dashboard overview
- `/dashboard/agency/clients` - Client management
- `/dashboard/agency/clients/[clientId]` - Client detail
- `/dashboard/agency/revenue` - Revenue tracking
- `/dashboard/agency/margins` - Margin analysis
- `/dashboard/brands` - All brands across clients
- `/dashboard/settings/white-label` - White label configuration
- `/dashboard/reports` - Client report generation
- `/dashboard/holding` - Portfolio/holding view

**Test Workflows:**

1. Login → Agency Dashboard → Check client overview → Verify all clients listed
2. Navigate to Client detail → Check brand performance → Generate client report
3. Review Revenue page → Verify revenue data → Check margin calculations
4. Configure White Label → Upload logo → Set colors → Preview branded experience
5. Switch between client brands → Verify data isolation between clients
6. Generate multi-client report → Download → Verify all clients included
7. Holding view → Portfolio overview → Verify aggregated metrics

---

### Persona 4: Alex Park - Brand Manager

**Role:** Organization member, focuses on brand health
**Background:** Brand manager at a consumer tech company. Focused on reputation and how AI represents the brand.
**Goals:** Monitor brand reputation in AI, detect hallucinations, track competitor mentions, get alerts
**Tech comfort:** Medium - comfortable with marketing tools, not deeply technical
**Frustration triggers:** False positives in alerts, unclear what AI is saying about the brand, slow reports

**Test Routes:**

- `/dashboard` - Dashboard overview
- `/dashboard/brands/[id]` - Brand deep dive
- `/dashboard/alerts` - Alert center
- `/dashboard/alerts/hallucinations` - Hallucination detection
- `/dashboard/competitors` - Competitor tracking
- `/dashboard/competitive` - Competitive landscape
- `/dashboard/recommendations` - Brand recommendations
- `/dashboard/quality` - Content quality review

**Test Workflows:**

1. Login → Dashboard → Check brand health summary → Verify sentiment data
2. Navigate to Brand detail → Check AI mention timeline → Verify platform breakdown
3. Check Hallucination alerts → Review detected inaccuracies → Verify source links
4. Open Competitors → Compare brand vs competitors → Verify Share of Voice accuracy
5. Review Recommendations → Check brand-specific advice → Verify actionability
6. Check Content Quality → Review scores per platform → Verify scoring logic
7. Navigate between features → Verify breadcrumbs and navigation consistency

---

## Test Credentials

Since SourceRank uses Supabase Auth, the QA skill needs valid test credentials.

**Before first run, ensure test users exist.** Check with:

```sql
SELECT id, email, role FROM users LIMIT 10;
```

If no test users exist, the personas should test public pages (landing, sign-up flow) and report that test accounts are needed.

**QA Test Credentials (pre-configured, email-confirmed):**

```
Sarah Chen (CMO/Admin)     → qa-admin@sourcerank.ai / QATest2026sr   (org admin, Test Organization)
Marcus Rivera (SEO/Member) → qa-member@sourcerank.ai / QATest2026sr  (org member, Test Organization)
Diana Foster (Agency)      → qa-admin@sourcerank.ai / QATest2026sr   (same admin, test agency features)
Alex Park (Brand Manager)  → qa-member@sourcerank.ai / QATest2026sr  (same member, test brand features)
```

**Organization:** Test Organization (id: c44f4b71-292e-4a55-a55d-e83a0c341387, plan: growth, brand_limit: 3)

Both accounts share the same password. Sarah/Diana use the admin account, Marcus/Alex use the member account. This tests both role levels.

## Execution Flow

### Phase 0: Initialize QA Session

```sql
-- Create a new QA session
INSERT INTO qa_sessions (trigger, personas)
VALUES ('qa-sourcerank', ARRAY['sarah','marcus','diana','alex'])
RETURNING id;
-- SAVE this session_id for all subsequent operations
```

Also check if the QA schema exists. If not, create it (see QA Database Schema section above).

### Phase 1: Environment Discovery

1. Determine target URL:
   - If `--url` flag provided, use that
   - Else check for running local dev: `http://localhost:3000`
   - Else use production: query render dashboard or use known URL
2. Verify the site is accessible via `mcp__chrome-devtools__navigate_page`
3. Check API health: navigate to `{api_url}/health`

**Default: Test against production** (https://sourcerank-web.onrender.com).
For local testing, use `--url http://localhost:3000`.

### Phase 2: Spawn Persona Swarm

Spawn one agent per persona using Task tool with `model: "haiku"`.

**MODEL RULES (3-tier):**

- **Strategic decisions: `model: "opus"`** - triage, prioritization, root cause
- **Orchestrator + Fix phase: `model: "sonnet"`** - orchestration, code changes
- **Discovery personas + Verify phase: `model: "haiku"`** - browser navigation, bug reporting

**Before spawning, load context for each persona from the DB:**

```sql
-- Check for open issues to avoid duplicates
SELECT id, title, severity, status, affected_page, endpoint
FROM qa_issues
WHERE status NOT IN ('closed', 'verified')
ORDER BY severity, created_at;

-- Check for verification queue (recently fixed bugs to re-test)
SELECT id, title, affected_page, reproduction_steps
FROM qa_issues
WHERE status = 'testing';
```

Then spawn each persona:

```
Task({
  subagent_type: "general-purpose",
  model: "haiku",
  name: "{persona-slug}-tester",
  prompt: "You are {persona name}, a {role description}. {full persona context}.

           TARGET URL: {url}
           SESSION ID: {session_id}

           CURRENTLY OPEN ISSUES (do NOT report duplicates):
           {open_issues}

           VERIFICATION QUEUE (re-test these fixed bugs):
           {testing_issues}

           STEP 1: Start your persona session by running this SQL via mcp__postgres__query:
           INSERT INTO qa_persona_sessions (session_id, persona)
           VALUES ('{session_id}', '{slug}')
           RETURNING id;
           SAVE the returned id.

           STEP 2: Navigate to {url} and test these workflows: {workflow list}.
           Use mcp__chrome-devtools to navigate, click, fill forms, take snapshots.
           For each page/action, evaluate:
           1. FUNCTIONALITY - Does it work? Any errors? Console errors?
           2. UX/USABILITY - Is it intuitive? Confusing? Too many clicks?
           3. PERFORMANCE - Is it fast? Any loading delays?
           4. DATA ACCURACY - Do numbers/dates/statuses look correct?
           5. VISUAL - Do charts render? Are layouts broken?

           STEP 3: For each bug found:
           a) Check for duplicates FIRST:
              SELECT id, title FROM qa_issues
              WHERE affected_page = '{page}' AND status != 'closed'
              LIMIT 5;
           b) If NO duplicate, create new issue:
              INSERT INTO qa_issues (
                session_id, title, severity, category, persona,
                endpoint, http_status, error_message,
                expected, actual, affected_page, reproduction_steps
              ) VALUES (
                '{session_id}', '{title}', '{severity}', '{category}', '{slug}',
                '{endpoint}', {status}, '{error}',
                '{expected}', '{actual}', '{page}',
                '{steps_json}'::jsonb
              );

           STEP 4: Verify fixed bugs from the verification queue:
           For each issue in testing status, follow reproduction steps.
           Record result:
              INSERT INTO qa_verifications (issue_id, session_id, persona, passed, notes)
              VALUES ({issue_id}, '{session_id}', '{slug}', {true|false}, '{notes}');
           If passed: UPDATE qa_issues SET status = 'verified', updated_at = NOW() WHERE id = {id};
           If failed: UPDATE qa_issues SET status = 'in_progress', updated_at = NOW() WHERE id = {id};

           STEP 5: Complete your persona session:
           UPDATE qa_persona_sessions
           SET satisfaction = {score}, pages_visited = ARRAY[{pages}],
               workflows_tested = ARRAY[{workflows}], completed_at = NOW(),
               observations = '{observations}'
           WHERE id = '{persona_session_id}';

           Write feedback AS THE PERSONA - first person, with their frustrations."
})
```

### Phase 3: Report Generation

After all personas complete, generate a summary:

```sql
-- Issues by severity
SELECT severity, COUNT(*) FROM qa_issues
WHERE session_id = '{session_id}' GROUP BY severity;

-- Issues by category
SELECT category, COUNT(*) FROM qa_issues
WHERE session_id = '{session_id}' GROUP BY category;

-- Persona satisfaction
SELECT persona, satisfaction FROM qa_persona_sessions
WHERE session_id = '{session_id}';

-- Verification results
SELECT v.issue_id, i.title, v.passed, v.notes
FROM qa_verifications v JOIN qa_issues i ON v.issue_id = i.id
WHERE v.session_id = '{session_id}';
```

Output a structured report for the user.

### Phase 4: Fix

For each open issue (sorted by severity):

1. Claim: `UPDATE qa_issues SET status = 'assigned', assigned_to = 'qa-agent' WHERE id = {id};`
2. Investigate the codebase using Explore agent or direct file reads
3. Apply fix using Edit/Write tools
4. Update: `UPDATE qa_issues SET status = 'testing', updated_at = NOW() WHERE id = {id};`
5. Add comment: `INSERT INTO qa_issue_comments (issue_id, author, comment_type, content) VALUES ({id}, 'qa-agent', 'fix', '{description}');`

### Phase 5: Verify

For each issue in `testing` status:

1. Navigate to the affected page via Chrome DevTools
2. Follow reproduction steps
3. Record verification result in DB
4. Move to `verified` or back to `in_progress`

### Phase 6: Regression Check

```sql
-- Check for regressions: previously closed issues that reappeared
SELECT i.id, i.title, i.severity
FROM qa_issues i
WHERE i.status = 'open'
  AND i.original_issue_id IS NOT NULL;

-- Trend: compare issue counts across sessions
SELECT s.id, s.started_at,
  COUNT(CASE WHEN i.severity = 'p0-critical' THEN 1 END) as p0,
  COUNT(CASE WHEN i.severity = 'p1-high' THEN 1 END) as p1,
  COUNT(*) as total
FROM qa_sessions s
LEFT JOIN qa_issues i ON i.session_id = s.id
GROUP BY s.id, s.started_at
ORDER BY s.started_at DESC
LIMIT 5;
```

### Session Completion

```sql
UPDATE qa_sessions
SET status = 'completed',
    completed_at = NOW(),
    summary = '{summary}'
WHERE id = '{session_id}';
```

## Autonomous Operation

This skill runs as a **continuous autonomous loop** until all issues are resolved:

```
discover → report → fix → verify → regression →
┌─── open issues remaining? ───┐
│ YES → start new cycle        │
│ NO  → output final summary   │
└──────────────────────────────┘
```

### Rules

- **Never ask the user** for confirmation, next steps, or permission at any point
- **Never stop between phases** — the full pipeline runs end-to-end
- After fixing, verify the fixes work on the target environment
- If open issues remain → start a new cycle automatically
- If zero open issues → output a final summary and stop
- Each cycle focuses on progressively lower severity: P0 first cycle, P1 second, etc.
- **Max 3 cycles** per invocation to prevent infinite loops
- The only exception: if `--discover-only`, `--fix-only`, or `--verify-only` flags are set, run only that phase then stop

**IMPORTANT:** Never output messages like "Want me to continue?", "Should I proceed?", "Next step would be...", or any phrasing that implies waiting for user input. Just do it.

## Deployment (Render.com)

SourceRank deploys to Render.com. After fixes:

```bash
# Commit fixes
git add -A && git commit -m "fix(qa): {summary of fixes}"

# Push triggers Render auto-deploy
git push origin master
```

**Post-deploy verification:**

```bash
# Check web health
curl -s -o /dev/null -w '%{http_code}' https://sourcerank-web.onrender.com

# Check API health
curl -s https://sourcerank-api.onrender.com/health
```

## Opus-for-Decisions Pattern

Use opus briefly for strategic thinking at these decision points:

1. **Post-Discovery Triage** - Which issues are real vs. environment artifacts?
2. **Complex Root Cause** - When a fix isn't obvious
3. **Regression Analysis** - Cross-session pattern analysis
4. **Deploy Decision** - Should we deploy these changes?

Keep opus calls **rare** (1-3 per full cycle) and **concise**.

## Flags Reference

| Flag              | Description                           | Phases Run                 |
| ----------------- | ------------------------------------- | -------------------------- |
| (none)            | Full cycle                            | All phases                 |
| `--discover-only` | Run persona testing only              | Discover + Report          |
| `--fix-only`      | Fix existing open issues              | Fix only                   |
| `--verify-only`   | Verify issues in TESTING status       | Verify only                |
| `--report`        | Generate report from current DB state | Report only                |
| `--severity X`    | Filter issues by severity             | Applies to all phases      |
| `--url URL`       | Override target URL (default: prod)   | Applies to discover+verify |
| `--limit N`       | Max issues to process per phase       | Applies to fix + verify    |

## Completion Signal

```json
{
  "status": "complete|partial|blocked|failed",
  "summary": "Full QA cycle completed",
  "sessionId": "{session_uuid}",
  "phases": {
    "discover": { "status": "complete", "newIssues": 8, "personasTested": 4 },
    "report": { "status": "complete" },
    "fix": { "status": "complete", "issuesFixed": 5, "issuesSkipped": 2 },
    "verify": { "status": "complete", "verified": 4, "failed": 1 },
    "regression": { "regressionsDetected": 0 }
  },
  "overallHealth": {
    "totalOpenIssues": 3,
    "criticalOpen": 0,
    "trend": "improving"
  }
}
```

---

## Version

**Current Version:** 1.0.0
**Last Updated:** February 2026

### Requirements

- Chrome DevTools MCP (for browser testing)
- PostgreSQL MCP (for QA issue tracking - uses SourceRank's Supabase DB)
- Access to SourceRank production or local dev environment
- SourceRank codebase at /Users/ps/code/Sourcerankai

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains.
