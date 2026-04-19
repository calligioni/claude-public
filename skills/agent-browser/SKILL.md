---
name: agent-browser
description: "Browser automation via agent-browser CLI (Rust, CDP). Navigate, snapshot, click, fill, screenshot, PDF, batch mode, visual diff, network intercept, session persistence. Replaces browse CLI and PinchTab. Triggers on: agent-browser, browser automation, browse website, page snapshot, element refs, accessibility tree, take screenshot, scrape page, test web app, dogfood, visual diff."
user-invocable: true
context: fork
model: sonnet
effort: low
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - AskUserQuestion
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: false }
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

# agent-browser

Native Rust CLI for browser automation via CDP. Replaces `browse` CLI and PinchTab.

**Binary:** `/opt/homebrew/bin/agent-browser` (v0.25.4+)
**Chrome:** `~/.agent-browser/browsers/`

## Step 1: Load the skill from the CLI

Before running ANY agent-browser commands, load the current skill content:

```bash
agent-browser skills get agent-browser
```

This returns the full, version-matched command reference. The CLI serves its own docs — never guess at command syntax.

For specific workflows, load specialized skills:

```bash
agent-browser skills get dogfood      # Exploratory testing / QA
agent-browser skills get electron      # VS Code, Slack, Discord, Figma automation
agent-browser skills get slack         # Slack workspace automation
agent-browser skills get agent-browser --full  # Full reference with templates
```

## Step 2: Execute

Follow the loaded skill content for command syntax and workflows.

## Quick Reference (high-level only — details in loaded skill)

| Task                        | Command                                           |
| --------------------------- | ------------------------------------------------- |
| Navigate                    | `agent-browser open <url>`                        |
| Snapshot (a11y tree + refs) | `agent-browser snapshot`                          |
| Click                       | `agent-browser click <sel or @ref>`               |
| Fill input                  | `agent-browser fill <sel or @ref> <text>`         |
| Type (real keystrokes)      | `agent-browser type <sel or @ref> <text>`         |
| Press key                   | `agent-browser press <key>`                       |
| Screenshot                  | `agent-browser screenshot [path]`                 |
| PDF                         | `agent-browser pdf <path>`                        |
| JS eval                     | `agent-browser eval "<js>"`                       |
| Console logs                | `agent-browser console`                           |
| Page errors                 | `agent-browser errors`                            |
| Network requests            | `agent-browser network requests`                  |
| Visual diff                 | `agent-browser diff screenshot --baseline <path>` |
| Snapshot diff               | `agent-browser diff snapshot`                     |
| Batch mode                  | `agent-browser batch` (stdin JSON)                |
| Tabs                        | `agent-browser tab [new\|list\|close\|<n>]`       |

## Batch Mode (QA subagents)

Batch eliminates per-command process startup overhead for multi-step flows:

```bash
echo '[
  {"command": "open", "args": ["https://example.com"]},
  {"command": "snapshot"},
  {"command": "click", "args": ["@e5"]},
  {"command": "snapshot"}
]' | agent-browser batch
```

## Detection Logic

```bash
if command -v agent-browser >/dev/null 2>&1; then
  # Primary: agent-browser (Rust, CDP, sessions, batch, diff)
  agent-browser open "https://example.com"
  agent-browser snapshot
elif command -v browse >/dev/null 2>&1; then
  # Fallback: browse CLI (Bun, Playwright)
  browse goto "https://example.com"
  browse snapshot -i
elif command -v pinchtab >/dev/null 2>&1; then
  # Fallback: PinchTab (HTTP server + CLI)
  pinchtab nav "https://example.com"
  pinchtab snap -i -c
else
  # Last resort: Chrome DevTools MCP
  # Use mcp__chrome-devtools__* tools
fi
```

## Key Advantages Over browse/PinchTab

- **Batch mode** — single invocation for multi-step flows (critical for QA subagents)
- **Visual diff** — pixel diff against baselines for visual regression
- **Network interception** — route/abort/mock network requests, HAR recording
- **Session persistence** — auth vault, cookie/storage management across runs
- **Self-updating docs** — `agent-browser skills get` always matches installed version
- **Real keyboard input** — `keyboard type` for apps that reject programmatic fill
- **Video recording** — `record start/stop` for debugging
- **Trace/profiler** — Chrome DevTools trace and profiler capture
- **No daemon** — direct CDP connection, no persistent server process

## When to Use Other Tools

| Need                         | Use                                |
| ---------------------------- | ---------------------------------- |
| Lighthouse audit             | Chrome DevTools MCP or Browserless |
| Anti-bot / Cloudflare bypass | Scrapling                          |
| Multi-site crawl to markdown | Firecrawl                          |
| Full Playwright test suite   | Playwright directly                |
