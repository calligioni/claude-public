---
name: qa-verify
description: "Loads issues in TESTING status from the QA database and verifies fixes using the browse CLI (primary) or Chrome DevTools MCP (fallback) for browser automation. Records verification results in DB, moves issues to VERIFIED or back to IN_PROGRESS. Triggers on: qa verify, verify fixes, verify qa issues, verify bugs, test fixes."
user-invocable: true
context: fork
model: sonnet
effort: medium
allowed-tools:
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - mcp__chrome-devtools__*
  - mcp__playwright__*
  - mcp__browserless__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  mcp__chrome-devtools__*: { readOnlyHint: false, openWorldHint: true }
  mcp__memory__*: { readOnlyHint: false, idempotentHint: false }
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

# QA Verify Skill (v1.0)

Loads issues in TESTING status from the QA database and verifies fixes by running the reproduction steps via the `browse` CLI (primary). Records results in DB and updates issue status.

## Browser Automation: `browse` CLI (Primary)

**`browse`** is a compiled headless Chromium CLI at `~/.local/bin/browse`. Zero MCP token overhead, ~100ms per call.

```bash
browse goto <url>           # Navigate to page
browse snapshot -i          # Interactive elements with @e refs (for clicking/filling)
browse snapshot -D          # Diff vs previous snapshot (see exactly what changed)
browse screenshot [path]    # Screenshot for evidence capture
browse text                 # Get page text content
browse click @e3            # Click element by ref
browse fill @e4 "value"     # Fill input by ref
browse console              # Check console errors
browse network              # List network requests
browse js "expr"            # Evaluate JavaScript expression
browse perf                 # Performance metrics
```

**Headed mode escalation:** For visual/CSS/layout failures that headless screenshots can't diagnose, escalate to `/open-gstack-browser` — a steerable Chromium with Claude Code sidebar for live interactive debugging.

**Chrome DevTools MCP** (`mcp__chrome-devtools__*`) remains available as a fallback when `browse` cannot handle a specific interaction.

### The snapshot -D Verification Pattern

This pattern is ideal for verifying that an action produced the expected change:

```bash
browse goto <page>
browse snapshot -i          # baseline — capture initial state
browse fill @e5 "credentials"
browse click @e10           # submit action
browse snapshot -D          # shows exactly what changed — did login succeed?
```

Use `snapshot -D` after any action that should change the UI — form submissions, button clicks, state transitions. It shows only the diff, making pass/fail determination fast and unambiguous.

## What It Does

When you run `/qa-verify`, it will:

1. **Load issues in TESTING status** from the QA database
2. **Create a verification session** in the DB
3. For each issue:
   - Read the reproduction steps from the DB
   - **Navigate the app via `browse`** following each step
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

#### 3b: Execute Steps via browse CLI

For each step in the reproduction:

1. **Navigate** to the page: `browse goto <url>`
2. **Discover interactive elements**: `browse snapshot -i` (returns @e refs for inputs, buttons)
3. **Fill forms** if needed: `browse fill @e<N> "value"`
4. **Click buttons** if needed: `browse click @e<N>`
5. **Check results**: `browse snapshot -D` to see what changed, or `browse js "expr"` to query DOM state
6. **Capture evidence**: `browse screenshot /tmp/issue-{id}-evidence.png` on failure or for confirmation

Fallback: if `browse` cannot handle an interaction, use `mcp__chrome-devtools__*` equivalents.

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

1. Navigate to the page that triggers the API call: `browse goto <url>`
2. Check network requests: `browse network`
3. Verify HTTP status codes are now correct and response body contains expected data

Fallback: `mcp__chrome-devtools__list_network_requests` if more detail is needed.

### UI Bug Verification

1. Navigate to the affected page: `browse goto <url>`
2. Take a baseline snapshot: `browse snapshot -i`
3. Perform the triggering action (fill, click)
4. Check what changed: `browse snapshot -D`
5. Confirm specific DOM state: `browse js "document.querySelector('.selector')?.textContent"`
6. Take screenshot for visual confirmation: `browse screenshot /tmp/issue-{id}.png`

### Permission Bug Verification

1. Login as the affected persona using the `snapshot -D` pattern to confirm login success
2. Navigate to the restricted resource: `browse goto <url>`
3. Verify correct access (granted or denied based on role) via `browse snapshot -i` or `browse text`
4. Check for proper error messages on denied access

### Performance Bug Verification

1. Navigate to the slow page: `browse goto <url>`
2. Capture performance metrics: `browse perf`
3. Check load time against acceptable threshold
4. Verify the specific bottleneck is resolved

Fallback: `mcp__chrome-devtools__performance_start_trace` / `performance_stop_trace` for detailed traces.

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
  "nextStep": "Verification complete. Output summary and stop."
}
```

## Autonomous Operation

This skill runs fully autonomously without user interaction:

- **Never ask the user** for confirmation, next steps, or permission to continue
- Verify ALL issues in TESTING status in a single run without pausing
- After verifying each issue, immediately move to the next one
- Complete the session and output a brief summary when done, then stop

**IMPORTANT:** Never output messages like "Want me to continue?", "Should I proceed?", "Next step would be...", or any phrasing that implies waiting for user input. Just do it.

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

- `browse` CLI at `~/.local/bin/browse` (primary browser automation — headless Chromium, zero MCP overhead)
- Chrome DevTools MCP (fallback for interactions browse cannot handle)
- Running Contably environment (admin + client portal + API)
- QA database schema (migration 029_qa_schema)
- qa_manager.py CLI script (apps/api/scripts/qa_manager.py)

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains.

## Hook Events

- **TaskCompleted**: Triggers when a verification task is marked completed
