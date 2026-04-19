---
name: pinchtab
description: "Local browser automation via PinchTab. A11y trees, element refs, screenshots, PDFs, JS eval. 5-13x cheaper. Triggers on: pinchtab, browser control, page snapshot, element refs, accessibility tree, pinch."
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
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: false }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
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

# PinchTab - Local Browser Automation

> **Note:** `agent-browser` is now the **primary** browser automation tool. Use `/agent-browser` for new work. PinchTab remains available for its unique strengths: profile management with persistent sessions, tab locking for multi-agent safety, stealth mode, and the HTTP API for non-Bash contexts.

Lightweight HTTP server + CLI for AI-controlled Chrome. Uses accessibility tree snapshots with stable element refs instead of screenshots — **5-13x cheaper in tokens**.

## Architecture

```
┌──────────────┐     HTTP      ┌──────────────┐     CDP      ┌─────────┐
│  Claude Code │ ──────────▶  │   PinchTab    │ ──────────▶ │  Chrome  │
│  (via Bash)  │  localhost    │   Server      │             │ Instance │
└──────────────┘   :9867      └──────────────┘              └─────────┘
```

- **Server** (`pinchtab`): Control plane — profiles, instances, routing, dashboard
- **Bridge** (`pinchtab bridge`): Per-instance lightweight runtime
- **Attach**: Register externally-managed Chrome processes

## Prerequisites

Ensure PinchTab is installed:

```bash
# Check if installed
pinchtab --version

# Install if needed
curl -fsSL https://pinchtab.com/install.sh | bash
# or: npm install -g pinchtab
```

## Core Workflow

The standard agent loop is **navigate → snapshot → act → re-snapshot**:

```bash
# 1. Navigate
pinchtab nav "https://example.com"

# 2. Snapshot (get element refs)
pinchtab snap -i -c    # -i = interactive only, -c = compact format

# 3. Act using refs
pinchtab click e5
pinchtab fill e12 "search query"
pinchtab press e12 Enter

# 4. Re-snapshot to verify
pinchtab snap -i -c
```

**Refs are stable** — no need to re-snapshot before every action. Only re-snapshot when the page changes significantly.

## CLI Commands

### Navigation & Inspection

| Command                         | Description                     | Token Cost |
| ------------------------------- | ------------------------------- | ---------- |
| `pinchtab nav <url>`            | Navigate to URL                 | —          |
| `pinchtab snap -i -c`           | Interactive elements, compact   | ~2,000     |
| `pinchtab snap -c`              | Full page, compact              | ~5,000     |
| `pinchtab snap`                 | Full page, JSON                 | ~10,500    |
| `pinchtab text`                 | Extract page text (readability) | ~800       |
| `pinchtab text --raw`           | Raw text extraction             | ~800       |
| `pinchtab ss`                   | Screenshot (base64)             | ~2,000     |
| `pinchtab ss -o file.jpg -q 80` | Screenshot to file              | —          |

### Interaction

| Command                        | Description                      |
| ------------------------------ | -------------------------------- |
| `pinchtab click <ref>`         | Click element by ref             |
| `pinchtab fill <ref> "<text>"` | Fill input field                 |
| `pinchtab type <ref> "<text>"` | Type text (keystroke simulation) |
| `pinchtab press <ref> <key>`   | Press key (Enter, Tab, Escape)   |

### Tab Management

| Command                    | Description    |
| -------------------------- | -------------- |
| `pinchtab tabs`            | List open tabs |
| `pinchtab tabs new <url>`  | Open new tab   |
| `pinchtab tabs close <id>` | Close tab      |

### Advanced

| Command                                | Description         |
| -------------------------------------- | ------------------- |
| `pinchtab eval "<js>"`                 | Evaluate JavaScript |
| `pinchtab pdf -o file.pdf`             | Export page as PDF  |
| `pinchtab pdf --landscape --scale 0.8` | PDF with options    |

## HTTP API (for programmatic use)

When CLI is insufficient, use the HTTP API directly via `curl`:

### Key Endpoints

| Method | Endpoint                                      | Purpose                           |
| ------ | --------------------------------------------- | --------------------------------- |
| POST   | `/navigate`                                   | Navigate to URL                   |
| GET    | `/snapshot?filter=interactive&format=compact` | Get element tree                  |
| POST   | `/action`                                     | Click, fill, press, hover, scroll |
| POST   | `/actions`                                    | Batch multiple actions            |
| GET    | `/text`                                       | Extract page text                 |
| GET    | `/screenshot`                                 | Capture screenshot                |
| GET    | `/tabs/{id}/pdf`                              | Export PDF                        |
| POST   | `/evaluate`                                   | Run JavaScript                    |
| GET    | `/cookies`                                    | Get cookies                       |
| POST   | `/cookies`                                    | Set cookies                       |
| GET    | `/health`                                     | Health check                      |

### Action Types

```bash
# Click
curl -X POST localhost:9867/action -d '{"kind":"click","ref":"e5"}'

# Fill
curl -X POST localhost:9867/action -d '{"kind":"fill","ref":"e12","text":"hello"}'

# Press key
curl -X POST localhost:9867/action -d '{"kind":"press","ref":"e12","key":"Enter"}'

# Hover
curl -X POST localhost:9867/action -d '{"kind":"hover","ref":"e3"}'

# Scroll
curl -X POST localhost:9867/action -d '{"kind":"scroll","scrollY":500}'

# Select dropdown
curl -X POST localhost:9867/action -d '{"kind":"select","ref":"e7","value":"option2"}'
```

### Batch Actions

```bash
curl -X POST localhost:9867/actions -d '{
  "actions": [
    {"kind":"fill","ref":"e5","text":"user@example.com"},
    {"kind":"fill","ref":"e8","text":"password123"},
    {"kind":"click","ref":"e10"}
  ],
  "stopOnError": true
}'
```

### Snapshot Filters

| Parameter   | Values                            | Effect                         |
| ----------- | --------------------------------- | ------------------------------ |
| `filter`    | `interactive`, `text`, `all`      | Element subset                 |
| `format`    | `compact`, `json`, `text`, `yaml` | Output format                  |
| `depth`     | number                            | Limit tree depth               |
| `diff`      | `true`                            | Smart diff since last snapshot |
| `selector`  | CSS selector                      | Scope to element               |
| `maxTokens` | number                            | Truncate output                |

**Most efficient combo:** `?filter=interactive&format=compact`

## Profile Management

Profiles persist cookies, storage, and session state between runs:

```bash
# Start server with profiles dashboard
pinchtab

# Via API
curl -X POST localhost:9867/profiles/start -d '{"name":"my-profile","port":9868}'

# Point CLI at specific instance
PINCHTAB_URL=http://localhost:9868 pinchtab nav "https://app.example.com"
```

**Human-agent handoff:** Start a profile in headed mode, log in manually (handle 2FA), then let the agent use the authenticated session.

## Multi-Instance (Parallel Testing)

```bash
# Launch multiple instances
curl -X POST localhost:9867/instances/launch -d '{"name":"test-1","mode":"headless"}'
curl -X POST localhost:9867/instances/launch -d '{"name":"test-2","mode":"headless"}'

# Each instance gets its own port — use PINCHTAB_URL to target
```

### Tab Locking (Multi-Agent Safety)

```bash
# Lock a tab for exclusive access
curl -X POST localhost:9867/tab/lock -d '{"tabId":"abc","owner":"agent-1","timeoutSec":30}'

# Unlock when done
curl -X POST localhost:9867/tab/unlock -d '{"tabId":"abc","owner":"agent-1"}'
```

## Environment Variables

| Variable              | Default                      | Purpose                          |
| --------------------- | ---------------------------- | -------------------------------- |
| `PINCHTAB_URL`        | `http://localhost:9867`      | Server URL for CLI               |
| `PINCHTAB_TOKEN`      | —                            | Auth token for CLI               |
| `BRIDGE_HEADLESS`     | `true`                       | Run Chrome headless              |
| `BRIDGE_PORT`         | `9867`                       | HTTP port                        |
| `BRIDGE_TOKEN`        | —                            | Bearer auth token                |
| `BRIDGE_PROFILE`      | `~/.pinchtab/chrome-profile` | Chrome profile dir               |
| `BRIDGE_STEALTH`      | `light`                      | Stealth level: `light` or `full` |
| `BRIDGE_BLOCK_IMAGES` | `false`                      | Block image loading              |
| `BRIDGE_BLOCK_MEDIA`  | `false`                      | Block all media                  |
| `BRIDGE_MAX_TABS`     | `20`                         | Max open tabs                    |
| `BRIDGE_TIMEOUT`      | `15`                         | Action timeout (sec)             |
| `BRIDGE_NAV_TIMEOUT`  | `30`                         | Navigation timeout (sec)         |

## Token Optimization

| Approach           | Tokens  | Use When                       |
| ------------------ | ------- | ------------------------------ |
| `pinchtab text`    | ~800    | Content extraction only        |
| `snap -i -c`       | ~2,000  | Need to interact with elements |
| `ss -q 60`         | ~2,000  | Visual verification needed     |
| `snap -c`          | ~5,000  | Full page structure            |
| `snap` (full JSON) | ~10,500 | Debugging, detailed analysis   |

**Tips:**

- Wait 3+ seconds after navigation before snapshotting (Chrome needs time to build a11y tree)
- Use `--max-tokens` to cap snapshot output
- Use `diff=true` for subsequent snapshots in a workflow
- Use `selector` to scope snapshots to specific page sections
- Block images/media when you only need text: `BRIDGE_BLOCK_IMAGES=true`

## Security

- Binds to `127.0.0.1` by default — local only
- IDPI (Indirect Prompt Injection Defense) enabled
- Use `BRIDGE_TOKEN` when exposing to network
- Uses isolated Chrome profile — no access to your daily browser
- No telemetry, no phone-home
- MIT licensed, builds via GitHub Actions with SHA256 checksums

## PinchTab vs Other Browser Tools

| Need                              | Use                                        |
| --------------------------------- | ------------------------------------------ |
| Token-efficient page interaction  | **PinchTab** (a11y tree + refs)            |
| Interactive browser testing (MCP) | **Chrome DevTools** MCP                    |
| PDF from URL/HTML (remote)        | **Browserless** `generate_pdf`             |
| Lighthouse audit (remote)         | **Browserless** `run_performance_audit`    |
| Anti-bot / Cloudflare bypass      | **Scrapling** or **Browserless** `unblock` |
| Multi-site crawling to markdown   | **Firecrawl** `firecrawl_crawl`            |
| Full Playwright automation        | **Playwright** MCP                         |

## browse CLI Alternative

`browse` is a compiled headless Chromium CLI at `~/.local/bin/browse`. Zero MCP token overhead, ~100ms per call after cold start. Shares the same conceptual model as PinchTab (accessibility tree snapshots with element refs, navigate → snapshot → act → re-snapshot loop) but adds capabilities not available in PinchTab.

### Command Mapping

| PinchTab                   | browse equivalent                   | Notes                                         |
| -------------------------- | ----------------------------------- | --------------------------------------------- |
| `pinchtab nav <url>`       | `browse goto <url>`                 | Same                                          |
| `pinchtab snap -i -c`      | `browse snapshot -i`                | browse uses compact by default                |
| `pinchtab snap -c`         | `browse snapshot`                   | Full page                                     |
| `pinchtab text`            | `browse text`                       | Same                                          |
| `pinchtab ss -o file.jpg`  | `browse screenshot file.jpg`        | Same                                          |
| `pinchtab click e5`        | `browse click @e5`                  | browse uses @e prefix                         |
| `pinchtab fill e12 "val"`  | `browse fill @e12 "val"`            | browse uses @e prefix                         |
| `pinchtab press e12 Enter` | `browse press Enter`                | browse press is global                        |
| `pinchtab eval "js"`       | `browse js "js"`                    | Same                                          |
| `pinchtab pdf -o file.pdf` | `browse pdf file.pdf`               | Same                                          |
| `pinchtab tabs`            | `browse tabs`                       | Same                                          |
| N/A                        | `browse snapshot -D`                | **Diff vs previous — unique to browse**       |
| N/A                        | `browse snapshot -a -o path`        | **Annotated screenshot — unique to browse**   |
| N/A                        | `browse snapshot -C`                | **Non-ARIA clickables — unique to browse**    |
| N/A                        | `browse console` / `browse network` | **Ring buffer capture — unique to browse**    |
| N/A                        | `browse cookie-import-browser`      | **Import browser cookies — unique to browse** |

### browse-Exclusive Features

- **`snapshot -D`** — unified diff vs previous snapshot; ideal for verifying that an action changed the expected elements
- **`snapshot -a -o path.png`** — annotated screenshot with ref labels overlaid on the image; useful for visual debugging
- **`snapshot -C`** — cursor-interactive mode; finds non-ARIA clickables (divs with onclick handlers, elements with `cursor:pointer`) that standard a11y tree traversal misses
- **`console` / `network`** — ring buffer captures (50K capacity) for console messages and network requests; essential for debugging JS errors and API calls
- **`cookie-import-browser`** — import cookies from Chrome/Arc/Brave/Edge via macOS Keychain decryption; enables authenticated sessions without manual login
- **Multi-workspace isolation** — set `BROWSE_STATE_FILE` to a different path per agent for fully isolated sessions

### Headed Mode Escalation

For visual/CSS/layout failures that headless `browse` or PinchTab screenshots can't diagnose, escalate to `/open-gstack-browser` — a real steerable Chromium with Claude Code sidebar for live interactive debugging. This is the intermediate step between headless automation and manual inspection.

### When to Use Which

**Use browse when:**

- You need console/network monitoring (`browse console`, `browse network`)
- You need snapshot diffing to verify page changes (`browse snapshot -D`)
- You need annotated screenshots for visual debugging (`browse snapshot -a`)
- You need to find non-ARIA clickables (`browse snapshot -C`)
- You need to import browser cookies without manual login (`browse cookie-import-browser`)
- You need multi-workspace isolation via `BROWSE_STATE_FILE`
- MCP token overhead matters (high call-count sessions — browse has zero MCP overhead)

**Use PinchTab when:**

- You need profile management with persistent sessions across runs
- You need tab locking for multi-agent safety (`/tab/lock`)
- You need stealth mode (`BRIDGE_STEALTH`)
- You need the HTTP API for programmatic access from non-Bash contexts

### Detection Logic

```bash
# Prefer agent-browser, then browse, then pinchtab
if command -v agent-browser >/dev/null 2>&1; then
  # Primary: agent-browser (Rust, CDP, sessions, batch)
  agent-browser open "https://example.com"
  agent-browser snapshot
  agent-browser click @e5
elif command -v browse >/dev/null 2>&1; then
  # First fallback: browse CLI
  browse goto "https://example.com"
  browse snapshot -i
  browse click @e5
elif command -v pinchtab >/dev/null 2>&1; then
  # Second fallback: PinchTab
  pinchtab nav "https://example.com"
  pinchtab snap -i -c
  pinchtab click e5
else
  # Last resort: Chrome DevTools MCP
  # Use mcp__chrome-devtools__* tools
fi
```

## Common Patterns

### Form Submission

```bash
pinchtab nav "https://app.example.com/login"
sleep 3
pinchtab snap -i -c
# Output: e5=username, e8=password, e10=submit
pinchtab fill e5 "user@example.com"
pinchtab fill e8 "password123"
pinchtab click e10
sleep 2
pinchtab snap -i -c   # verify logged in
```

### Data Extraction

```bash
pinchtab nav "https://dashboard.example.com"
sleep 3
pinchtab text   # get readable text (~800 tokens)
# or for structured data:
pinchtab eval "JSON.stringify(Array.from(document.querySelectorAll('table tr')).map(r => Array.from(r.cells).map(c => c.textContent)))"
```

### Multi-Page Testing

```bash
for url in "/" "/about" "/pricing" "/blog"; do
  pinchtab nav "http://localhost:3000${url}"
  sleep 3
  # Check for console errors via snapshot
  pinchtab snap -c --max-tokens 1000
  pinchtab text
done
```

### Screenshot Workflow

```bash
pinchtab nav "https://example.com"
sleep 3
pinchtab ss -o /tmp/homepage.jpg -q 80
# Read the screenshot file for visual verification
```
