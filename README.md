# Claude Code Configuration

Personal Claude Code configuration for ps. This directory contains agents, skills, commands, and settings that extend Claude Code's capabilities.

## Quick Start

```bash
# Start Claude Code with all configurations loaded
claude

# Use a specific skill
/mna triage                    # M&A deal scoring
/autonomous-agent              # Autonomous coding loop
/website-design                # B2B SaaS website design
```

## Directory Structure

```
claude/
├── agents/              # Specialized AI agents (13)
├── skills/              # Task-specific skills (13)
├── commands/            # Custom slash commands (5)
├── guides/              # Coordination guides
├── settings.json        # Main configuration
└── README.md            # This file
```

## Agents (13 total)

| Agent                  | Purpose                                 | Model |
| ---------------------- | --------------------------------------- | ----- |
| `frontend-agent`       | React/Vue/Angular development           | opus  |
| `backend-agent`        | Node/Python/Go APIs                     | opus  |
| `database-agent`       | Schema design, migrations, optimization | opus  |
| `devops-agent`         | CI/CD, Docker, Kubernetes, cloud        | opus  |
| `security-agent`       | Vulnerability scanning, security review | opus  |
| `codereview-agent`     | PR reviews, code quality                | opus  |
| `documentation-agent`  | README, API docs, architecture          | opus  |
| `api-agent`            | REST/GraphQL API design and testing     | opus  |
| `performance-agent`    | Profiling, Lighthouse, load testing     | opus  |
| `fulltesting-agent`    | E2E testing with Chrome DevTools        | opus  |
| `page-tester`          | Individual page testing subagent        | opus  |
| `test-analyst`         | Test failure analysis and fixes         | opus  |
| `project-orchestrator` | Full project coordination               | opus  |

## Skills (13 total)

### Development Skills

| Skill                | Trigger               | Purpose                                |
| -------------------- | --------------------- | -------------------------------------- |
| `autonomous-agent`   | `/autonomous-agent`   | Iterative feature development with PRD |
| `website-design`     | `/website-design`     | B2B SaaS websites and dashboards       |
| `website-replicator` | `/website-replicator` | Clone websites for study               |
| `codebase-cleanup`   | `/codebase-cleanup`   | Find and remove unused files           |
| `share-to-nuvini`    | `/share-to-nuvini`    | Share skills to nuvini-claude repo     |

### M&A Toolkit (Unified)

| Command         | Purpose                                |
| --------------- | -------------------------------------- |
| `/mna triage`   | Score deals 0-10 against criteria      |
| `/mna extract`  | Extract financial data from PDFs/Excel |
| `/mna proposal` | Generate IRR/MOIC financial models     |
| `/mna analysis` | Create 18-page investment PDF          |
| `/mna deck`     | Create board approval PowerPoint       |
| `/mna aimpact`  | AI cost reduction analysis             |

### Individual M&A Skills (Legacy)

- `triage-analyzer` - Deal scoring
- `financial-data-extractor` - PDF/Excel extraction
- `mna-proposal-generator` - Financial modeling
- `investment-analysis-generator` - Investment PDFs
- `committee-presenter` - Board presentations
- `aimpact` - AI cost savings analysis

## MCP Servers (10 configured)

| Server                | Purpose                                    |
| --------------------- | ------------------------------------------ |
| `sequential-thinking` | Step-by-step problem solving               |
| `memory`              | Persistent knowledge graph (iCloud synced) |
| `fetch`               | Web content fetching                       |
| `git`                 | Git repository operations                  |
| `brave-search`        | Web search                                 |
| `postgres`            | PostgreSQL database access                 |
| `resend`              | Email sending                              |
| `slack`               | Slack integration                          |
| `notion`              | Notion integration                         |
| `chrome-devtools`     | Browser automation and testing             |

## Plugins (7 enabled)

- `frontend-design` - UI component design
- `context7` - Documentation lookup
- `code-review` - PR review assistance
- `supabase` - Supabase integration
- `ralph-wiggum` - Autonomous coding loops
- `code-simplifier` - Code simplification
- `document-skills` - Document creation (xlsx, docx, pdf, pptx)

## Hooks

| Event                     | Action                     |
| ------------------------- | -------------------------- |
| `SessionStart`            | Start git-autosave         |
| `PreToolUse(Bash)`        | Log commands               |
| `PostToolUse(Edit/Write)` | Format files               |
| `Notification`            | macOS notification         |
| `Stop`                    | Completion notification    |
| `SessionEnd`              | Cleanup + memory backup    |
| `SubagentStart/Stop`      | Subagent activity tracking |

## Configuration Files

| File                            | Purpose                                 |
| ------------------------------- | --------------------------------------- |
| `settings.json`                 | Main settings (symlinked to ~/.claude/) |
| `~/.claude/settings.local.json` | Local permission overrides              |
| `~/.claude/rules/*.md`          | Coding standards and rules              |
| `~/.claude/hooks/*.sh`          | Hook scripts                            |
| `~/.claude/backups/`            | Memory backup storage                   |

## Rules

Located in `~/.claude/rules/`:

- `coding-standards.md` - Code quality conventions
- `git-conventions.md` - Commit and branch standards
- `security-rules.md` - Security guidelines
- `mcp-permissions.md` - MCP permission patterns

## Common Workflows

### Start a New Feature

```bash
# Use autonomous agent for iterative development
/autonomous-agent

# Or use project orchestrator for full coordination
/project-orchestrator
```

### Analyze M&A Deal

```bash
/mna triage                    # Initial scoring
/mna extract CIM.pdf           # Extract data
/mna proposal                  # Financial model
/mna deck                      # Board presentation
```

### Test Website

```bash
# Use fulltesting-agent for comprehensive E2E testing
# Requires Chrome DevTools MCP
```

## Maintenance

### Backup

Memory is automatically backed up to `~/.claude/backups/` on session end.
Also synced to iCloud at `~/Library/Mobile Documents/com~apple~CloudDocs/Claude/`.

### Version Control

This directory is version controlled:

```bash
cd ~/code/claude
git status
git add .
git commit -m "Update Claude configuration"
```

## Symlinks

The `~/.claude/` directory uses symlinks:

- `settings.json` → `~/.claude-setup/settings.json`
- `agents/` → iCloud synced location
- `skills/` → `~/.claude-setup/skills/`
- `commands/` → `~/.claude-setup/commands/`

## Adding Custom Components

### Add Agent

Create `agents/your-agent.md`:

```markdown
---
name: your-agent
description: Agent description
tools: Bash, Read, Write, Edit
color: #FF5733
model: opus
---

# Your Agent

[Instructions here]
```

### Add Skill

Create `skills/your-skill/SKILL.md`:

```markdown
---
name: your-skill
description: Skill description
user-invocable: true
---

# Your Skill

[Instructions here]
```

## Support

- Claude Code docs: https://docs.anthropic.com/claude-code
- Report issues: https://github.com/anthropics/claude-code/issues
