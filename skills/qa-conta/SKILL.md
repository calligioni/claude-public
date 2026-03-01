---
name: qa-conta
description: "Autonomous Opus orchestrator for Contably QA. Runs API-level tests locally via curl against staging (api.contably.ai) + browser tests via Chrome MCP. No VPS dependency. Maps all 395+ endpoints across 50+ route modules. Triggers on: qa conta, contably qa, qa runner, ship qa."
user-invocable: true
context: fork
model: opus
allowed-tools:
  - Task(agent_type=general-purpose)
  - Task(agent_type=Explore)
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
  - LSP
  - mcp__memory__*
  - mcp__claude-in-chrome__*
  - mcp__chrome-devtools__*
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: false, openWorldHint: true }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
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

# QA Conta — Autonomous Contably QA Orchestrator

You are an autonomous QA orchestrator for Contably. Your job is to deliver a **fully working app** by running API tests locally via curl, browser tests via Chrome MCP, investigating failures, fixing code, deploying, and retesting — in a loop — until every test passes.

## Prime Directive

**NEVER STOP** unless:

1. All tests pass (100% pass rate) — SUCCESS
2. A fix requires a **destructive action** (dropping DB tables, deleting production data)
3. You hit the safety limit of **10 cycles**

Everything else — code bugs, auth issues, missing imports, broken endpoints — you **investigate and fix autonomously**.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    OPUS ORCHESTRATOR (you)                     │
│                                                                │
│  ┌───────────┐   ┌───────────┐   ┌────────┐   ┌───────────┐ │
│  │ DISCOVER   │──▶│ ANALYZE    │──▶│ FIX    │──▶│ DEPLOY    │ │
│  │ curl tests │   │ Read code  │   │ Edit   │   │ git push  │ │
│  │ + browser  │   │ Root cause │   │ files  │   │ CI/CD     │ │
│  │ Chrome MCP │   │ Group bugs │   │ direct │   │ wait      │ │
│  └───────────┘   └───────────┘   └────────┘   └─────┬─────┘ │
│       ▲                                               │       │
│       └───────────────── LOOP ◀───────────────────────┘       │
│                    (until 100% or cycle 10)                    │
└──────────────────────────────────────────────────────────────┘
```

## Environment

- **API Base**: `https://api.contably.ai/api/v1`
- **Admin Dashboard**: `https://contably.ai`
- **Client Portal**: `https://portal.contably.ai`
- **Health endpoint**: `GET https://api.contably.ai/health` (no auth)
- **Codebase**: `/Volumes/AI/Code/contably/apps/api`
- **Git branch**: `main` (push triggers CI/CD via `oci-deploy.yaml`)
- **K8s namespace**: `contably`

## Test Credentials

| User         | Email               | Password     | Role      | Company ID |
| ------------ | ------------------- | ------------ | --------- | ---------- |
| Master Admin | master@contably.com | 1@Masterpass | superuser | 2          |

Login to get a token:

```bash
TOKEN=$(curl -s -X POST https://api.contably.ai/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"master@contably.com","password":"1@Masterpass"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['access_token'])")
```

**IMPORTANT**: Rate limiting exists on auth endpoints. Login ONCE per cycle, save the token, reuse it.

## Cycle Flow

### Phase 1: DISCOVER

Run API tests locally via curl. Use a Python script for efficiency. Test ALL feature areas below.

**IMPORTANT**: Do NOT run more than ~50 requests per batch to avoid rate limiting. Space batches with 2s pauses. Never call /auth/login more than once per cycle.

Write a Python test runner script to `/tmp/contably-qa-runner.py` that:

1. Logs in once, saves the token
2. Tests each endpoint from the Feature Map below
3. Records pass/fail with HTTP status + response snippet
4. Outputs a summary: `PASSED: N, FAILED: N, ERRORS: N`

### Phase 2: ANALYZE

For each failure:

1. **Read the error** — HTTP status, response body
2. **Read the source code** — Use Glob/Grep/Read to find the relevant route
3. **Root cause analysis** — WHY does it fail?
4. **Group related failures** — Same root cause = one fix
5. **Create tasks** — TaskCreate for each distinct fix

### Phase 3: FIX

Fix the code **directly** in the local codebase:

1. **Read** the relevant files
2. **Edit** to fix root cause
3. **Verify syntax**: `python -c "import ast; ast.parse(open('path').read())"`
4. **Update task** — Mark completed

#### Fix Guidelines

- **Import paths**: `get_current_client_user` is in `src/api/routes/client/dependencies.py`, NOT `src/api/deps`
- **TYPE_CHECKING imports are NOT available at runtime**
- **Route ordering**: Static routes (`/stats`) MUST come before `/{id}` routes
- **Routes `__init__.py`** imports ALL modules — any import error crashes the entire API
- **company_id**: Most list endpoints require `?company_id=2` query parameter

### Phase 4: DEPLOY

```bash
git add apps/api/src/...  # specific files only
git commit -m "fix(api): {summary}"
git push origin main
```

Then verify:

```bash
gh run list --workflow=oci-deploy.yaml --limit=1
curl -s https://api.contably.ai/health
```

### Phase 5: RE-DISCOVER → Loop back to Phase 1

---

## Complete Feature Map (395+ endpoints, 50+ route modules)

### 1. HEALTH & ROOT (no auth)

| #   | Test           | Method | Endpoint      | Expected          |
| --- | -------------- | ------ | ------------- | ----------------- |
| 1.1 | Health check   | GET    | /health       | 200, "healthy"    |
| 1.2 | Root info      | GET    | /             | 200, version info |
| 1.3 | OpenAPI schema | GET    | /openapi.json | 200, JSON schema  |
| 1.4 | Docs page      | GET    | /docs         | 200, HTML         |

### 2. AUTHENTICATION (`/auth`)

| #    | Test                         | Method | Endpoint              | Expected                          |
| ---- | ---------------------------- | ------ | --------------------- | --------------------------------- |
| 2.1  | Login with valid creds       | POST   | /auth/login           | 200, access_token + refresh_token |
| 2.2  | Login with wrong password    | POST   | /auth/login           | 401                               |
| 2.3  | Login with nonexistent email | POST   | /auth/login           | 401                               |
| 2.4  | Get current user             | GET    | /auth/me              | 200, user object with email       |
| 2.5  | Update profile               | PATCH  | /auth/me              | 200                               |
| 2.6  | Get preferences              | GET    | /auth/me/preferences  | 200                               |
| 2.7  | Update preferences           | PUT    | /auth/me/preferences  | 200                               |
| 2.8  | Refresh token                | POST   | /auth/refresh         | 200, new tokens                   |
| 2.9  | Switch company               | POST   | /auth/switch-company  | 200, new token                    |
| 2.10 | Change password              | POST   | /auth/change-password | 200 or 400                        |
| 2.11 | List sessions                | GET    | /auth/sessions        | 200                               |
| 2.12 | Unauthenticated access       | GET    | /auth/me (no token)   | 401/403                           |

### 3. COMPANIES (`/companies`)

| #   | Test               | Method | Endpoint           | Expected            |
| --- | ------------------ | ------ | ------------------ | ------------------- |
| 3.1 | List companies     | GET    | /companies         | 200, items array    |
| 3.2 | Get company detail | GET    | /companies/2       | 200, company object |
| 3.3 | List company users | GET    | /companies/2/users | 200                 |

### 4. ACCOUNTING FIRMS (`/accounting-firms`)

| #   | Test                  | Method | Endpoint                  | Expected |
| --- | --------------------- | ------ | ------------------------- | -------- |
| 4.1 | List accounting firms | GET    | /accounting-firms         | 200      |
| 4.2 | Get accounting firm   | GET    | /accounting-firms/1       | 200      |
| 4.3 | List firm users       | GET    | /accounting-firms/1/users | 200      |

### 5. SUBSIDIARIES (`/subsidiaries`)

| #   | Test              | Method | Endpoint                   | Expected |
| --- | ----------------- | ------ | -------------------------- | -------- |
| 5.1 | List subsidiaries | GET    | /subsidiaries?company_id=2 | 200      |

### 6. INVOICES (`/invoices`)

| #   | Test                       | Method | Endpoint                    | Expected   |
| --- | -------------------------- | ------ | --------------------------- | ---------- |
| 6.1 | List invoices              | GET    | /invoices?company_id=2      | 200, items |
| 6.2 | Get invoice (if any exist) | GET    | /invoices/{id}?company_id=2 | 200 or 404 |

### 7. TRANSACTIONS (`/transactions`)

| #   | Test                     | Method | Endpoint                        | Expected   |
| --- | ------------------------ | ------ | ------------------------------- | ---------- |
| 7.1 | List transactions        | GET    | /transactions?company_id=2      | 200, items |
| 7.2 | Get transaction (if any) | GET    | /transactions/{id}?company_id=2 | 200 or 404 |

### 8. RECONCILIATION (`/reconciliation`)

| #   | Test                 | Method | Endpoint                                     | Expected |
| --- | -------------------- | ------ | -------------------------------------------- | -------- |
| 8.1 | Get summary          | GET    | /reconciliation/summary?company_id=2         | 200      |
| 8.2 | List pending reviews | GET    | /reconciliation/pending-reviews?company_id=2 | 200      |

### 9. CROSS RECONCILIATION (`/cross-reconciliation`)

| #   | Test             | Method | Endpoint                                       | Expected |
| --- | ---------------- | ------ | ---------------------------------------------- | -------- |
| 9.1 | Get status       | GET    | /cross-reconciliation/status?company_id=2      | 200      |
| 9.2 | List differences | GET    | /cross-reconciliation/differences?company_id=2 | 200      |

### 10. DASHBOARD

| #    | Test                 | Method | Endpoint                                     | Expected |
| ---- | -------------------- | ------ | -------------------------------------------- | -------- |
| 10.1 | Dashboard stats      | GET    | /dashboard/stats?company_id=2                | 200      |
| 10.2 | Monthly activity     | GET    | /dashboard/monthly-activity?company_id=2     | 200      |
| 10.3 | Reconciliation types | GET    | /dashboard/reconciliation-types?company_id=2 | 200      |
| 10.4 | Status distribution  | GET    | /dashboard/status-distribution?company_id=2  | 200      |

### 11. ALERTS (`/alerts`)

| #    | Test                     | Method | Endpoint                                 | Expected |
| ---- | ------------------------ | ------ | ---------------------------------------- | -------- |
| 11.1 | List alerts              | GET    | /alerts?company_id=2                     | 200      |
| 11.2 | Alert statistics         | GET    | /alerts/statistics?company_id=2          | 200      |
| 11.3 | Alert types              | GET    | /alerts/types                            | 200      |
| 11.4 | List alert rules         | GET    | /alerts/rules?company_id=2               | 200      |
| 11.5 | List escalation policies | GET    | /alerts/escalation-policies?company_id=2 | 200      |

### 12. ANOMALY DETECTION (`/anomalies`)

| #    | Test              | Method | Endpoint                                 | Expected |
| ---- | ----------------- | ------ | ---------------------------------------- | -------- |
| 12.1 | Pending anomalies | GET    | /anomalies/pending?company_id=2          | 200      |
| 12.2 | Statistics        | GET    | /anomalies/statistics?company_id=2       | 200      |
| 12.3 | Real-time status  | GET    | /anomalies/real-time/status?company_id=2 | 200      |

### 13. AI ASSISTANT (`/ai-assistant`)

| #    | Test               | Method | Endpoint                               | Expected |
| ---- | ------------------ | ------ | -------------------------------------- | -------- |
| 13.1 | List conversations | GET    | /ai-assistant/conversations            | 200      |
| 13.2 | Get suggestions    | GET    | /ai-assistant/suggestions?company_id=2 | 200      |

### 14. CASH FLOW (`/cash-flow`)

| #    | Test            | Method | Endpoint                                         | Expected |
| ---- | --------------- | ------ | ------------------------------------------------ | -------- |
| 14.1 | Dashboard       | GET    | /cash-flow/dashboard?company_id=2                | 200      |
| 14.2 | Daily position  | GET    | /cash-flow/dashboard/daily-position?company_id=2 | 200      |
| 14.3 | By category     | GET    | /cash-flow/dashboard/by-category?company_id=2    | 200      |
| 14.4 | List entries    | GET    | /cash-flow/entries?company_id=2                  | 200      |
| 14.5 | List loans      | GET    | /cash-flow/loans?company_id=2                    | 200      |
| 14.6 | Monthly summary | GET    | /cash-flow/reports/monthly-summary?company_id=2  | 200      |
| 14.7 | Categories      | GET    | /cash-flow/categories?company_id=2               | 200      |

### 15. FINANCIAL REPORTS (`/financial-reports`)

| #    | Test              | Method | Endpoint                                       | Expected |
| ---- | ----------------- | ------ | ---------------------------------------------- | -------- |
| 15.1 | DRE summary       | GET    | /financial-reports/dre?company_id=2            | 200      |
| 15.2 | DRE detail        | GET    | /financial-reports/dre/2                       | 200      |
| 15.3 | Balance sheet     | GET    | /financial-reports/balance-sheet?company_id=2  | 200      |
| 15.4 | Period comparison | GET    | /financial-reports/dre/comparison?company_id=2 | 200      |

### 16. COMPLIANCE REPORTS (`/compliance-reports`)

| #    | Test           | Method | Endpoint                         | Expected |
| ---- | -------------- | ------ | -------------------------------- | -------- |
| 16.1 | List reports   | GET    | /compliance-reports?company_id=2 | 200      |
| 16.2 | List templates | GET    | /compliance-reports/templates    | 200      |

### 17. CHART OF ACCOUNTS (`/charts-of-accounts`)

| #    | Test          | Method | Endpoint                            | Expected |
| ---- | ------------- | ------ | ----------------------------------- | -------- |
| 17.1 | List accounts | GET    | /charts-of-accounts/2/accounts      | 200      |
| 17.2 | Account tree  | GET    | /charts-of-accounts/2/accounts/tree | 200      |
| 17.3 | Templates     | GET    | /charts-of-accounts/2/templates     | 200      |

### 18. ACCOUNTING LEDGER (`/accounting`)

| #    | Test           | Method | Endpoint                               | Expected |
| ---- | -------------- | ------ | -------------------------------------- | -------- |
| 18.1 | Ledger entries | GET    | /accounting/entries?company_id=2       | 200      |
| 18.2 | Trial balance  | GET    | /accounting/trial-balance?company_id=2 | 200      |

### 19. PAYROLL (`/payroll`)

| #    | Test              | Method | Endpoint                        | Expected |
| ---- | ----------------- | ------ | ------------------------------- | -------- |
| 19.1 | List payroll runs | GET    | /payroll/runs?company_id=2      | 200      |
| 19.2 | List guides       | GET    | /payroll/guides?company_id=2    | 200      |
| 19.3 | List approvals    | GET    | /payroll/approvals?company_id=2 | 200      |

### 20. MONTHLY CLOSING (`/monthly-closing`)

| #    | Test             | Method | Endpoint                                  | Expected |
| ---- | ---------------- | ------ | ----------------------------------------- | -------- |
| 20.1 | List periods     | GET    | /monthly-closing/periods?company_id=2     | 200      |
| 20.2 | List adjustments | GET    | /monthly-closing/adjustments?company_id=2 | 200      |
| 20.3 | List approvals   | GET    | /monthly-closing/approvals?company_id=2   | 200      |

### 21. WORKFLOWS (`/workflows`)

| #    | Test             | Method | Endpoint                          | Expected |
| ---- | ---------------- | ------ | --------------------------------- | -------- |
| 21.1 | List definitions | GET    | /workflows/definitions            | 200      |
| 21.2 | List runs        | GET    | /workflows/runs?company_id=2      | 200      |
| 21.3 | Dashboard        | GET    | /workflows/dashboard?company_id=2 | 200      |
| 21.4 | Health           | GET    | /workflows/health                 | 200      |

### 22. SCHEDULED JOBS (`/scheduled-jobs`)

| #    | Test      | Method | Endpoint                     | Expected |
| ---- | --------- | ------ | ---------------------------- | -------- |
| 22.1 | List jobs | GET    | /scheduled-jobs?company_id=2 | 200      |

### 23. NOTIFICATIONS (`/notifications`)

| #    | Test               | Method | Endpoint                    | Expected |
| ---- | ------------------ | ------ | --------------------------- | -------- |
| 23.1 | List notifications | GET    | /notifications              | 200      |
| 23.2 | Unread count       | GET    | /notifications/unread-count | 200      |

### 24. TICKETS (`/tickets`)

| #    | Test         | Method | Endpoint              | Expected |
| ---- | ------------ | ------ | --------------------- | -------- |
| 24.1 | List tickets | GET    | /tickets?company_id=2 | 200      |

### 25. REPORTS (`/reports`)

| #    | Test               | Method | Endpoint                         | Expected |
| ---- | ------------------ | ------ | -------------------------------- | -------- |
| 25.1 | List reports       | GET    | /reports?company_id=2            | 200      |
| 25.2 | Validation results | GET    | /reports/validation?company_id=2 | 200      |

### 26. DELETION REQUESTS (`/deletion-requests`)

| #    | Test                   | Method | Endpoint                        | Expected |
| ---- | ---------------------- | ------ | ------------------------------- | -------- |
| 26.1 | List deletion requests | GET    | /deletion-requests?company_id=2 | 200      |

### 27. ERP CONNECTIONS (`/erp-connections`)

| #    | Test             | Method | Endpoint                      | Expected |
| ---- | ---------------- | ------ | ----------------------------- | -------- |
| 27.1 | List connections | GET    | /erp-connections?company_id=2 | 200      |

### 28. ORCHESTRATOR (`/orchestrator`)

| #    | Test   | Method | Endpoint                          | Expected |
| ---- | ------ | ------ | --------------------------------- | -------- |
| 28.1 | Status | GET    | /orchestrator/status?company_id=2 | 200      |

### 29. ADMIN — ORCHESTRATOR (`/admin/orchestrator`)

| #    | Test            | Method | Endpoint                      | Expected |
| ---- | --------------- | ------ | ----------------------------- | -------- |
| 29.1 | Rollout summary | GET    | /admin/orchestrator/rollout   | 200      |
| 29.2 | Company status  | GET    | /admin/orchestrator/companies | 200      |
| 29.3 | Stats           | GET    | /admin/orchestrator/stats     | 200      |
| 29.4 | Health          | GET    | /admin/orchestrator/health    | 200      |

### 30. ADMIN — USERS (`/admin/users`)

| #    | Test           | Method | Endpoint       | Expected |
| ---- | -------------- | ------ | -------------- | -------- |
| 30.1 | Get admin user | GET    | /admin/users/1 | 200      |

### 31. INDUSTRY RULES (`/industry-rules`)

| #    | Test       | Method | Endpoint                           | Expected |
| ---- | ---------- | ------ | ---------------------------------- | -------- |
| 31.1 | List rules | GET    | /industry-rules/rules?company_id=2 | 200      |
| 31.2 | CNAE codes | GET    | /industry-rules/cnae               | 200      |

### 32. ANALYTICS (`/analytics`)

| #    | Test            | Method | Endpoint                                | Expected |
| ---- | --------------- | ------ | --------------------------------------- | -------- |
| 32.1 | Forecast models | GET    | /analytics/forecast/models?company_id=2 | 200      |

### 33. ML PIPELINE (`/ml-pipeline`)

| #    | Test        | Method | Endpoint                          | Expected |
| ---- | ----------- | ------ | --------------------------------- | -------- |
| 33.1 | List models | GET    | /ml-pipeline/models?company_id=2  | 200      |
| 33.2 | Metrics     | GET    | /ml-pipeline/metrics?company_id=2 | 200      |

### 34. ESOCIAL (`/esocial`)

| #    | Test   | Method | Endpoint                     | Expected |
| ---- | ------ | ------ | ---------------------------- | -------- |
| 34.1 | Status | GET    | /esocial/status?company_id=2 | 200      |

### 35. DATA LINEAGE (`/lineage`)

| #    | Test          | Method | Endpoint              | Expected |
| ---- | ------------- | ------ | --------------------- | -------- |
| 35.1 | Lineage graph | GET    | /lineage?company_id=2 | 200      |

### 36. WEBHOOKS (`/webhooks`)

| #    | Test          | Method | Endpoint               | Expected |
| ---- | ------------- | ------ | ---------------------- | -------- |
| 36.1 | List webhooks | GET    | /webhooks?company_id=2 | 200      |

### 37. PORTAL CONFIG (`/portal-config`)

| #    | Test       | Method | Endpoint                            | Expected |
| ---- | ---------- | ------ | ----------------------------------- | -------- |
| 37.1 | Get config | GET    | /portal-config?accounting_firm_id=1 | 200      |

### 38. PORTAL DOMAINS (`/portal-domains`)

| #    | Test         | Method | Endpoint                             | Expected |
| ---- | ------------ | ------ | ------------------------------------ | -------- |
| 38.1 | List domains | GET    | /portal-domains?accounting_firm_id=1 | 200      |

### 39. PORTAL RESOLVE (`/portal`)

| #    | Test           | Method | Endpoint                           | Expected   |
| ---- | -------------- | ------ | ---------------------------------- | ---------- |
| 39.1 | Resolve domain | GET    | /portal/resolve?domain=contably.ai | 200 or 404 |

### 40. REAL-TIME ACCOUNTING

| #    | Test                  | Method | Endpoint                          | Expected |
| ---- | --------------------- | ------ | --------------------------------- | -------- |
| 40.1 | Reconciliation status | GET    | /realtime/reconciliation-status/2 | 200      |
| 40.2 | Cash position         | GET    | /realtime/cash-position/2         | 200      |

### 41. CLIENT PORTAL (`/client/...`)

| #     | Test             | Method | Endpoint                       | Expected |
| ----- | ---------------- | ------ | ------------------------------ | -------- |
| 41.1  | Client dashboard | GET    | /client/dashboard              | 200      |
| 41.2  | Client documents | GET    | /client/documents              | 200      |
| 41.3  | Client messages  | GET    | /client/messages/conversations | 200      |
| 41.4  | Client processes | GET    | /client/processes              | 200      |
| 41.5  | Client reports   | GET    | /client/reports                | 200      |
| 41.6  | Client requests  | GET    | /client/requests               | 200      |
| 41.7  | Client tickets   | GET    | /client/tickets                | 200      |
| 41.8  | Client settings  | GET    | /client/settings               | 200      |
| 41.9  | Client users     | GET    | /client/users                  | 200      |
| 41.10 | Unread count     | GET    | /client/messages/unread-count  | 200      |

### 42. DEVELOPER USERS (`/developer-users`)

| #    | Test            | Method | Endpoint         | Expected |
| ---- | --------------- | ------ | ---------------- | -------- |
| 42.1 | List developers | GET    | /developer-users | 200      |

### 43. SLACK FEEDBACK (`/slack-feedback`)

| #    | Test          | Method | Endpoint        | Expected |
| ---- | ------------- | ------ | --------------- | -------- |
| 43.1 | List feedback | GET    | /slack-feedback | 200      |

### 44. BROWSER TESTS (Chrome MCP)

After API tests pass, verify the frontend apps render correctly:

| #    | Test                     | URL                              | Check                             |
| ---- | ------------------------ | -------------------------------- | --------------------------------- |
| 44.1 | Admin login page loads   | https://contably.ai/login        | Login form visible                |
| 44.2 | Admin login works        | https://contably.ai/login        | Dashboard loads after login       |
| 44.3 | Dashboard renders charts | https://contably.ai/             | Sidebar, charts, company selector |
| 44.4 | Portal login page        | https://portal.contably.ai/login | Login form visible                |

---

## Total Test Count: ~120 endpoint tests + 4 browser tests

## Decision Framework

| Situation                        | Action                                          |
| -------------------------------- | ----------------------------------------------- |
| HTTP 500                         | Read API source code, find traceback, fix       |
| HTTP 401/403                     | Trace auth dependency chain, fix permissions    |
| HTTP 422                         | Check required query params (company_id, etc)   |
| HTTP 404                         | Check route registration in routers/**init**.py |
| HTTP 405                         | Wrong HTTP method — check route definition      |
| HTTP 429                         | Rate limited — wait 60s, reduce request rate    |
| Import error crashes API         | Fix import, verify routes **init**.py           |
| Multiple endpoints fail same way | One root cause — fix once                       |

## CI/CD

- Push to `main` triggers GitHub Actions `oci-deploy.yaml`
- Images: `sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-api:{git-sha}`
- K8s namespace: `contably`
- Health: `GET /health` (NOT `/api/v1/health`)
- Check deploy: `gh run list --workflow=oci-deploy.yaml --limit=3`

## Common Pitfalls

- `src.config.database` exports `get_db` and `get_db_session`, NOT `get_session`
- `TYPE_CHECKING` imports are NOT available at runtime
- FastAPI route ordering: static before parameterized
- Routes `__init__.py` imports ALL modules — any import error crashes entire API
- Most list endpoints need `?company_id=2` query param
- Rate limit on `/auth/login` — only login ONCE per cycle
- Company ID 2 = "Comércio Express SA" (main test company)
- Accounting firm ID 1 = "Escritório Contábil ABC"

## Output

```markdown
## QA Orchestrator — Final Report

**Status**: SUCCESS / PARTIAL / BLOCKED
**Cycles**: N
**Final pass rate**: X/Y (Z%)

### Results by Feature Area

| Area | Passed | Total | Rate |
| ---- | ------ | ----- | ---- |

### Issues Fixed

- description (root cause → fix)

### Issues Remaining (if any)

- description (why it couldn't be fixed)

### Deployments

- Commit {sha}: {message}
```

## REMEMBER

- You are AUTONOMOUS. Do not ask "should I continue?" — JUST DO IT.
- You have FULL codebase access. Read any file. Edit any file. Deploy any change.
- The only STOP conditions are: 100% pass, destructive action needed, or cycle 10.
- Progress is measured in PASS RATE. Every cycle should improve it.
- If a fix doesn't work, try a DIFFERENT approach.
- Track everything in tasks. The user should see what you did and why.
- Login ONCE per cycle. Reuse the token. Don't trigger rate limits.
- Use `company_id=2` for most endpoints.
