---
name: nanoclaw
description: "Install and configure NanoClaw — a lightweight Claude-native agent runtime with Docker Sandbox isolation, persistent memory, scheduled tasks, and multi-channel messaging (WhatsApp, Telegram, Slack, Discord, Gmail). Triggers on: nanoclaw, nanoclaw setup, agent runtime, docker sandbox agent, nanoclaw configure."
argument-hint: "<setup | add-channel <telegram|gmail|discord|slack> | sandbox | schedule <task> | swarm | status | --help>"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - WebSearch
  - WebFetch
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
---

# NanoClaw — Claude-Native Agent Runtime

Lightweight open-source AI agent runtime built on Claude Code + Anthropic Agents SDK. ~15 source files, ~3,900 lines. 100x smaller than OpenClaw. Docker Sandbox micro-VM isolation out of the box.

**Repo:** https://github.com/qwibitai/nanoclaw
**Docs:** https://nanoclaw.dev

## Commands

- `/nanoclaw setup` — Full install: clone repo, install deps, configure container runtime, set up messaging channels
- `/nanoclaw add-channel <telegram|gmail|discord|slack>` — Add a messaging channel to an existing install
- `/nanoclaw sandbox` — Enable Docker Sandbox micro-VM isolation (upgrade from plain Docker/Apple Container)
- `/nanoclaw schedule <description>` — Create a scheduled task (cron, interval, or one-shot)
- `/nanoclaw swarm` — Configure a multi-agent swarm with specialized sub-agents
- `/nanoclaw status` — Check health of NanoClaw instance (process, container runtime, channels, scheduled tasks)
- `/nanoclaw` (no args) — Interactive: detect what's needed and guide user

## Architecture Overview

```
Host machine
  └─ NanoClaw (single Node.js process)
       ├─ src/index.ts          — Orchestrator: state, message loop, agent invocation
       ├─ src/channels/         — Self-registering channel plugins
       │   ├─ whatsapp.ts       — Baileys (QR auth)
       │   ├─ telegram.ts       — Bot API
       │   ├─ gmail.ts          — Composio OAuth
       │   ├─ discord.ts        — Bot token
       │   └─ slack.ts          — Bot token
       ├─ src/container-runner.ts — Spawns ephemeral agent containers
       ├─ src/task-scheduler.ts   — Cron/interval/one-shot jobs
       ├─ src/db.ts              — SQLite (better-sqlite3)
       ├─ src/ipc.ts             — Filesystem-based IPC
       ├─ src/router.ts          — Message formatting & output routing
       └─ src/group-queue.ts     — Per-group concurrency (parallel across groups, serial within)

Container runtime (Docker | Apple Container | Docker Sandbox)
  └─ Ephemeral agent containers
       ├─ Node.js 22-slim + Chromium
       ├─ Claude Code + agent-browser
       ├─ Mounted: /nanoclaw (project), /group (memory), /input (session)
       └─ NOT mounted: ~/.ssh, ~/.gnupg, ~/.aws, ~/.env
```

## Workflow: `/nanoclaw setup`

### Step 1: Prerequisites Check

```bash
# Required
node --version    # Must be 20+
docker --version  # Or verify Apple Container on macOS
claude --version  # Claude Code must be installed
```

If any missing, guide user through installation.

### Step 2: Clone & Install

```bash
# Clone into user's preferred location
git clone https://github.com/qwibitai/nanoclaw.git
cd nanoclaw
npm install
```

### Step 3: Configure Authentication

Check for existing Anthropic credentials:

1. **Claude Code OAuth** (preferred) — no API key needed, NanoClaw inherits auth
2. **API key** — create `.env` with `ANTHROPIC_API_KEY=sk-ant-...`

Ask user which method. If API key, guide them to https://console.anthropic.com/settings/keys

### Step 4: Container Runtime

Detect platform and configure:

| Platform | Default Runtime | Upgrade Path   |
| -------- | --------------- | -------------- |
| macOS    | Apple Container | Docker Sandbox |
| Linux    | Docker          | Docker Sandbox |

If Docker not installed on Linux:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Build the agent container:

```bash
./container/build.sh
```

### Step 5: Messaging Channel Setup

Ask user which channels to configure. At minimum one channel is needed.

**WhatsApp** (built-in, configured during setup):

- Scan QR code displayed in terminal
- Auto-detects groups

**Other channels** — delegate to `/nanoclaw add-channel <name>`

### Step 6: Background Service

**macOS:**

```bash
# Install launchd plist
cp launchd/nanoclaw.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/nanoclaw.plist
```

**Linux:**

```bash
# Install systemd service
mkdir -p ~/.config/systemd/user/
cp setup/nanoclaw.service ~/.config/systemd/user/
systemctl --user enable nanoclaw
systemctl --user start nanoclaw
```

### Step 7: Verify

```bash
# Check process is running
# Check container runtime responds
# Send test message through configured channel
```

## Workflow: `/nanoclaw add-channel <channel>`

### Telegram

1. Guide user to message @BotFather on Telegram → `/newbot`
2. Collect bot token
3. Add to `.env`: `TELEGRAM_BOT_TOKEN=...`
4. Register chat IDs (format: `tg:123456789` or `tg:-1001234567890` for groups)
5. Restart NanoClaw

### Gmail

1. Set up Composio OAuth integration
2. Configure trigger rules (which emails activate agent)
3. Test with a sample email

### Discord

1. Create bot at https://discord.com/developers/applications
2. Collect bot token
3. Add to `.env`: `DISCORD_BOT_TOKEN=...`
4. Invite bot to server with appropriate permissions
5. Register channel IDs

### Slack

1. Create Slack app at https://api.slack.com/apps
2. Configure bot token scopes (chat:write, channels:read, etc.)
3. Add to `.env`: `SLACK_BOT_TOKEN=xoxb-...`
4. Install to workspace
5. Register channel IDs

After adding any channel, restart NanoClaw:

```bash
# macOS
launchctl kickstart -k gui/$(id -u)/nanoclaw

# Linux
systemctl --user restart nanoclaw
```

## Workflow: `/nanoclaw sandbox`

Enable Docker Sandbox micro-VM isolation (partnership with Docker, March 2026).

### Prerequisites

- Docker Desktop 4.40+ with Sandbox support
- macOS (Apple Silicon) or Linux

### Setup

```bash
# Create sandbox workspace
mkdir -p ~/nanoclaw-workspace

# Copy NanoClaw into workspace
cp -r /path/to/nanoclaw/* ~/nanoclaw-workspace/

# Create sandbox
docker sandbox create --name nanoclaw shell ~/nanoclaw-workspace

# Start sandbox
docker sandbox start nanoclaw
```

### What changes

| Aspect          | Plain Docker          | Docker Sandbox              |
| --------------- | --------------------- | --------------------------- |
| Isolation       | Container (cgroups)   | Micro-VM (hypervisor)       |
| API key access  | Passed via stdin      | Proxy-managed (never in VM) |
| Startup time    | ~500ms                | ~200ms                      |
| Host visibility | Mount allowlist       | Only workspace dir          |
| Security model  | Container escape risk | VM escape required          |

### Management

```bash
docker sandbox list              # List sandboxes
docker sandbox stop nanoclaw     # Stop
docker sandbox start nanoclaw    # Start
docker sandbox rm nanoclaw       # Remove
```

## Workflow: `/nanoclaw schedule <description>`

Create scheduled tasks that run Claude at specified intervals.

### Schedule Types

| Type    | Syntax Example                       | Use Case                  |
| ------- | ------------------------------------ | ------------------------- |
| `at`    | `at 2026-03-14T08:00:00`             | One-time execution        |
| `every` | `every 5m` / `every 1h` / `every 1d` | Interval-based            |
| `cron`  | `0 8 * * 1-5` (weekdays at 8am)      | Standard cron expressions |

### Configuration

Tasks are stored in SQLite (`data/nanoclaw.db`) and persist across restarts.

Each task defines:

- **Schedule** — when to run
- **Prompt** — what Claude should do
- **Group** — which memory context to use
- **Channel** — where to send results (WhatsApp, Telegram, etc.)

### Error Handling

- Exponential backoff on failure: 30s → 1m → 5m → 15m → 60m
- Backoff resets after next successful run
- Failed executions logged, don't halt scheduler

### Examples

Ask user to describe what they want scheduled, then configure:

- "Check if Contably staging is up every 30 minutes, notify me on Telegram"
- "Send a daily briefing to WhatsApp at 8am with news about AI agents"
- "Run a GEO visibility audit every Sunday at 9am"

## Workflow: `/nanoclaw swarm`

Configure multi-agent swarm with specialized sub-agents.

### Architecture

```
Main orchestrator (NanoClaw instance)
  ├── Agent 1 (e.g., Telegram bot "researcher") — own container, own memory
  ├── Agent 2 (e.g., Telegram bot "analyst")    — own container, own memory
  ├── Agent 3 (e.g., Telegram bot "writer")     — own container, own memory
  └── Each isolated: filesystem, memory, session
```

### Setup Steps

1. **Define agents** — Ask user how many sub-agents and their roles
2. **Create channel endpoints** — Each agent gets its own Telegram bot (recommended) or channel
3. **Configure memory** — Create `groups/{agent-name}/CLAUDE.md` with role-specific system prompt
4. **Set up orchestration** — Main agent knows how to delegate to sub-agents
5. **Test** — Send a task that requires coordination

### Design Principles

- 3-5 sub-agents max (coordination degrades above 5)
- Each agent gets a focused role and scoped filesystem access
- Orchestrator decomposes tasks and assigns, sub-agents execute and report
- All containers ephemeral — no persistent agent state in containers

## Workflow: `/nanoclaw status`

### Health Checks

```
NanoClaw Status
===============

Process:    ✓ Running (PID 12345, uptime 3d 4h)
Runtime:    ✓ Docker Sandbox (nanoclaw sandbox running)
Database:   ✓ SQLite OK (data/nanoclaw.db, 2.3MB)

Channels:
  WhatsApp: ✓ Connected (3 groups)
  Telegram: ✓ Connected (bot @my_agent_bot)
  Gmail:    ✗ Not configured
  Discord:  ✗ Not configured
  Slack:    ✗ Not configured

Scheduled Tasks: 2 active
  ✓ daily-briefing    (cron: 0 8 * * *)     Last run: 2h ago
  ✓ health-check      (every: 30m)          Last run: 12m ago

Groups: 3 active
  main         — 142 messages, last active 5m ago
  family-chat  — 87 messages, last active 2h ago
  work-team    — 203 messages, last active 1d ago
```

## Key Paths

| Purpose           | Location                                  |
| ----------------- | ----------------------------------------- |
| Source code       | `src/`                                    |
| Container image   | `container/Dockerfile`                    |
| Group memories    | `groups/{name}/CLAUDE.md`                 |
| Conversation logs | `groups/{name}/logs/`                     |
| SQLite database   | `data/nanoclaw.db`                        |
| Session state     | `data/sessions/{group}/.claude/`          |
| IPC queue         | `data/queue/`                             |
| Mount allowlist   | `~/.config/nanoclaw/mount-allowlist.json` |
| Config            | `.env`                                    |
| Skills            | `.claude/skills/`                         |
| Service (macOS)   | `~/Library/LaunchAgents/nanoclaw.plist`   |
| Service (Linux)   | `~/.config/systemd/user/nanoclaw.service` |

## Security Model

NanoClaw follows a "design for distrust" philosophy — security enforced at OS/VM layer, not by trusting agent behavior.

**Guarantees:**

- Each agent runs in an ephemeral, isolated container
- Filesystem mount allowlist (`~/.config/nanoclaw/mount-allowlist.json`) blocks sensitive dirs
- API keys passed via stdin, never stored on disk inside containers
- Docker Sandbox adds hypervisor-level isolation (micro-VM)
- Per-group memory isolation — agents in different groups cannot see each other's data

## Troubleshooting

If anything goes wrong during setup or operation:

```bash
cd /path/to/nanoclaw
claude
/debug
```

NanoClaw's built-in `/debug` skill checks Node.js version, container runtime, API connectivity, and credentials.

## Integration with Existing Skills

NanoClaw complements the existing skill system:

| Existing Skill     | NanoClaw Enhancement                                             |
| ------------------ | ---------------------------------------------------------------- |
| `/qa-cycle`        | Run QA agents in Docker Sandboxes for OS-level isolation         |
| `/chief-geo`       | Deploy as always-on scheduled NanoClaw agent with Slack/Telegram |
| `/parallel-dev`    | Docker Sandbox as hardened alternative to bare worktrees         |
| `/cto` (swarm)     | Each analyst runs in isolated container with scoped filesystem   |
| `/proposal-source` | Sandboxed agent crawls client sites, generates PDF safely        |
