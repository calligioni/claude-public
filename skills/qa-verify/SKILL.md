---
name: qa-verify
description: "Loads issues in TESTING status from the QA database and verifies fixes using Chrome DevTools MCP browser testing. Records verification results in DB, moves issues to VERIFIED or back to IN_PROGRESS. Triggers on: qa verify, verify fixes, verify qa issues, verify bugs, test fixes."
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
  - AskUserQuestion
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - mcp__chrome-devtools__*
  - mcp__memory__*
memory: user
---

# QA Verify Skill (v1.0)

Loads issues in TESTING status from the QA database and verifies fixes by running the reproduction steps via Chrome DevTools MCP browser testing. Records results in DB and updates issue status.

## What It Does

When you run `/qa-verify`, it will:

1. **Load issues in TESTING status** from the QA database
2. **Create a verification session** in the DB
3. For each issue:
   - Read the reproduction steps from the DB
   - **Navigate the app via Chrome DevTools** following each step
   - **Verify the expected behavior** matches actual behavior
   - **Record the result** in the DB (pass/fail with notes)
   - Move issue to VERIFIED (if passed) or back to IN_PROGRESS (if failed)
4. **Complete the session** with a summary of verification results

## Usage

```
/qa-verify                     # Verify all issues in TESTING status
/qa-verify --issue 42          # Verify a specific issue
/qa-verify --persona renata    # Verify as a specific persona (uses their credentials)
/qa-verify --session {uuid}    # Associate verifications with an existing QA session
```

## Execution Flow

### Step 1: Load Issues to Verify

```bash
# Get all issues in TESTING status
python apps/api/scripts/qa_manager.py query open-issues --status testing

# Or verify a specific issue
python apps/api/scripts/qa_manager.py query open-issues --id 42
```

### Step 2: Create/Join Session

```bash
# Create a new verification session
python apps/api/scripts/qa_manager.py session start \
  --trigger manual \
  --personas verifier

# Or use an existing session ID if provided
```

### Step 3: For Each Issue, Run Verification

#### 3a: Read Reproduction Steps

Each issue has structured `reproduction_steps` stored as JSON:

```json
[
  {
    "step": 1,
    "action": "Navigate to /login",
    "expected": "Login form displayed",
    "actual": "Login form displayed"
  },
  {
    "step": 2,
    "action": "Enter valid credentials",
    "expected": "Redirect to /dashboard",
    "actual": "500 error"
  }
]
```

#### 3b: Execute Steps via Chrome DevTools

For each step in the reproduction:

1. **Navigate** to the page: `mcp__chrome-devtools__navigate_page`
2. **Fill forms** if needed: `mcp__chrome-devtools__fill`
3. **Click buttons** if needed: `mcp__chrome-devtools__click`
4. **Check results**: `mcp__chrome-devtools__evaluate_script` to verify expected state
5. **Capture evidence**: `mcp__chrome-devtools__take_screenshot` on failure

#### 3c: Determine Persona Credentials

Select credentials based on the `discovered_by` persona or `--persona` flag:

```
maria   → master@contably.com / 1@Masterpass           (admin app)
carlos  → analyst1.abc@contably.com / 1@Masterpass      (admin app)
renata  → renata@test.contably.ai / 1@Masterpass        (client portal)
joao    → joao@test.contably.ai / 1@Masterpass          (client portal)
pedro   → admin.tech@empresa.com.br / 1@Masterpass      (admin app)
```

Use the same persona who discovered the bug for the most accurate verification.

#### 3d: Record Verification Result

```bash
# If the bug is fixed (expected behavior now matches)
python apps/api/scripts/qa_manager.py issue verify \
  --id {issue_id} \
  --persona {persona_slug} \
  --passed true \
  --session-id {session_uuid} \
  --notes "Verified fixed. Steps 1-3 now produce expected results. Login redirects to dashboard correctly."

# If the bug persists (still broken)
python apps/api/scripts/qa_manager.py issue verify \
  --id {issue_id} \
  --persona {persona_slug} \
  --passed false \
  --session-id {session_uuid} \
  --notes "Still failing at step 2. Login returns 500 error. Screenshot captured."
```

When verification fails, the issue automatically moves back to IN_PROGRESS for the fixer to address.

### Step 4: Complete Session

```bash
python apps/api/scripts/qa_manager.py session complete \
  --id {session_uuid} \
  --summary "Verification session: X passed, Y failed out of Z issues tested"
```

## Verification Strategies

### API Bug Verification

1. Navigate to the page that triggers the API call
2. Check network requests via `mcp__chrome-devtools__list_network_requests`
3. Verify HTTP status codes are now correct
4. Check response body for expected data

### UI Bug Verification

1. Navigate to the affected page
2. Use `mcp__chrome-devtools__evaluate_script` to check DOM state
3. Verify elements exist, are visible, and have correct content
4. Take screenshot for visual confirmation

### Permission Bug Verification

1. Login as the affected persona
2. Navigate to the restricted resource
3. Verify correct access (granted or denied based on role)
4. Check for proper error messages on denied access

### Performance Bug Verification

1. Navigate to the slow page
2. Use `mcp__chrome-devtools__performance_start_trace` and `performance_stop_trace`
3. Check load time against acceptable threshold
4. Verify the specific bottleneck is resolved

## Completion Signal

```json
{
  "status": "complete|partial|blocked|failed",
  "summary": "Verified 5 issues: 4 passed, 1 failed",
  "sessionId": "{session_uuid}",
  "results": [
    {
      "issueId": 42,
      "title": "Client portal login returns 500",
      "passed": true,
      "notes": "Login now works correctly"
    },
    {
      "issueId": 43,
      "title": "Dashboard charts not loading",
      "passed": false,
      "notes": "Charts still timeout after 10s"
    }
  ],
  "verified": 4,
  "failed": 1,
  "nextStep": "Run /qa-fix for failed verifications, or /virtual-user-testing for full regression check"
}
```

## Integration with QA Cycle

```
/virtual-user-testing  →  Discovers bugs in DB
/qa-fix                →  Reads DB, fixes code, moves to TESTING
/qa-verify             →  THIS SKILL: verifies fixes via browser
/qa-cycle              →  Orchestrates all phases
```

---

## Version

**Current Version:** 1.0.0
**Last Updated:** February 2026

### Requirements

- Chrome DevTools MCP (for browser navigation and verification)
- Running Contably environment (admin + client portal + API)
- QA database schema (migration 029_qa_schema)
- qa_manager.py CLI script (apps/api/scripts/qa_manager.py)

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains.

## Hook Events

- **TaskCompleted**: Triggers when a verification task is marked completed
