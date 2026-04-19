---
name: qa-fix
description: "Fix open QA issues: reads from DB, prioritizes by severity, investigates codebase, implements fixes. Triggers on: qa fix, fix bugs, fix qa issues, fix open issues."
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
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - mcp__playwright__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
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

# QA Fix Skill (v1.0)

Reads open issues from the QA database, prioritizes by severity, investigates root causes in the codebase, and creates fixes. Updates issue status throughout the fix lifecycle.

## What It Does

When you run `/qa-fix`, it will:

1. **Read open issues** from the QA database via `qa_manager.py`
2. **Prioritize** by severity (P0 first, then P1, P2, P3)
3. For each issue:
   - Read full reproduction steps and technical details from DB
   - **Investigate the codebase** to find the root cause
   - **Create a fix** (direct code change or PR)
   - **Update issue status** in DB (assigned → in_progress → pr_created)
   - Add comments documenting the investigation and fix
4. Commit all fixes and output a summary

## Usage

```
/qa-fix                        # Fix top priority open issues (P0 + P1)
/qa-fix --issue 42             # Fix a specific issue by ID
/qa-fix --severity p0          # Fix only P0 critical issues
/qa-fix --severity p0,p1,p2   # Fix P0 through P2 issues
/qa-fix --limit 5              # Fix at most 5 issues
/qa-fix --dry-run              # Show what would be fixed without making changes
```

## Execution Flow

### Step 1: Load Open Issues from DB

```bash
# Get prioritized list of open issues
python apps/api/scripts/qa_manager.py query open-issues --severity p0-critical,p1-high

# Or for a specific issue
python apps/api/scripts/qa_manager.py query open-issues --id 42
```

### Step 2: For Each Issue, Investigate and Fix

For each issue (in severity order):

#### 2a: Claim the Issue

```bash
# Mark issue as assigned to this agent
python apps/api/scripts/qa_manager.py issue update \
  --id {issue_id} \
  --status assigned \
  --assigned-to "qa-fix-agent"

# Add investigation comment
python apps/api/scripts/qa_manager.py comment add \
  --issue-id {issue_id} \
  --author "qa-fix-agent" \
  --type note \
  --comment "Starting investigation. Reproduction steps: {steps_summary}"
```

#### 2b: Investigate Root Cause

Using the issue's technical details:

1. **Read the endpoint** code if `endpoint` is specified
2. **Check console errors** for stack traces
3. **Follow the reproduction steps** to understand the flow
4. **Search the codebase** for related patterns
5. **Identify root cause** and determine fix strategy

```bash
# Mark as in progress
python apps/api/scripts/qa_manager.py issue update \
  --id {issue_id} \
  --status in_progress
```

#### 2c: Implement the Fix

Apply the fix directly to the codebase using Edit/Write tools.

When spawning multiple Task agents to fix different issues in parallel, always use `isolation: "worktree"` to prevent concurrent file edit conflicts between agents.

For complex fixes, consider:

- Impact on other parts of the system
- Whether tests need updating
- Whether the fix could cause regressions

#### 2d: Update Issue Status

```bash
# After fix is applied, update status
python apps/api/scripts/qa_manager.py issue close \
  --id {issue_id} \
  --fixed-by "qa-fix-agent" \
  --commit {commit_hash} \
  --pr "{pr_url_if_applicable}"

# Add fix documentation comment
python apps/api/scripts/qa_manager.py comment add \
  --issue-id {issue_id} \
  --author "qa-fix-agent" \
  --type fix \
  --comment "Fixed by modifying {file}. Root cause: {explanation}. Changes: {summary}"
```

If creating a PR instead of direct fix:

```bash
python apps/api/scripts/qa_manager.py issue update \
  --id {issue_id} \
  --status pr_created \
  --pr "https://github.com/..."
```

### Step 3: Move Fixed Issues to Testing

After all fixes are applied:

```bash
# Move issues to testing status for verification
python apps/api/scripts/qa_manager.py issue update \
  --id {issue_id} \
  --status testing
```

This signals to `` that these issues are ready for verification.

## Investigation Patterns

### API Endpoint Bugs

1. Find the endpoint handler in `apps/api/`
2. Trace the request flow: route → handler → service → database
3. Check for missing error handling, incorrect queries, auth issues
4. Look for related tests in `tests/`

### UI/Navigation Bugs

1. Find the component in `apps/admin/` or `apps/portal/`
2. Check the route configuration
3. Look for state management issues
4. Verify data fetching logic

### Permission Bugs

1. Check the permission decorators/middleware
2. Verify role-based access control logic
3. Compare with the permission matrix for the persona's role
4. Look for missing permission checks

### Performance Bugs

1. Check database queries for N+1 patterns
2. Look for missing indexes
3. Check for unnecessary data fetching
4. Look for blocking operations

## Completion Signal

```json
{
  "status": "complete|partial|blocked|failed",
  "summary": "Fixed 3 of 5 open issues",
  "issuesProcessed": [
    {
      "id": 42,
      "title": "Client portal login returns 500",
      "severity": "p0-critical",
      "action": "fixed",
      "fix_description": "Added null check in auth middleware",
      "files_changed": ["apps/api/middleware/auth.py"]
    },
    {
      "id": 43,
      "title": "Dashboard charts not loading",
      "severity": "p1-high",
      "action": "fixed",
      "fix_description": "Fixed API endpoint returning wrong date format",
      "files_changed": ["apps/api/routes/dashboard.py"]
    },
    {
      "id": 44,
      "title": "Slow page load on /reports",
      "severity": "p2-medium",
      "action": "skipped",
      "reason": "Requires database migration - needs user approval"
    }
  ],
  "issuesFixed": 2,
  "issuesSkipped": 1,
  "issuesFailed": 0,
  "nextStep": "Run  to verify fixes, or /virtual-user-testing for full regression test"
}
```

## Integration with QA Cycle

```
/virtual-user-testing  →  Discovers bugs in DB
/qa-fix                →  THIS SKILL: reads DB, fixes code
             →  Verifies fixes via browser
/qa-cycle              →  Orchestrates all phases
```

## Autonomous Operation

This skill runs fully autonomously without user interaction:

- **Never ask the user** for confirmation, next steps, or permission to continue
- Process ALL matching issues in a single run without pausing
- After fixing each issue, immediately move to the next one
- Commit all changes at the end with a single descriptive commit
- Output a brief summary when complete, then stop

**IMPORTANT:** Never output messages like "Want me to continue?", "Should I proceed?", "Next step would be...", or any phrasing that implies waiting for user input. Just do it.

## Safety Checks

- Always reads the full issue context before attempting a fix
- Adds comments to document investigation trail
- Does not push to remote unless explicitly asked
- Preserves existing tests and does not disable them

---

## Version

**Current Version:** 1.0.0
**Last Updated:** February 2026

### Requirements

- QA database schema (migration 029_qa_schema)
- qa_manager.py CLI script (apps/api/scripts/qa_manager.py)
- Access to the ExampleProject codebase

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains.

## Hook Events

- **TaskCompleted**: Triggers when a fix task is marked completed
