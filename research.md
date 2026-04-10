# Research: Shared Memory & Secrets Parity Across Machines

**Date:** 2026-04-10
**Scope:** Achieve full parity of memory, secrets, and knowledge systems across MacBook Air (primary), Mac Mini M4 Pro (Tailscale SSH), and Contabo VPS (Tailscale SSH).

## Prior Context (from memory)

- `reference_vps_connection.md` — VPS at 100.77.51.51, SSH as root
- `reference_search_api_keys.md` — Brave + Exa keys in macOS Keychain (claims iCloud sync — incorrect for generic passwords)
- `reference_openrouter_api.md` — Notes "Mac Mini: not in keychain (SSH blocks interactive auth)"
- `reference_cloudflare.md` — Cloudflare token stored in Keychain + `~/.config/cloudflare/.env` on Mini + VPS

## Current Architecture

### Machine Inventory

| Machine         | Hostname            | SSH                     | User | OS    | Tailscale IP   |
| --------------- | ------------------- | ----------------------- | ---- | ----- | -------------- |
| MacBook Air     | pierres-macbook-air | local                   | ps   | macOS | 100.65.26.31   |
| Mac Mini M4 Pro | mac-mini-2          | `ssh mini`              | psm2 | macOS | 100.66.244.112 |
| Contabo VPS     | vmi3065960          | `ssh root@100.77.51.51` | root | Linux | 100.77.51.51   |

### What's Shared Today (via git + symlinks)

All three machines have `~/.claude-setup/` as a git clone, with symlinks from `~/.claude/` to it:

| Item               | Mac (primary)                      | Mac Mini            | VPS                                      |
| ------------------ | ---------------------------------- | ------------------- | ---------------------------------------- |
| `skills/`          | symlink to repo                    | symlink to repo     | symlink to repo                          |
| `agents/`          | symlink to repo                    | symlink to repo     | symlink to repo                          |
| `hooks/`           | symlink to repo                    | symlink to repo     | symlink to repo                          |
| `rules/`           | symlink to repo                    | symlink to repo     | symlink to repo                          |
| `commands/`        | symlink to repo (missing from Mac) | symlink to repo     | in `~/.claude/commands/` (not symlinked) |
| `settings.json`    | **symlink** to repo                | **symlink** to repo | **own copy** (diverged)                  |
| `tools/`           | in repo                            | in repo (via git)   | symlink to repo                          |
| `memory/auto/*.md` | in repo                            | in repo (via git)   | in repo (via git)                        |

**Git sync:** LaunchAgent `com.claude.setup-sync.plist` pulls every 3 minutes on Mac + Mini. VPS has a SessionStart hook that pulls. The `/cs` skill pushes.

### What's NOT Shared (the gaps)

#### 1. MCP Memory (Knowledge Graph) — PARTIALLY SHARED

| Machine  | Backend                                                                                                              | Status   |
| -------- | -------------------------------------------------------------------------------------------------------------------- | -------- |
| Mac      | Turso cloud (`libsql://claude-memory-escotilha.aws-us-east-1.turso.io`) via custom `memory-turso` MCP server         | Working  |
| Mac Mini | **Same settings.json** (symlinked) but `memory-turso` MCP server requires `node` — **node is NOT installed on Mini** | BROKEN   |
| VPS      | Uses `@modelcontextprotocol/server-memory` (file-based, local) — **completely separate graph**                       | ISOLATED |

The Turso auth token is hardcoded in `settings.json` (lines 351-353), so it's already on Mini via the symlink. The blocker is that **Mini has no Node.js** installed (no npm, no npx, no pnpm).

The VPS has Node.js v22.22.0 and npm but uses the stock `server-memory` (file-based JSON) instead of `memory-turso`. Its `settings.json` is its own copy and does NOT reference Turso.

#### 2. Secrets (API Keys) — MAJOR GAP

**Mac (primary) — macOS Keychain:**

| Service                    | Status                    |
| -------------------------- | ------------------------- |
| `BRAVE_API_KEY`            | In Keychain               |
| `EXA_API_KEY`              | In Keychain               |
| `OPENROUTER_API_KEY`       | In Keychain               |
| `RESEND_API_KEY`           | In Keychain               |
| `cloudflare-dns-api-token` | In Keychain               |
| `clerk-secret-key`         | In Keychain               |
| `telnyx-api-key`           | In Keychain               |
| `gh:github.com`            | In Keychain (gh CLI auth) |
| `Claude Code-credentials`  | In Keychain (Claude auth) |
| `Claude Safe Storage`      | In Keychain               |

**Mac Mini — macOS Keychain:**

| Service                          | Status      |
| -------------------------------- | ----------- |
| `claude-code-github-token`       | **MISSING** |
| `claude-code-brave-api-key`      | **MISSING** |
| `claude-code-resend-api-key`     | **MISSING** |
| `claude-code-digitalocean-token` | **MISSING** |
| All others                       | **MISSING** |

The Mini has **ZERO** claude-code-prefixed keychain entries. The `load-secrets.sh` hook looks for `claude-code-*` prefixed entries, but the main Mac stores them as `BRAVE_API_KEY` (no prefix). This is a naming mismatch.

However, for Claude Code specifically: **settings.json has API keys hardcoded in the `env` block** (lines 7-9: RESEND_API_KEY, BRAVE_API_KEY, EXA_API_KEY). Since Mini symlinks to this file, these keys are already available to Claude Code on Mini via env vars. The Keychain approach (`load-secrets.sh`) is a secondary/unused mechanism.

**VPS — No Keychain (Linux):**

The VPS stores secrets in `/opt/claudia/.env` (14 key-value pairs). Claude Code on VPS gets keys via its own `settings.json` env block — but VPS has its own copy of settings.json that does NOT include the env block with BRAVE_API_KEY, EXA_API_KEY, RESEND_API_KEY. These are available as shell env vars only if sourced.

#### 3. GBrain (Knowledge Brain) — MAC-ONLY GAP

| Machine  | Status                                                                                                                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mac      | Connected via `postgres` MCP server → SSH tunnel `127.0.0.1:5433` (maps to VPS postgres)                                                                                                                      |
| Mac Mini | **No postgres MCP server configured** (settings.json has it but Mini has no node)                                                                                                                             |
| VPS      | `gbrain` binary installed at `/usr/local/bin/gbrain` but **broken** (`bun: No such file or directory`). PostgreSQL is local with `gbrain` database (10 tables). Direct psql access works via `su - postgres`. |

The `postgres` MCP server in settings.json connects to `postgresql://postgres:postgres@127.0.0.1:5433/claudia` — this is a tunnel to the VPS claudia database, NOT the gbrain database.

GBrain PostgreSQL credentials on VPS: `claudia_app` / `067b68c578fc3a6d24b05725d53c9edfac08a8a3fc61ba33` (from Claudia's .env, but this is for the `claudia` database).

#### 4. mem-search Index — PARTIALLY SHARED

| Machine  | Status                                                     |
| -------- | ---------------------------------------------------------- |
| Mac      | `mem-search.db` = 229,376 bytes, working                   |
| Mac Mini | `mem-search.db` = 217,088 bytes (slightly older, from git) |
| VPS      | `mem-search.db` = 217,088 bytes (slightly older, from git) |

The `.db` file is committed to git. Mini and VPS have slightly older versions. Running `mem-search --reindex` on each would rebuild from the `.md` files. The `mem-search` script uses bash + sqlite3, which is available everywhere.

#### 5. settings.json — DIVERGED

The Mac and Mini share the same file (symlink). The VPS has its own copy with significant differences:

**VPS has but Mac doesn't:**

- `google-workspace` MCP
- `computer-use-linux` MCP
- `context7` MCP
- `desktop-commander` MCP
- `sec-edgar` MCP
- `financial-datasets` MCP (HTTP)
- `tavily` MCP
- `mem0` MCP (self-hosted with Qdrant + Gemini)
- `hermes` MCP
- `sentry` (HTTP), `vercel` (HTTP), `stripe` (HTTP)
- Agent definitions (claudia, bella, julia, rex, buzz, cris, marco, arnold)
- `systemPrompt`: "Always reply to Pierre in English..."

**Mac has but VPS doesn't:**

- `exa` MCP (on Mac, missing from VPS)
- `chrome-devtools` MCP
- `ScraplingServer` MCP
- `context-mode` MCP
- `qmd` MCP
- `officecli` MCP (in mcpServers block)
- All hooks except SessionStart, SubagentStop, PreToolUse, TaskCompleted
- Plugins (discord, codex, frontend-design, etc.)
- `env` block with hardcoded keys
- `autoMemoryDirectory`, `plansDirectory`, etc.

**VPS `memory` MCP uses file-based `@modelcontextprotocol/server-memory`** — not Turso-backed.

#### 6. Binary Tools — MAJOR GAP ON MINI

| Tool                   | Mac          | Mini                           | VPS                      |
| ---------------------- | ------------ | ------------------------------ | ------------------------ |
| `node` / `npm` / `npx` | Yes          | **NO**                         | Yes (v22.22.0)           |
| `brew`                 | Yes          | **NO**                         | N/A                      |
| `pnpm`                 | Yes          | **NO**                         | No                       |
| `qmd`                  | Yes          | **NO**                         | No                       |
| `browse`               | Yes          | **NO**                         | Yes                      |
| `scrapling`            | Yes          | **NO**                         | No                       |
| `officecli`            | Yes          | Yes (`~/.local/bin/officecli`) | No                       |
| `gbrain`               | No (via MCP) | No                             | Yes (broken — needs bun) |
| `sqlite3`              | Yes          | Yes                            | Yes                      |
| `claude`               | Yes          | Yes                            | Yes                      |

Mini is missing Node.js entirely, which breaks all `npx`-based MCP servers.

## Data Flow

### Git-based sync (working):

```
Mac (push via /cs) → GitHub → Mini/VPS (pull via launchd/hook)
```

Skills, agents, hooks, rules, commands, memory .md files, tools scripts all flow this way.

### Settings.json:

```
Mac → symlink → ~/.claude-setup/settings.json (in git)
Mini → symlink → same file (via git pull)
VPS → own copy at ~/.claude/settings.json (manually maintained, diverged)
```

### MCP Memory:

```
Mac → memory-turso MCP → Turso cloud DB (us-east-1)
Mini → same settings but no node → BROKEN
VPS → server-memory MCP → local JSON file → ISOLATED
```

### Secrets:

```
Mac → hardcoded in settings.json env{} + macOS Keychain
Mini → inherits settings.json env{} (symlink) → API keys WORK for Claude Code
Mini → macOS Keychain → EMPTY (no claude-code-* entries)
VPS → /opt/claudia/.env + own settings.json env{} → INCOMPLETE
```

## Existing Patterns

1. **Git repo + symlinks** — The primary sync mechanism. Works well for static files.
2. **LaunchAgent auto-pull** — Every 3 minutes, `git pull --ff-only`. Good for eventual consistency.
3. **SessionStart hook** — Runs `git pull` at session start on all machines. Ensures fresh state.
4. **Hardcoded keys in settings.json env{}** — Currently the actual mechanism Claude Code uses for API keys. The Keychain system (`load-secrets.sh`) is a parallel path that's mostly unused.
5. **setup-symlinks.sh** — Comprehensive symlink setup for new machines.

## Dependencies

- **Tailscale** — Private encrypted network connecting all machines. Already working.
- **Turso** — Cloud-hosted libSQL. Account: escotilha. DB URL and auth token already in settings.json.
- **PostgreSQL on VPS** — Running, has `gbrain` and `claudia` databases.
- **Git + GitHub** — Repo at `escotilha/claude` (private). All machines can pull.

## Constraints

1. **VPS has no macOS Keychain** — Secrets must use env vars or files
2. **Mac Mini has no Node.js** — All npx-based MCP servers are broken
3. **settings.json can't be fully shared** — VPS needs Linux-specific servers (computer-use-linux), Mac needs macOS-specific ones (chrome-devtools, ScraplingServer)
4. **iCloud Keychain does NOT sync generic passwords** — The setup scripts incorrectly claim this
5. **The `load-secrets.sh` uses `claude-code-*` prefix** but main Mac stores keys without that prefix — naming mismatch
6. **GBrain on VPS needs `bun` runtime** — Currently broken
7. **No plaintext secrets in git** — API keys in settings.json env{} are already in git (this is a security concern, but it's the current pattern)

## Key Files

| File                                  | Purpose                                                         | Relevance                                            |
| ------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------- |
| `settings.json`                       | Main Claude Code config — MCP servers, hooks, env vars, plugins | Central config that diverges across machines         |
| `hooks/load-secrets.sh`               | Load API keys from macOS Keychain                               | Unused in practice (keys are in settings.json env{}) |
| `hooks/setup-keychain.sh`             | Interactive script to add keys to Keychain                      | Only useful on macOS, never run on Mini              |
| `setup-symlinks.sh`                   | Create symlinks from ~/.claude to repo                          | Primary setup mechanism                              |
| `setup-new-machine.sh`                | Full new-machine setup (symlinks + keychain check)              | Outdated assumptions about iCloud Keychain sync      |
| `setup-mcp-servers.sh`                | Build memory-turso MCP server                                   | Needs node/npm — won't work on Mini                  |
| `mcp-servers/memory-turso/`           | Custom Turso-backed MCP memory server                           | The key to shared knowledge graph                    |
| `tools/mem-search`                    | Bash + sqlite3 FTS5 search over memory .md files                | Works everywhere (bash + sqlite3)                    |
| `memory/core-memory.json`             | Core memory (user profile, preferences, paths)                  | Uses `~` paths — portable                            |
| `launchd/com.claude.setup-sync.plist` | Auto-pull git every 3 minutes                                   | macOS only — needs equivalent on VPS                 |

## Open Questions

1. **Should we install Node.js on Mac Mini?** Mini is used for MLX inference — adding Node.js is straightforward (homebrew or nvm) but adds maintenance. Without it, no npx-based MCP servers work.

2. **Should VPS settings.json be merged with Mac's or kept separate?** VPS has many unique MCP servers (hermes, mem0, computer-use-linux, financial tools). Options: (a) shared base + machine-specific overlays, (b) keep separate but sync specific blocks.

3. **The API keys in settings.json env{} are committed to a private git repo.** Is this acceptable security posture, or should they move to a proper secrets mechanism?

4. **GBrain on VPS needs `bun` — should we fix gbrain or use the `postgres` MCP server directly for gbrain access from Mac/Mini?**

5. **Should the `load-secrets.sh` / Keychain approach be abandoned in favor of the env{} block in settings.json?** The Keychain approach is more secure but broken (naming mismatch, iCloud doesn't sync generic passwords, Mini has no entries).
