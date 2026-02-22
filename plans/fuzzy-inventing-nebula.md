# Plan: Contably QA — Standalone Instance on VPS

## Context

Run the full Contably QA cycle (discover, diagnose, fix, verify, report) as a **standalone Claude Code instance** on the VPS. Nanoclaw doesn't run the QA — it just triggers it and reads the results to post to Discord.

The QA instance has model tiering for cost efficiency and quality, plus automatic fallback to OpenAI when Anthropic credits run out.

## Architecture

```
VPS
├── Nanoclaw (Discord bot, scheduling)
│   ├── Triggers QA: ssh/script call to start a cycle
│   ├── Reads: shared QA output dir + QA DB
│   └── Posts: summary to Discord when cycle completes
│
├── Contably QA Instance (standalone)
│   ├── ~/code/contably (repo, read-write for fixes)
│   ├── qa_manager.py → PostgreSQL QA schema
│   ├── Headless Chromium (Playwright)
│   ├── contably-qa-runner.py (orchestrator)
│   │   ├── Phase: DISCOVER → haiku (test personas)
│   │   ├── Phase: DIAGNOSE → opus (root cause analysis)
│   │   ├── Phase: FIX      → sonnet (implement fixes)
│   │   ├── Phase: VERIFY   → haiku (re-test fixes)
│   │   └── Phase: REPORT   → haiku (generate reports)
│   └── Fallback: OpenAI when Anthropic credits exhaust
│       ├── haiku → 4o-mini
│       ├── opus  → codex
│       └── sonnet → 4o
│
├── Shared
│   ├── QA DB: PostgreSQL (contably_db, schema qa)
│   └── QA output: ~/contably-qa/output/ (reports, logs)
│
└── Remote: Contably Staging (OKE)
    ├── https://staging.contably.ai
    ├── https://staging-portal.contably.ai
    └── https://staging-api.contably.ai
```

## Model Strategy

| Phase    | Role                         | Anthropic | OpenAI Fallback |
| -------- | ---------------------------- | --------- | --------------- |
| DISCOVER | Persona testers (5 parallel) | haiku     | 4o-mini         |
| DIAGNOSE | Root cause + fix strategy    | opus      | codex           |
| FIX      | Implement code changes       | sonnet    | 4o              |
| VERIFY   | Re-test after fixes          | haiku     | 4o-mini         |
| REPORT   | Generate summary + CTO rpt   | haiku     | 4o-mini         |
| Other    | Health checks, DB ops, misc  | haiku     | 4o-mini         |

**Fallback trigger**: When Anthropic API returns `429` (rate limit / credits exhausted) or balance check fails, all subsequent calls in the cycle switch to OpenAI equivalents. The fallback is session-wide — once triggered, the entire remaining cycle uses OpenAI.

## Implementation Steps

### 1. Set up QA workspace on VPS

Create a dedicated directory for the QA runner outside of nanoclaw:

```
~/contably-qa/
├── contably-qa-runner.py     # Main orchestrator
├── config.yaml               # URLs, DB, model config
├── output/                   # Reports, logs per cycle
│   └── 2026-02-14_08-00/     # One dir per run
│       ├── discover.json     # Raw test results
│       ├── diagnose.json     # Root cause analysis
│       ├── fixes.json        # Applied fixes
│       ├── verify.json       # Verification results
│       └── report.md         # Final summary
├── .env                      # API keys, DB URL
└── requirements.txt          # Python deps
```

**`.env`:**

```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
QA_DATABASE_URL=postgresql://contably:***@10.0.2.46:5432/contably_db
QA_ADMIN_URL=https://staging.contably.ai
QA_PORTAL_URL=https://staging-portal.contably.ai
QA_API_URL=https://staging-api.contably.ai
CONTABLY_REPO=~/code/contably
```

**`requirements.txt`:**

```
anthropic>=0.40.0
openai>=1.50.0
pyyaml
psycopg2-binary
```

### 2. Build the orchestrator (`contably-qa-runner.py`)

Python script that orchestrates the full QA cycle using direct API calls. Key design:

**Model routing with fallback:**

```python
class ModelRouter:
    def __init__(self):
        self.anthropic = Anthropic()
        self.openai = OpenAI()
        self.use_openai = False  # Flips on credit exhaustion

    def call(self, role: str, prompt: str, system: str = "") -> str:
        model = self.get_model(role)
        try:
            if self.use_openai:
                return self._call_openai(model, prompt, system)
            return self._call_anthropic(model, prompt, system)
        except RateLimitError:
            self.use_openai = True
            model = self.get_model(role)  # Re-resolve to OpenAI model
            return self._call_openai(model, prompt, system)

    def get_model(self, role: str) -> str:
        if self.use_openai:
            return {"test": "gpt-4o-mini", "diagnose": "codex",
                    "fix": "gpt-4o", "report": "gpt-4o-mini"}[role]
        return {"test": "claude-haiku-4-5-20251001", "diagnose": "claude-opus-4-6",
                "fix": "claude-sonnet-4-5-20250929", "report": "claude-haiku-4-5-20251001"}[role]
```

**Phase execution:**

1. **DISCOVER** (haiku / 4o-mini): Run 5 personas in parallel. Each persona gets a prompt with their test workflows, staging URLs, and auth credentials. They test via curl + Playwright and report bugs via `qa_manager.py`.

2. **DIAGNOSE** (opus / codex): For each new issue found, opus reads the codebase, analyzes the bug, and produces a structured fix plan: what files to change, what the fix should be, and why.

3. **FIX** (sonnet / 4o): For each diagnosis, sonnet implements the code changes. It receives the diagnosis + relevant source files and outputs diffs/patches.

4. **VERIFY** (haiku / 4o-mini): Re-run the specific test cases that found the bugs. Mark issues as verified or failed in the DB.

5. **REPORT** (haiku / 4o-mini): Generate the CTO report and Discord summary from the DB.

**Tool use**: The orchestrator shells out to `qa_manager.py` for DB operations, `playwright` for browser tests, and `curl` for API tests. The LLM calls are for reasoning/analysis/code generation — the orchestrator handles all tool execution itself.

### 3. Give nanoclaw access

Nanoclaw needs three things:

**a) Trigger the QA runner:**

Add a trigger script that nanoclaw can call:

```bash
# ~/contably-qa/trigger.sh
#!/bin/bash
cd ~/contably-qa
nohup python contably-qa-runner.py --notify-file ~/contably-qa/output/latest/done.flag > ~/contably-qa/output/latest/runner.log 2>&1 &
echo $! > ~/contably-qa/runner.pid
echo "QA cycle started (PID: $(cat runner.pid))"
```

Nanoclaw's contably-qa group calls this via bash:

```bash
bash ~/contably-qa/trigger.sh
```

**b) Read the output directory:**

Mount `~/contably-qa/output/` into the nanoclaw container (read-only) so it can read reports:

- Add to mount allowlist: `~/contably-qa/output`
- Add to contably-qa group's `containerConfig.additionalMounts`

**c) Access the QA DB:**

Already available — nanoclaw has `QA_DATABASE_URL` in its env. It can run `qa_manager.py` queries to check status.

### 4. Update nanoclaw group config

Update `groups/contably-qa/register.json` to mount the QA output dir:

```json
{
  "name": "Contably QA",
  "folder": "contably-qa",
  "trigger": "@Andy",
  "requiresTrigger": false,
  "containerConfig": {
    "additionalMounts": [
      {
        "hostPath": "~/code/contably",
        "containerPath": "contably",
        "readonly": true
      },
      {
        "hostPath": "~/contably-qa/output",
        "containerPath": "qa-output",
        "readonly": true
      }
    ],
    "timeout": 1800000
  }
}
```

### 5. Update nanoclaw group CLAUDE.md

The contably-qa group's CLAUDE.md changes from "you are a QA tester" to "you can trigger and monitor the QA runner":

```markdown
# Contably QA Commander

You manage the Contably QA system. You can:

- Trigger QA cycles: `bash ~/contably-qa/trigger.sh`
- Check status: `cat ~/contably-qa/output/latest/runner.log`
- Read reports: `cat /workspace/extra/qa-output/report.md`
- Query the DB: `python /workspace/extra/contably/apps/api/scripts/qa_manager.py query open-issues`
- Post summaries to Discord via send_message

When asked to "run qa" or scheduled to run:

1. Trigger the QA runner
2. Monitor until complete (poll done.flag)
3. Read the report
4. Post summary to Discord
```

### 6. Scheduled QA via nanoclaw

Same cron setup as before — nanoclaw schedules it:

```json
{
  "type": "schedule_task",
  "prompt": "Trigger a QA cycle. Run ~/contably-qa/trigger.sh, wait for completion, then read the report and send the summary to Discord.",
  "schedule_type": "cron",
  "schedule_value": "0 8 * * 1-5",
  "context_mode": "isolated"
}
```

### 7. Install dependencies on VPS

On the VPS:

```bash
# QA workspace
mkdir -p ~/contably-qa/output
cd ~/contably-qa
pip install anthropic openai pyyaml psycopg2-binary

# Playwright for browser testing
pip install playwright
playwright install chromium

# Ensure contably repo is cloned
cd ~/code/contably && git pull
```

### 8. Discord summary format

Same as before — the nanoclaw agent reads the report and formats for Discord:

```
*QA Cycle Complete* - Feb 14, 2026

*Provider:* Anthropic (no fallback needed)
*Issues Found:* 3 new (1 P1-high, 2 P2-medium)
*Issues Fixed:* 2 (1 P1, 1 P2)
*Issues Verified:* 5 passed, 1 failed
*Regressions:* 0

*New Issues:*
- #42 P1: Login endpoint returns 500 on expired token → FIXED
- #43 P2: Client portal dashboard shows wrong date format → FIXED
- #44 P2: Missing pagination on transactions list → deferred

*Failed Verifications:*
- #38: Upload file still fails for PDFs > 5MB

Full report: ~/contably-qa/output/2026-02-14_08-00/report.md
```

## Files to Create/Modify

| File                                        | Action | Purpose                                         |
| ------------------------------------------- | ------ | ----------------------------------------------- |
| `~/contably-qa/contably-qa-runner.py`       | Create | Main orchestrator with model routing + fallback |
| `~/contably-qa/config.yaml`                 | Create | Staging URLs, persona defs, test workflows      |
| `~/contably-qa/.env`                        | Create | API keys + DB URL                               |
| `~/contably-qa/trigger.sh`                  | Create | Entry point script for nanoclaw                 |
| `~/contably-qa/requirements.txt`            | Create | Python deps                                     |
| `nanoclaw/groups/contably-qa/CLAUDE.md`     | Modify | Change from tester to commander                 |
| `nanoclaw/groups/contably-qa/register.json` | Modify | Add QA output mount                             |
| `~/.config/nanoclaw/mount-allowlist.json`   | Modify | Allow QA output dir                             |

## Verification

1. **Direct test**: SSH into VPS, run `python ~/contably-qa/contably-qa-runner.py` manually. Check output dir for reports.
2. **Fallback test**: Temporarily set invalid ANTHROPIC_API_KEY, run again — should fall back to OpenAI.
3. **Nanoclaw trigger**: Send `@Andy run qa` in Discord → agent triggers runner → waits → posts report.
4. **Cron test**: Set a 5-min interval, verify automated execution + Discord report.
5. **DB check**: Verify issues created in `qa` schema via `qa_manager.py query open-issues`.

## Cost Estimate (per cycle)

| Phase                 | Model     | ~Tokens              | ~Cost      |
| --------------------- | --------- | -------------------- | ---------- |
| DISCOVER (5 personas) | haiku × 5 | 50k in + 10k out × 5 | ~$0.15     |
| DIAGNOSE (per issue)  | opus      | 30k in + 5k out × 3  | ~$1.35     |
| FIX (per issue)       | sonnet    | 20k in + 5k out × 3  | ~$0.45     |
| VERIFY                | haiku × 5 | 20k in + 5k out × 5  | ~$0.08     |
| REPORT                | haiku     | 10k in + 3k out      | ~$0.02     |
| **Total**             |           |                      | **~$2.05** |

With OpenAI fallback, costs would be similar or slightly lower.
