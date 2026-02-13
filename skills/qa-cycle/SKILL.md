---
name: qa-cycle
description: "Full QA cycle orchestrator: discover bugs via virtual user testing, report from DB, fix issues via CTO/dev patterns, and verify fixes via browser testing. Accepts flags for running individual phases or the complete cycle. Handles regression detection across sessions. Triggers on: qa cycle, full qa, run qa, continuous qa, qa pipeline."
user-invocable: true
context: fork
model: sonnet # Orchestration-focused; coordinates discovery/fix/verify phases
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
  - WebSearch
  - mcp__chrome-devtools__*
  - mcp__memory__*
memory: user
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

**MODEL RULES:**

- **Discovery personas: `model: "haiku"`** - navigation, bug reporting, verification
- **Fix phase: `model: "sonnet"`** - codebase investigation, code changes
- **Verify phase: `model: "haiku"`** - browser re-testing of fixes
- **Orchestrator: sonnet** (this skill's YAML header)

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

Present reports to user and ask whether to proceed with fixes:

```
AskUserQuestion:
  question: "Discovery found X new issues (Y critical). Proceed with auto-fix phase?"
  options:
    - "Yes, fix all" → continue to Phase 3
    - "Fix P0 only" → Phase 3 with severity filter
    - "Skip fix, just verify" → jump to Phase 4
    - "Stop here" → complete session with discovery-only results
```

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
  "nextStep": "Review reports and schedule next cycle"
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

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains.

## Hook Events

- **TeammateIdle**: Triggers when a persona tester completes (discover phase)
- **TaskCompleted**: Triggers when a fix or verify task is marked completed
