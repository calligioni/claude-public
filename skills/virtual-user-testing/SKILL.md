---
name: virtual-user-testing
description: "Swarm-enabled virtual user testing for Contably with persistent QA database. Spawns parallel persona agents (haiku) that simulate real users - accountants, business owners, client portal users - navigating the app, testing workflows, and reporting bugs to the QA database via qa_manager.py. Includes verification of previously fixed bugs and regression detection. Triggers on: virtual user test, persona test, user simulation, test as user, user feedback simulation, qa discover."
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
  - AskUserQuestion
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - mcp__chrome-devtools__*
  - mcp__memory__*
memory: user
---

# Virtual User Testing Skill (v2.0 - DB-Backed QA Cycle)

Spawns parallel virtual user personas that simulate real Contably users navigating the app, testing workflows, reporting bugs to the QA database, and verifying previously fixed issues.

## What It Does

When you run `/virtual-user-testing`, it will:

1. **Create a QA session** in the database via `qa_manager.py`
2. Detect the running Contably environment (admin + client portal URLs)
3. **Spawn concurrent persona testers** (haiku model) - one per user type
4. Each persona:
   - **Loads their history** from the DB (past bugs, satisfaction trends)
   - **Loads open issues** to avoid duplicate reporting
   - **Loads verification queue** of recently fixed bugs to re-test
   - Navigates the app **as their role would**, testing real workflows
   - **Reports bugs to the QA database** via `qa_manager.py issue create`
   - **Verifies fixed bugs** via `qa_manager.py issue verify`
   - **Records their session** (pages visited, satisfaction, observations)
5. Orchestrator generates reports from DB data:
   - **CTO Report** - technical issues, bugs, performance, security concerns (with DB issue IDs)
   - **CPO Report** - UX issues, feature gaps, workflow friction, satisfaction trends
6. **Completes the QA session** in the database

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│              VIRTUAL USER TESTING ORCHESTRATOR (sonnet)               │
│                                                                      │
│  Phase 0: Session Initialization (qa_manager.py session start)       │
│         │                                                            │
│         ▼                                                            │
│  Phase 1: Environment Discovery                                      │
│         │                                                            │
│         ▼                                                            │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │            PHASE 2: PERSONA SWARM TESTING (haiku)             │   │
│  │                                                                │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│  │  │  MARIA   │  │  CARLOS  │  │  RENATA  │  │  JOAO    │      │   │
│  │  │ AF Admin │  │ Analyst  │  │ Client   │  │ Client   │      │   │
│  │  │ (master) │  │(company) │  │  Admin   │  │ Viewer   │      │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘      │   │
│  │       │              │              │              │            │   │
│  │  ┌────┴──────────────┴──────────────┴──────────────┘            │   │
│  │  │  PEDRO (Company Admin)                                       │   │
│  │  └──────────────────────────────────────────────────────────┐   │   │
│  │                          │                                   │   │   │
│  │             ┌────────────┴────────────┐                      │   │   │
│  │             │   DB-BACKED BUG REPORTS  │                      │   │   │
│  │             │ • qa_manager.py issue    │                      │   │   │
│  │             │ • Duplicate detection    │                      │   │   │
│  │             │ • Verification results   │                      │   │   │
│  │             └─────────────────────────┘                      │   │   │
│  └───────────────────────────────────────────────────────────────┘   │
│         │                                                            │
│         ▼                                                            │
│  Phase 3: Verification (personas re-test fixed bugs)                 │
│         │                                                            │
│         ▼                                                            │
│  Phase 4: Report Generation (from DB via qa_manager.py report)       │
│         │                                                            │
│         ▼                                                            │
│  Phase 5: Session Completion (qa_manager.py session complete)        │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
               ┌─────────────────────────────┐
               │   PostgreSQL (qa schema)     │
               │   qa_issues, qa_sessions,    │
               │   qa_personas, etc.          │
               └─────────────────────────────┘
```

## Contably User Personas

### Persona 1: Maria Silva - Accounting Firm Master Admin

**Role:** `is_master_admin=true`, Accounting Firm Admin
**Background:** Senior partner at a mid-size accounting firm managing 25 companies
**Goals:** Efficiently manage all client companies, onboard analysts, oversee work quality
**Tech comfort:** High - power user who expects keyboard shortcuts and bulk actions
**Frustration triggers:** Slow page loads, too many clicks for common tasks, unclear error messages

**Test Routes (Admin App):**

- `/admin/accounting-firms` - Managing her firm's settings
- `/admin/accounting-firm-users` - Adding/removing team members
- `/admin/subsidiaries` - Managing company subsidiaries
- `/admin/client-users` - Managing client portal access
- `/admin/analysts` - Assigning analysts to companies
- `/companies` - Switching between client companies
- `/settings` - Firm-wide and company settings
- `/admin/scheduled-jobs` - Monitoring automated jobs
- `/admin/erp-integrations` - ERP connection health

**Test Workflows:**

1. Login → Switch between 3 different companies → Check dashboard for each
2. Create new analyst user → Assign to 2 companies → Verify access
3. Manage client portal users → Bulk activate/deactivate → Verify status
4. Check ERP integration status → Troubleshoot failed sync → Re-trigger
5. Review scheduled jobs → Check for failures → Acknowledge alerts

---

### Persona 2: Carlos Mendes - Accounting Analyst

**Role:** `AccountingFirmUser.role='analyst'`, assigned to specific companies
**Background:** Junior accountant (2 years experience) handling 8 client companies
**Goals:** Process monthly accounting efficiently, reconcile transactions, generate reports
**Tech comfort:** Medium - comfortable with accounting software but not a power user
**Frustration triggers:** Confusing navigation, data inconsistencies, losing work without save

**Test Routes (Admin App):**

- `/accounting` - Daily ledger work
- `/reconciliation` - Bank reconciliation
- `/reconciliation/cross` - Cross-company reconciliation
- `/invoices` - Invoice management
- `/financial-reports` - Balance sheet, DRE
- `/reports` - Report generation
- `/monthly-closing` - Monthly closing process
- `/anomalies` - Reviewing flagged anomalies
- `/alerts` - Checking alert center
- `/cash-flow` - Cash flow analysis
- `/payroll` - Payroll data review
- `/compliance` - Compliance reports
- `/deadlines` - Tax deadline tracking

**Test Workflows:**

1. Login → Select company → Open accounting ledger → Filter by date range → Export
2. Start reconciliation → Match transactions → Handle unmatched items → Complete
3. Generate balance sheet → Compare with previous month → Export PDF
4. Review anomalies → Investigate flagged transactions → Mark as resolved/escalate
5. Check monthly closing status → Run pre-close checks → Complete closing
6. Navigate to company they DON'T have access to → Verify permission denied

---

### Persona 3: Renata Oliveira - Client Portal Admin

**Role:** `ClientUser.role='admin'`, company owner
**Background:** Owner of a mid-size e-commerce company, 50 employees
**Goals:** Monitor financial health, upload documents on time, communicate with accountant
**Tech comfort:** Low-medium - uses phone more than desktop, easily frustrated by complexity
**Frustration triggers:** Jargon, unclear next steps, can't find what she needs quickly

**Test Routes (Client Portal):**

- `/dashboard` - Overview of company financial health
- `/financial-summary` - Monthly financial summary
- `/reports` - View available reports from accountant
- `/documents` - Upload/manage documents
- `/document-requests` - Respond to document requests
- `/messages` - Communicate with accounting team
- `/tickets` - Submit support tickets
- `/requests` - Submit requests using templates
- `/processes` - Track ongoing processes
- `/tax-calendar` - View upcoming tax deadlines
- `/settings` - Manage profile and other client users

**Test Workflows:**

1. Login → Check dashboard → View financial summary → Download latest report
2. Receive document request notification → Upload document → Confirm submission
3. Open messages → Send question to accountant → Check for reply
4. Submit support ticket → Track status → Add follow-up comment
5. Check tax calendar → Note upcoming deadlines → Set reminder
6. Manage other client users → Invite new user → Set as viewer role
7. Try accessing admin features → Verify restricted to client portal only

---

### Persona 4: Joao Ferreira - Client Portal Viewer

**Role:** `ClientUser.role='viewer'`, company CFO
**Background:** CFO who needs read-only access to financial reports and dashboards
**Goals:** Monitor financial KPIs, download reports for board meetings, stay informed
**Tech comfort:** Medium-high - comfortable with data but expects clean visualizations
**Frustration triggers:** Can't find specific data, reports not up-to-date, slow loading charts

**Test Routes (Client Portal):**

- `/dashboard` - Financial dashboard
- `/financial-summary` - Detailed financial data
- `/reports` - Download reports
- `/documents` - View (not upload) documents
- `/tax-calendar` - Tax deadline overview
- `/processes` - View process status

**Test Workflows:**

1. Login → Dashboard → Check all KPI widgets load → Verify data freshness
2. Navigate to reports → Filter by type/date → Download PDF/Excel
3. View financial summary → Check all charts render → Verify number accuracy
4. Try to upload document → Verify viewer restriction (should be blocked)
5. Try to manage users in settings → Verify admin-only features are hidden
6. Check tax calendar → Verify deadlines display correctly

---

### Persona 5: Pedro Santos - Company Admin (Internal)

**Role:** `CompanyUser.role='admin'`, company-level admin within the accounting firm
**Background:** Senior accountant responsible for a key client's complete accounting
**Goals:** Full control over one company's accounting, reporting, and team coordination
**Tech comfort:** High - deep knowledge of accounting and the system
**Frustration triggers:** Permission issues, missing features for edge cases, slow bulk operations

**Test Routes (Admin App):**

- All Carlos routes PLUS:
- `/settings` - Company-specific settings
- `/admin/client-users` - Managing this company's client portal users
- `/lineage` - Data lineage tracking
- `/analytics` - Predictive analytics
- `/workflows` - Workflow management
- `/orchestrator` - Approval console

**Test Workflows:**

1. Login → Full accounting workflow: ledger → reconciliation → reports → closing
2. Configure company settings → Verify changes persist → Check downstream effects
3. Manage client portal users for this company → Create, edit, deactivate
4. Run predictive analytics → Verify data accuracy → Export insights
5. Check data lineage → Trace a transaction through the system
6. Manage workflow approvals → Approve/reject pending items

---

## Execution Flow

### Phase 0: Session Initialization

```bash
# Create a QA session in the database
# Returns a session UUID to pass to all persona agents
python apps/api/scripts/qa_manager.py session start \
  --trigger manual \
  --personas maria,carlos,renata,joao,pedro

# Output: {"session_id": "abc-123-uuid", "status": "started"}
# SAVE this session_id - pass it to every persona agent
```

### Phase 1: Environment Discovery

```
1. Detect running services:
   - Admin app URL (default: http://localhost:5173)
   - Client portal URL (default: http://localhost:3000)
   - API URL (default: http://localhost:8000)
2. Verify services are accessible via chrome-devtools
3. Check for test credentials or create virtual users via API
```

### Phase 2: Spawn Persona Swarm

Spawn one agent per persona using Task tool with `model: "haiku"`.

**CRITICAL MODEL RULES:**

- **Persona testers MUST use `model: "haiku"`** - they do navigation, bug reporting, and verification. Haiku is fast, cheap, and sufficient for this.
- **Orchestrator runs on sonnet** (set in YAML header above) - it handles coordination, report synthesis, and cross-persona analysis.
- **NEVER spawn persona testers with sonnet or opus** - this wastes budget with no benefit.

**CRITICAL: Before spawning, load context for each persona from the DB.**

For each persona, first gather their context:

```bash
# Load persona history (past sessions, bugs found, satisfaction trend)
python apps/api/scripts/qa_manager.py query persona-history --persona {slug} --limit 5

# Load currently open issues (to avoid duplicates)
python apps/api/scripts/qa_manager.py query open-issues

# Load verification queue (recently fixed bugs this persona should re-test)
python apps/api/scripts/qa_manager.py query regression-check --persona {slug}
```

Then spawn the persona agent with all this context:

```
For each persona:
  Task({
    subagent_type: "general-purpose",
    model: "haiku",
    name: "{persona-name}-tester",
    prompt: "You are {persona name}, a {role description}. {full persona context}.

             SESSION CONTEXT:
             - Session ID: {session_id}
             - QA Manager script: python apps/api/scripts/qa_manager.py

             YOUR HISTORY (from previous sessions):
             {persona_history_output}

             CURRENTLY OPEN ISSUES (do NOT report duplicates):
             {open_issues_output}

             VERIFICATION QUEUE (re-test these fixed bugs):
             {regression_check_output}

             STEP 1: Start your persona session:
             python apps/api/scripts/qa_manager.py persona-session start \
               --session-id {session_id} --persona {slug}
             SAVE the returned persona_session_id.

             STEP 2: Navigate to {app URL} and test these workflows: {workflow list}.
             For each page/action, evaluate:
             1. FUNCTIONALITY - Does it work? Any errors? Console errors?
             2. UX/USABILITY - Is it intuitive? Confusing? Too many clicks?
             3. PERFORMANCE - Is it fast? Any loading delays?
             4. PERMISSIONS - Can you access only what your role allows?
             5. DATA ACCURACY - Do numbers/dates/statuses look correct?
             6. MOBILE/RESPONSIVE - Does it work on smaller screens?

             STEP 3: For each bug found:
             a) Check for duplicates FIRST:
                python apps/api/scripts/qa_manager.py query duplicate-check \
                  --endpoint '{endpoint}' --http-status {status}
             b) If NO duplicate found, create new issue:
                python apps/api/scripts/qa_manager.py issue create \
                  --title 'Description of bug' \
                  --severity {p0-critical|p1-high|p2-medium|p3-low} \
                  --persona {slug} \
                  --session-id {session_id} \
                  --endpoint '{endpoint}' \
                  --http-status {status} \
                  --error-message '{error}' \
                  --expected 'What should happen' \
                  --actual 'What actually happened' \
                  --category {auth|navigation|api|ui|data|performance} \
                  --affected-app {admin|portal} \
                  --affected-page '{page_path}' \
                  --steps '[{\"step\":1,\"action\":\"...\",\"expected\":\"...\",\"actual\":\"...\"}]'
             c) If duplicate found, add a comment instead:
                python apps/api/scripts/qa_manager.py comment add \
                  --issue-id {existing_id} \
                  --author {slug} \
                  --comment 'Still reproducing as of {date}' \
                  --type note

             STEP 4: Verify fixed bugs from your queue:
             For each issue in the verification queue:
             a) Follow the reproduction steps from the issue
             b) Record the result:
                python apps/api/scripts/qa_manager.py issue verify \
                  --id {issue_id} \
                  --persona {slug} \
                  --passed {true|false} \
                  --session-id {session_id} \
                  --notes 'Description of verification result'

             STEP 5: Complete your persona session:
             python apps/api/scripts/qa_manager.py persona-session complete \
               --id {persona_session_id} \
               --satisfaction {1-10 score} \
               --pages '[\"page1\",\"page2\"]' \
               --workflows '[\"workflow1\",\"workflow2\"]'

             Write your feedback AS THE PERSONA - in first person, with their
             level of technical sophistication and their specific frustrations.

             IMPORTANT: ALL bugs go to the database via qa_manager.py.
             Do NOT write bugs to markdown files or MCP memory."
  })
```

**CRITICAL: All persona testers MUST use `model: "haiku"` to minimize cost.**

The orchestrator (sonnet) manages coordination, synthesis, and report generation.

### Phase 3: Real-Time Cross-Persona Detection

As persona testers report back, the orchestrator watches for:

| Pattern                      | Detection                                          | Action                    |
| ---------------------------- | -------------------------------------------------- | ------------------------- |
| Same bug on multiple portals | 2+ personas report same error                      | Flag as systemic          |
| Permission leak              | Viewer can do admin actions                        | Flag as CRITICAL security |
| UX inconsistency             | Same feature works differently across roles        | Flag for CPO              |
| Performance bottleneck       | Multiple personas report slow page                 | Flag for CTO              |
| Data inconsistency           | Different roles see different data for same entity | Flag as CRITICAL          |
| Regression                   | Previously CLOSED issue reappears                  | Auto-escalate to P0       |

### Phase 4: Report Generation (from DB)

After all personas complete, generate reports from the database:

```bash
# Generate CTO report with issue IDs, severities, trends
python apps/api/scripts/qa_manager.py report cto --session-id {session_id}

# Generate CPO report with UX observations, satisfaction trends
python apps/api/scripts/qa_manager.py report cpo --session-id {session_id}
```

Reports are generated from actual DB data and include:

- Issue IDs that can be referenced directly (e.g., "Bug #42")
- Links to previous sessions for trend analysis
- Verification results and regression flags

### Phase 5: Session Completion

```bash
# Complete the QA session with summary
python apps/api/scripts/qa_manager.py session complete \
  --id {session_id} \
  --summary "Discovery session with 5 personas. Found X new issues, verified Y fixes, detected Z regressions."
```

## Usage

```
/virtual-user-testing                          # Test all personas
/virtual-user-testing admin-only               # Test admin app personas only
/virtual-user-testing client-only              # Test client portal personas only
/virtual-user-testing persona:maria            # Test single persona
/virtual-user-testing --url http://localhost:5173 --api http://localhost:8000
/virtual-user-testing --verify-only            # Only verify fixed bugs, skip discovery
```

## Test Credentials

**Password for ALL test users:** `1@Masterpass`

These users are created by the seed script (`apps/api/scripts/seed_database.py`).
To re-seed: `kubectl exec -n contably <api-pod> -- python scripts/seed_database.py`

### Admin App Users (https://contably.ai or staging)

| Persona               | Email                       | Role                   | Firm/Company              | Access                          |
| --------------------- | --------------------------- | ---------------------- | ------------------------- | ------------------------------- |
| Maria (Master Admin)  | `master@contably.com`       | `is_master_admin=true` | All firms/companies       | Full system access              |
| Carlos (Analyst)      | `analyst1.abc@contably.com` | AF Analyst             | ABC Firm → Tech Solutions | Company only, no subsidiaries   |
| Pedro (Company Admin) | `admin.tech@empresa.com.br` | Company Admin          | Tech Solutions            | Full company + all subsidiaries |
| Admin ABC (AF Admin)  | `admin.abc@contably.com`    | AF Admin               | ABC Firm                  | All companies under ABC         |

### Client Portal Users (https://portal.contably.ai or staging)

| Persona               | Email                     | Role          | Company        |
| --------------------- | ------------------------- | ------------- | -------------- |
| Renata (Client Admin) | `renata@test.contably.ai` | Client Admin  | Tech Solutions |
| Joao (Client Viewer)  | `joao@test.contably.ai`   | Client Viewer | Tech Solutions |

### Additional Test Users (available for deeper testing)

**Analysts:**

- `analyst2.abc@contably.com` - ABC Firm → Comercio Express (company + all subsidiaries)
- `analyst3.abc@contably.com` - ABC Firm → Tech Solutions (Filial 1 only, no company access)
- `analyst1.xyz@contably.com` - XYZ Firm → Industria Nacional (company only)

**Company Users:**

- `admin.comercio@empresa.com.br` - Comercio Express Admin
- `user1.tech@empresa.com.br` - Tech Solutions Editor (company + Filial 1)
- `user2.tech@empresa.com.br` - Tech Solutions Viewer (Filial 2 only)

### Staging Environment URLs

- **Admin App:** `https://contably.ai` (current OCI staging)
- **Client Portal:** `https://portal.contably.ai`
- **API:** `https://api.contably.ai`

### Persona-to-Credential Mapping

When spawning persona testers, use these mappings:

```
Maria Silva (AF Master Admin)    → master@contably.com / 1@Masterpass
Carlos Mendes (Analyst)          → analyst1.abc@contably.com / 1@Masterpass
Renata Oliveira (Client Admin)   → renata@test.contably.ai / 1@Masterpass  (CLIENT PORTAL)
Joao Ferreira (Client Viewer)    → joao@test.contably.ai / 1@Masterpass    (CLIENT PORTAL)
Pedro Santos (Company Admin)     → admin.tech@empresa.com.br / 1@Masterpass
```

## Bug Reporting Flow (DB-Backed)

### Creating a New Issue

Every persona uses `qa_manager.py` to report bugs. The flow is:

```bash
# 1. Check for duplicates FIRST
python apps/api/scripts/qa_manager.py query duplicate-check \
  --endpoint "/api/v1/client/auth/login" \
  --http-status 500

# 2a. If no duplicate: create new issue
python apps/api/scripts/qa_manager.py issue create \
  --title "Client portal login returns 500 on valid credentials" \
  --severity p1-high \
  --persona renata \
  --session-id {session_uuid} \
  --endpoint "/api/v1/client/auth/login" \
  --http-status 500 \
  --error-message "Internal server error" \
  --expected "Successful login with redirect to dashboard" \
  --actual "500 error page displayed" \
  --category auth \
  --affected-app portal \
  --affected-page "/login" \
  --steps '[{"step":1,"action":"Navigate to /login","expected":"Login form","actual":"Login form displayed"},{"step":2,"action":"Enter valid credentials","expected":"Redirect to /dashboard","actual":"500 error"}]'

# 2b. If duplicate found: add comment to existing issue
python apps/api/scripts/qa_manager.py comment add \
  --issue-id 42 \
  --author renata \
  --comment "Still reproducing as of 2026-02-12. Tried 3 times with same result." \
  --type note
```

### Verifying Fixed Bugs

```bash
# Each persona verifies bugs from their verification queue
python apps/api/scripts/qa_manager.py issue verify \
  --id 42 \
  --persona renata \
  --passed true \
  --session-id {session_uuid} \
  --notes "Login now works correctly. Redirects to dashboard as expected."
```

### Regression Detection

If a persona encounters a bug that was previously CLOSED:

```bash
# Create regression issue linked to original
python apps/api/scripts/qa_manager.py issue create \
  --title "REGRESSION: Client portal login returns 500 again" \
  --severity p0-critical \
  --persona renata \
  --session-id {session_uuid} \
  --endpoint "/api/v1/client/auth/login" \
  --http-status 500 \
  --expected "Login works (was fixed in issue #42)" \
  --actual "500 error returned again" \
  --category auth \
  --affected-app portal \
  --affected-page "/login" \
  --original-issue-id 42 \
  --steps '[{"step":1,"action":"Navigate to /login","expected":"Login form","actual":"Login form"},{"step":2,"action":"Enter credentials","expected":"Dashboard","actual":"500 error"}]'
```

## Persona Session Tracking

Each persona tracks their full session in the DB:

```bash
# Start persona session
python apps/api/scripts/qa_manager.py persona-session start \
  --session-id {session_uuid} \
  --persona maria
# Returns: {"persona_session_id": "ps-uuid-123"}

# ... testing happens ...

# Complete persona session with results
python apps/api/scripts/qa_manager.py persona-session complete \
  --id {persona_session_id} \
  --satisfaction 7 \
  --pages '["/admin/accounting-firms","/companies","/settings"]' \
  --workflows '["company-switching","analyst-management","erp-troubleshooting"]'
```

## Completion Signal

```json
{
  "status": "complete|partial|blocked|failed",
  "summary": "Virtual user testing complete with 5 personas",
  "sessionId": "{qa_session_uuid}",
  "personaResults": {
    "maria": { "satisfaction": 7, "bugs": 2, "verified": 1, "regressions": 0 },
    "carlos": { "satisfaction": 6, "bugs": 4, "verified": 2, "regressions": 0 },
    "renata": { "satisfaction": 5, "bugs": 1, "verified": 0, "regressions": 1 },
    "joao": { "satisfaction": 8, "bugs": 0, "verified": 1, "regressions": 0 },
    "pedro": { "satisfaction": 7, "bugs": 3, "verified": 1, "regressions": 0 }
  },
  "issuesSummary": {
    "new_bugs": 10,
    "duplicates_found": 3,
    "verifications_passed": 4,
    "verifications_failed": 1,
    "regressions_detected": 1
  },
  "reports": {
    "cto": "Generated via: qa_manager.py report cto --session-id {uuid}",
    "cpo": "Generated via: qa_manager.py report cpo --session-id {uuid}"
  },
  "crossPersonaPatterns": {
    "systemic_bugs": 1,
    "permission_issues": 0,
    "ux_inconsistencies": 2,
    "performance_bottlenecks": 1
  },
  "userActionRequired": "Review CTO and CPO reports, then run /qa-fix to address issues or /qa-cycle for full cycle"
}
```

## Integration with QA Cycle Skills

### Workflow: Discover → Fix → Verify (Full Cycle)

```
1. /virtual-user-testing     →  Personas discover bugs, report to DB, verify old fixes
2. /qa-fix                   →  CTO/dev agents read DB issues, create fixes
3. /qa-verify                →  Personas verify fixes via browser testing
4. /qa-cycle                 →  Orchestrates all phases automatically
```

### Workflow: Virtual Users → CTO → Implementation

```
1. /virtual-user-testing  →  Discovers bugs, writes to DB with issue IDs
2. /qa-fix --severity p0  →  Auto-fix critical bugs from DB
3. /virtual-user-testing  →  Re-test to verify fixes + check for regressions
```

### Workflow: Virtual Users → CPO → Product Decisions

```
1. /virtual-user-testing  →  Generates CPO report with UX observations
2. Review CPO report      →  Prioritize product improvements
3. /deep-plan             →  Plan feature implementations
```

## Configuration

Create `virtual-user-testing.config.md` in project root to customize:

```markdown
# Virtual User Testing Configuration

## Environment

- admin_url: http://localhost:5173
- client_portal_url: http://localhost:3000
- api_url: http://localhost:8000

## Personas to Test

- [x] maria (AF Master Admin)
- [x] carlos (Analyst)
- [x] renata (Client Admin)
- [x] joao (Client Viewer)
- [x] pedro (Company Admin)

## Focus Areas

- [x] Functionality
- [x] UX/Usability
- [x] Performance
- [x] Permissions
- [x] Data Accuracy
- [ ] Mobile/Responsive

## Custom Scenarios

- Test monthly closing workflow end-to-end
- Test client onboarding flow
- Test multi-company switching under load
```

---

## Version

**Current Version:** 2.0.0
**Last Updated:** February 2026

### Changelog

- **2.0.0**: DB-backed QA cycle integration
  - Session initialization via qa_manager.py
  - Persona history loading from DB
  - Bug reporting via qa_manager.py (replaces markdown/memory)
  - Duplicate detection before issue creation
  - Verification phase for fixed bugs
  - Persona session tracking in DB
  - Report generation from DB data
  - Regression detection with auto-escalation
- **1.0.0**: Initial release with markdown reports and MCP memory

### Requirements

- Chrome DevTools MCP (for browser navigation)
- Running Contably environment (admin + client portal + API)
- QA database schema (migration 029_qa_schema)
- qa_manager.py CLI script (apps/api/scripts/qa_manager.py)

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains:

```json
{ "taskId": "1", "status": "deleted" }
```

## Hook Events

This skill leverages:

- **TeammateIdle**: Triggers when a persona tester completes their workflow
- **TaskCompleted**: Triggers when a persona test task is marked completed
