---
name: qa-cycle
description: "Full QA cycle orchestrator: discover bugs via virtual user testing, report from DB, fix issues via CTO/dev patterns, and verify fixes via browser testing. Accepts flags for running individual phases or the complete cycle. Handles regression detection across sessions. Triggers on: qa cycle, full qa, run qa, continuous qa, qa pipeline."
user-invocable: true
context: fork
model: sonnet # Orchestrator on sonnet; persona testers on haiku
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

# QA Cycle Skill (v1.0 - Full Orchestrator)

Runs the complete QA lifecycle: discover bugs via virtual user personas, generate reports from DB, fix issues using CTO/dev patterns, and verify fixes via browser testing. Handles regression detection and provides a single command to run the full or partial cycle.

## What It Does

When you run `/qa-cycle`, it orchestrates:

1. **DISCOVER** - Run `/virtual-user-testing` to spawn personas that test the app and report bugs to DB
2. **REPORT** - Generate CTO and CPO reports from DB data
3. **FIX** - Run `/qa-fix` to read open issues from DB and create fixes
4. **VERIFY** - Run `/qa-verify` to verify fixes via browser testing
5. **REGRESSION CHECK** - Detect regressions by comparing with previous sessions

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    QA CYCLE ORCHESTRATOR                          │
│                                                                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐   │
│  │ DISCOVER │ ──▶│  REPORT  │ ──▶│   FIX    │ ──▶│  VERIFY  │   │
│  │          │    │          │    │          │    │          │   │
│  │ 5 persona│    │ CTO/CPO  │    │ Read DB  │    │ Browser  │   │
│  │ agents   │    │ from DB  │    │ fix code │    │ re-test  │   │
│  │ test app │    │ reports  │    │ update DB│    │ update DB│   │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘   │
│       │               │               │               │          │
│       ▼               ▼               ▼               ▼          │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │              PostgreSQL (qa schema)                        │    │
│  │  qa_issues | qa_sessions | qa_personas | qa_verifications │    │
│  └──────────────────────────────────────────────────────────┘    │
│                              │                                    │
│                              ▼                                    │
│                    ┌──────────────────┐                           │
│                    │ REGRESSION CHECK │                           │
│                    │ Compare sessions │                           │
│                    │ Flag regressions │                           │
│                    └──────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

```
/qa-cycle                      # Full cycle: discover → report → fix → verify
/qa-cycle --discover-only      # Only run persona discovery (writes bugs to DB)
/qa-cycle --fix-only           # Only fix open issues from DB
/qa-cycle --verify-only        # Only verify issues in TESTING status
/qa-cycle --report             # Generate reports from current DB state
/qa-cycle --severity p0        # Full cycle but only for P0 issues
/qa-cycle --skip-fix           # Discover + report + verify (no auto-fix)
```

## Execution Flow

### Full Cycle

```
                    ┌─────────────────────┐
                    │  Parse CLI flags     │
                    │  Determine phases    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Create QA Session   │
                    │  qa_manager.py       │
                    │  session start       │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                     │
   ┌──────▼──────┐    ┌───────▼───────┐    ┌───────▼──────┐
   │ --discover  │    │  --fix-only   │    │ --verify-only│
   │     only    │    │               │    │              │
   └──────┬──────┘    └───────┬───────┘    └───────┬──────┘
          │                   │                     │
          ▼                   │                     │
   Phase 1: DISCOVER          │                     │
   (virtual-user-testing)     │                     │
          │                   │                     │
          ▼                   │                     │
   Phase 2: REPORT            │                     │
   (qa_manager.py report)     │                     │
          │                   │                     │
          │         ┌─────────▼─────────┐           │
          └────────▶│  Phase 3: FIX     │           │
                    │  (qa-fix logic)   │           │
                    └─────────┬─────────┘           │
                              │                     │
                    ┌─────────▼─────────┐           │
                    │  Phase 4: VERIFY  │◀──────────┘
                    │  (qa-verify logic)│
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │ Phase 5: REGRESSION│
                    │ Compare with prev  │
                    │ sessions           │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Complete Session  │
                    │  Generate summary  │
                    └───────────────────┘
```

### Phase 1: DISCOVER

Invokes the `/virtual-user-testing` skill logic:

```bash
# Create session
python apps/api/scripts/qa_manager.py session start \
  --trigger qa-cycle \
  --personas maria,carlos,renata,joao,pedro
```

Then spawns persona agents using `model: "haiku"` (same as virtual-user-testing):

**MODEL RULES (3-tier):**

- **Strategic decisions: `model: "opus"`** - triage, prioritization, architectural analysis, root cause reasoning
- **Orchestrator + Fix phase: `model: "sonnet"`** - orchestration, codebase investigation, code changes
- **Discovery personas + Verify phase: `model: "haiku"`** - browser navigation, bug reporting, verification

- Each persona loads history, open issues, and verification queue from DB
- Each persona tests the app via Chrome DevTools MCP
- Each persona reports bugs via `qa_manager.py issue create`
- Each persona verifies fixed bugs via `qa_manager.py issue verify`

### Phase 2: REPORT

After discovery completes, generate reports:

```bash
# CTO report - technical issues, bugs, performance
python apps/api/scripts/qa_manager.py report cto --session-id {session_id}

# CPO report - UX issues, satisfaction, feature requests
python apps/api/scripts/qa_manager.py report cpo --session-id {session_id}
```

After generating reports, automatically proceed to the next phase without asking the user. Log the report summary and continue.

### Phase 3: FIX

Invokes the `/qa-fix` skill logic:

```bash
# Get prioritized open issues
python apps/api/scripts/qa_manager.py query open-issues --severity p0-critical,p1-high
```

For each issue:

1. Claim the issue: `issue update --status assigned`
2. Investigate the codebase
3. Create the fix
4. Update status: `issue update --status pr_created` or `issue close`
5. Move to testing: `issue update --status testing`

### Phase 4: VERIFY

Invokes the `/qa-verify` skill logic:

```bash
# Get issues ready for verification
python apps/api/scripts/qa_manager.py query open-issues --status testing
```

For each issue:

1. Read reproduction steps
2. Execute via Chrome DevTools MCP
3. Record result: `issue verify --passed true/false`
4. Move to VERIFIED or back to IN_PROGRESS

### Phase 5: REGRESSION DETECTION

Compare current session with previous sessions:

```bash
# Get session summary including regression data
python apps/api/scripts/qa_manager.py query session-summary --session-id {session_id}
```

Check for:

- **New regressions**: Bugs that were CLOSED but reappeared in this session
- **Persistent issues**: Bugs that failed verification (bounced back from TESTING)
- **Trend analysis**: Is the overall issue count going up or down across sessions?

If regressions detected:

```bash
# Regressions are auto-created as P0 issues during discovery
# Here we summarize them
python apps/api/scripts/qa_manager.py query open-issues --status regression
```

### Session Completion

```bash
python apps/api/scripts/qa_manager.py session complete \
  --id {session_id} \
  --summary "Full QA cycle: discovered X issues, fixed Y, verified Z, N regressions detected"
```

## Completion Signal

```json
{
  "status": "complete|partial|blocked|failed",
  "summary": "Full QA cycle completed",
  "sessionId": "{session_uuid}",
  "phases": {
    "discover": {
      "status": "complete",
      "newIssues": 8,
      "duplicates": 2,
      "personasTested": 5
    },
    "report": {
      "status": "complete",
      "ctoReport": "generated",
      "cpoReport": "generated"
    },
    "fix": {
      "status": "complete",
      "issuesFixed": 5,
      "issuesSkipped": 2,
      "issuesFailed": 1
    },
    "verify": {
      "status": "complete",
      "verified": 4,
      "failed": 1
    },
    "regression": {
      "regressionsDetected": 0,
      "previouslyClosed": 15,
      "stillClosed": 15
    }
  },
  "overallHealth": {
    "totalOpenIssues": 12,
    "criticalOpen": 1,
    "trend": "improving",
    "avgSatisfaction": 6.8
  },
  "nextStep": "Cycle complete. Output summary and stop."
}
```

## Flags Reference

| Flag              | Description                            | Phases Run                 |
| ----------------- | -------------------------------------- | -------------------------- |
| (none)            | Full cycle                             | All 5 phases               |
| `--discover-only` | Run persona testing only               | Discover + Report          |
| `--fix-only`      | Fix existing open issues               | Fix only                   |
| `--verify-only`   | Verify issues in TESTING status        | Verify only                |
| `--report`        | Generate reports from current DB state | Report only                |
| `--skip-fix`      | Discover + verify without auto-fixing  | Discover + Report + Verify |
| `--severity X`    | Filter issues by severity              | Applies to all phases      |
| `--limit N`       | Max issues to process per phase        | Applies to fix + verify    |

## Regression Detection Strategy

The cycle detects regressions at multiple levels:

1. **During Discovery**: Personas check their verification queue of recently-fixed bugs. If a fixed bug reappears, it's auto-created as a regression issue (P0).

2. **Cross-Session Comparison**: After each cycle, compare the set of CLOSED issues with any new reports matching the same endpoint/error pattern.

3. **Trend Analysis**: Track these metrics across sessions:
   - Total open issues (going up = problems, going down = progress)
   - Average persona satisfaction (trending up = improving UX)
   - Time-to-fix for issues (shorter = better process)
   - Regression rate (regressions / total closed issues)

## Autonomous Operation

This skill runs as a **continuous autonomous loop** until all issues are resolved:

```
┌─────────────────────────────────────────────────────────┐
│                   CONTINUOUS QA LOOP                     │
│                                                          │
│   discover → report → fix → commit → verify →            │
│   regression → deploy → confirm deploy →                 │
│                                                          │
│   ┌─── open issues remaining? ───┐                      │
│   │ YES → start new cycle        │                      │
│   │ NO  → output final summary   │                      │
│   └──────────────────────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

### Rules

- **Never ask the user** for confirmation, next steps, or permission at any point
- **Never stop between phases** — the full pipeline runs end-to-end
- After deploy, **verify the deployment succeeded** (check production endpoints)
- After confirming deploy, **query DB for remaining open issues**
- If open issues remain → **start a new cycle automatically** (re-discover, fix, verify, deploy)
- If zero open issues → **output a final summary and stop**
- Each cycle should focus on progressively lower severity: P0 first cycle, P1 second, P2/P3 later
- **Max 5 cycles** per invocation to prevent infinite loops (if issues keep recurring, stop and report)
- The only exception: if `--discover-only`, `--fix-only`, or `--verify-only` flags are set, run only that phase then stop

### Cycle Tracking

Track cycle count and log progress:

```
Cycle 1: Discovered 33 issues, fixed 17 (P0+P1), deployed, 12 remaining
Cycle 2: Discovered 3 new issues, fixed 10 (P1+P2), deployed, 5 remaining
Cycle 3: Fixed 5 (P2+P3), deployed, 0 remaining → DONE
```

**IMPORTANT:** The orchestrator must never output messages like "Want me to continue?", "Should I proceed?", "Next step would be...", or any phrasing that implies waiting for user input. Just do it.

## Opus-for-Decisions Pattern

Use opus briefly for strategic thinking, then hand execution back to sonnet/haiku.
Opus calls should be short, focused prompts — ask one question, get one answer.

### When to Escalate to Opus

Spawn a `Task(model: "opus")` at these decision points:

1. **Post-Discovery Triage** (between Phase 2 and Phase 3):

   ```
   Task(model: "opus", prompt: "Given these {N} QA issues from discovery:
   {issue_list_with_titles_severity_endpoints}

   Determine:
   1. Which are real bugs vs expected behavior or test environment artifacts?
   2. Priority order for fixing (considering dependencies between issues)
   3. Which issues likely share a root cause and should be fixed together?
   4. Any issues that are deployment/infra problems vs code bugs?

   Return a structured fix plan as JSON.")
   ```

2. **Complex Root Cause Analysis** (during Phase 3, when a fix isn't obvious):

   ```
   Task(model: "opus", prompt: "Issue: {title}
   Reproduction: {steps}
   Error: {error_details}
   Relevant code: {code_snippets}

   What is the root cause and what is the minimal fix?")
   ```

3. **Regression Analysis** (Phase 5):

   ```
   Task(model: "opus", prompt: "Compare these sessions:
   Previous: {prev_session_summary}
   Current: {current_session_summary}

   Are any regressions real, or are they flaky/environment-dependent?
   What systemic patterns do you see across sessions?")
   ```

4. **Deploy + Continue Decision** (after Phase 5):

   ```
   Task(model: "opus", prompt: "QA cycle {N} summary:
   {fixes_applied}
   {verification_results}
   {regression_status}
   {remaining_open_issues}

   1. Should we deploy these changes to production? (YES/NO + reasoning)
   2. Are there remaining open issues worth fixing in another cycle? (YES/NO)
   Consider: risky changes, unverified fixes, regressions, diminishing returns.")
   ```

   - If deploy YES → commit, push, deploy, verify production endpoints
   - If deploy NO → commit locally only
   - If continue YES + open issues remain → start next cycle automatically
   - If continue NO or zero open issues or cycle >= 5 → output final summary, stop

### Cost Control

- Opus calls should be **rare** — 1-3 per full cycle, not per issue
- Keep opus prompts **concise** — include only relevant data, not full file contents
- Opus returns a **decision/plan**, sonnet **executes** it, haiku **verifies** it
- Never use opus for: browser navigation, file reading, running commands, writing code

### Model Flow per Phase

```
  ┌──────────────────────────────────────────────────────────┐
  │                                                          │
  ▼                                                          │
Phase 1 DISCOVER:  haiku × 5 personas (parallel browser testing)  │
                      ↓                                      │
Phase 2 REPORT:    sonnet (generate reports from DB)         │
                      ↓                                      │
     ┌─── TRIAGE:  opus × 1 call (prioritize, plan fixes)   │
     ↓                                                       │
Phase 3 FIX:       sonnet × N tasks (code changes)           │
     │                 ↑                                     │
     │    ESCALATE: opus × 0-2 calls (hard root causes)     │
     ↓                                                       │
Phase 4 VERIFY:    haiku × N tasks (browser re-testing)      │
                      ↓                                      │
Phase 5 REGRESS:   opus × 1 call (cross-session analysis)   │
                      ↓                                      │
     ┌─── DEPLOY:  opus × 1 call (deploy + continue?)       │
     ↓                                                       │
                   sonnet (commit, push, deploy)             │
                      ↓                                      │
              open issues remaining?                         │
              YES + cycle < 5 ──────────────────────────────┘
              NO  → output final summary, stop
```

## Integration with Other Skills

```
/virtual-user-testing  →  Discovery phase only
/qa-fix                →  Fix phase only
/qa-verify             →  Verify phase only
/qa-cycle              →  THIS SKILL: orchestrates all phases

/cto                   →  Can read QA reports for technical strategy
/deep-plan             →  Can plan implementation of complex fixes
```

---

## Version

**Current Version:** 1.0.0
**Last Updated:** February 2026

### Requirements

- Chrome DevTools MCP (for browser testing in discover + verify phases)
- Running Contably environment (admin + client portal + API)
- QA database schema (migration 029_qa_schema)
- qa_manager.py CLI script (apps/api/scripts/qa_manager.py)
- kubectl access to OKE cluster (context: context-ckxzb7tcsvq)
- OCI CLI (`~/bin/oci`) for infrastructure management

## Production & Staging Server Management

The QA cycle has **full authority** to manage production and staging infrastructure.

### Infrastructure Access

```
Kubernetes:  kubectl (context: context-ckxzb7tcsvq)
Namespace:   contably
OCI CLI:     ~/bin/oci
Docker:      docker (for building images)
Registry:    OCI Container Registry
```

### Deployments

| Service         | Deployment             | Replicas |
| --------------- | ---------------------- | -------- |
| API             | contably-api           | 2        |
| Admin Dashboard | contably-dashboard     | 2        |
| Client Portal   | contably-portal        | 2        |
| Celery Worker   | contably-celery-worker | 3        |
| Celery Beat     | contably-celery-beat   | 1        |
| Flower          | contably-flower        | 1        |

### Deploy Commands

Images are tagged with the git commit hash. Registry: `sa-saopaulo-1.ocir.io/gr5ovmlswwos/`

```bash
# Get current commit hash for tagging
COMMIT=$(git rev-parse --short HEAD)

# Build and push images (only for services with code changes)
docker build -t sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-api:$COMMIT -f apps/api/Dockerfile .
docker push sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-api:$COMMIT

docker build -t sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-admin:$COMMIT -f apps/admin/Dockerfile .
docker push sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-admin:$COMMIT

docker build -t sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-portal:$COMMIT -f apps/client-portal/Dockerfile .
docker push sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-portal:$COMMIT

# Update deployments with new image tag
kubectl set image deployment/contably-api contably-api=sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-api:$COMMIT -n contably
kubectl set image deployment/contably-dashboard contably-admin=sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-admin:$COMMIT -n contably
kubectl set image deployment/contably-portal contably-portal=sa-saopaulo-1.ocir.io/gr5ovmlswwos/contably-portal:$COMMIT -n contably

# Check rollout status
kubectl rollout status deployment/contably-api -n contably --timeout=120s
kubectl rollout status deployment/contably-dashboard -n contably --timeout=120s
kubectl rollout status deployment/contably-portal -n contably --timeout=120s

# Verify pods are healthy
kubectl get pods -n contably
```

### Post-Deploy Verification

After deploying, verify production endpoints:

```bash
# Check API health
curl -s https://api.contably.ai/health

# Check admin dashboard
curl -s -o /dev/null -w '%{http_code}' https://contably.ai

# Check client portal
curl -s -o /dev/null -w '%{http_code}' https://portal.contably.ai

# Check pod logs for errors
kubectl logs -n contably -l app=contably-api --tail=20 --since=2m
```

### Database Migrations

```bash
# Run migrations on production DB
kubectl exec -n contably deployment/contably-api -- alembic upgrade head

# Check current migration
kubectl exec -n contably deployment/contably-api -- alembic current
```

### Rollback

If deployment fails verification:

```bash
kubectl rollout undo deployment/contably-api -n contably
kubectl rollout undo deployment/contably-dashboard -n contably
kubectl rollout undo deployment/contably-portal -n contably
```

### Permissions

The QA cycle can autonomously:

- Build and push Docker images
- Deploy to production and staging
- Restart services
- Run database migrations
- Check logs and health endpoints
- Rollback failed deployments
- Scale replicas up/down
- Exec into pods for debugging

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains.

## Hook Events

- **TeammateIdle**: Triggers when a persona tester completes (discover phase)
- **TaskCompleted**: Triggers when a fix or verify task is marked completed
