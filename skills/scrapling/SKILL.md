---
name: scrapling
description: "Web scraping with anti-bot bypass, TLS impersonation, adaptive tracking via Scrapling MCP. Three modes: HTTP, stealth browser, Playwright. Triggers on: scrapling, stealth scrape, bypass cloudflare, anti-bot scrape."
user-invocable: true
context: fork
model: sonnet
effort: low
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - mcp__ScraplingServer__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  mcp__ScraplingServer__*: { readOnlyHint: true, openWorldHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
  agent-spawned:
    verbosity: minimal
---

# Scrapling — Stealth Web Scraping Skill

High-performance web scraping with anti-bot bypass, adaptive element tracking, and three fetching modes via Scrapling's MCP server.

## When to Use Scrapling vs Firecrawl

| Scenario                                       | Use                               |
| ---------------------------------------------- | --------------------------------- |
| Quick scrape, don't care about anti-bot        | Firecrawl                         |
| Cloudflare Turnstile / aggressive anti-bot     | Scrapling (StealthyFetcher)       |
| Firecrawl credits exhausted                    | Scrapling (Fetcher — free, local) |
| Need adaptive selectors that survive redesigns | Scrapling                         |
| Batch scrape with structured extraction        | Firecrawl                         |
| TLS fingerprint impersonation needed           | Scrapling (Fetcher)               |
| Full browser automation with stealth           | Scrapling (PlayWrightFetcher)     |

## Available MCP Tools

The Scrapling MCP server exposes these tools:

### `mcp__ScraplingServer__fetch`

Fast HTTP fetcher with TLS fingerprint impersonation. No browser overhead.

**Best for:** Simple pages, APIs, sites without JS rendering requirements.

```
mcp__ScraplingServer__fetch({
  url: "https://example.com/page",
  headless: true,
  follow_redirects: true,
  timeout: 30,
  adaptor_arguments: {}
})
```

### `mcp__ScraplingServer__stealthy_fetch`

Playwright-based stealth browser that bypasses Cloudflare and other anti-bot systems. Uses real browser fingerprints and human-like behavior.

**Best for:** Cloudflare-protected sites, aggressive anti-bot systems, JS-heavy pages.

```
mcp__ScraplingServer__stealthy_fetch({
  url: "https://protected-site.com",
  headless: true,
  block_webrtc: true,
  allow_webgl: false,
  timeout: 60
})
```

### `mcp__ScraplingServer__playwright_fetch`

Full Playwright browser automation. Maximum compatibility, highest resource usage.

**Best for:** Complex SPAs, multi-step interactions, pages requiring login state.

```
mcp__ScraplingServer__playwright_fetch({
  url: "https://spa-site.com/dashboard",
  headless: true,
  disable_resources: true,
  timeout: 60
})
```

### `mcp__ScraplingServer__find_elements`

Adaptive element finding using CSS selectors, text content, or attributes. Elements are tracked across site redesigns using fuzzy matching.

```
mcp__ScraplingServer__find_elements({
  url: "https://example.com",
  selector: "div.product-card",
  fetcher_type: "stealthy"
})
```

### `mcp__ScraplingServer__get_page_info`

Get page metadata: title, links, images, scripts, forms, meta tags.

```
mcp__ScraplingServer__get_page_info({
  url: "https://example.com",
  fetcher_type: "fetch"
})
```

## Workflow

### Step 1: Choose Fetcher Mode

| Site Characteristic                | Fetcher                    | Why                                 |
| ---------------------------------- | -------------------------- | ----------------------------------- |
| Static HTML, no anti-bot           | `fetch`                    | Fastest, lowest overhead            |
| Cloudflare, DataDome, PerimeterX   | `stealthy_fetch`           | TLS impersonation + stealth browser |
| Heavy JS SPA, needs full rendering | `playwright_fetch`         | Full browser engine                 |
| Unknown / first attempt            | `fetch` → `stealthy_fetch` | Start cheap, escalate if blocked    |

### Step 2: Execute

Start with the lightest fetcher that might work. Escalate only on failure (403, captcha, empty content).

```
Escalation chain:
1. fetch (fast HTTP, TLS impersonation)
   ↓ if blocked (403, empty, captcha)
2. stealthy_fetch (Playwright stealth, Cloudflare bypass)
   ↓ if still blocked
3. playwright_fetch (full browser, max compat)
   ↓ if still blocked
4. Report failure to user with details
```

### Step 3: Extract Data

After fetching, use `find_elements` for targeted extraction:

```
1. Fetch the page with appropriate fetcher
2. Use find_elements with CSS selectors to extract specific data
3. Structure results for user
```

For page overview, use `get_page_info` to get metadata, links, and structure.

### Step 4: Process Results

1. **Clean** — Strip irrelevant markup, deduplicate
2. **Format** — Present as markdown, table, or JSON
3. **Save** — Write to file if requested
4. **Memory** — Save reusable patterns for sites that needed escalation

## Common Patterns

### Anti-Bot Bypass

```
1. Try fetch first (fast, free)
2. If 403/captcha → stealthy_fetch with block_webrtc: true
3. Extract data with find_elements
```

### Adaptive Scraping (Survives Redesigns)

```
1. fetch or stealthy_fetch the page
2. find_elements with descriptive selectors
3. Scrapling tracks element identity across DOM changes
```

### Multi-Page Extraction

```
1. get_page_info → discover all links
2. Filter to target pages
3. fetch/stealthy_fetch each page
4. find_elements to extract structured data
```

## Integration with Other Skills

Scrapling tools are available to any skill that includes `mcp__ScraplingServer__*` in allowed-tools.

| Skill             | Use Case                                                      |
| ----------------- | ------------------------------------------------------------- |
| **research**      | Fallback when Firecrawl fails or credits exhausted            |
| **firecrawl**     | Complement — Scrapling handles anti-bot cases Firecrawl can't |
| **qa-cycle**      | Stealth fetch for testing protected staging environments      |
| **deep-research** | Additional data source with Cloudflare bypass                 |

## Setup

```bash
pip install "scrapling[all]"
scrapling install  # downloads browser engines + stealth patches
claude mcp add ScraplingServer "$(which scrapling)" mcp
```

Verify: `claude mcp list` should show `ScraplingServer`.

No API key needed — Scrapling runs entirely locally.

## Limits & Best Practices

- **Local only** — no cloud costs, no rate limits from provider
- **Respect robots.txt** — Scrapling does not bypass robots.txt by default
- Start with `fetch` (fastest) and escalate only when blocked
- Use `headless: true` in production, `headless: false` for debugging
- `block_webrtc: true` on stealthy_fetch prevents IP leaks
- `disable_resources: true` on playwright_fetch reduces bandwidth
- Adaptive tracking works best with semantic selectors (classes, data attributes) rather than positional selectors (nth-child)
