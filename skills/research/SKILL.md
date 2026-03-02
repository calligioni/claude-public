---
name: research
description: "Analyze any URL or image (article, GitHub repo, tweet, tool, screenshot, diagram) and determine how it can improve existing skills/agents, inspire new skills, or benefit active projects (Contably, SourceRank). Triggers on: research this, analyze this link, learn from this, /research."
argument-hint: "<url or image path>"
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
  - AskUserQuestion
  - mcp__firecrawl__*
  - mcp__ScraplingServer__*
  - mcp__browserless__*
  - mcp__brave-search__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__firecrawl__*: { readOnlyHint: true, openWorldHint: true }
  mcp__ScraplingServer__*: { readOnlyHint: true, openWorldHint: true }
  mcp__memory__*: { readOnlyHint: false, idempotentHint: false }
hooks:
  Stop:
    - hooks:
        - type: command
          command: 'cd "$HOME/.claude-setup" && { git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ] && echo "No changes to commit"; } || { git add -A && git commit -m "feat: apply research skill recommendations" && git push origin master && echo "Committed and pushed"; }'
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

# Research — URL & Image-to-Action Intelligence

Analyze any URL or image and turn it into actionable improvements for your Claude Code setup or projects.

## Paths

```bash
ICLOUD_SETUP="$HOME/.claude-setup"
```

All reads and writes go to the iCloud path directly. Never use symlink paths.

## Active Projects

| Project    | Path                | Stack                | Key Needs                                                         |
| ---------- | ------------------- | -------------------- | ----------------------------------------------------------------- |
| Contably   | ~/code/contably     | Next.js + Supabase   | Brazil accounting, tax compliance, financial data extraction      |
| SourceRank | ~/code/sourcerankai | Next.js + GitHub API | Repository analytics, developer metrics, open source intelligence |

## Skill Map (for matching content to existing skills)

- Web scraping/data → firecrawl, scrapling, mna-toolkit
- Code quality/architecture → cto, code-review-agent
- Testing/QA → fulltest-skill, test-and-fix, qa-cycle
- Product/UX → cpo-ai-skill, website-design
- Security → security-agent, cto
- DevOps/deploy → devops-agent, run-local, verify
- Financial/M&A → mna-toolkit, portfolio-reporter, finance-\*
- GitHub/repos → cpr, review-changes
- Email/comms → agentmail
- Research → deep-research, firecrawl, scrapling
- Legal/compliance → legal-_, compliance-_

## Workflow

### Phase 1: Extract + Analyze

Do everything in a single pass — no separate inventory scan needed.

#### 1a. Detect Input Type

- **URL**: Starts with `http://`, `https://`, or is a recognizable domain
- **Image path**: Ends with `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.bmp`, `.tiff`
- **Pasted image**: Already visible in conversation

If ambiguous, check if path exists on disk using Glob.

#### 1b. Extract Content

**URLs** — Try Firecrawl first, escalate through fallbacks:

```
mcp__firecrawl__firecrawl_scrape({
  url: "<url>",
  formats: ["markdown"],
  onlyMainContent: true
})
```

Fallback chain if Firecrawl fails (403, empty, credits exhausted, bot-detected):

```
1. Firecrawl (cloud, fast, structured extraction)
   ↓ if fails
2. Scrapling Fetcher (local HTTP, TLS fingerprint impersonation, free)
   mcp__ScraplingServer__fetch({ url: "<url>", headless: true })
   ↓ if blocked (403, captcha, empty)
3. Scrapling StealthyFetcher (Playwright stealth, Cloudflare bypass)
   mcp__ScraplingServer__stealthy_fetch({ url: "<url>", headless: true, block_webrtc: true })
   ↓ if still fails
4. WebFetch (last resort)
```

If URL is a tweet/social post, replace domain with `api.fxtwitter.com` and use WebFetch. Fall back to WebSearch if that fails.

**GitHub repos** — Scrape repo page (description, stars, tech stack from package.json). Only fetch README separately if the repo page lacks sufficient detail.

**Tweets/X posts** — Replace domain with `api.fxtwitter.com`, fetch via WebFetch. Fall back to WebSearch if that fails.

**Images** — Read with `Read` tool (multimodal). Extract visible text, tool names, URLs, code. Use WebSearch for context on identified tools/products.

**Doc sites** — Use firecrawl_map to discover pages, scrape key sections.

#### 1c. Classify + Score (inline, no agent needed)

Classify content type:

| Type                  | Indicators                                       |
| --------------------- | ------------------------------------------------ |
| **Tool/API**          | MCP server, CLI tool, SDK, npm package, API docs |
| **Pattern/Technique** | Coding pattern, architecture, workflow           |
| **Product/Feature**   | Product launch, feature demo, UX pattern         |
| **Infrastructure**    | Deployment, CI/CD, monitoring, DevOps            |

Score relevance 0-10 against three targets:

1. **Existing skills** — Does it introduce a tool/pattern an existing skill could use? Use the Skill Map above to match.
2. **New skill opportunity** — No existing skill covers this, it's reusable, aligns with our stack (TypeScript, Next.js, Supabase)?
3. **Active projects** — Would Contably or SourceRank benefit directly?

### Phase 2: Recommend + Act

#### 2a. Present Report

```markdown
## Research: [Title]

**Source:** [url or image path]
**Type:** [Tool/Pattern/Product/Infrastructure]

### Summary

[2-3 sentences]

### Recommendations

#### 1. [Improve Existing / Create New / Benefit Project] — Score: X/10

- **Target:** [skill name / "New skill: xyz" / project name]
- **What:** [specific change]
- **Why:** [concrete benefit]
- **Effort:** Low / Medium / High
- **Score:** X/10 — [one-line justification]

> Score = (impact × 0.4) + (feasibility × 0.3) + (relevance × 0.3)
> where each factor is 1-10. Impact: how much it improves the target.
> Feasibility: how easy to implement. Relevance: how aligned with current priorities.

### Memory

[Only if max relevance score >= 5: insight worth saving]
```

#### 2b. Ask User What to Apply

Use `AskUserQuestion` with recommendations as options. Each option label MUST include the score (e.g., "8/10 — Update /cto with new pattern"). Sort options by score descending. Include "Just save to memory" and "Skip".

#### 2c. Implement Approved Changes

**Improving a skill:**

1. Read the full SKILL.md
2. Make minimal, targeted changes (add tools, update workflow)
3. Don't rewrite the skill

**Creating a new skill:**

1. Create `$ICLOUD_SETUP/skills/<name>/SKILL.md`
2. Follow existing skill patterns (frontmatter + workflow)
3. Use sonnet model unless complex reasoning needed

**Benefiting a project:**

1. Save as memory entity: `research-finding:<project>-<topic>`
2. Optionally create a GitHub issue

**Save to memory only when max relevance score >= 5:**

```javascript
mcp__memory__create_entities({
  entities: [
    {
      name: "research-finding:<topic>",
      entityType: "research-finding",
      observations: [
        "Discovered: <date>",
        "Source: <url>",
        "Summary: <what it is>",
        "Applies to: <skills/projects>",
        "Action taken: <what was done>",
      ],
    },
  ],
});
```

## Edge Cases

- **URL unreachable**: Try WebSearch for cached/discussed versions
- **Paywalled**: Extract what's available, supplement with WebSearch
- **Irrelevant content**: Report "No actionable recommendations" and offer to save as general reference
- **Already processed**: Check memory for existing `research-finding:` entities with same URL first
- **Image unreadable**: Report what's visible, ask user for context
