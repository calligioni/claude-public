---
name: research
description: "Analyze any URL or image (article, GitHub repo, tweet, tool, screenshot, diagram, YouTube video, podcast) and determine how it can improve existing skills/agents, inspire new skills, benefit active projects (Contably, SourceRank), or enhance Claudia (agent router). Uses summarize CLI for AV content transcription. Triggers on: research this, analyze this link, learn from this, /research."
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

| Project    | Path                | Stack                  | Key Needs                                                         |
| ---------- | ------------------- | ---------------------- | ----------------------------------------------------------------- |
| Contably   | ~/code/contably     | Next.js + Supabase     | Brazil accounting, tax compliance, financial data extraction      |
| SourceRank | ~/code/sourcerankai | Next.js + GitHub API   | Repository analytics, developer metrics, open source intelligence |
| Claudia    | ~/code/claudia      | TypeScript + Agent SDK | Agent router, multi-channel messaging, inference fallback         |

## Claudia Context

Claudia is the agent runtime replacing OpenClaw. Routes multi-channel messages (Discord, Telegram, Slack, WhatsApp, Voice) to Claude Code Agent SDK sessions with 3-tier inference fallback (Claude Max → Mac Mini MLX → VPS Ollama).

**On every run, read `~/code/claudia/claudia-config.md` for the current config snapshot.** This avoids re-scanning the project each time. If the file is missing, note it in the report and score Claudia relevance based on the summary above.

### Claudia Skill Map (for matching content to Claudia)

- Agent orchestration/routing → Claudia router, session management
- MCP servers → mcp-memory-pg (pgvector knowledge graph), new MCP integrations
- Channel adapters → Discord, Telegram, Slack, WhatsApp, Voice adapters
- Voice/audio/STT/TTS → Claudia voice pipeline (Groq Whisper, ElevenLabs, Twilio)
- Local/small models → 3-tier inference (MLX, Ollama, model routing)
- Scheduling/cron/proactive → Claudia scheduler (briefings, monitoring, heartbeat)
- Agent personas/identity → 9 agent configs (claudia, buzz, marco, cris, julia, arnold, bella, rex, swarmy)
- Knowledge graph/memory → mcp-memory-pg (semantic search, entity/relation storage)
- Agent security/sandboxing → channel auth, rate limiting, session isolation
- Cost optimization → inference routing, caching, batching, model selection
- Observability/monitoring → agent session tracking, error reporting, health checks
- Media processing → image/audio/video handling across channels

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

Score relevance 0-10 against four targets:

1. **Existing skills** — Does it introduce a tool/pattern an existing skill could use? Use the Claude Setup Skill Map to match.
2. **New skill opportunity** — No existing skill covers this, it's reusable, aligns with our stack (TypeScript, Next.js, Supabase)?
3. **Active projects** — Would Contably or SourceRank benefit directly?
4. **Claudia** — Does it improve Claudia's router, agents, channels, MCP, inference, scheduler, voice, or observability? Use the Claudia Skill Map to match. Read `~/code/claudia/claudia-config.md` for current capabilities before scoring.

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

### Claudia Recommendations

[Only include this section if Claudia relevance score >= 3]

#### 1. [Improve Component / New Integration / Enhance Capability] — Score: X/10

- **Target:** [router / channel adapter / MCP / inference / scheduler / voice / agents]
- **What:** [specific change to Claudia]
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

#### 2c. Do NOT Auto-Install

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
