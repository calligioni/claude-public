---
name: health-report
description: "Generate a comprehensive health report proving SourceRank AI is fully functional. Chains API testing, E2E browser verification, unit tests, and Lighthouse audits into a single HTML/PDF deliverable with evidence. Triggers on: health report, site health, functional report, prove it works, health-report."
argument-hint: "[--skip-qa] [--skip-lighthouse] [--pdf-only] [--url URL]"
user-invocable: true
context: fork
model: opus
allowed-tools:
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - AskUserQuestion
  - mcp__browserless__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: true }
  Write: { destructiveHint: false, idempotentHint: true }
  mcp__browserless__*: { openWorldHint: true }
  mcp__browserless__initialize_browserless: { idempotentHint: true }
  mcp__browserless__generate_pdf: { readOnlyHint: true }
  mcp__browserless__take_screenshot: { readOnlyHint: true }
  mcp__browserless__run_performance_audit: { readOnlyHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    outputFormat: structured
---

# Health Report Skill — SourceRank AI

Generate a comprehensive, evidence-backed health report proving SourceRank AI is fully functional. Produces a shareable HTML file (with optional PDF export) containing API coverage, browser verification, unit test results, and Lighthouse scores.

## What It Does

When you run `/health-report`, it:

1. **Collects evidence** from 4 layers in parallel
2. **Queries the QA database** for the latest session results
3. **Assembles** everything into a single self-contained HTML report
4. **Exports to PDF** via Browserless

## Arguments

```
/health-report                  # Full report (all layers)
/health-report --skip-qa        # Skip QA DB query (if no recent session)
/health-report --skip-lighthouse # Skip Lighthouse (faster)
/health-report --pdf-only       # Only generate PDF from existing HTML
/health-report --url URL        # Override target URL
```

## Configuration

```bash
# SourceRank production URLs
WEB_URL="https://sourcerank-web.onrender.com"
API_URL="https://sourcerank-api.onrender.com"

# QA Database
export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

# Report output
REPORT_DIR="/Volumes/AI/Code/Sourcerankai/reports"
```

## Execution Plan

### Phase 1: Setup

1. Parse arguments (--skip-qa, --skip-lighthouse, --pdf-only, --url)
2. Set URLs (default: production)
3. Create report output directory: `$REPORT_DIR/`
4. Set timestamp: `REPORT_DATE=$(date +%Y-%m-%d)`
5. Create report data file: `$REPORT_DIR/data-$REPORT_DATE.json`

### Phase 2: Evidence Collection (parallel subagents)

Spawn 4 evidence collectors simultaneously. Each writes its results to a JSON file.

#### Collector 1: API Health (model: haiku)

Test every known API endpoint and record HTTP status codes.

```bash
API_URL="https://sourcerank-api.onrender.com"
# Test credentials
ADMIN_EMAIL="qa-admin@sourcerank.ai"
ADMIN_PASS="QATest2026sr"

# 1. Health endpoint
curl -s -o /dev/null -w "%{http_code}" "$API_URL/health"

# 2. Authenticate
TOKEN=$(curl -s "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASS\"}" | jq -r '.token // .accessToken // .data.token // .data.accessToken // empty')

# If direct login doesn't work, use Supabase Auth:
# TOKEN=$(curl -s "https://swpznmoctbtnmspmyrfu.supabase.co/auth/v1/token?grant_type=password" \
#   -H "apikey: $SUPABASE_ANON_KEY" \
#   -H "Content-Type: application/json" \
#   -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASS\"}" | jq -r '.access_token')

# 3. Test each endpoint group with the token
# Record: endpoint, method, http_status, response_time_ms
```

**Endpoints to test (28+):**

| Group           | Endpoints                                                                                      |
| --------------- | ---------------------------------------------------------------------------------------------- |
| Health          | `GET /health`                                                                                  |
| Users           | `GET /api/v1/users/me`                                                                         |
| Organizations   | `GET /api/v1/organizations/current`                                                            |
| Brands          | `GET /api/v1/brands`, `GET /api/v1/brands/:id`                                                 |
| Monitoring      | `GET /api/v1/brands/:id/mentions`, `GET /api/v1/monitoring/hallucinations`                     |
| Content         | `GET /api/v1/brands/:id/content`                                                               |
| Competitors     | `GET /api/v1/brands/:id/competitors`                                                           |
| Authority       | `GET /api/v1/brands/:id/authority`                                                             |
| Competitive     | `GET /api/v1/brands/:id/competitive/share-of-voice`                                            |
| Intelligence    | `GET /api/v1/brands/:id/topics`, `GET /api/v1/brands/:id/gaps`                                 |
| Analytics       | `GET /api/v1/analytics/:id/overview`, `/trends`, `/attribution`, `/predictions`, `/benchmarks` |
| Recommendations | `GET /api/v1/brands/:id/recommendations`                                                       |
| Readiness       | `GET /api/v1/brands/:id/readiness/latest`                                                      |
| Site Audit      | `GET /api/v1/brands/:id/site-audits`                                                           |
| Backlog         | `GET /api/v1/brands/:id/backlog`                                                               |
| Visibility      | `GET /api/v1/visibility/objectives`                                                            |
| Alerts          | `GET /api/v1/alerts`                                                                           |
| Billing         | `GET /api/v1/billing/plans`                                                                    |
| Agency          | `GET /api/v1/agency/status`, `/portfolio`, `/margins`, `/clients`                              |
| White Label     | `GET /api/v1/white-label/config`                                                               |
| Platform        | `GET /api/v1/platform/api-keys`, `/webhooks`                                                   |
| Holdings        | `GET /api/v1/holdings`                                                                         |
| Stream          | `GET /api/v1/stream/health`                                                                    |
| Providers       | `GET /api/v1/providers`                                                                        |

**Output:** Write results to `$REPORT_DIR/api-health.json`:

```json
{
  "timestamp": "2026-03-17T...",
  "total_endpoints": 28,
  "passed": 28,
  "failed": 0,
  "endpoints": [
    { "method": "GET", "path": "/health", "status": 200, "time_ms": 45 },
    ...
  ]
}
```

#### Collector 2: Browser Verification (model: haiku)

Use `browse` CLI to verify key pages render correctly and have no console errors.

```bash
export BROWSE_STATE_FILE="/tmp/browse-state-health-report.json"

# Pages to verify (public + authenticated)
PAGES=(
  "/"
  "/about"
  "/solutions"
  "/sign-in"
  "/sign-up"
  "/dashboard"
  "/dashboard/brands"
  "/dashboard/competitive"
  "/dashboard/alerts"
  "/dashboard/recommendations"
  "/dashboard/reports"
  "/dashboard/agency"
  "/dashboard/settings"
  "/dashboard/analytics"
  "/dashboard/visibility"
  "/dashboard/readiness"
  "/dashboard/site-audit"
)

# For each page:
# 1. browse goto $WEB_URL$page
# 2. browse console (check for errors)
# 3. browse text (verify page rendered, not blank)
# 4. browse screenshot $REPORT_DIR/screenshots/page-name.png
```

**Output:** Write to `$REPORT_DIR/browser-check.json`:

```json
{
  "timestamp": "...",
  "total_pages": 18,
  "passed": 18,
  "failed": 0,
  "pages": [
    { "path": "/", "title": "SourceRank AI", "console_errors": 0, "rendered": true, "screenshot": "screenshots/landing.png" },
    ...
  ]
}
```

#### Collector 3: Unit & Integration Tests (model: haiku)

Run the project's test suite and capture results.

```bash
cd /Volumes/AI/Code/Sourcerankai

# API tests (Vitest)
pnpm --filter @sourcerank/api test 2>&1 | tee $REPORT_DIR/test-output-api.txt

# Parse results: Tests X passed, Y failed, Z total
# Extract from vitest output
```

**Output:** Write to `$REPORT_DIR/test-results.json`:

```json
{
  "timestamp": "...",
  "suites": {
    "api": {
      "total": 42,
      "passed": 42,
      "failed": 0,
      "skipped": 0,
      "duration_s": 12.3
    }
  },
  "typescript": { "errors": 0 }
}
```

#### Collector 4: Lighthouse Audit (model: haiku)

Run Lighthouse via Browserless MCP on key pages.

```
mcp__browserless__initialize_browserless(...)
mcp__browserless__run_performance_audit({
  url: "https://sourcerank-web.onrender.com",
  categories: ["performance", "accessibility", "seo", "best-practices"]
})
```

**Pages to audit:** `/` (landing), `/sign-in`, `/dashboard` (if accessible)

**Output:** Write to `$REPORT_DIR/lighthouse.json`:

```json
{
  "timestamp": "...",
  "audits": [
    {
      "url": "/",
      "performance": 85,
      "accessibility": 92,
      "seo": 95,
      "best_practices": 88
    }
  ]
}
```

### Phase 3: QA Database Query

Unless `--skip-qa`, query the latest QA session from Supabase:

```bash
export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

# Latest session
SESSION_ID=$(psql "$SRDB" -t -A -c "
  SELECT id FROM qa_sessions
  ORDER BY started_at DESC LIMIT 1
")

# Coverage summary
psql "$SRDB" -t -A -c "
  SELECT json_build_object(
    'session_id', '$SESSION_ID',
    'total_features', (SELECT COUNT(*) FROM qa_feature_coverage WHERE session_id = '$SESSION_ID'),
    'approved', (SELECT COUNT(*) FROM qa_feature_coverage WHERE session_id = '$SESSION_ID' AND status = 'approved'),
    'blocked', (SELECT COUNT(*) FROM qa_feature_coverage WHERE session_id = '$SESSION_ID' AND status = 'blocked'),
    'untested', (SELECT COUNT(*) FROM qa_feature_coverage WHERE session_id = '$SESSION_ID' AND status = 'untested'),
    'open_issues', (SELECT COUNT(*) FROM qa_issues WHERE session_id = '$SESSION_ID' AND status = 'open'),
    'fixed_issues', (SELECT COUNT(*) FROM qa_issues WHERE session_id = '$SESSION_ID' AND status IN ('fixed', 'verified')),
    'persona_scores', (
      SELECT json_agg(json_build_object('persona', persona, 'satisfaction', satisfaction))
      FROM qa_persona_sessions WHERE session_id = '$SESSION_ID'
    )
  )
"

# Issue history trend (last 5 sessions)
psql "$SRDB" -t -A -c "
  SELECT json_agg(t) FROM (
    SELECT
      s.id,
      s.started_at::date as date,
      COUNT(i.id) FILTER (WHERE i.severity = 'p0-critical') as p0,
      COUNT(i.id) FILTER (WHERE i.severity = 'p1-high') as p1,
      COUNT(i.id) FILTER (WHERE i.severity = 'p2-medium') as p2,
      COUNT(i.id) as total_issues,
      (SELECT COUNT(*) FROM qa_feature_coverage fc
       WHERE fc.session_id = s.id AND fc.status = 'approved') as approved_features
    FROM qa_sessions s
    LEFT JOIN qa_issues i ON i.session_id = s.id
    GROUP BY s.id, s.started_at
    ORDER BY s.started_at DESC
    LIMIT 5
  ) t
"
```

Write to `$REPORT_DIR/qa-summary.json`.

### Phase 4: Report Assembly

After all collectors complete, assemble the HTML report. The report MUST be a single self-contained HTML file with inline CSS (no external dependencies).

**Write the file to:** `$REPORT_DIR/sourcerank-health-report-$REPORT_DATE.html`

#### HTML Report Structure

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>SourceRank AI — Health Report — {DATE}</title>
    <style>
      /* Professional report styling — dark header, clean tables, status badges */
      /* All CSS inline — no external dependencies */
    </style>
  </head>
  <body>
    <header>
      <h1>SourceRank AI — Platform Health Report</h1>
      <p class="date">{DATE}</p>
      <div class="executive-summary">
        <div class="metric">
          <span class="value">{API_PASS}/{API_TOTAL}</span>
          <span class="label">API Endpoints</span>
        </div>
        <div class="metric">
          <span class="value">{PAGES_PASS}/{PAGES_TOTAL}</span>
          <span class="label">Pages Verified</span>
        </div>
        <div class="metric">
          <span class="value">{TESTS_PASS}/{TESTS_TOTAL}</span>
          <span class="label">Unit Tests</span>
        </div>
        <div class="metric">
          <span class="value">{LIGHTHOUSE_AVG}</span>
          <span class="label">Lighthouse Avg</span>
        </div>
        <div class="metric">
          <span class="value">{QA_APPROVED}/{QA_TOTAL}</span>
          <span class="label">QA Features</span>
        </div>
      </div>
    </header>

    <section id="verdict">
      <!-- FULLY FUNCTIONAL / ISSUES FOUND — based on pass rates -->
      <h2>Verdict: {FULLY_FUNCTIONAL | ISSUES_FOUND}</h2>
      <p>{Summary sentence}</p>
    </section>

    <section id="api-health">
      <h2>1. API Endpoint Coverage</h2>
      <table>
        <tr>
          <th>Method</th>
          <th>Endpoint</th>
          <th>Status</th>
          <th>Time</th>
        </tr>
        <!-- One row per endpoint -->
      </table>
    </section>

    <section id="browser">
      <h2>2. Browser Verification</h2>
      <p>
        Each page verified for: successful render, no console errors, correct
        title.
      </p>
      <table>
        <tr>
          <th>Page</th>
          <th>Title</th>
          <th>Console Errors</th>
          <th>Status</th>
        </tr>
        <!-- One row per page -->
      </table>
    </section>

    <section id="tests">
      <h2>3. Test Suite Results</h2>
      <table>
        <tr>
          <th>Suite</th>
          <th>Passed</th>
          <th>Failed</th>
          <th>Skipped</th>
          <th>Duration</th>
        </tr>
      </table>
      <p>TypeScript compilation: {PASS/FAIL} ({error_count} errors)</p>
    </section>

    <section id="lighthouse">
      <h2>4. Lighthouse Scores</h2>
      <table>
        <tr>
          <th>Page</th>
          <th>Performance</th>
          <th>Accessibility</th>
          <th>SEO</th>
          <th>Best Practices</th>
        </tr>
      </table>
    </section>

    <section id="qa">
      <h2>5. QA Coverage (Latest Session)</h2>
      <p>Session: {SESSION_ID} | Date: {SESSION_DATE}</p>
      <div class="coverage-bar">
        <!-- Visual bar showing approved/blocked/untested -->
      </div>
      <h3>Persona Satisfaction</h3>
      <table>
        <tr>
          <th>Persona</th>
          <th>Role</th>
          <th>Score</th>
        </tr>
      </table>
      <h3>Issue Trend (Last 5 Sessions)</h3>
      <table>
        <tr>
          <th>Date</th>
          <th>P0</th>
          <th>P1</th>
          <th>P2</th>
          <th>Total</th>
          <th>Approved Features</th>
        </tr>
      </table>
    </section>

    <footer>
      <p>Generated by SourceRank Health Report v1.0 | {TIMESTAMP}</p>
      <p>This report is auto-generated from live production data.</p>
    </footer>
  </body>
</html>
```

#### Verdict Logic

```
IF api_pass_rate == 100% AND pages_pass_rate == 100% AND test_fail_count == 0 AND qa_blocked == 0:
  verdict = "FULLY FUNCTIONAL"
  color = green
ELIF api_pass_rate >= 95% AND test_fail_count <= 2 AND qa_blocked <= 2:
  verdict = "OPERATIONAL — Minor Issues"
  color = yellow
ELSE:
  verdict = "ISSUES FOUND"
  color = red
```

#### Styling Guidelines

- Professional, clean design suitable for stakeholder sharing
- Dark navy header with white text
- Status badges: green (pass), red (fail), yellow (warning)
- Coverage bar: green (approved), red (blocked), gray (untested)
- Responsive layout (readable on mobile)
- Lighthouse scores color-coded: green >= 90, yellow >= 50, red < 50
- Monospace font for endpoints and technical data
- Total page count and timestamp in footer

### Phase 5: PDF Export

Use Browserless to convert the HTML report to PDF:

```
mcp__browserless__initialize_browserless(...)
mcp__browserless__generate_pdf({
  html: "<full HTML content from the report file>",
  options: {
    format: "A4",
    printBackground: true,
    margin: { top: "10mm", bottom: "10mm", left: "10mm", right: "10mm" }
  }
})
```

Save as: `$REPORT_DIR/sourcerank-health-report-$REPORT_DATE.pdf`

### Phase 6: Summary

Output to the user:

- Verdict (FULLY FUNCTIONAL / ISSUES FOUND)
- Key metrics (API pass rate, test count, Lighthouse avg, QA coverage)
- File paths to HTML and PDF reports
- Any failures or issues detected

## Subagent Strategy

| Collector            | Model               | Why                                   |
| -------------------- | ------------------- | ------------------------------------- |
| API Health           | haiku               | Pure curl execution, no judgment      |
| Browser Verification | haiku               | Navigate + check console — mechanical |
| Unit Tests           | haiku               | Run pnpm test, parse output           |
| Lighthouse           | haiku               | Call Browserless MCP, record scores   |
| Report Assembly      | orchestrator (opus) | Synthesizes all data, writes HTML     |
| PDF Export           | orchestrator (opus) | Single MCP call                       |

## Important Notes

1. **All 4 collectors run in parallel** — spawn them as simultaneous Agent calls
2. **The HTML must be self-contained** — inline all CSS, no external assets
3. **Screenshots are optional** — they make the report larger but more convincing. Include if time permits.
4. **QA data comes from Supabase** — NOT from the mcp**postgres**query tool (that connects to a different DB)
5. **Auth for API testing** — use Supabase Auth to get JWT tokens, then pass as Bearer header
6. **Lighthouse may be slow** on Render cold-start — allow up to 60s timeout
7. **If --skip-qa is passed**, omit Section 5 entirely
8. **If --skip-lighthouse is passed**, omit Section 4 entirely
9. **Report files go in** `/Volumes/AI/Code/Sourcerankai/reports/` — create the directory if it doesn't exist
10. **Never commit reports** to git — they contain timestamps and are ephemeral artifacts
