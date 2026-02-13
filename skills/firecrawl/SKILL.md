---
name: firecrawl
description: "Web scraping, crawling, site mapping, search, and autonomous data extraction via Firecrawl. Converts websites to LLM-ready markdown or structured data. Handles JS rendering, anti-bot protection, and proxy rotation. Use for: scraping pages, crawling sites, searching the web, mapping URLs, or autonomous multi-source research. Triggers on: scrape, crawl, web data, extract website, site map, web research, firecrawl."
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - mcp__firecrawl__*
  - mcp__memory__*
memory: user
---

# Firecrawl - Web Data Extraction Skill

Extract, crawl, search, and gather data from any website using the Firecrawl MCP server.

## Available Tools

| Tool                                     | Purpose                | When to Use                                              |
| ---------------------------------------- | ---------------------- | -------------------------------------------------------- |
| `mcp__firecrawl__firecrawl_scrape`       | Single page extraction | Get clean markdown/data from one URL                     |
| `mcp__firecrawl__firecrawl_batch_scrape` | Multi-URL extraction   | Process multiple URLs in parallel                        |
| `mcp__firecrawl__firecrawl_crawl`        | Full site crawl        | Extract content across entire site with depth control    |
| `mcp__firecrawl__firecrawl_map`          | URL discovery          | Find all pages on a site before targeted scraping        |
| `mcp__firecrawl__firecrawl_search`       | Web search + scrape    | Search the web and get scraped results                   |
| `mcp__firecrawl__firecrawl_agent`        | Autonomous research    | Describe what data you need; agent finds and extracts it |

## Workflow

### Step 1: Understand the Request

Determine which Firecrawl tool fits the user's need:

| User Intent                       | Tool                     | Example                                     |
| --------------------------------- | ------------------------ | ------------------------------------------- |
| "Get content from this URL"       | `firecrawl_scrape`       | Extract a blog post as markdown             |
| "Scrape these 10 URLs"            | `firecrawl_batch_scrape` | Extract pricing from competitor pages       |
| "Crawl this entire site"          | `firecrawl_crawl`        | Index all docs from a documentation site    |
| "What pages does this site have?" | `firecrawl_map`          | Discover all URLs before targeted scraping  |
| "Search the web for X"            | `firecrawl_search`       | Find and extract info across multiple sites |
| "Find me data about X"            | `firecrawl_agent`        | Autonomous multi-source research            |

### Step 2: Execute

#### Single Page Scrape

```
mcp__firecrawl__firecrawl_scrape({
  url: "https://example.com/page",
  formats: ["markdown"],        // markdown, html, screenshot, links
  onlyMainContent: true,        // strip navs, footers, ads
  waitFor: 2000                 // wait for JS rendering (ms)
})
```

**With structured extraction (JSON schema):**

```
mcp__firecrawl__firecrawl_scrape({
  url: "https://example.com/pricing",
  formats: ["extract"],
  extract: {
    schema: {
      type: "object",
      properties: {
        plans: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              price: { type: "string" },
              features: { type: "array", items: { type: "string" } }
            }
          }
        }
      }
    }
  }
})
```

#### Batch Scrape (Multiple URLs)

```
mcp__firecrawl__firecrawl_batch_scrape({
  urls: ["https://a.com", "https://b.com", "https://c.com"],
  formats: ["markdown"],
  onlyMainContent: true
})
```

#### Site Crawl

```
mcp__firecrawl__firecrawl_crawl({
  url: "https://docs.example.com",
  maxDepth: 3,
  limit: 50,
  allowBackwardLinks: false
})
```

#### URL Map

```
mcp__firecrawl__firecrawl_map({
  url: "https://example.com",
  limit: 100
})
```

#### Web Search + Scrape

```
mcp__firecrawl__firecrawl_search({
  query: "best React state management libraries 2026",
  limit: 5,
  lang: "en",
  country: "us"
})
```

#### Autonomous Agent

For complex, multi-source research where you don't know the exact URLs:

```
mcp__firecrawl__firecrawl_agent({
  prompt: "Find the pricing, features, and customer reviews for the top 3 project management tools for small teams"
})
```

### Step 3: Process Results

After extraction:

1. **Clean the data** - Remove noise, duplicates, irrelevant sections
2. **Format for user** - Present as markdown, table, or structured data
3. **Save if requested** - Write to file for later use
4. **Store insights** - Save reusable patterns to memory if high-value

## Common Patterns

### Competitor Analysis

```
1. firecrawl_map → discover competitor's site pages
2. firecrawl_batch_scrape → extract pricing, features, about pages
3. Structure into comparison table
```

### Documentation Indexing

```
1. firecrawl_map → find all doc pages
2. firecrawl_crawl → extract all content with depth control
3. Save as local markdown files
```

### Market Research

```
1. firecrawl_search → find relevant articles/reports
2. firecrawl_scrape → deep extract from top results
3. Synthesize findings
```

### Company Intelligence (M&A)

```
1. firecrawl_agent → "Find revenue, team size, funding for [company]"
2. firecrawl_scrape → extract specific pages (about, team, pricing)
3. Structure into due diligence format
```

## Integration with Other Skills

This skill's Firecrawl tools are available to any skill that includes `mcp__firecrawl__*` in its allowed-tools. Key integrations:

| Skill              | Use Case                                                        |
| ------------------ | --------------------------------------------------------------- |
| **mna-toolkit**    | Company research, market sizing, competitive intel              |
| **cto**            | Tech stack research, security advisories, architecture patterns |
| **website-design** | Competitor design analysis, component library research          |
| **cpo-ai-skill**   | Product research, feature comparison, market analysis           |

## Limits & Best Practices

- **Free tier**: 500 credits/month, 5 agent executions/day
- **Rate limiting**: Built-in retry with exponential backoff
- **JS rendering**: Automatic — handles SPAs and dynamic content
- **Anti-bot**: Built-in proxy rotation and bot detection bypass
- Use `onlyMainContent: true` to reduce noise and token usage
- Use `firecrawl_map` before `firecrawl_crawl` to scope the crawl
- Prefer `firecrawl_search` over `firecrawl_agent` for simple lookups
- Use `firecrawl_agent` only for complex multi-source research

## Setup

Requires `FIRECRAWL_API_KEY` environment variable. Get a key at https://firecrawl.dev/app/api-keys

The MCP server is configured in `~/.claude/settings.json` under `mcp.mcpServers.firecrawl`.
