---
name: claude-setup-optimizer
description: Analyzes Claude Code changelog, reviews your current agents/skills/plugins setup, and recommends improvements based on new features. Use when asked to "optimize claude setup", "check for claude updates", "improve my agents", "sync with claude changelog", or "/optimize-setup".
user-invocable: true
model: sonnet
context: fork
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

Automatically analyzes the Claude Code changelog and recommends improvements to your agents, skills, plugins, and configuration based on new features.

## What This Skill Does

1. **Gets Latest Changelog** - Uses the built-in `/release-notes` command or conversation context
2. **Analyzes Your Setup** - Reviews all your agents, skills, plugins, rules, and configuration
3. **Identifies Opportunities** - Finds ways your setup could benefit from new Claude features
4. **Recommends Improvements** - Provides specific, actionable recommendations
5. **Implements Changes** - Optionally applies improvements automatically

## Paths

### Portable Path Variable

**IMPORTANT:** Always use `$HOME` in bash commands and `~/` in documentation to ensure portability across different machines/users.

**Define this variable at the start of any bash operations:**

```bash
SETUP="$HOME/.claude-setup"
```

**Source of Truth Structure:**

```
~/.claude-setup/
├── skills/       <- All skills (SKILL.md per directory)
├── agents/       <- All agents (.md files)
├── commands/     <- Slash commands (.md files)
├── rules/        <- Global instruction files (.md)
├── hooks/        <- Hook scripts (.sh)
├── memory/       <- Memory files (core-memory.json, etc.)
└── settings.json <- Settings (hooks, MCP servers, env vars)
```

**IMPORTANT:** Always read from AND write to `~/.claude-setup` directly. Do NOT use symlink paths like `~/.claude/` - use the source path to ensure:

- Consistent behavior regardless of symlink state
- Changes persist correctly
- Syncs across all devices

### Background (FYI only)

Claude Code searches for skills/agents in multiple locations, but symlinks point everything to the setup dir:

- `~/.claude/skills` -> ~/.claude-setup/skills
- `~/.claude/agents` -> ~/.claude-setup/agents
- `~/.claude/commands` -> ~/.claude-setup/commands

## Workflow

### Step 1: Fetch Changelog + Inventory Setup (ALL IN PARALLEL)

**Run changelog fetch AND setup inventory simultaneously** — they are independent. Use a single message with parallel tool calls.

#### 1a. Changelog

The release notes are available directly inside Claude Code via the `/release-notes` command. **Check if the user already ran `/release-notes` in this conversation** — if the release notes are already in context, skip fetching entirely and use them.

If the release notes are NOT already in context, get them via Bash:

```bash
# Get the last ~300 lines of release notes (most recent versions)
claude -p "/release-notes" 2>/dev/null | tail -300
```

If `claude -p` is unavailable, fall back to:

1. WebSearch for "Claude Code changelog site:docs.anthropic.com" or "Claude Code release notes 2026"
2. WebFetch on https://code.claude.com/docs/en/changelog (if it exists)

**Never fetch the full CHANGELOG.md from GitHub** — it exceeds token limits.

Extract: new tools, skill/agent format changes, MCP updates, config options, hook events, plugin features, breaking changes.

#### 1b. Setup Inventory (Bash — single command, no subagents)

**Do NOT spawn Explore/Agent subagents for inventory.** Use Bash to extract all frontmatter in one pass:

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

echo "=== PLUGINS ==="
claude plugin list 2>/dev/null || echo "(no plugin CLI available)"

echo "=== CONFIG (settings.json) ==="
cat "$SETUP/settings.json" 2>/dev/null

echo "=== MCP SERVERS ==="
cat "$SETUP/settings.json" 2>/dev/null | grep -A1 '"description"' | grep description || true
```

This single Bash call replaces 3 Explore subagents and runs in seconds instead of minutes.

**Launch 1a and 1b in parallel** (two Bash calls in the same message), then proceed to Step 2 with combined results.

### Step 2: Compare and Identify Opportunities

Cross-reference changelog features against your current setup:

**Feature Categories to Check:**

1. **New Tools**: Are there new tools you're not using that could benefit your workflows?
2. **Skill/Agent Frontmatter Updates**: New frontmatter fields or format changes?
3. **Agent Capabilities**: Isolation modes, team patterns, background agents, memory scopes?
4. **MCP Updates**: New MCP servers, protocol changes, OAuth improvements, tool search?
5. **Hooks**: New hook events, HTTP hooks, prompt-based hooks, agent-scoped hooks?
6. **Plugin System**: Overlap between custom skills and available plugins?
7. **Performance Optimizations**: Parallelization, caching, context efficiency?
8. **Security Features**: New permission patterns, sandbox changes, security best practices?
9. **Configuration Options**: New settings, model overrides, auto-memory directory?

**Analysis Checklist — Skills:**

For each skill, check:

- [ ] Uses latest skill format (SKILL.md with YAML frontmatter)
- [ ] Takes advantage of parallel tool calls where applicable
- [ ] Uses `Agent` tool (not deprecated `Task`) for spawning subagents
- [ ] Uses appropriate model tier selection (haiku/sonnet/opus per model-tier-strategy)
- [ ] Has proper tool-annotations in frontmatter (destructiveHint, readOnlyHint, etc.)
- [ ] Follows current best practices for triggers/descriptions
- [ ] Uses YAML-style lists in `allowed-tools` (cleaner than inline arrays)
- [ ] Leverages `${CLAUDE_SKILL_DIR}` for self-referencing paths where useful
- [ ] Leverages `${CLAUDE_SESSION_ID}` where session tracking is needed
- [ ] Uses `context: fork` where appropriate (runs in sub-agent, protects main context)
- [ ] Uses `agent` field to specify agent type for execution where applicable
- [ ] Has `hooks` in frontmatter for skill-scoped lifecycle events where needed
- [ ] Uses `skills` frontmatter field to auto-load dependencies for subagents

**Analysis Checklist — Agents:**

For each agent, check:

- [ ] Has `memory` frontmatter field (`user`, `project`, or `local` scope) where persistent state is useful
- [ ] Has `background: true` if it should always run as a background task
- [ ] Has `isolation: worktree` if it modifies files that could conflict with main session
- [ ] Has `permissionMode` set appropriately (e.g., `bypassPermissions` for trusted automated agents)
- [ ] Has `disallowedTools` to explicitly block tools that shouldn't be available
- [ ] Has `hooks` in frontmatter for agent-scoped lifecycle events where needed
- [ ] Specifies `model` explicitly when not inheriting from parent is desired

**Analysis Checklist — Hooks:**

Check for adoption of newer hook events:

- [ ] `PermissionRequest` — auto-approve/deny tool permissions with custom logic
- [ ] `SubagentStart` / `SubagentStop` — lifecycle management for subagents
- [ ] `Setup` — repository setup/maintenance via `--init` or `--maintenance` flags
- [ ] `InstructionsLoaded` — fires when CLAUDE.md or rules files load into context
- [ ] `ConfigChange` — fires when config files change mid-session (audit/security)
- [ ] `WorktreeCreate` / `WorktreeRemove` — custom VCS setup/teardown for worktree isolation
- [ ] `TeammateIdle` / `TaskCompleted` — multi-agent workflow coordination
- [ ] `SessionStart` / `SessionEnd` — session lifecycle
- [ ] HTTP hooks (`type: http`) — POST to webhook URLs instead of shell commands
- [ ] Prompt-based stop hooks — model-evaluated conditions for stopping

**Analysis Checklist — Configuration:**

Check for newer settings:

- [ ] `autoMemoryDirectory` — custom directory for auto-memory storage
- [ ] `modelOverrides` — map model picker entries to custom provider model IDs
- [ ] `spinnerVerbs` / `spinnerTipsOverride` — customized spinner experience
- [ ] `plansDirectory` — custom location for plan files
- [ ] `language` — configure Claude's response language
- [ ] `attribution` — customize commit and PR bylines
- [ ] `sandbox.enableWeakerNetworkIsolation` — for Go programs behind MITM proxies
- [ ] `includeGitInstructions` — remove built-in git instructions from system prompt
- [ ] `CLAUDE_CODE_DISABLE_CRON` — disable scheduled cron jobs
- [ ] `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` — override file read token limit

**Analysis Checklist — Plugins:**

- [ ] Are any custom skills duplicated by available plugins?
- [ ] Are installed plugins up-to-date?
- [ ] Could any skills benefit from being distributed as plugins for team use?

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
Version and feature name from changelog

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
- Z plugins installed
- W rules loaded

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

**IMPORTANT: `~/.claude-setup` is the source of truth.** All changes MUST be made directly in the setup path to ensure they sync across devices.

**CRITICAL: Use parallel agents to implement changes concurrently.** Group approved changes into independent work streams and launch them as parallel agents. This dramatically speeds up implementation.

#### 5a. Back up affected files first

```bash
SETUP="$HOME/.claude-setup"
BACKUP="$SETUP/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp <file> "$BACKUP/"
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

A `Stop` hook in this skill's frontmatter automatically commits and pushes all changes to the GitHub backup repo when the skill finishes. No manual git commands needed.

## Example Recommendations

### Example 1: New Frontmatter Feature

````markdown
## [MEDIUM] Add memory scope to persistent agents

**Affected Items:** qa-runner.md, research-tracker.md

**Current State:**
Agents have no `memory` field — they lose context between sessions

**Recommended Change:**
Add `memory: project` to agents that benefit from remembering past runs within the same project.

**New Feature Reference:**
v2.1.33 — Added `memory` frontmatter field support for agents

**Implementation:**
Add to agent frontmatter:

```yaml
memory: project
```

**Effort:** Low
````

### Example 2: Worktree Isolation

````markdown
## [HIGH] Enable worktree isolation for parallel-dev agents

**Affected Items:** parallel-dev skill agent spawning

**Current State:**
Feature agents run in manually-created worktrees

**Recommended Change:**
Use `isolation: worktree` on Agent tool calls to let Claude Code manage worktree lifecycle automatically, including cleanup.

**New Feature Reference:**
v2.1.49 — Subagents support `isolation: "worktree"` for working in a temporary git worktree

**Implementation:**
Update Agent spawning calls:

```
Agent(subagent_type="general-purpose", model="sonnet", isolation="worktree", prompt="Implement feature X...")
```

**Effort:** Medium
````

### Example 3: HTTP Hook

````markdown
## [MEDIUM] Add HTTP hook for deployment notifications

**Affected Items:** settings.json hooks section

**Current State:**
No deployment notification hook configured

**Recommended Change:**
Use HTTP hooks to POST deployment status to a webhook URL when skills complete. HTTP hooks are simpler and more portable than shell command hooks.

**New Feature Reference:**
v2.1.63 — Added HTTP hooks support

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

**Effort:** Low
````

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

### Changelog Not Available

If `/release-notes` output is not in context and `claude -p` fails:

1. **WebSearch** — Search for "Claude Code changelog" or "Claude Code new features 2026"
2. **Read with limits** — Use `Read` tool with `limit=500` on any local changelog file
3. **WebFetch** — Fetch the official docs changelog page

### Large File Errors

If you encounter "File content exceeds maximum allowed tokens":

1. Use `Read` tool with `limit` and `offset` parameters to paginate
2. Use Bash `tail -N` to get only recent entries
3. Never attempt to fetch the full CHANGELOG.md via WebFetch — it's too large

## Notes

- Always preserve existing functionality when making changes
- Create backups before modifying files
- Test changes before committing
- Some recommendations may require manual review
- Keep track of which changelog versions have been reviewed to avoid duplicate work
- All paths use `$HOME` variable for cross-machine compatibility
