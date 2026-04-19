---
name: browserless
description: "Headless browser via Browserless. PDFs, screenshots, Lighthouse, JS rendering, anti-bot. Triggers on: browserless, headless browser, generate PDF, take screenshot, lighthouse audit, unblock site, browser automation."
user-invocable: true
context: fork
model: sonnet
effort: medium
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - WebSearch
  - AskUserQuestion
  - mcp__browserless__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  mcp__browserless__*: { openWorldHint: true }
  mcp__browserless__initialize_browserless: { idempotentHint: true }
  mcp__browserless__get_health: { readOnlyHint: true, idempotentHint: true }
  mcp__browserless__get_sessions: { readOnlyHint: true, idempotentHint: true }
  mcp__browserless__get_metrics: { readOnlyHint: true, idempotentHint: true }
  mcp__browserless__take_screenshot: { readOnlyHint: true }
  mcp__browserless__generate_pdf: { readOnlyHint: true }
  mcp__browserless__get_content: { readOnlyHint: true }
  mcp__browserless__run_performance_audit: { readOnlyHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
  agent-spawned:
    verbosity: minimal
---

# Browserless - Headless Browser Automation

Self-hosted headless Chrome automation via Browserless on the VPS. Generates PDFs, captures screenshots, extracts JS-rendered content, runs Lighthouse audits, and bypasses anti-bot protections.

## Available Tools

| Tool                          | Purpose               | When to Use                                          |
| ----------------------------- | --------------------- | ---------------------------------------------------- |
| `initialize_browserless`      | Connect to instance   | First call — establishes connection                  |
| `generate_pdf`                | URL/HTML to PDF       | Convert pages or raw HTML to PDF documents           |
| `take_screenshot`             | Capture page image    | Get png/jpeg/webp screenshots, full-page or viewport |
| `get_content`                 | Extract rendered HTML | Get page content after JS execution                  |
| `execute_function`            | Run browser-side JS   | Execute custom scripts in browser context            |
| `run_performance_audit`       | Lighthouse audit      | Performance, accessibility, SEO analysis             |
| `unblock`                     | Bypass bot detection  | Access anti-bot protected sites with stealth mode    |
| `execute_browserql`           | GraphQL queries       | Advanced browser state queries                       |
| `create_websocket_connection` | WebSocket session     | Puppeteer/Playwright remote connection               |
| `get_health`                  | Instance health       | Check if Browserless is running                      |
| `get_sessions`                | Active sessions       | List current browser sessions                        |
| `get_metrics`                 | Performance metrics   | Monitor instance performance                         |

## Workflow

### Step 1: Initialize Connection

Always initialize the connection first:

```
mcp__browserless__initialize_browserless({
  host: process.env.BROWSERLESS_HOST,
  port: parseInt(process.env.BROWSERLESS_PORT),
  token: process.env.BROWSERLESS_TOKEN,
  protocol: process.env.BROWSERLESS_PROTOCOL
})
```

### Step 2: Execute Task

#### Generate PDF

```
mcp__browserless__generate_pdf({
  url: "https://example.com/report",
  options: {
    format: "A4",
    printBackground: true,
    margin: { top: "1cm", bottom: "1cm", left: "1cm", right: "1cm" }
  }
})
```

From raw HTML:

```
mcp__browserless__generate_pdf({
  html: "<h1>Report</h1><p>Content here</p>",
  options: { format: "Letter" }
})
```

#### Take Screenshot

```
mcp__browserless__take_screenshot({
  url: "https://example.com",
  options: {
    type: "png",
    fullPage: true,
    quality: 90
  }
})
```

#### Extract Rendered Content

```
mcp__browserless__get_content({
  url: "https://spa-app.com/dashboard",
  waitForSelector: {
    selector: ".data-loaded",
    timeout: 10000
  }
})
```

#### Run Lighthouse Audit

```
mcp__browserless__run_performance_audit({
  url: "https://example.com",
  config: {
    extends: "lighthouse:default",
    settings: {
      onlyCategories: ["performance", "accessibility", "seo"]
    }
  }
})
```

#### Bypass Bot Detection

```
mcp__browserless__unblock({
  url: "https://protected-site.com",
  content: true,
  screenshot: true,
  stealth: true,
  blockAds: true
})
```

#### Execute Custom JS

```
mcp__browserless__execute_function({
  code: "export default async function({ page }) { await page.goto('https://example.com'); return await page.title(); }",
  context: { customData: "value" }
})
```

#### BrowserQL (GraphQL)

```
mcp__browserless__execute_browserql({
  query: "mutation { goto(url: \"https://example.com\") { status } }",
  variables: {}
})
```

## Common Patterns

### Invoice/Report PDF Generation

```
1. Prepare HTML content or target URL
2. generate_pdf with custom margins and backgrounds
3. Save output to file
```

### SPA Content Extraction

```
1. get_content with waitForSelector for dynamic content
2. Parse rendered HTML for data
3. Structure extracted data
```

### Site Performance Audit

```
1. run_performance_audit with all categories
2. Parse scores and recommendations
3. Generate actionable report
```

### Anti-Bot Scraping

```
1. unblock with stealth + content flags
2. Parse returned HTML content
3. Optionally capture screenshot for verification
```

## Browserless vs Other Tools

| Need                            | Use                                     | Notes                                          |
| ------------------------------- | --------------------------------------- | ---------------------------------------------- |
| JS-rendered content extraction  | **Browserless** `get_content`           | Remote, cloud-hosted                           |
| PDF from URL or HTML            | **Browserless** `generate_pdf`          | Remote, cloud-hosted                           |
| Lighthouse performance audit    | **Browserless** `run_performance_audit` | Remote, cloud-hosted                           |
| Bot-protected site access       | **Browserless** `unblock`               | Remote, stealth mode                           |
| Token-efficient page inspection | **PinchTab** `snap -i -c` / `text`      | Local, 5-13x cheaper than screenshots          |
| Local browser automation        | **PinchTab** CLI/API                    | Local, a11y tree + stable refs, multi-instance |
| General web scraping (markdown) | **Firecrawl** `firecrawl_scrape`        | Handles JS rendering                           |
| Multi-site crawling             | **Firecrawl** `firecrawl_crawl`         | Proxy rotation, anti-bot                       |
| Interactive browser testing     | **Chrome DevTools** MCP                 | Console/network monitoring                     |
| Full page interaction/clicks    | **Playwright** MCP                      | Complex automation sequences                   |

### PinchTab vs Browserless Decision

| Scenario                        | Choose                    | Why                                        |
| ------------------------------- | ------------------------- | ------------------------------------------ |
| Need remote/cloud execution     | **Browserless**           | PinchTab is local-only                     |
| Token budget is tight           | **PinchTab**              | `text` = ~800 tokens vs screenshot ~2K+    |
| Need Lighthouse audit           | **Browserless**           | PinchTab has no Lighthouse                 |
| Need element interaction by ref | **PinchTab**              | Stable refs, no coordinate guessing        |
| Need anti-bot bypass            | **Browserless** `unblock` | Or Scrapling for TLS fingerprinting        |
| PDF generation (remote)         | **Browserless**           | More options (margins, headers, etc.)      |
| PDF generation (local)          | **PinchTab** `pdf`        | Faster, no network round-trip              |
| Multi-instance parallel testing | **PinchTab**              | Built-in instance management + tab locking |

## Infrastructure

- **Self-hosted** on Contabo VPS (100.77.51.51)
- **Docker container**: `ghcr.io/browserless/chromium`
- **Config**: env vars `BROWSERLESS_HOST`, `BROWSERLESS_PORT`, `BROWSERLESS_TOKEN`, `BROWSERLESS_PROTOCOL`
- **MCP server**: `/Users/ps/.claude/mcp-servers/browserless-mcp/dist/index.js`

## Limits & Best Practices

- Always call `initialize_browserless` before other tools
- Use `waitForSelector` in `get_content` for SPAs to ensure content loads
- Set reasonable timeouts (default 30s) for slow pages
- Use `fullPage: true` for screenshots only when needed (larger output)
- Prefer `unblock` over `get_content` for bot-protected sites
- Use `get_health` to verify instance is running before batch operations
