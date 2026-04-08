---
name: virtual-user-testing
description: "Swarm-enabled virtual user testing for Contably with QA database. Spawns parallel persona agents simulating real users, reports bugs, verifies fixes, detects regressions. Triggers on: virtual user test, persona test, user simulation, test as user, qa discover."
user-invocable: true
context: fork
model: opus
effort: medium
allowed-tools:
  - Agent
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
  # browse CLI (~/.local/bin/browse) is the PRIMARY browser tool
  # mcp__chrome-devtools__* is the fallback when browse is unavailable
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__chrome-devtools__click: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__fill: { destructiveHint: false, idempotentHint: false }
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

# Virtual User Testing Skill (v2.1 - browse CLI + DB-Backed QA Cycle)

Spawns parallel virtual user personas that simulate real Contably users navigating the app, testing workflows, reporting bugs to the QA database, and verifying previously fixed issues.

## Browser Automation: Primary vs Fallback

**Primary tool: `browse` CLI** (`~/.local/bin/browse`) — compiled headless Chromium, zero MCP token overhead, ~100ms per call.

**Fallback: Chrome DevTools MCP** (`mcp__chrome-devtools__*`) — used only when `browse` is not available.

### Detection

At the start of the session, check for `browse`:

```bash
test -x ~/.local/bin/browse && echo "browse available" || echo "fallback to MCP"
```

### browse Command Reference

| Task                                | Command                                             |
| ----------------------------------- | --------------------------------------------------- |
| Navigate                            | `browse goto <url>`                                 |
| Interactive elements (with @e refs) | `browse snapshot -i`                                |
| Diff vs previous snapshot           | `browse snapshot -D`                                |
| Annotated screenshot                | `browse snapshot -a -o path.png`                    |
| Plain screenshot                    | `browse screenshot [path]`                          |
| Page text                           | `browse text`                                       |
| Click element                       | `browse click @e3`                                  |
| Fill input                          | `browse fill @e4 "value"`                           |
| Console logs                        | `browse console`                                    |
| Network requests                    | `browse network`                                    |
| Evaluate JS                         | `browse js "expr"`                                  |
| Get cookies                         | `browse cookies`                                    |
| Import browser cookies              | `browse cookie-import-browser [chrome\|arc\|brave]` |

### Per-Persona Isolation

Each persona agent runs an **isolated Chromium instance** via a unique `BROWSE_STATE_FILE`. Set this at the top of each persona agent's prompt:

```bash
# Prefix EVERY browse call with the env var (it does not persist across Bash tool calls):
BROWSE_STATE_FILE="/tmp/browse-state-{persona-slug}.json" browse goto http://localhost:5173
BROWSE_STATE_FILE="/tmp/browse-state-{persona-slug}.json" browse snapshot -i
# etc.
```

**IMPORTANT:** Each `Bash` tool invocation runs in a new shell process — `export` does not persist between calls. You MUST prefix every `browse` call with `BROWSE_STATE_FILE=...` inline, or create a wrapper script at session start:

```bash
echo '#!/bin/bash
BROWSE_STATE_FILE="/tmp/browse-state-{persona-slug}.json" exec ~/.local/bin/browse "$@"' > /tmp/browse-{persona-slug}.sh && chmod +x /tmp/browse-{persona-slug}.sh
# Then use: /tmp/browse-{persona-slug}.sh goto http://localhost:5173
```

This keeps sessions fully isolated across parallel persona agents.

### Headed Mode Escalation

For visual/CSS/layout failures that headless screenshots can't diagnose, escalate to `/open-gstack-browser` — a steerable Chromium with Claude Code sidebar for live interactive debugging. Use before falling back to Chrome DevTools MCP when the issue is visual, not functional.

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
│              VIRTUAL USER TESTING ORCHESTRATOR (opus)                 │
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
│  │       │         ┌────┴──────────────┴──────────────┘            │   │
│  │       │         │  PEDRO (Company Admin)                        │   │
│  │       │         └──────────────────────┘                        │   │
│  │       │              │                                          │   │
│  │       └──────────────┤                                          │   │
│  │                      ▼                                          │   │
│  │         ┌─────────────────────────┐                             │   │
│  │         │   DB-BACKED BUG REPORTS  │                             │   │
│  │         │ • qa_manager.py issue    │                             │   │
│  │         │ • Duplicate detection    │                             │   │
│  │         │ • Verification results   │                             │   │
│  │         └─────────────────────────┘                             │   │
│  └───────────────────────────────────────────────────────────────┘   │
│         │                                                            │
│         ▼                                                            │
│  Phase 3: Cross-Persona Pattern Detection (from DB query)            │
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

```bash
# Detect browse availability
test -x ~/.local/bin/browse && BROWSE_AVAILABLE=true || BROWSE_AVAILABLE=false

# Detect running services
# Admin app URL (default: http://localhost:5173)
# Client portal URL (default: http://localhost:3000)
# API URL (default: http://localhost:8000)

# Verify services are accessible (using browse if available, MCP fallback)
if [ "$BROWSE_AVAILABLE" = true ]; then
  browse goto http://localhost:5173 && browse text | head -n 20 || true   # admin app
  browse goto http://localhost:3000 && browse text | head -n 20 || true   # client portal
else
  # Fallback: mcp__chrome-devtools__navigate_page
fi

# Check for test credentials or create virtual users via API
```

### Phase 2: Spawn Persona Swarm

Spawn one agent per persona using the `Agent` tool with `model: "haiku"`.

**CRITICAL MODEL RULES:**

- **Persona testers MUST use `model: "haiku"`** - they do navigation, bug reporting, and verification. Haiku is fast, cheap, and sufficient for this.
- **Orchestrator runs on opus** (set in YAML header above) - it handles coordination, report synthesis, and cross-persona analysis.
- **NEVER spawn persona testers with sonnet or opus** - this wastes budget with no benefit.

**Flag handling:**

- `admin-only` → spawn only: maria, carlos, pedro (admin app personas)
- `client-only` → spawn only: renata, joao (client portal personas)
- `persona:{name}` → spawn only the named persona (e.g., `persona:maria`)
- `--verify-only` → skip discovery (STEP 2), only run STEP 4 (verification queue), then complete session

**CRITICAL: Before spawning, pre-compute shared context ONCE in the orchestrator.**

The orchestrator loads open issues once and passes them to all personas (avoids 5 redundant DB queries):

```bash
# PRE-COMPUTE: Load open issues ONCE (shared across all personas)
OPEN_ISSUES=$(python apps/api/scripts/qa_manager.py query open-issues)

# PER-PERSONA: Load persona-specific context
# (run these in parallel for all personas being spawned)
python apps/api/scripts/qa_manager.py query persona-history --persona {slug} --limit 5
python apps/api/scripts/qa_manager.py query regression-check --persona {slug}
```

Then spawn each persona agent with all context pre-loaded:

```
For each persona (spawn all in parallel via Agent tool):
  Agent(
    subagent_type="general-purpose",
    model="haiku",
    description="{persona-name} persona tester",
    prompt="You are {persona name}, a {role description}. {full persona context}.

             ## Browser Automation Setup

             FIRST: Create your browse wrapper for session isolation:

               echo '#!/bin/bash
               BROWSE_STATE_FILE=/tmp/browse-state-{slug}.json exec ~/.local/bin/browse \"$@\"' > /tmp/browse-{slug}.sh && chmod +x /tmp/browse-{slug}.sh

             Then check availability:
               test -x ~/.local/bin/browse && echo 'browse available' || echo 'fallback to MCP'

             Use `/tmp/browse-{slug}.sh` (primary) for all browser interactions.
             Fall back to mcp__chrome-devtools__* only if browse is not available.

             browse commands (via your wrapper):
               /tmp/browse-{slug}.sh goto <url>            — navigate
               /tmp/browse-{slug}.sh snapshot -i           — list interactive elements with @e refs
               /tmp/browse-{slug}.sh snapshot -D           — diff vs previous state
               /tmp/browse-{slug}.sh snapshot -a -o f.png  — annotated screenshot
               /tmp/browse-{slug}.sh screenshot [path]     — plain screenshot
               /tmp/browse-{slug}.sh text                  — page text
               /tmp/browse-{slug}.sh click @e3             — click element
               /tmp/browse-{slug}.sh fill @e4 'value'      — fill input
               /tmp/browse-{slug}.sh console               — console logs (check for JS errors)
               /tmp/browse-{slug}.sh network               — network requests (check for API errors)
               /tmp/browse-{slug}.sh js 'expr'             — evaluate JS

             ## Session Context

             - Session ID: {session_id}
             - QA Manager script: python apps/api/scripts/qa_manager.py

             YOUR HISTORY (from previous sessions):
             {persona_history_output}

             CURRENTLY OPEN ISSUES (do NOT report duplicates):
             {open_issues_output}

             VERIFICATION QUEUE (re-test these fixed bugs):
             {regression_check_output}

             ## STEP 1: Start your persona session

             python apps/api/scripts/qa_manager.py persona-session start \
               --session-id {session_id} --persona {slug}
             SAVE the returned persona_session_id.

             ## STEP 2: Navigate and test workflows

             Navigate to {app URL} and test these workflows: {workflow list}.

             Login workflow (using your browse wrapper):
               /tmp/browse-{slug}.sh goto {app_url}/login
               /tmp/browse-{slug}.sh snapshot -i
               /tmp/browse-{slug}.sh fill @e{email_field} '{email}'
               /tmp/browse-{slug}.sh fill @e{pass_field} '{password}'
               /tmp/browse-{slug}.sh click @e{submit_button}
               /tmp/browse-{slug}.sh snapshot -D       # verify redirect to dashboard
               /tmp/browse-{slug}.sh console            # check for JS errors
               /tmp/browse-{slug}.sh network            # check for failed API calls

             For each page/action, evaluate:
             1. FUNCTIONALITY — Does it work? Any errors? Console errors?
                (browse console after every interaction)
             2. UX/USABILITY — Is it intuitive? Confusing? Too many clicks?
                (count clicks for core tasks)
             3. PERFORMANCE — Is it fast? Any loading delays?
                (note slow network calls from browse network)
             4. PERMISSIONS — Can you access only what your role allows?
             5. DATA ACCURACY — Do numbers/dates/statuses look correct?
                (browse text to extract displayed values)
             6. MOBILE/RESPONSIVE — Does it work on smaller screens?

             ## STEP 3: Report bugs

             For each bug found:
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

             ## STEP 4: Verify fixed bugs from your queue

             For each issue in the verification queue:
             a) Follow the reproduction steps using browse
             b) Run: browse console and browse network to capture evidence
             c) Record the result:
                python apps/api/scripts/qa_manager.py issue verify \
                  --id {issue_id} \
                  --persona {slug} \
                  --passed {true|false} \
                  --session-id {session_id} \
                  --notes 'Description of verification result'

             ## STEP 5: Complete your persona session

             Satisfaction score guide:
               1-3: Core workflows broken or impossible
               4-5: Works but significant friction / confusion
               6-7: Mostly smooth, minor issues
               8-9: Polished, intuitive
               10: No issues found

             python apps/api/scripts/qa_manager.py persona-session complete \
               --id {persona_session_id} \
               --satisfaction {1-10 score per rubric above} \
               --pages '[\"page1\",\"page2\"]' \
               --workflows '[\"workflow1\",\"workflow2\"]'

             Write your feedback AS THE PERSONA — in first person, with their
             level of technical sophistication and their specific frustrations.

             IMPORTANT: ALL bugs go to the database via qa_manager.py.
             Do NOT write bugs to markdown files or MCP memory."
  )
```

**CRITICAL: All persona testers MUST use `model: "haiku"` to minimize cost.**

**Timeout:** If any persona agent does not complete within 10 minutes, the orchestrator should proceed to report generation and mark that persona as `status: timed-out` in the completion signal.

The orchestrator (opus) manages coordination, synthesis, and report generation.

### Phase 3: Cross-Persona Pattern Detection

**Note:** Verification of fixed bugs happens inside each persona's Phase 2 (STEP 4), not as a separate sequential phase. Phase 3 runs after all persona agents complete.

After all persona agents finish (or time out), the orchestrator queries the DB to detect cross-persona patterns:

```bash
# Query all issues from this session, grouped by endpoint/page
python apps/api/scripts/qa_manager.py query cross-persona --session-id {session_id}
```

The orchestrator analyzes the results for these patterns:

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
/virtual-user-testing --verify-only            # Only verify fixed bugs, skip discovery (see also /qa-verify)
```

**Flag behavior:**

- `admin-only` → spawns only maria, carlos, pedro (admin app personas)
- `client-only` → spawns only renata, joao (client portal personas)
- `persona:{name}` → spawns only the named persona
- `--verify-only` → skips Phase 0 session creation and Phase 2 discovery; loads only the verification queue per persona, runs STEP 4 (verify fixed bugs), then completes. For pure verification runs, prefer `/qa-verify` which is purpose-built for this.

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

**Current Version:** 2.2.0
**Last Updated:** April 2026

### Changelog

- **2.2.0**: Fixes from comprehensive review
  - Orchestrator model upgraded from sonnet to opus (matches model-tier-strategy)
  - Spawn syntax changed from `Task({...})` pseudocode to `Agent(...)` invocation form
  - `BROWSE_STATE_FILE` env var fix: wrapper script pattern replaces broken `export`
  - Pre-compute open-issues once in orchestrator, pass to all personas (saves 4 redundant DB queries)
  - Added flag implementation: `admin-only`, `client-only`, `persona:{name}`, `--verify-only`
  - Added satisfaction score calibration rubric (1-10 guide) in persona spawn prompt
  - Added 10-minute timeout for stuck persona agents
  - Phase 3 clarified: cross-persona detection runs post-swarm via DB query, not in real-time
  - Verification happens inside Phase 2 (STEP 4), not as separate phase
  - Fixed Phase 1 pipe SIGPIPE issue (`head -n 20 || true`)
  - Fixed ASCII architecture diagram broken box
  - Removed unused `mcp__playwright__*`, `mcp__browserless__*`, `mcp__memory__*` from allowed-tools
  - `browse` CLI is now clearly primary in Requirements; Chrome DevTools MCP is subordinate fallback
- **2.1.0**: browse CLI integration as primary browser tool
  - Added Browser Automation section (primary/fallback detection, command reference, per-persona isolation)
  - Per-persona `BROWSE_STATE_FILE` isolation for parallel Chromium instances
  - Persona spawn prompts updated to use browse for navigation, snapshots, clicks, fill, console, network
  - Phase 1 environment discovery updated to use browse with MCP fallback
  - Requirements updated to list browse as primary dependency
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

- **`browse` CLI** at `~/.local/bin/browse` — **PRIMARY** browser tool (zero MCP overhead, per-persona isolation via `BROWSE_STATE_FILE` wrapper)
  - Fallback: Chrome DevTools MCP (`mcp__chrome-devtools__*`) — used only when `browse` is not installed
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
