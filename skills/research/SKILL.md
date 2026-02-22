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
  - Task(agent_type=Explore)
  - Task(agent_type=general-purpose)
  - AskUserQuestion
  - mcp__firecrawl__*
  - mcp__browserbase__*
  - mcp__brave-search__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__firecrawl__*: { readOnlyHint: true, openWorldHint: true }
  mcp__memory__*: { readOnlyHint: false, idempotentHint: false }
hooks:
  Stop:
    - hooks:
        - type: command
          command: 'cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup" && { git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ] && echo "No changes to commit"; } || { git add -A && git commit -m "feat: apply research skill recommendations" && git push origin master && echo "Committed and pushed"; }'
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
ICLOUD_SETUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup"
```

All reads and writes go to the iCloud path directly. Never use symlink paths.

## Active Projects

| Project    | Path                | Stack                | Key Needs                                                         |
| ---------- | ------------------- | -------------------- | ----------------------------------------------------------------- |
| Contably   | ~/code/contably     | Next.js + Supabase   | Brazil accounting, tax compliance, financial data extraction      |
| SourceRank | ~/code/sourcerankai | Next.js + GitHub API | Repository analytics, developer metrics, open source intelligence |

Update this table when projects change.

## Workflow

### Phase 0: Detect Input Type

Determine if the input is a **URL** or an **image**:

- **URL**: Starts with `http://`, `https://`, or is a recognizable domain (e.g., `github.com/...`)
- **Image path**: Ends with `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.bmp`, `.tiff`, or is an absolute/relative file path pointing to an image
- **Pasted image**: User provides an image directly in the conversation (no path needed — it's already visible)

If the input is ambiguous, check if the path exists on disk using Glob. If it's a file, treat as image. If not, treat as URL.

### Phase 1: Extract (Parallel)

Launch two parallel operations in a single message:

**Agent A — Content Extraction:**

**If input is a URL:**

Try Firecrawl first, fall back to WebFetch:

```
mcp__firecrawl__firecrawl_scrape({
  url: "<user-provided-url>",
  formats: ["markdown"],
  onlyMainContent: true
})
```

If Firecrawl fails or URL is a tweet/social media post, use WebFetch + WebSearch as fallback to gather content.

For GitHub repos, also run:

```
mcp__firecrawl__firecrawl_scrape({
  url: "<repo-url>/blob/main/README.md",
  formats: ["markdown"]
})
```

**If input is an image:**

1. Read the image using the `Read` tool (which supports PNG, JPG, etc. natively as a multimodal input)
2. Analyze the image content — identify:
   - **Screenshots of tools/UIs**: What tool/product is shown? What features are visible?
   - **Architecture diagrams**: What components, services, patterns are depicted?
   - **Code screenshots**: Extract the code and language, identify the technique/pattern
   - **Tweet/social screenshots**: Extract the text, author, links mentioned
   - **Terminal/CLI output**: What command/tool is being demonstrated?
   - **Error screenshots**: What error, what tool, what context?
3. If the image contains URLs, tool names, or product names, use WebSearch to gather more context about them
4. If the image contains code, identify the language, framework, and pattern being demonstrated

**Agent B — Setup Inventory:**

Use a Task(agent_type=Explore) to read all current skills and agents in parallel:

```
Read all SKILL.md frontmatter (first 30 lines) from:
  $ICLOUD_SETUP/skills/*/SKILL.md

Read all agent frontmatter (first 20 lines) from:
  $ICLOUD_SETUP/agents/*.md

Return a list of: skill name → description → allowed-tools (one line each)
```

### Phase 2: Analyze

#### 2a. Classify the URL Content

Determine the content type:

| Type                  | Indicators                                            | Example                              |
| --------------------- | ----------------------------------------------------- | ------------------------------------ |
| **Tool/API**          | MCP server, CLI tool, SDK, npm package, API docs      | "Introducing Firecrawl MCP Server"   |
| **Pattern/Technique** | Coding pattern, architecture, workflow, best practice | "How to structure Next.js apps"      |
| **Product/Feature**   | Product launch, feature demo, UX pattern              | "Building a coupon finder extension" |
| **Infrastructure**    | Deployment, CI/CD, monitoring, DevOps                 | "Railway vs Vercel for Next.js"      |
| **Visual/Image**      | Screenshot, diagram, architecture chart, UI mockup    | Screenshot of a new dev tool UI      |

#### 2b. Score Relevance Against 3 Targets

For each target, score 0-10:

**1. Existing Skills/Agents (Can this improve what we have?)**

Check if the URL content:

- Introduces a tool that an existing skill could use
- Describes a pattern that improves an existing workflow
- Reveals a capability gap in a current skill
- Suggests better architecture for an existing agent

Map content keywords to skills:

- Web scraping/data → firecrawl, mna-toolkit
- Code quality/architecture → cto, code-review-agent
- Testing/QA → fulltest-skill, test-and-fix
- Product/UX → cpo-ai-skill, website-design
- Security → security-agent, cto
- DevOps/deploy → devops-agent, run-local, verify
- Financial/M&A → mna-toolkit, portfolio-reporter
- GitHub/repos → cpr, review-changes

**2. New Skill Opportunity (Is this something we can't do yet?)**

Check if:

- No existing skill covers this capability
- The capability is reusable (not one-off)
- It aligns with user's tech stack (TypeScript, Next.js, Supabase)
- It would be invoked more than once

**3. Active Projects (Would Contably or SourceRank benefit?)**

Check against project needs:

- **Contably**: Brazil tax APIs, accounting standards, financial reporting, invoice processing, Supabase patterns, payment integrations
- **SourceRank**: GitHub API patterns, repository metrics, developer analytics, data visualization, ranking algorithms

### Phase 3: Recommend + Act

#### 3a. Present Report

```markdown
## Research: [URL Title]

**Source:** [url]
**Type:** [Tool/Pattern/Product/Infrastructure]

### Summary

[2-3 sentences: what the URL is about and why it matters]

### Recommendations

#### 1. [Improve Existing / Create New / Benefit Project]

- **Target:** [skill name / "New skill: xyz" / project name]
- **What:** [specific change or integration]
- **Why:** [concrete benefit]
- **Effort:** Low / Medium / High

#### 2. ...

### Memory

[Any high-value insight worth saving to knowledge graph]
```

#### 3b. Ask User What to Apply

Use `AskUserQuestion` with the recommendations as options. Always include "Just save to memory" and "Skip" options.

#### 3c. Implement Approved Changes

Based on user selection:

**If improving a skill:**

1. Read the full SKILL.md
2. Add new tools to allowed-tools, update workflow sections, or add integration notes
3. Keep changes minimal — don't rewrite the skill

**If creating a new skill:**

1. Create `$ICLOUD_SETUP/skills/<name>/SKILL.md`
2. Follow existing skill patterns (frontmatter + workflow)
3. Use sonnet model unless the skill needs complex reasoning

**If benefiting a project:**

1. Create a brief note explaining what to implement and why
2. Save as a memory entity: `research-finding:<project>-<topic>`
3. Optionally create a GitHub issue if the project has a repo

**Always save high-value insights to memory:**

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

## Input Type Handling

### Images (Screenshots, Diagrams, Mockups)

- Read the image with the `Read` tool — Claude sees it natively as a multimodal input
- Identify what the image shows: tool UI, architecture diagram, code snippet, error message, tweet, terminal output, etc.
- Extract all text visible in the image (tool names, URLs, code, error messages)
- Use WebSearch to research any tools, products, or libraries identified in the image
- If the image shows code, determine the language/framework and the pattern being demonstrated
- If the image shows a UI/product, identify the product and search for its docs/repo
- If the image is an architecture diagram, map the components to technologies and patterns
- Treat extracted context the same as URL-sourced content for Phase 2 (Analyze) and Phase 3 (Recommend)

### GitHub Repos

- Scrape README for overview
- Check package.json or similar for tech stack
- Look at repo description, stars, recent activity
- Focus on: what does this tool do, how could we use it

### Articles/Blog Posts

- Extract main content (skip nav, ads, footers)
- Identify key takeaways, tools mentioned, code snippets
- Focus on: actionable techniques or tools

### Tweets/X Posts

- Use the FixTweet API: replace `x.com` or `twitter.com` with `api.fxtwitter.com` in the URL
- Example: `https://x.com/user/status/123` → `WebFetch https://api.fxtwitter.com/user/status/123`
- Prompt WebFetch to return: author, date, full text, media descriptions, engagement stats, and quoted tweet content
- If FixTweet fails, fall back to WebSearch: `site:x.com "<tweet author>" "<key phrase>"`
- Also check if there's a linked article, repo, or demo
- Focus on: what product/tool/technique is being announced

### Documentation Sites

- Use firecrawl_map to discover pages, then scrape key sections
- Focus on: installation, API reference, integration guides

## Examples

### Example 1: New MCP Server Announcement

```
User: /research https://github.com/some-org/cool-mcp-server

Research: Cool MCP Server

Source: https://github.com/some-org/cool-mcp-server
Type: Tool/API

Summary: An MCP server that provides X capability.
It exposes tools for Y and Z.

Recommendations:

1. **Improve Existing** — Add to CTO skill
   - Target: cto
   - What: Add mcp__cool__* to allowed-tools for [specific use case]
   - Effort: Low

2. **Benefit Project** — SourceRank could use this
   - Target: SourceRank
   - What: [specific integration opportunity]
   - Effort: Medium
```

### Example 2: Screenshot of a Tool

```
User: /research ~/Desktop/screenshot-new-mcp-tool.png

Research: [Tool Name from Screenshot]

Source: ~/Desktop/screenshot-new-mcp-tool.png
Type: Visual/Image → Tool/API

Summary: Screenshot shows [tool name], which provides [capability].
Researched via WebSearch: [additional context found].

Recommendations:

1. **Improve Existing** — Add to CTO skill
   - Target: cto
   - What: Integrate [tool] for [specific use case]
   - Effort: Low

2. **Save to Memory** — New tool discovery
   - Entity: research-finding:tool-name
   - Applies to: [relevant skills/projects]
```

### Example 3: Architecture Article

```
User: /research https://blog.example.com/next-js-server-actions-patterns

Research: Next.js Server Actions Patterns

Source: https://blog.example.com/...
Type: Pattern/Technique

Summary: Covers advanced patterns for Next.js server actions
including optimistic updates, error boundaries, and streaming.

Recommendations:

1. **Benefit Project** — Contably uses Next.js server actions
   - Target: Contably
   - What: Apply optimistic update pattern to invoice submission flow
   - Effort: Medium

2. **Save to Memory** — Reusable Next.js patterns
   - Entity: pattern:nextjs-server-actions-optimistic
   - Applies to: All Next.js projects
```

## Edge Cases

- **URL is unreachable**: Try WebSearch for cached/discussed versions of the content
- **Content is paywalled**: Extract what's available, supplement with WebSearch for summaries/discussions
- **Content is irrelevant**: Report "No actionable recommendations found" and offer to save as general reference
- **Multiple recommendations**: Present all, let user pick which to apply
- **URL already processed**: Check memory for existing `research-finding:` entities with same URL before re-processing
- **Image is low quality/unreadable**: Report what's visible, ask user for context about what the image shows
- **Image has no identifiable tools/products**: Describe what's visible and ask user what they'd like to research about it
- **Image contains multiple topics**: Identify all topics, prioritize the most actionable ones
