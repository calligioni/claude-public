---
name: research
description: "Analyze any URL or image (article, repo, tweet, tool, screenshot, video, podcast) for skill/agent/project improvements. Triggers on: research this, analyze this link, learn from this, /research."
argument-hint: "<url or image path>"
user-invocable: true
context: fork
model: sonnet
effort: medium
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
  - mcp__exa__*
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

| Project    | Path                | Stack                        | Key Needs                                                              |
| ---------- | ------------------- | ---------------------------- | ---------------------------------------------------------------------- |
| ExampleProject   | ~/code/example-project     | Next.js + Supabase           | Brazil accounting, tax compliance, financial data extraction           |
| SourceRank | ~/code/sourcerankai | Next.js + GitHub API         | Repository analytics, developer metrics, open source intelligence      |
| AgentWave  | ~/code/agentwave    | TypeScript + SQLite + Croner | Multi-agent SaaS platform, Visual Agent Builder, Skill Studio, billing |
| OpenClaw   | ~/code/openclaw-vps | Shell + systemd              | VPS agent deployment, failsafe system, sentinel watchdog               |

## AgentWave Context

AgentWave is an open-core SaaS platform for deploying AI agent teams across communication channels (Telegram, Discord, Slack, WhatsApp). Multi-agent orchestration, 4-strategy knowledge graph search, JWT/OAuth auth, and a Visual Agent Builder.

**On every run, read `~/code/agentwave/prd-definition.md` for current product scope.** If the file is missing, note it in the report and score AgentWave relevance based on the summary above.

## OpenClaw Context

OpenClaw is the VPS-deployed agent gateway on Contabo (`vmi3065960`). Config-driven agent routing with a two-layer failsafe (config rollback + AI watchdog via Claude Code CLI), sentinel monitoring, and systemd service management.

### AgentWave Skill Map (for matching content to AgentWave)

- Multi-agent orchestration/routing → agent router, strategy selection
- Channel adapters → Telegram, Discord, Slack, WhatsApp integrations
- Knowledge graph/memory → 4-strategy search (vector, semantic, entity, temporal)
- Agent personas/identity → custom agent builder, persona config
- Custom skills/tools → Skill Studio, webhook integrations, Composio bridge
- Workspace/billing → multi-tenant workspaces, seat management, plan enforcement
- Agent marketplace → templates, community-published agent packs
- Auth → JWT/OAuth, workspace-level access control
- Observability → agent session tracking, active agent-hours metrics

### OpenClaw Skill Map (for matching content to OpenClaw)

- Agent deployment/operations → systemd services, gateway config
- Self-healing/failsafe → config rollback, crash-loop detection, AI watchdog
- Monitoring/sentinel → health checks, escalation scripts
- VPS infrastructure → systemd units, service management
- Agent config management → openclaw.json, agent identities, workspaces

### Claude Code Skill Map (for matching content to Claude Code setup)

- CLI features/hooks/settings → ~/.claude-setup configuration, hooks, rules
- MCP servers → new MCP integrations, tool discovery
- Subagent patterns → model tiers, Agent Teams, parallel execution
- Skills/agents → skill authoring, agent definitions, routing
- Memory/knowledge → auto-memory, mem-search, knowledge graph
- Cost optimization → model delegation, token efficiency, advisor strategy

## Claude Setup Skill Map (for matching content to existing skills)

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
- **AV URL**: YouTube, Spotify episode, Apple Podcast, or URL ending in `.mp3`/`.mp4`/`.wav`/`.m4a`/`.webm` — route to `summarize` CLI
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
2. Exa highlights (neural search, query-relevant excerpts only — use when researching a topic, not a specific URL)
   mcp__exa__get_contents({ ids: ["<url>"], highlights: true, maxCharacters: 2000 })
   ↓ if not applicable (specific URL, not topic)
3. Scrapling Fetcher (local HTTP, TLS fingerprint impersonation, free)
   mcp__ScraplingServer__fetch({ url: "<url>", headless: true })
   ↓ if blocked (403, captcha, empty)
4. Scrapling StealthyFetcher (Playwright stealth, Cloudflare bypass)
   mcp__ScraplingServer__stealthy_fetch({ url: "<url>", headless: true, block_webrtc: true })
   ↓ if still fails
5. WebFetch (last resort)
```

If URL is a tweet/social post, replace domain with `api.fxtwitter.com` and use WebFetch. Fall back to WebSearch if that fails.

**YouTube / Podcasts / Audio-Video URLs** — Route through `summarize` CLI for transcription + summary:

```bash
# Detect AV URLs: youtube.com, youtu.be, spotify.com/episode, podcasts.apple.com,
# or any URL ending in .mp3, .mp4, .wav, .m4a, .webm
summarize "<url>" --markdown 2>/dev/null
```

If `summarize` succeeds, use its markdown output as the content for Phase 1c (classify + score). Skip the Firecrawl chain entirely for AV content — it can't extract transcripts.

If `summarize` fails (not installed, unsupported URL, API error), fall back to:

1. WebSearch for "[video/podcast title] transcript"
2. Firecrawl on the page itself (may get description/comments but not transcript)

**GitHub repos** — Scrape repo page (description, stars, tech stack from package.json). Only fetch README separately if the repo page lacks sufficient detail.

**Tweets/X posts** — Replace domain with `api.fxtwitter.com`, fetch via WebFetch. Fall back to WebSearch if that fails. For X long-form article posts (Twitter Articles / Notes), also try `summarize "<url>"` as it uses xurl for full article extraction that fxtwitter may miss.

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

Score relevance 0-10 against five targets:

1. **Claude Code setup** — Does it improve skills, agents, hooks, MCP servers, memory, or subagent patterns? Use the Claude Code Skill Map to match.
2. **Existing skills** — Does it introduce a tool/pattern an existing skill could use? Use the Claude Setup Skill Map to match.
3. **New skill opportunity** — No existing skill covers this, it's reusable, aligns with our stack (TypeScript, Next.js, Supabase)?
4. **Active projects** — Would ExampleProject or SourceRank benefit directly?
5. **AgentWave / OpenClaw** — Does it improve AgentWave's orchestration, channels, knowledge graph, agent builder, skill studio, or marketplace? Or OpenClaw's failsafe, sentinel, deployment, or gateway? Use the AgentWave/OpenClaw Skill Maps to match. Read `~/code/agentwave/prd-definition.md` for current AgentWave scope before scoring.

### Phase 2: Recommend + Act

#### 2a. Present Report

```markdown
## Research: [Title]

**Source:** [url or image path]
**Type:** [Tool/Pattern/Product/Infrastructure]

### Summary

[2-3 sentences]

### Claude Setup Recommendations

#### 1. [Improve Existing / Create New / Benefit Project] — Score: X/10

- **Target:** [skill name / "New skill: xyz" / project name]
- **What:** [specific change]
- **Why:** [concrete benefit]
- **Effort:** Low / Medium / High
- **Score:** X/10 — [one-line justification]

### AgentWave / OpenClaw Recommendations

[Only include this section if AgentWave/OpenClaw relevance score >= 3]

#### 1. [Improve Component / New Integration / Enhance Capability] — Score: X/10

- **Target:** [AgentWave: orchestration / channels / knowledge graph / agent builder / skill studio / marketplace] or [OpenClaw: failsafe / sentinel / gateway / deployment]
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

#### 2c. Queue for Wiki Harvest (Memex)

After presenting the report, **always** queue the researched URL for wiki auto-ingest so it becomes part of the persistent knowledge base:

```bash
QUEUE_FILE="$HOME/.claude-setup/data/wiki-harvest-queue.json"
URL="<the researched URL>"
NOTE="<one-line summary from Phase 1c>"

# Create data dir and queue file if they don't exist
mkdir -p "$HOME/.claude-setup/data"
[ -f "$QUEUE_FILE" ] || echo '[]' > "$QUEUE_FILE"

# Append URL if not already queued (jq dedup)
if ! jq -e --arg u "$URL" '.[] | select(.url == $u)' "$QUEUE_FILE" >/dev/null 2>&1; then
  jq --arg u "$URL" --arg n "$NOTE" --arg d "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '. + [{"url": $u, "note": $n, "addedAt": $d, "addedBy": "research-skill"}]' \
    "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"
fi
```

This feeds into the wiki harvest which ingests queued URLs into the knowledge base.

#### 2d. Do NOT Auto-Install

Never automatically implement changes (skill edits, new skill creation, project modifications). Only present the recommendations and let the user decide what to do next. If the user explicitly asks you to implement a recommendation, then proceed.

**Save to memory only when max relevance score >= 5:**

First, dedup check — search for existing memories on the same topic:

```bash
~/.claude-setup/tools/mem-search "<topic keywords>"
```

- If a **high-relevance match** is found (same URL, tool, or concept), **update the existing memory file** with new observations instead of creating a duplicate entity.
- If **no match**, proceed with creating a new memory:

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

After writing any new or updated memory, reindex:

```bash
~/.claude-setup/tools/mem-search --reindex
```

## Token Efficiency Notes

When researching a topic (not a specific URL):

- **Prefer Exa highlights** (`mcp__exa__search`) over Firecrawl search — returns only query-relevant passages (500-1,500 tokens vs 2,000-5,000)
- **Use Brave LLM Context** (`mcp__brave-search__brave_web_search`) for quick factual lookups with `count=5`
- **Avoid fetching full pages** unless the specific content is needed — highlights mode covers 80% of research needs

## Edge Cases

- **URL unreachable**: Try WebSearch for cached/discussed versions
- **Paywalled**: Extract what's available, supplement with WebSearch
- **Irrelevant content**: Report "No actionable recommendations" and offer to save as general reference
- **Already processed**: Run `~/.claude-setup/tools/mem-search "<url or topic>"` to check for existing `research-finding:` entities with same URL first
- **Image unreadable**: Report what's visible, ask user for context
