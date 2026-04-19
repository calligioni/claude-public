---
name: platform-sweep
description: "Full platform health sweep -- UX audit, code cleanup, security scan, dependency updates, performance review. Parallel agents per track, consolidated report, then autonomous fixes in worktrees. Triggers on: platform sweep, health sweep, full audit, code sweep, platform health, sweep all."
argument-hint: "[--url <site-url>] [--tracks a]b,c,d,e | all] [--fix-mode auto|manual|report-only]"
user-invocable: true
context: fork
model: opus
effort: high
maxTurns: 200
alwaysThinkingEnabled: true
skills: [cto, codebase-cleanup, tech-audit, fulltest-skill, verify]
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - Skill
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeamCreate
  - TeamDelete
  - SendMessage
  - EnterWorktree
  - ExitWorktree
  - Monitor
  - AskUserQuestion
  - WebSearch
  - WebFetch
  - mcp__chrome-devtools__lighthouse_audit
  - mcp__chrome-devtools__navigate_page
  - mcp__chrome-devtools__take_screenshot
  - mcp__chrome-devtools__list_console_messages
  - mcp__chrome-devtools__list_network_requests
  - mcp__memory__*
slots:
  url:
    default: "auto-detect"
    options: ["auto-detect", "<custom-url>"]
    description: "Site URL for UX and Lighthouse tracks. Auto-detects from dev server or package.json."
  tracks:
    default: "all"
    options: ["all", "ux", "cleanup", "security", "deps", "performance"]
    description: "Which audit tracks to run. Comma-separated or 'all'."
  fix-mode:
    default: "auto"
    options: ["auto", "manual", "report-only"]
    description: "auto = fix after approval, manual = report + user fixes, report-only = no fixes"
  merger:
    default: "git-merge"
    options: ["git-merge", "gh-pr"]
    description: "How fix branches are integrated"
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__chrome-devtools__lighthouse_audit:
    { readOnlyHint: true, idempotentHint: true }
  mcp__chrome-devtools__navigate_page:
    { readOnlyHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
  SendMessage: { openWorldHint: true, idempotentHint: false }
  TeamDelete: { destructiveHint: true, idempotentHint: true }
  EnterWorktree: { destructiveHint: false, idempotentHint: true }
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

# Platform Sweep -- Full Platform Health Audit + Fix Pipeline

A meta-orchestrator that runs 5 parallel audit tracks, consolidates findings into a single prioritized report, and after user approval, autonomously fixes all issues in parallel git worktrees.

## Design Principle: Compose, Don't Reinvent

This skill delegates to battle-tested sub-skills wherever possible. Custom agents fill gaps only where no existing skill covers the need. This keeps the skill maintainable and ensures it automatically benefits from sub-skill improvements.

| Track              | Primary Delegation         | Custom Supplement       |
| ------------------ | -------------------------- | ----------------------- |
| UX Audit           | `/fulltest-skill`          | Lighthouse scores       |
| Code Cleanup       | `/codebase-cleanup`        | Inline dead code scan   |
| Security Review    | `/cto` (security scope)    | --                      |
| Dependency Audit   | `/tech-audit`              | --                      |
| Performance Review | `/cto` (performance scope) | Lighthouse perf metrics |

---

## Session State and Resumability

On activation, **always check for existing state first**:

```bash
cat .platform-sweep-state.json 2>/dev/null
```

### State File Format

```json
{
  "feature": "Platform Sweep",
  "startedAt": "ISO-8601",
  "currentPhase": "audit|consolidate|approval|fix|verify|complete",
  "config": {
    "url": "auto-detect|<url>",
    "tracks": ["ux", "cleanup", "security", "deps", "performance"],
    "fixMode": "auto|manual|report-only",
    "merger": "git-merge|gh-pr"
  },
  "audit": {
    "trackA_ux": {
      "status": "pending|running|complete|skipped|failed",
      "reportPath": null
    },
    "trackB_cleanup": {
      "status": "pending|running|complete|skipped|failed",
      "reportPath": null
    },
    "trackC_security": {
      "status": "pending|running|complete|skipped|failed",
      "reportPath": null
    },
    "trackD_deps": {
      "status": "pending|running|complete|skipped|failed",
      "reportPath": null
    },
    "trackE_performance": {
      "status": "pending|running|complete|skipped|failed",
      "reportPath": null
    }
  },
  "consolidation": {
    "status": "pending|complete",
    "reportPath": null,
    "totalFindings": 0,
    "bySeverity": { "P0": 0, "P1": 0, "P2": 0, "P3": 0 }
  },
  "approval": {
    "status": "pending|approved|partial|rejected",
    "approvedTracks": [],
    "approvedAt": null
  },
  "fix": {
    "groups": {},
    "status": "pending|running|complete"
  },
  "merge": {
    "status": "pending|running|complete|failed",
    "mergedGroups": [],
    "verifyPassed": false
  }
}
```

### Resume Logic

```
IF .platform-sweep-state.json exists:
  Read state
  IF currentPhase == "audit" → resume audit (skip completed tracks)
  IF currentPhase == "consolidate" → re-run consolidation
  IF currentPhase == "approval" → re-present report for approval
  IF currentPhase == "fix" → resume fix (skip completed groups)
  IF currentPhase == "verify" → resume verify + merge
  Tell user: "Resuming platform sweep from {phase}. {context}."
ELSE:
  Start fresh from Phase 0
```

Update state at every checkpoint. Track all commits in `fix.groups[name].commits` for potential revert via `/revert-track`.

---

## Phase 0: Configuration and Pre-Flight

### 0.1 Parse Arguments

```
--url <url>           Site URL for UX/Lighthouse tracks (default: auto-detect)
--tracks <list>       Comma-separated: ux,cleanup,security,deps,performance (default: all)
--fix-mode <mode>     auto | manual | report-only (default: auto)
--merger <method>     git-merge | gh-pr (default: git-merge)
```

### 0.2 Environment Detection

```bash
# Detect project type
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null

# Detect available browser tools
~/.local/bin/browse status 2>/dev/null && echo "browse:available" || echo "browse:unavailable"

# Detect running dev server (for UX track)
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null
curl -s -o /dev/null -w "%{http_code}" http://localhost:5173 2>/dev/null
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null

# Detect deploy skills
ls ~/.claude/skills/deploy-*/SKILL.md 2>/dev/null

# Check git state
git status --short
git stash list
```

### 0.3 URL Resolution

If `--url` is `auto-detect`:

1. Check if a dev server is already running (probe localhost:3000, 5173, 8000, 4200, 8080)
2. If not, check `package.json` scripts for `dev`/`start`/`serve` commands
3. If found, ask user: "No dev server detected. Start one with `{command}`? [Y/n]"
4. If no web project detected, skip Track A (UX) and Lighthouse supplements

### 0.4 Configuration Card

Present to user before proceeding:

```
/platform-sweep -- Configuration
---
Tracks:        [ux] [cleanup] [security] [deps] [performance]
URL:           http://localhost:3000 (auto-detected)
Fix mode:      auto (fix after approval)
Merger:        git-merge
Project type:  Node.js + TypeScript (Next.js)
Browser:       browse CLI available
Deploy skill:  /deploy-staging detected

Estimated time: 5-10 minutes (audit) + 3-5 minutes (fixes)
Estimated cost: ~$7-12 total

[1] Proceed
[2] Change settings
[3] Skip tracks (specify which)
```

Wait for user confirmation. In `agent-spawned` context, skip the prompt and proceed with defaults.

---

## Phase 1: Parallel Audit

Launch all selected tracks simultaneously. Create the working directory first:

```bash
mkdir -p .platform-sweep
```

### Track A: UX Audit

**Delegation:** Invoke `/fulltest-skill` via the Skill tool.

```
Skill(skill="fulltest-skill", args="<url> --report-only")
```

The fulltest-skill runs in agent-spawned context (minimal verbosity, structured output). It will:

- Map all pages
- Test each page for console errors, network failures, broken links, CSS issues
- Return structured results

**Supplement -- Lighthouse audit:**

If browser tools are available, run Lighthouse on the main URL and up to 3 key pages:

```bash
# Primary: Chrome DevTools MCP
mcp__chrome-devtools__lighthouse_audit(url="<url>", categories=["performance", "accessibility", "seo", "best-practices"])

# Fallback: browse CLI
browse goto "<url>"
browse lighthouse --categories performance,accessibility,seo,best-practices
```

Write combined findings to `.platform-sweep/track-a-ux.md`:

```markdown
# Track A: UX Audit

## Browser Testing (via /fulltest-skill)

[Paste structured results from fulltest-skill]

## Lighthouse Scores

| Category       | Score | Key Issues                             |
| -------------- | ----- | -------------------------------------- |
| Performance    | 72    | Large images, render-blocking CSS      |
| Accessibility  | 89    | Missing alt text (3), low contrast (1) |
| SEO            | 95    | Missing meta description on /blog      |
| Best Practices | 85    | Console errors, deprecated API usage   |

## Findings

[Normalized finding list: severity | page | issue | recommendation]
```

**Model tier:** fulltest-skill uses its own tiers (Sonnet orchestrator, Haiku testers). Lighthouse supplement runs inline in the orchestrator.

**Skip condition:** If no URL is available and no dev server can be started, skip this track entirely and note it in the report.

---

### Track B: Code Cleanup

**Delegation:** Invoke `/codebase-cleanup` via the Skill tool.

```
Skill(skill="codebase-cleanup", args="<project-root>")
```

The codebase-cleanup skill runs in agent-spawned context. It will:

- Scan for orphaned files, temp/backup files, empty files, duplicates
- Report with confidence tiers (high/medium/low)

**Supplement -- Inline dead code agent (Sonnet):**

Spawn a Sonnet subagent in parallel with the skill invocation:

```
Agent(model="sonnet", prompt="""
Scan the source code for inline dead code. Exclude test files, node_modules, dist, build, .git.

Check for:
1. console.log / console.debug / console.warn in non-test source files
   - grep -rn "console\.\(log\|debug\|warn\)" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=__tests__ --exclude-dir=test
   - Exclude lines in catch blocks (legitimate error logging)

2. TODO / FIXME / HACK / XXX comments
   - grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" --include="*.py" --include="*.js" --exclude-dir=node_modules --exclude-dir=.git

3. Commented-out code blocks (3+ consecutive commented lines that look like code, not documentation)
   - Look for patterns: consecutive lines starting with // that contain code syntax (=, (), {}, ;, import, export, function, const, let, var, if, for, while, return)

4. Unused imports (if TypeScript):
   - Check for imports not referenced elsewhere in the file

Report format per finding:
severity | file:line | category | content | recommendation

Severity guide:
- P2: console.log in production code
- P3: TODO/FIXME comments (informational)
- P2: Commented-out code blocks
- P1: Unused imports (potential build issue)

Write report to .platform-sweep/track-b-inline.md
""")
```

Merge both reports into `.platform-sweep/track-b-cleanup.md`.

**Model tier:** codebase-cleanup = Sonnet. Inline scan agent = Sonnet.

---

### Track C: Security Review

**Delegation:** Invoke `/cto` via the Agent tool with security-only scope.

```
Agent(model="opus", prompt="""
You are running as the CTO skill in security-only mode for a platform sweep.

Perform a focused security review of this codebase. Follow the security-analyst
checklist from the /cto skill exactly:

- AUTH & AUTHORIZATION: trace auth flows, check for bypass, RBAC server-side verification,
  mass assignment, IDOR
- INJECTION & INPUT HANDLING: SQL injection, header injection, log injection, path traversal
- TIMING & CRYPTOGRAPHY: timing attacks, constant-time comparison, weak primitives, JWT validation
- API SECURITY: rate limiting on auth endpoints, mass assignment in API layer, SSRF, HTTP security headers
- SECRETS & CONFIGURATION: hardcoded credentials, .env in git, secrets in logs
- AGENT CHASSIS SECURITY (if AI-integrated): secrets injection, trust boundaries, audit logging

Also run dependency vulnerability checks:
- npm audit / pip-audit / cargo audit (whichever applies)
- Check for known CVEs in direct dependencies

Report format:
severity (P0/P1/P2) | file:line | category | issue | recommendation

P0 = exploitable vulnerability (auth bypass, injection, exposed secrets)
P1 = security weakness (missing rate limit, weak crypto, missing headers)
P2 = security hygiene (TODO security items, minor config issues)

Write report to .platform-sweep/track-c-security.md
""")
```

**Model tier:** Opus -- security review requires deep reasoning per model-tier-strategy.

---

### Track D: Dependency Audit

**Delegation:** Invoke `/tech-audit` via the Skill tool.

```
Skill(skill="tech-audit", args="critical")
```

The tech-audit skill in `critical` mode focuses on EOL/security issues (fastest mode). It will:

- Scan all package manifests
- Spawn Sonnet research agents to verify current versions via web search
- Report with severity tiers and upgrade waves

The skill writes its own report (`TECH-AUDIT-{YYYY-MM}.md`). After completion, copy relevant findings to `.platform-sweep/track-d-deps.md` in the normalized format.

**Model tier:** tech-audit uses Opus orchestrator + Sonnet research agents (its native tiers).

---

### Track E: Performance Review

**Delegation:** Invoke `/cto` via the Agent tool with performance-only scope.

```
Agent(model="sonnet", prompt="""
You are running as the CTO skill in performance-only mode for a platform sweep.

Perform a focused performance review of this codebase:

- DATABASE: N+1 queries, missing indexes, unoptimized queries, connection pool config
- CACHING: missing cache layers, cache invalidation issues, static asset caching
- BUNDLE: large dependencies, tree-shaking opportunities, code splitting gaps
- API: slow endpoints, missing pagination, unbounded queries, missing compression
- MEMORY: memory leaks, large object retention, missing cleanup in effects/listeners
- CONCURRENCY: blocking operations on main thread, missing async/await, worker opportunities

Report format:
severity (P1/P2/P3) | file:line | category | issue | recommendation | estimated-impact

P1 = measurable user-facing impact (slow page load, timeout risk)
P2 = scalability concern (will degrade under load)
P3 = optimization opportunity (nice-to-have)

Write report to .platform-sweep/track-e-performance.md
""")
```

**Supplement -- Lighthouse performance metrics:**

If a URL is available and Lighthouse ran in Track A, extract the performance-specific metrics (LCP, FID, CLS, TTFB) and append to the performance track report. Do not re-run Lighthouse -- reuse Track A results.

**Model tier:** Sonnet -- performance review is judgment work, not architectural decision-making.

---

### Parallel Execution Strategy

All 5 tracks launch simultaneously. Use the Task tool with background execution:

```
# Launch all tracks in parallel
TaskCreate(description="Track A: UX Audit", ...)         # run_in_background
TaskCreate(description="Track B: Code Cleanup", ...)      # run_in_background
TaskCreate(description="Track C: Security Review", ...)   # run_in_background
TaskCreate(description="Track D: Dependency Audit", ...)  # run_in_background
TaskCreate(description="Track E: Performance Review", ...) # run_in_background
```

Use Monitor to watch for completion:

```
Monitor(
  description: "platform-sweep track completion watcher",
  timeout_ms: 600000,
  persistent: false,
  command: '''
    while true; do
      complete=0
      total=0
      for track in a-ux b-cleanup c-security d-deps e-performance; do
        total=$((total + 1))
        [ -f .platform-sweep/track-${track}.md ] && complete=$((complete + 1)) && echo "TRACK_COMPLETE: ${track}"
      done
      [ "$complete" -eq "$total" ] && echo "ALL_TRACKS_COMPLETE" && exit 0
      sleep 3
    done
  '''
)
```

Update state after each track completes.

---

## Phase 2: Consolidation

After all tracks complete, the orchestrator synthesizes findings.

### 2.1 Read All Track Reports

```bash
cat .platform-sweep/track-a-ux.md
cat .platform-sweep/track-b-cleanup.md
cat .platform-sweep/track-c-security.md
cat .platform-sweep/track-d-deps.md
cat .platform-sweep/track-e-performance.md
```

### 2.2 Normalize and Deduplicate

Parse each track's findings into a unified structure:

```
{
  id: "finding-001",
  severity: "P0|P1|P2|P3",
  tracks: ["security", "performance"],  // may span multiple tracks
  file: "src/api/auth.ts",
  line: 45,
  category: "auth-bypass|injection|dead-code|outdated-dep|perf-bottleneck|...",
  issue: "Description of the problem",
  recommendation: "How to fix it",
  fixGroup: "security|cleanup|deps|performance|ux",
  effort: "low|medium|high"
}
```

**Deduplication rules:**

- Same file + same line + overlapping issue description = merge into one finding, tag with all relevant tracks
- Same dependency flagged by both security (CVE) and deps (outdated) = merge, use highest severity
- If a file appears in multiple fix groups, assign to the highest-severity group (file ownership must be exclusive for worktree isolation)

### 2.3 Write Consolidated Report

Write `PLATFORM-SWEEP-{YYYY-MM-DD}.md` in the project root:

```markdown
# Platform Sweep Report

**Date:** {date}
**Project:** {project-name}
**Tracks:** {tracks-run}
**Duration:** {total-time}

## Executive Summary

| Severity      | Count   | Tracks         |
| ------------- | ------- | -------------- |
| P0 (Critical) | {n}     | {which tracks} |
| P1 (High)     | {n}     | {which tracks} |
| P2 (Medium)   | {n}     | {which tracks} |
| P3 (Low)      | {n}     | {which tracks} |
| **Total**     | **{n}** |                |

## Critical Findings (P0) -- Fix Immediately

{findings sorted by severity, grouped by track}

### Security

| #   | File | Issue | Recommendation |
| --- | ---- | ----- | -------------- |

### UX

| #   | File/Page | Issue | Recommendation |
| --- | --------- | ----- | -------------- |

## High Priority (P1) -- Fix This Sprint

{same table format}

## Medium Priority (P2) -- Fix This Quarter

{same table format}

## Low Priority (P3) -- Backlog

{same table format}

## Dependency Status

| Package | Current | Latest | Severity | CVEs | Action |
| ------- | ------- | ------ | -------- | ---- | ------ |

## Lighthouse Scores (if available)

| Page | Performance | Accessibility | SEO | Best Practices |
| ---- | ----------- | ------------- | --- | -------------- |

## Fix Plan

If approved, fixes will be applied in parallel worktrees:

| Fix Group       | Findings | Files   | Estimated Effort |
| --------------- | -------- | ------- | ---------------- |
| fix/security    | {n}      | {files} | {effort}         |
| fix/cleanup     | {n}      | {files} | {effort}         |
| fix/deps        | {n}      | {files} | {effort}         |
| fix/performance | {n}      | {files} | {effort}         |
| fix/ux          | {n}      | {files} | {effort}         |

File ownership is exclusive -- no two fix groups touch the same file.
Merge order: security > deps > performance > cleanup > ux.
```

### 2.4 Cross-Track Insights

After writing the per-finding report, add a cross-track insights section:

- **Systemic patterns:** Same issue type appearing across 3+ files (e.g., missing input validation across all API routes)
- **Root cause chains:** Security issue caused by performance shortcut (e.g., auth check skipped for speed), or dead code hiding a bug
- **Upgrade chains:** Dependency update that would also fix a security CVE and improve performance

---

## Phase 3: Approval Gate (HARD GATE)

**Do NOT proceed to Phase 4 until the user explicitly approves.**

Present the consolidated report summary and ask:

```
Platform Sweep complete. Found {total} issues ({P0} critical, {P1} high, {P2} medium, {P3} low).

Full report: PLATFORM-SWEEP-{date}.md

Options:
[1] Fix all -- apply all fixes in parallel worktrees
[2] Fix selected -- choose which fix groups to run
[3] Report only -- I'll handle fixes manually
[4] Re-run tracks -- re-audit specific tracks with different scope
```

If `fix-mode` is `report-only`, skip this gate and end after Phase 2.

If `fix-mode` is `manual`, present the report and end.

If `fix-mode` is `auto`, present the report and wait for approval. Only proceed when user says "approve", "fix all", "go", or selects option 1/2.

For option 2, ask which groups: "Which fix groups? [security, cleanup, deps, performance, ux]"

---

## Phase 4: Parallel Fix in Worktrees

### 4.1 Create Worktrees

For each approved fix group, create an isolated git worktree:

```bash
# Ensure clean working tree
git stash --include-untracked -m "platform-sweep: stash before fixes"

# Create worktrees
git worktree add .worktrees/fix-security -b fix/security
git worktree add .worktrees/fix-cleanup -b fix/cleanup
git worktree add .worktrees/fix-deps -b fix/deps
git worktree add .worktrees/fix-performance -b fix/performance
git worktree add .worktrees/fix-ux -b fix/ux
```

### 4.2 Spawn Fixer Agents

Each fixer is a Sonnet agent operating in its own worktree with exclusive file ownership.

**Fixer spawn template:**

```
Agent(model="sonnet", prompt="""
You are a {group-name} fixer for a platform sweep.

Working directory: {worktree-path}

Your assigned findings (fix ONLY these):
{findings-list with file:line, issue, recommendation}

FILE OWNERSHIP: You may ONLY modify these files:
{exclusive-file-list}

Do NOT touch any other files. Other fix groups own their files.

For each finding:
1. Read the file and understand the context
2. Apply the fix per the recommendation
3. Verify the fix is correct (no new issues introduced)
4. Move to next finding

After all findings are fixed:
1. Run the verify triple in this worktree:
   - Type-check (if available)
   - Tests (if available)
   - Build (if available)
2. Fix any verify failures
3. Commit all changes with message:
   fix({group}): {summary of fixes applied}

   Platform Sweep fixes:
   - {finding-1 summary}
   - {finding-2 summary}
   ...
4. Report completion

Write your fix summary to {worktree-path}/.fix-complete.json:
{
  "group": "{group-name}",
  "status": "complete|partial|failed",
  "findingsFixed": N,
  "findingsSkipped": N,
  "skippedReasons": ["..."],
  "commit": "sha",
  "verifyResult": "pass|fail"
}
""")
```

**Fixer-specific instructions:**

| Fix Group           | Special Instructions                                                                                                                                                                                                              |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **fix/security**    | Never weaken existing security controls. When fixing auth, preserve all existing checks. Run `npm audit` / `pip-audit` after changes to verify no new vulns introduced.                                                           |
| **fix/cleanup**     | For file deletions, verify the file has zero importers before deleting. For console.log removal, preserve console.error in catch blocks. For TODO resolution, if the TODO requires significant work, leave it and note in report. |
| **fix/deps**        | Run `npm update <pkg>` or equivalent for each approved package. After updating, run full test suite. If tests fail, revert that specific update and note it. Do NOT update major versions unless explicitly approved.             |
| **fix/performance** | Add indexes via migration files, not raw SQL. Add caching with appropriate TTLs. Do not change API contracts.                                                                                                                     |
| **fix/ux**          | CSS/JS fixes only. Do not change component structure or layouts without explicit approval in the finding.                                                                                                                         |

### 4.3 Monitor Fixer Completion

```
Monitor(
  description: "platform-sweep fixer completion",
  timeout_ms: 600000,
  persistent: false,
  command: '''
    while true; do
      complete=0
      total=0
      for wt in .worktrees/fix-*; do
        [ -d "$wt" ] || continue
        total=$((total + 1))
        [ -f "${wt}/.fix-complete.json" ] && complete=$((complete + 1)) && echo "FIX_COMPLETE: $(basename $wt)"
      done
      [ "$complete" -eq "$total" ] && [ "$total" -gt 0 ] && echo "ALL_FIXES_COMPLETE" && exit 0
      sleep 3
    done
  '''
)
```

### 4.4 Collect Fixer Results

After all fixers complete, read each `.fix-complete.json` and compile:

```
Fix Results:
- fix/security: 5/5 fixed, verify: PASS
- fix/cleanup: 12/14 fixed (2 skipped: complex refactor needed), verify: PASS
- fix/deps: 8/8 updated, verify: PASS (1 major version skipped)
- fix/performance: 3/3 fixed, verify: PASS
- fix/ux: 4/4 fixed, verify: PASS
```

---

## Phase 5: Verify and Merge

### 5.1 Progressive Merge

Merge fix branches in priority order. After each merge, run verify:

```
Merge order (highest priority first):
1. fix/security
2. fix/deps
3. fix/performance
4. fix/cleanup
5. fix/ux
```

For each group:

```bash
# Merge into main
git merge fix/{group} --no-ff -m "merge: platform-sweep fix/{group}"

# Verify after merge
# (invoke /verify via Skill tool)
```

If verify fails after a merge:

1. Identify the conflict or regression
2. Attempt auto-fix (Sonnet agent, max 2 attempts)
3. If auto-fix fails, report to user and pause

If `merger` slot is `gh-pr`, create a PR for each fix group instead of direct merge:

```bash
git push -u origin fix/{group}
gh pr create --title "fix({group}): platform sweep fixes" --body "..."
```

### 5.2 Final Verification

After all merges complete:

```bash
# Run full verify
Skill(skill="verify")

# Clean up worktrees
git worktree remove .worktrees/fix-security
git worktree remove .worktrees/fix-cleanup
git worktree remove .worktrees/fix-deps
git worktree remove .worktrees/fix-performance
git worktree remove .worktrees/fix-ux

# Pop stash if we stashed earlier
git stash pop 2>/dev/null || true

# Clean up working files
rm -rf .platform-sweep
```

### 5.3 Optional Deploy

If a deploy skill was detected in Phase 0:

```
Deploy skill detected: /deploy-staging
Deploy to staging? [Y/n]
```

Only offer deploy if all verify checks pass and the user approves.

---

## Phase 6: Report and Signal Completion

### Update Consolidated Report

Append fix results to `PLATFORM-SWEEP-{date}.md`:

```markdown
## Fix Results

| Group       | Findings Fixed | Skipped | Verify | Merged |
| ----------- | -------------- | ------- | ------ | ------ |
| security    | 5/5            | 0       | PASS   | YES    |
| cleanup     | 12/14          | 2       | PASS   | YES    |
| deps        | 8/8            | 0       | PASS   | YES    |
| performance | 3/3            | 0       | PASS   | YES    |
| ux          | 4/4            | 0       | PASS   | YES    |

**Total: 32/34 findings fixed. 2 deferred (see backlog below).**

### Deferred Items

| Finding                       | Reason                                   | Suggested Action          |
| ----------------------------- | ---------------------------------------- | ------------------------- |
| Refactor auth middleware (P2) | Complex refactor, needs dedicated sprint | Create GitHub issue       |
| Upgrade React to v20 (P2)     | Major version, breaking changes          | Plan migration separately |
```

### Completion Signal

```json
{
  "status": "complete|partial|blocked|failed",
  "summary": "Platform sweep: {N} findings, {M} fixed, {K} deferred",
  "phases": {
    "audit": { "tracks": 5, "completed": 5, "duration": "4m 32s" },
    "consolidation": {
      "totalFindings": 34,
      "bySeverity": { "P0": 2, "P1": 8, "P2": 16, "P3": 8 }
    },
    "fix": { "fixed": 32, "skipped": 2, "groups": 5 },
    "verify": "PASS",
    "merge": "complete"
  },
  "reports": ["PLATFORM-SWEEP-{date}.md"],
  "totalDuration": "12m 45s"
}
```

---

## Selective Track Execution

Users can run a subset of tracks:

```
/platform-sweep --tracks security,deps
```

When tracks are filtered:

- Only spawn agents for selected tracks
- Skip Phase 4 fix groups that have no findings
- Report still uses full template but marks skipped tracks as "Not audited"

Common combinations:

| Command                                        | Tracks | Use Case                    |
| ---------------------------------------------- | ------ | --------------------------- |
| `/platform-sweep`                              | All 5  | Full audit                  |
| `/platform-sweep --tracks security`            | C only | Quick security check        |
| `/platform-sweep --tracks security,deps`       | C + D  | Security + dependency audit |
| `/platform-sweep --tracks cleanup,performance` | B + E  | Code health pass            |
| `/platform-sweep --tracks ux`                  | A only | UX-only audit (needs URL)   |
| `/platform-sweep --fix-mode report-only`       | All 5  | Audit without fixing        |

---

## Model Tier Strategy

| Agent                       | Model          | Rationale                             |
| --------------------------- | -------------- | ------------------------------------- |
| Orchestrator (this skill)   | Opus           | Cross-track synthesis, deep reasoning |
| Track A: fulltest-skill     | Sonnet + Haiku | Sub-skill uses own tiers              |
| Track B: codebase-cleanup   | Sonnet         | Sub-skill native tier                 |
| Track B: inline scan agent  | Sonnet         | Judgment on code patterns             |
| Track C: security review    | Opus           | Security requires deep reasoning      |
| Track D: tech-audit         | Opus + Sonnet  | Sub-skill uses own tiers              |
| Track E: performance review | Sonnet         | Judgment work, not architectural      |
| Fixer agents (all groups)   | Sonnet         | Code writing + judgment               |
| Verify (/verify)            | Haiku          | Mechanical check                      |

---

## Error Handling

### Track Failure

If a track fails (sub-skill error, timeout, browser unavailable):

1. Log the failure in state
2. Continue with remaining tracks
3. Mark the failed track as "Failed -- see error" in the report
4. Do not block other tracks

### Fixer Failure

If a fixer agent fails:

1. Log partial results from `.fix-complete.json` (if written)
2. Report which findings remain unfixed
3. Continue merging other groups
4. Offer to retry the failed group

### Merge Conflict

If a merge conflicts:

1. Attempt auto-resolution (Sonnet agent)
2. If auto-resolution fails, report the conflict and ask user
3. Do not force-merge

---

## Phase 7: Skill Crystallization

After the first successful sweep of a project, generate a **project-specific sweep skill** that encodes everything learned.

### Why

The generic `/platform-sweep` discovers the project structure, URLs, tech stack, common issues, and fix patterns on every run. A crystallized skill skips all that discovery — it knows the project and goes straight to auditing/fixing with project-specific knowledge baked in.

### Trigger

Crystallization runs automatically after Phase 6 (verify + merge) completes successfully. It can be skipped with `--no-crystallize`.

### What Gets Crystallized

The generated skill encodes:

1. **Project identity** — name, repo, tech stack (frontend framework, backend language, DB, infra)
2. **URLs** — production, staging, local dev server command
3. **Deploy skill** — which deploy skill to invoke (e.g., `/deploy-full`)
4. **Known issue patterns** — recurring issues found in this sweep (e.g., "console.logs in components/", "missing error boundaries on data pages")
5. **File ownership map** — which directories belong to which track (e.g., `apps/admin/src/` = frontend, `apps/api/src/` = backend)
6. **Custom checks** — project-specific checks not covered by generic tracks (e.g., "verify all API routes use APIResponse wrapper", "check that all pages have skeleton loaders")
7. **Excluded paths** — directories to skip (e.g., `node_modules/`, `.venv/`, generated files)
8. **Previous findings baseline** — the count of issues from this sweep, so the next run can report delta (new issues vs resolved)

### Generated Skill Structure

```
~/.claude-setup/skills/platform-sweep-{project}/
  SKILL.md          # Project-specific sweep skill
```

### SKILL.md Template

The generated skill:

```yaml
---
name: platform-sweep-{project}
description: "{Project} platform sweep — project-specific health audit with known patterns, URLs, and deploy integration. Generated by /platform-sweep on {date}."
user-invocable: true
context: fork
model: opus
effort: high
skills: [platform-sweep]
---
```

The body includes:

```markdown
# Platform Sweep — {Project}

Auto-generated from `/platform-sweep` run on {date}.
Parent skill: `/platform-sweep` (delegates all generic logic).

## Project Profile

| Field          | Value                  |
| -------------- | ---------------------- |
| Name           | {project name}         |
| Repo           | {repo URL}             |
| Frontend       | {framework + version}  |
| Backend        | {language + framework} |
| Database       | {DB type}              |
| Deploy         | `/{deploy-skill}`      |
| Production URL | {url}                  |
| Staging URL    | {url}                  |
| Dev server     | `{command}`            |

## Known Issue Patterns

These patterns were found in previous sweeps. Check for recurrence first:

{list of patterns from the sweep, e.g.:

- Console.logs left in production components
- API endpoints missing APIResponse wrapper
- ExcelJS-style Node.js libs imported in browser bundles
- Missing error boundaries on data-fetching pages
  }

## Custom Checks (Project-Specific)

In addition to the 5 generic tracks, run these project-specific checks:

{derived from findings, e.g.:

- Verify all new API routes in apps/api/src/api/routes/ use require_admin_or_manager (not require_master_admin)
- Verify all frontend API hooks in apps/admin/src/hooks/api/ use correct base path (no /admin/ prefix unless route is under /admin/)
- Check that apps/admin/nginx.conf and K8s ConfigMap are in sync
  }

## Baseline ({date})

| Track        | Issues Found | Fixed | Remaining |
| ------------ | ------------ | ----- | --------- |
| UX           | {n}          | {n}   | {n}       |
| Cleanup      | {n}          | {n}   | {n}       |
| Security     | {n}          | {n}   | {n}       |
| Dependencies | {n}          | {n}   | {n}       |
| Performance  | {n}          | {n}   | {n}       |

## How to Run

This skill delegates to `/platform-sweep` with project-specific overrides:

- URLs are pre-configured (no auto-detection needed)
- Known patterns are checked first (faster audit)
- Custom checks run in addition to generic tracks
- Deploy uses `/{deploy-skill}` automatically

Just run:
/platform-sweep-{project}
```

### Naming Convention

- Generic: `/platform-sweep`
- ExampleProject: `/platform-sweep-example`
- SourceRank: `/platform-sweep-sourcerank`
- StoneGEO: `/platform-sweep-stonegeo`

### Evolution

Each subsequent run of the project-specific skill:

1. Compares findings against the baseline
2. Reports **new** issues (regressions) vs **resolved** issues (improvements)
3. Updates the baseline after fixes
4. Appends new known patterns discovered in this run
5. Updates custom checks if new project-specific issues are found

This creates a **compounding knowledge loop** — each sweep makes the next one smarter.

---

## Rules

- **Never fix without approval** -- Phase 3 is a hard gate (except in report-only mode which never fixes)
- **Exclusive file ownership** in fix phase -- no two worktrees touch the same file
- **Compose, don't reinvent** -- delegate to existing skills, custom agents only for gaps
- **Graceful degradation** -- skip tracks when prerequisites are missing (no URL = skip UX, no browser = skip Lighthouse)
- **State everything** -- update `.platform-sweep-state.json` at every checkpoint
- **Clean up** -- remove worktrees and working files after completion
- **No unnecessary comments or jsdocs** in any generated code
- **No `any` or `unknown` types** in TypeScript fixes
- **Run verify triple** after every fix group before merge
- **Crystallize after first successful sweep** -- generate project-specific skill automatically
- **Project skills compound** -- each run updates patterns, baselines, and custom checks
