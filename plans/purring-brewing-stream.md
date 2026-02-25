# Setup Optimization: Boris Cherny Patterns

Based on Boris Cherny's (Claude Code creator) workflow patterns vs our current setup.

**Core insight**: Boris's setup is "surprisingly vanilla" — 5 agents, 5 commands, minimal hooks. Our setup has 22 skills + 13 agents. The gap isn't missing complexity — it's missing the simple, high-frequency patterns that Boris uses daily.

---

## 1. ACTIVATE PostToolUse Formatting Hook (Quick Win)

The `format-file.sh` hook exists but isn't wired into settings.json.

**File**: `~/.claude-setup/settings.json`

Add to `hooks` section:
```json
"PostToolUse": [
  {
    "matcher": "Write|Edit|NotebookEdit",
    "hooks": [
      {
        "type": "command",
        "command": "\"$HOME/.claude-setup/hooks/format-file.sh\""
      }
    ]
  }
]
```

---

## 2. CREATE New Daily Workflow Skills

### 2a. `/verify` — Verify project health after changes

**File**: `~/.claude-setup/skills/verify/SKILL.md`

- Detect project type from package.json/go.mod/etc.
- Run type-check (`tsc --noEmit`)
- Run test suite (`pnpm test`)
- Run build (`pnpm build`)
- Report pass/fail summary
- Model: haiku, context: fork

### 2b. `/test-and-fix` — Run tests, auto-fix failures in loop

**File**: `~/.claude-setup/skills/test-and-fix/SKILL.md`

- Run test suite
- If failures: analyze errors, read failing test + source, fix
- Re-run (max 3 iterations)
- Model: sonnet, context: fork

### 2c. `/review-changes` — Pre-commit quality review

**File**: `~/.claude-setup/skills/review-changes/SKILL.md`

- Run `git diff --cached` or `git diff`
- Review for bugs, security issues, accidental secrets, debug code
- Provide approval or list concerns
- Model: sonnet, context: fork

### 2d. `/cpr` — Commit, push, and create PR

**File**: `~/.claude-setup/skills/cpr/SKILL.md`

- Precompute `git diff --stat` via inline bash (Boris's key optimization)
- Generate commit message from diff
- Commit, push, create PR via `gh pr create`
- Model: haiku, context: fork

### 2e. `/first-principles` — Structured problem decomposition

**File**: `~/.claude-setup/skills/first-principles/SKILL.md`

- Walk through: What problem? What constraints? What approaches? Trade-offs?
- Select approach, create implementation plan
- Model: opus (needs deep reasoning), context: normal

---

## 3. CREATE New Agent

### 3a. `oncall-guide` — Production incident diagnosis

**File**: `~/.claude-setup/agents/oncall-guide.md`

- Accept error description/stack trace/alert
- Check recent deploys (`git log`)
- Query database for anomalies (Postgres MCP)
- Check DigitalOcean app status
- Correlate findings, suggest root cause + fix
- Tools: Read, Bash, Glob, Grep, mcp__postgres__*, mcp__digitalocean__*
- Model: opus

---

## 4. ARCHIVE Redundant M&A Skills

Move to `skills/_archive/`:
- `triage-analyzer` (duplicated by `/mna triage`)
- `financial-data-extractor` (duplicated by `/mna extract`)
- `mna-proposal-generator` (duplicated by `/mna proposal`)
- `investment-analysis-generator` (duplicated by `/mna analysis`)
- `committee-presenter` (duplicated by `/mna deck`)

Fold `mna-swarm-orchestrator` swarm mode into `mna-toolkit` as a `mode: swarm` flag in the SKILL.md.

**Result**: 8 M&A skills down to 2 (mna-toolkit, portfolio-reporter)

---

## 5. CONSOLIDATE Agents

### 5a. Merge `api-agent` into `backend-agent`
- Add API design section to backend-agent.md
- Archive api-agent.md

### 5b. Move testing subagents out of top-level agents/
- `fulltesting-agent.md`, `page-tester.md`, `test-analyst.md` are already defined inside `fulltest-skill/`
- Move to `agents/_archive/` or `skills/fulltest-skill/agents/`

### 5c. Demote `documentation-agent` to `/docs` command
- Replace full agent with a lightweight skill
- Archive documentation-agent.md

**Result**: 13 agents down to 9 (remove api-agent, 3 testing agents, documentation-agent; add oncall-guide)

---

## 6. ADD Stop Hook for Verification

Add to settings.json `hooks.Stop`:
```json
{
  "hooks": [
    {
      "type": "prompt",
      "prompt": "Before ending: Did you verify your work compiles/passes tests? If not, run verification now."
    }
  ]
}
```

This implements Boris's "always give Claude a way to verify" as a system-level guardrail.

---

## 7. COMMIT TO MEMORY

Save Boris Cherny patterns as memory entities:
- `pattern:boris-verification-loops` — Always verify work (tests, build, browser)
- `pattern:boris-vanilla-setup` — Fewer agents, more commands; simple > complex
- `pattern:boris-inline-bash-precomputation` — Precompute git context in slash commands
- `pattern:boris-plan-mode-first` — Start in plan mode, iterate, then auto-accept
- `tech-insight:boris-opus-less-steering` — Opus requires less steering than Sonnet

---

## Summary of Changes

| Category | Before | After | Delta |
|----------|--------|-------|-------|
| Skills | 22 | 21 | -6 archived, +5 new commands |
| Agents | 13 | 9 | -5 removed/archived, +1 oncall-guide |
| Hooks | 4 types | 5 types | +PostToolUse formatting |
| Daily commands | 1 (/cp) | 6 | +verify, test-and-fix, review-changes, cpr, first-principles |

---

## Verification

After implementation:
1. Run `/verify` in an existing project — should detect project type and run checks
2. Run `/test-and-fix` in a project with a known failing test
3. Run `/review-changes` after making a code change
4. Run `/cpr` to test full commit-push-PR flow
5. Confirm PostToolUse hook formats files after Write/Edit
6. Confirm archived skills no longer appear in `/` autocomplete
7. Verify `mna-toolkit` still handles all M&A subcommands
