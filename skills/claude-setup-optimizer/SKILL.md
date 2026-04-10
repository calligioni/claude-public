---
name: claude-setup-optimizer
description: Analyzes Claude Code changelog, reviews your current agents/skills setup, and recommends improvements based on new features. Use when asked to "optimize claude setup", "check for claude updates", "improve my agents", "sync with claude changelog", or "/optimize-setup".
user-invocable: true
allowed-tools:
  - WebFetch
  - WebSearch
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
  - TaskList
effort: medium
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

Claude Code searches for skills/agents in multiple locations with this precedence:

1. **Managed** (enterprise) - Organization-wide
2. **Personal** - `~/.claude/skills/`, `~/.claude/agents/`, `~/.claude/commands/`
3. **Project** - `.claude/skills/`, `.claude/agents/` in current project

### User's Setup

Personal skills, agents, and commands are stored under `~/.claude/`:

```
~/.claude/
├── skills/       ← All custom skills (each in its own folder with SKILL.md)
├── agents/       ← All custom agents (.md files)
├── commands/     ← Custom commands (.md files)
└── settings.json ← Global settings (permissions, plugins)
```

**Platform Notes:**
- **Windows**: `~/.claude/` resolves to `C:\Users\<username>\.claude\`
- **macOS/Linux**: `~/.claude/` resolves to `/Users/<username>/.claude/` or `/home/<username>/.claude/`
- All edits should target `~/.claude/` directly using the platform-appropriate path

## Workflow

### Step 1: Fetch Claude Code Changelog

Fetch the latest Claude Code changelog from multiple sources:

**Primary Source - GitHub Releases:**

```
https://github.com/anthropics/claude-code/releases
```

**Secondary Source - Changelog File:**

```
https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
```

**Tertiary Source - Web Search:**
Search for "Claude Code changelog 2025" or "Claude Code new features" for recent announcements.

Extract key information:

- New features and capabilities
- New tools or MCP changes
- Skill/agent system updates
- Configuration options
- Breaking changes
- Best practice updates

### Step 2: Analyze Current Setup

**Inventory all skills:**

```bash
# All skills are in one place (via ~/.claude/skills symlink to iCloud)
find ~/.claude/skills -maxdepth 2 \( -name "SKILL.md" -o -name "skill.md" \) 2>/dev/null
```

For each skill, read and extract:

- Name and description
- Allowed tools
- Triggers/activation patterns
- Dependencies

**Inventory all agents:**

```bash
# All agents are in one place (via ~/.claude/agents symlink to iCloud)
find ~/.claude/agents -name "*.md" 2>/dev/null
```

For each agent, read and extract:

- Name and purpose
- Tools it uses
- Subagent relationships

**Inventory all commands:**

```bash
# All commands are in one place (via ~/.claude/commands symlink to iCloud)
ls ~/.claude/commands/*.md 2>/dev/null
```

**Read configuration files:**

```bash
# Settings in iCloud
cat "/Users/ps/Library/Mobile Documents/com~apple~CloudDocs/claude-setup/settings.json"

# Global Claude config
cat ~/.claude.json
```

### Step 3: Compare and Identify Opportunities

Cross-reference changelog features against your current setup:

**Feature Categories to Check:**

1. **New Tools**: Are there new tools you're not using that could benefit your workflows?
2. **Skill System Updates**: Has the skill format changed? Are there new frontmatter options?
3. **Agent Improvements**: New agent capabilities or patterns?
4. **MCP Updates**: New MCP servers or protocol changes?
5. **Performance Optimizations**: Parallelization, caching, or efficiency improvements?
6. **Security Features**: New permission patterns or security best practices?
7. **Configuration Options**: New settings that could improve your experience?

**Analysis Checklist:**

For each skill/agent, check:

- [ ] Uses latest skill format (SKILL.md with frontmatter)
- [ ] Takes advantage of parallel tool calls where applicable
- [ ] Uses appropriate model selection (haiku for fast tasks, etc.)
- [ ] Has proper error handling patterns
- [ ] Follows current best practices for triggers/descriptions
- [ ] Uses new tools/features that weren't available before

### Step 4: Generate Recommendations

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

### Step 5: Present and Confirm

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

### Step 6: Implement Improvements

For approved changes:

1. **Back up affected files first:**

```bash
# Create timestamped backup
BACKUP_DIR="$HOME/.claude/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp <file> "$BACKUP_DIR/"
```

2. **Apply changes using Edit or Write tools**
   - Use the platform-appropriate path to `~/.claude/`
   - Windows: `C:\Users\<username>\.claude\skills\<skill-name>\SKILL.md`
   - macOS/Linux: `~/.claude/skills/<skill-name>/SKILL.md`

3. **Validate changes:**

- Check syntax/format is valid
- Ensure no breaking changes to existing functionality

4. **Verify files exist:**

```bash
ls -la "$HOME/.claude/skills/<skill-name>/"
```

## Example Recommendations

### Example 1: New Tool Usage

````markdown
## [MEDIUM] Add WebSearch to financial-data-extractor skill

**Affected Items:** financial-data-extractor

**Current State:**
Skill only uses WebFetch for external data

**Recommended Change:**
Add WebSearch to allowed-tools to enable broader research capabilities when extracting financial data from unfamiliar sources.

**New Feature Reference:**
Claude Code v2.x added native WebSearch tool

**Implementation:**
Add `WebSearch` to allowed-tools in frontmatter:

```yaml
allowed-tools:
  - Read
  - WebFetch
  - WebSearch # NEW
```
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

### Example 3: Skill Format Migration

```markdown
## [HIGH] Migrate legacy .skill files to SKILL.md format

**Affected Items:** financial-data-extractor.skill

**Current State:**
Using legacy .skill format

**Recommended Change:**
Migrate to new SKILL.md format with YAML frontmatter for better Claude recognition and metadata support.

**New Feature Reference:**
SKILL.md is now the recommended format

**Implementation:**

1. Rename file to SKILL.md
2. Add YAML frontmatter with name, description, allowed-tools
3. Update content to match new format

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

## Notes

- Always preserve existing functionality when making changes
- Create backups before modifying files
- Test changes before committing
- Some recommendations may require manual review
- Keep track of which changelog versions have been reviewed to avoid duplicate work
