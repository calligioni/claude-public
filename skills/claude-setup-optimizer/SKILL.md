---
name: claude-setup-optimizer
description: Analyzes Claude Code changelog, reviews your current agents/skills setup, and recommends improvements based on new features. Use when asked to "optimize claude setup", "check for claude updates", "improve my agents", "sync with claude changelog", or "/optimize-setup".
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - WebFetch
  - WebSearch
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
hooks:
  Stop:
    - hooks:
        - type: command
          command: 'cd "$HOME/.claude-setup" && { git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ] && echo ''No changes to commit''; } || { git add -A && git commit -m ''feat: apply claude-setup-optimizer recommendations'' && git push origin master && echo ''Committed and pushed to GitHub''; }'
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
---

# Claude Setup Optimizer

Automatically analyzes the Claude Code changelog and recommends improvements to your agents, skills, and configuration based on new features.

## What This Skill Does

1. **Fetches Latest Changelog** - Gets the most recent Claude Code changelog from official sources
2. **Analyzes Your Setup** - Reviews all your agents, skills, commands, and configuration
3. **Identifies Opportunities** - Finds ways your setup could benefit from new Claude features
4. **Recommends Improvements** - Provides specific, actionable recommendations
5. **Implements Changes** - Optionally applies improvements automatically

## Paths

### Portable iCloud Path Variable

**IMPORTANT:** Always use `$HOME` in bash commands and `~/` in documentation to ensure portability across different machines/users.

**Define this variable at the start of any bash operations:**

```bash
ICLOUD_SETUP="$HOME/.claude-setup"
```

**Source of Truth Structure:**

```
~/.claude-setup/
├── skills/       ← All skills (SKILL.md per directory)
├── agents/       ← All agents (.md files)
├── commands/     ← Slash commands (.md files)
├── rules/        ← Global instruction files (.md)
├── hooks/        ← Hook scripts (.sh)
├── memory/       ← Memory files (core-memory.json, etc.)
└── settings.json ← Settings (hooks, MCP servers, env vars)
```

**IMPORTANT:** Always read from AND write to the iCloud path directly. Do NOT use symlink paths like `~/.claude/` - use the iCloud path to ensure:

- Consistent behavior regardless of symlink state
- Changes persist correctly to iCloud
- Syncs across all devices

### Background (FYI only)

Claude Code searches for skills/agents in multiple locations, but symlinks point everything to iCloud:

- `~/.claude/skills` → iCloud
- `~/.claude/agents` → iCloud
- `~/.claude/commands` → iCloud

## Workflow

### Step 1: Fetch Changelog + Inventory Setup (ALL IN PARALLEL)

**Run changelog fetch AND setup inventory simultaneously** — they are independent. Use a single message with parallel tool calls.

#### 1a. Changelog (Bash — fast)

```bash
# Get 5 most recent releases in one shot
gh release list --repo anthropics/claude-code --limit 5 --json tagName,publishedAt,name
```

Then fetch details for the 2–3 most recent tags:

```bash
gh release view <tag> --repo anthropics/claude-code
```

If `gh` fails, fall back to WebSearch for "Claude Code changelog 2026".

**Never fetch the full CHANGELOG.md** — it exceeds token limits.

Extract: new tools, skill/agent format changes, MCP updates, config options, breaking changes.

#### 1b. Setup Inventory (Bash — single command, no subagents)

**Do NOT spawn Explore/Task agents for inventory.** Use Bash to extract all frontmatter in one pass:

```bash
SETUP="$HOME/.claude-setup"

echo "=== SKILLS FRONTMATTER ==="
for f in "$SETUP"/skills/*/SKILL.md; do
  echo "--- $(basename $(dirname "$f")) ---"
  sed -n '/^---$/,/^---$/p' "$f" 2>/dev/null
  echo ""
done

echo "=== AGENTS FRONTMATTER ==="
for f in "$SETUP"/agents/*.md "$SETUP"/agents/**/*.md; do
  [ -f "$f" ] || continue
  echo "--- $(basename "$f") ---"
  sed -n '/^---$/,/^---$/p' "$f" 2>/dev/null
  echo ""
done

echo "=== COMMANDS ==="
ls "$SETUP/commands/" 2>/dev/null

echo "=== RULES ==="
ls "$SETUP/rules/" 2>/dev/null

echo "=== HOOKS ==="
ls "$SETUP/hooks/" 2>/dev/null

echo "=== CONFIG (settings.json) ==="
cat "$SETUP/settings.json" 2>/dev/null

echo "=== MCP SERVERS ==="
# Extract just the MCP server names and descriptions
cat "$SETUP/settings.json" 2>/dev/null | grep -A1 '"description"' | grep description || true
```

This single Bash call replaces 3 Explore subagents and runs in seconds instead of minutes.

**Launch 1a and 1b in parallel** (two Bash calls in the same message), then proceed to Step 2 with combined results.

### Step 2: Compare and Identify Opportunities

Cross-reference changelog features against your current setup:

**Feature Categories to Check:**

1. **New Tools**: Are there new tools you're not using that could benefit your workflows?
2. **Skill System Updates**: Has the skill format changed? Are there new frontmatter options?
3. **Agent Improvements**: New agent capabilities, isolation modes (`isolation: worktree`), or team patterns?
4. **MCP Updates**: New MCP servers, protocol changes, or OAuth improvements?
5. **Hooks**: New hook events (HTTP hooks, ConfigChange, WorktreeCreate/Remove, TeammateIdle, TaskCompleted)?
6. **Performance Optimizations**: Parallelization, caching, memory leak fixes, or context efficiency?
7. **Security Features**: New permission patterns, sandbox changes, or security best practices?
8. **Configuration Options**: New settings (spinnerTips, statusLine, plugins, plansDirectory)?

**Analysis Checklist:**

For each skill/agent, check:

- [ ] Uses latest skill format (SKILL.md with YAML frontmatter)
- [ ] Takes advantage of parallel tool calls where applicable
- [ ] Uses `Agent` tool (not deprecated `Task`) for spawning subagents
- [ ] Uses appropriate model tier selection (haiku/sonnet/opus per model-tier-strategy)
- [ ] Has proper tool-annotations in frontmatter (destructiveHint, readOnlyHint, etc.)
- [ ] Follows current best practices for triggers/descriptions
- [ ] Uses new tools/features that weren't available before
- [ ] Leverages relevant hook events (WorktreeCreate, ConfigChange, etc.)

### Step 3: Generate Recommendations

Create a structured report with:

**Priority Levels:**

- **HIGH**: Security improvements, breaking change migrations, significant efficiency gains
- **MEDIUM**: New feature adoption, best practice updates
- **LOW**: Nice-to-have improvements, style updates

**Recommendation Format:**

```markdown
## [Priority] Recommendation Title

**Affected Items:** skill-name, agent-name, etc.

**Current State:**
Description of how it works now

**Recommended Change:**
What should be changed and why

**New Feature Reference:**
Link to changelog or documentation

**Implementation:**
Specific steps or code changes needed

**Effort:** Low/Medium/High
```

### Step 4: Present and Confirm

Present findings to the user:

```
# Claude Setup Optimization Report

## Changelog Summary
- Version X.Y.Z released on DATE
- Key new features: [list]

## Your Setup Analysis
- X skills analyzed
- Y agents analyzed
- Z commands analyzed

## Recommendations Found: N

### High Priority (M items)
1. [Brief description]
2. ...

### Medium Priority (N items)
1. ...

### Low Priority (P items)
1. ...

Would you like me to:
1. Show detailed recommendations for all items
2. Show only HIGH priority recommendations
3. Auto-implement all HIGH priority changes
4. Auto-implement specific recommendations
5. Skip implementation (just review)
```

### Step 5: Implement Improvements with Parallel Agents

**IMPORTANT: iCloud is the source of truth.** All changes MUST be made directly in the iCloud path to ensure they sync across devices.

**CRITICAL: Use parallel agents to implement changes concurrently.** Group approved changes into independent work streams and launch them as parallel agents. This dramatically speeds up implementation.

#### 5a. Back up affected files first

```bash
ICLOUD_SETUP="$HOME/.claude-setup"
mkdir -p "$ICLOUD_SETUP/backups/$(date +%Y%m%d-%H%M%S)"
cp <file> "$ICLOUD_SETUP/backups/$(date +%Y%m%d-%H%M%S)/"
```

#### 5b. Group changes into independent work streams

Categorize approved changes into groups that can run in parallel without conflicts (no two agents should edit the same file):

- **Skills agent**: All SKILL.md frontmatter and body changes
- **Agents agent**: All agent .md file changes
- **Config agent**: settings.json, hooks, and other config changes
- **Filesystem agent**: Directory moves, file deletions, archive operations

If a group touches too many files, split further (e.g., separate M&A skills from dev skills).

#### 5c. Launch parallel agents

Use the Agent tool to launch multiple agents in a **single message** with multiple tool calls. Each agent gets a detailed prompt listing exactly which files to change and what to do. Use `model: "haiku"` for mechanical edits, `model: "sonnet"` for edits requiring judgment.

Example pattern:

```
# In a SINGLE message, launch all these Agent calls simultaneously:

Agent(subagent_type="general-purpose", model="haiku", description="Fix skill frontmatter", prompt="Read and edit these SKILL.md files: [list]. For each: [specific changes]...", run_in_background=true)

Agent(subagent_type="general-purpose", model="haiku", description="Update agent files", prompt="Read and edit these agent .md files: [list]. For each: [specific changes]...", run_in_background=true)

Agent(subagent_type="general-purpose", model="sonnet", description="Update config files", prompt="Read and edit settings.json: [specific changes]...", run_in_background=true)
```

**Rules for parallel agents:**

- Each agent prompt must be self-contained with ALL context needed (file paths, exact changes)
- No agent should edit a file that another agent is also editing
- Use `run_in_background=true` to launch them concurrently
- Wait for all agents to complete, then verify results
- If a change depends on another change, put them in the same agent or run sequentially

#### 5d. Verify all changes

After all agents complete, spot-check key files to confirm changes were applied correctly. Read the frontmatter of a few modified files to verify.

#### 5e. Git commit and push (automatic)

A `Stop` hook in this skill's frontmatter automatically commits and pushes all changes to the GitHub backup repo (`github.com/escotilha/claude`) when the skill finishes. No manual git commands needed.

## Example Recommendations

### Example 1: New Tool Usage

````markdown
## [MEDIUM] Add Agent tool to deep-research skill

**Affected Items:** deep-research

**Current State:**
Skill uses Task tool for spawning parallel research tracks

**Recommended Change:**
Replace `Task` with `Agent` in allowed-tools. The `Task` tool was renamed to `Agent` and now supports `model` parameter for per-agent tier selection.

**New Feature Reference:**
Claude Code v2.1.x unified agent spawning under the Agent tool

**Implementation:**
Update allowed-tools in frontmatter:

```yaml
allowed-tools:
  - Agent # was: Task
```

And update spawn calls to use `model: "sonnet"` for research tracks.
````

**Effort:** Low

````

### Example 2: Parallel Execution
```markdown
## [HIGH] Enable parallel agent execution in project-orchestrator

**Affected Items:** project-orchestrator.md

**Current State:**
Agent launches subagents sequentially

**Recommended Change:**
Update orchestrator to launch independent agents (frontend, backend, database) in parallel using multiple Task tool calls in single message.

**New Feature Reference:**
Task tool now supports parallel agent launches

**Implementation:**
Update the workflow section to specify parallel launch pattern for independent tasks.

**Effort:** Medium
````

### Example 3: New Hook Event

````markdown
## [MEDIUM] Add HTTP hook for deployment notifications

**Affected Items:** settings.json hooks section

**Current State:**
No deployment notification hook configured

**Recommended Change:**
Use the new HTTP hooks feature to POST deployment status to a webhook URL when skills complete. HTTP hooks run a POST request instead of a shell command.

**New Feature Reference:**
Claude Code v2.1.63 added HTTP hooks support

**Implementation:**
Add to hooks section in settings.json:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "https://your-webhook.example.com/deploy",
            "headers": { "Authorization": "Bearer ${WEBHOOK_TOKEN}" },
            "allowedEnvVars": ["WEBHOOK_TOKEN"]
          }
        ]
      }
    ]
  }
}
```
````

**Effort:** Low

```

## Triggers

This skill activates on:

- "optimize my claude setup"
- "check claude code updates"
- "improve my agents"
- "sync with claude changelog"
- "what's new in claude code"
- "update my skills for new features"
- "/optimize-setup"

## Error Handling

### Large File Errors

If you encounter "File content exceeds maximum allowed tokens" when fetching changelog:

1. **Use `gh` CLI instead** - Fetch releases via `gh release list` and `gh release view`
2. **Read with limits** - Use `Read` tool with `limit=500` to get only recent entries
3. **Use WebSearch** - Search for "Claude Code new features 2026" for recent announcements
4. **Fetch releases page** - WebFetch the releases page with a focused prompt

Never attempt to fetch the full CHANGELOG.md via WebFetch - it's too large.

## Notes

- Always preserve existing functionality when making changes
- Create backups before modifying files
- Test changes before committing
- Some recommendations may require manual review
- Keep track of which changelog versions have been reviewed to avoid duplicate work
- All paths use `$HOME` variable for cross-machine compatibility
```
