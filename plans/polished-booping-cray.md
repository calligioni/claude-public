# Plan: `/research` Skill — URL-to-Action Intelligence

## Context

Pierre often discovers articles, GitHub repos, tweets, and tools that could improve his Claude Code setup or benefit his projects (Contably, SourceRank). Currently there's no skill that takes a URL, analyzes its content, and maps it back to actionable improvements. The `claude-setup-optimizer` does something similar but only for Claude Code changelogs. This skill generalizes that pattern to any URL.

## What It Does

User shares a link → skill extracts content → analyzes it → recommends one of three actions:

1. **Improve existing skills/agents** — add new tools, patterns, or techniques
2. **Create a new skill** — if the URL reveals a capability not covered by current setup
3. **Benefit a project** — identify how Contably, SourceRank, or other active projects could use this

## Skill: `/research`

**File:** `~/.claude-setup/skills/research/SKILL.md`

### Frontmatter

```yaml
name: research
description: "Analyze any URL (article, GitHub repo, tweet, tool) and determine how it can improve existing skills/agents, inspire new skills, or benefit active projects (Contably, SourceRank). Triggers on: research this, analyze this link, learn from this, /research."
argument-hint: "<url>"
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
  - Task(agent_type=Explore)
  - Task(agent_type=general-purpose)
  - AskUserQuestion
  - mcp__firecrawl__*
  - mcp__memory__*
memory: user
hooks:
  Stop:
    - hooks:
        - type: command
          command: 'cd "$HOME/.claude-setup" && { git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ] && echo "No changes to commit"; } || { git add -A && git commit -m "feat: apply research skill recommendations" && git push origin master && echo "Committed and pushed"; }'
```

### Workflow (3 phases)

#### Phase 1: Extract (parallel)

Two parallel operations:

- **Agent A**: Firecrawl scrape the URL → get clean markdown content
- **Agent B**: Inventory current setup — read all skill frontmatter + agent frontmatter + list active projects from core-memory.json

#### Phase 2: Analyze

Classify the URL content into categories:

- **Tool/API** — new MCP server, CLI tool, SDK, API
- **Pattern/Technique** — coding pattern, architecture approach, workflow
- **Product/Feature** — product idea, feature implementation, UX pattern
- **Infrastructure** — deployment, CI/CD, monitoring, DevOps

Then score relevance against 3 targets:

| Target                     | How to Score                                                                        |
| -------------------------- | ----------------------------------------------------------------------------------- |
| **Existing skills/agents** | Does it add a capability to CTO, MNA, CPO, fulltest, website-design, etc.?          |
| **New skill opportunity**  | Is this a capability not covered by any current skill?                              |
| **Active projects**        | Would Contably (accounting SaaS), SourceRank (GitHub analytics), or others benefit? |

#### Phase 3: Recommend + Act

Present a concise report:

```
## Research: [URL title]

### What I Found
[2-3 sentence summary]

### Recommendations

1. **[Improve/Create/Project]** — [specific action]
   - Target: [skill name / new skill / project name]
   - Action: [what to change]
   - Effort: [Low/Medium/High]

### Apply?
```

Then use `AskUserQuestion` to let user pick which recommendations to apply. On approval, implement changes directly (edit skills, create new skill, or create project-specific notes).

### Key Design Decisions

- **Model: sonnet** — this is analysis + writing, not complex reasoning; keeps costs low
- **Firecrawl first, WebFetch fallback** — Firecrawl handles JS/anti-bot; WebFetch for simple pages
- **No auto-apply** — always ask before modifying skills or creating new ones
- **Stop hook** — auto-commits changes to iCloud git repo (same pattern as claude-setup-optimizer)
- **Memory integration** — saves high-value learnings to knowledge graph for cross-session recall

### Project Context (hardcoded in skill body)

The skill will reference these active projects with descriptions so it can match relevance:

| Project    | Stack                | Key Needs                                            |
| ---------- | -------------------- | ---------------------------------------------------- |
| Contably   | Next.js + Supabase   | Brazil accounting, tax compliance, financial data    |
| SourceRank | Next.js + GitHub API | Repository analytics, developer metrics, open source |

This list gets updated when projects change.

## Files to Create/Modify

| Action     | File                                                  |
| ---------- | ----------------------------------------------------- |
| **Create** | `~/Library/.../claude-setup/skills/research/SKILL.md` |

That's it — single file creation. No other files need modification.

## Verification

1. Restart Claude Code after creation
2. Run `/research https://github.com/some-interesting-repo`
3. Verify it scrapes the URL, inventories setup, and presents recommendations
4. Test with different URL types: GitHub repo, blog post, tweet
