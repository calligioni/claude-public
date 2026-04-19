---
name: gbrain
description: "GBrain knowledge brain management — setup, import, query, maintain, ingest. Triggers on: gbrain, knowledge brain, brain query, brain search, brain import, brain setup, brain ingest."
argument-hint: "<subcommand: setup | import | query | ingest | maintain | stats>"
user-invocable: true
context: fork
model: sonnet
effort: medium
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - WebFetch
  - WebSearch
  - mcp__memory__*
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
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

# GBrain — Personal Knowledge Brain

Manage GBrain, a Postgres-native personal knowledge brain with hybrid RAG search.
GBrain stores world knowledge (people, companies, concepts, meetings) as pages with
compiled truth + append-only timelines, cross-linked via a typed graph.

## Architecture

```
Markdown files (git) → gbrain import → PostgreSQL (pgvector)
                                          ├─ pages (compiled_truth + timeline)
                                          ├─ content_chunks (embeddings, 1536-dim)
                                          ├─ links (typed cross-references)
                                          ├─ tags
                                          └─ timeline_entries

Search: keyword (tsvector) + vector (HNSW) + RRF fusion + multi-query expansion
MCP: 30 tools via `gbrain serve` (stdio)
Direct: Claudia queries gbrain DB directly via gbrain-client.ts
```

## Subcommands

### `setup`

Install GBrain on the VPS. Only needed once.

```bash
# From local machine — runs install script on VPS
ssh root@100.77.51.51 'bash -s' < /path/to/claudia/scripts/install-gbrain.sh
```

Alternatively, on the VPS directly:

```bash
# Create gbrain database on existing Postgres
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d postgres \
  -c "CREATE DATABASE gbrain;"

# Install
mkdir -p /opt/gbrain && cd /opt/gbrain
bun init -y && bun add github:garrytan/gbrain
ln -sf /opt/gbrain/node_modules/.bin/gbrain /usr/local/bin/gbrain

# Init with local Postgres
gbrain init --non-interactive --url "postgresql://postgres:postgres@127.0.0.1:5432/gbrain"

# Verify
gbrain get_stats
```

**Required env vars** (source from Claudia's .env):

- `DATABASE_URL` — Postgres connection string
- `OPENAI_API_KEY` — for embeddings (text-embedding-3-large, 1536-dim)
- `ANTHROPIC_API_KEY` — for multi-query expansion via Haiku

### `import <directory>`

Index a directory of markdown files into the brain.

```bash
# Import without embeddings first (fast)
gbrain import /path/to/markdown/ --no-embed

# Then backfill embeddings
gbrain import /path/to/markdown/

# Incremental sync (picks up changes since last sync)
gbrain sync --repo /path/to/markdown/
```

### `query <question>`

Hybrid search (keyword + vector + RRF fusion) with multi-query expansion.

```bash
gbrain query "What do we know about Company X?"
gbrain search "Pierre Schurmann"  # keyword-only (faster)
gbrain get people/pierre-schurmann  # direct slug lookup
```

**Search precedence:** keyword (tsvector) → vector (cosine similarity) → RRF fusion → dedup

### `ingest`

Process new information into the brain. The brain-agent loop:

1. **Parse** incoming text for entities (people, companies, concepts)
2. **Search** brain for existing pages on each entity
3. **Update** existing pages: rewrite compiled_truth, append timeline entry
4. **Create** new pages for notable entities not yet tracked
5. **Link** entities: `knows`, `works_at`, `invested_in`, `founded`, `met_at`, `discussed`
6. **Sync** index: `gbrain sync --no-pull --no-embed`

**Notability criteria:** Direct interaction with user, professional/investment relevance,
original thinking, user-generated frameworks.

**Quality rules:**

- Compiled truth gets REWRITTEN (not appended) when evidence changes
- Timeline entries are reverse-chronological, include source attribution
- Every mentioned person/company gets a page (if absent)
- Links use specific relationship types

### `maintain`

Brain health checks and maintenance.

```bash
gbrain get_health  # Embed coverage, stale pages, orphans
gbrain get_stats   # Page count, chunk count, link count
```

**Maintenance tasks:**

- Find contradictions between compiled_truth and timeline evidence
- Flag stale pages (no updates in 90+ days)
- Find orphan pages (no links in or out)
- Verify embedding coverage

### `stats`

Quick brain overview.

```bash
gbrain get_stats
```

## Minions — Durable Job Queue (v0.11+)

GBrain v0.11 ships **Minions**: a BullMQ-backed durable job queue that uses GBrain's
existing Postgres/PGLite as the backend. Solves the "subagent timed out silently"
failure mode — jobs persist, retry on failure, and survive process crashes.

**Why it matters:** Replaces fire-and-forget subagent spawns with a guaranteed-delivery
queue. Directly analogous to the `/parallel-dev` and `/qa-cycle` timeout problems.
See `~/.claude-setup/memory/auto/tech_gbrain_integration.md` for the full pattern.

### Setup (VPS)

```bash
# Minions ships with gbrain v0.11+ — verify
gbrain --version   # >= 0.11.0

# Redis optional — Postgres backend is default (uses gbrain DB)
gbrain minions init

# Start the worker process (run under systemd for durability)
gbrain minions worker --concurrency 4 &
```

**Systemd unit** (`/etc/systemd/system/gbrain-minions.service`):

```ini
[Unit]
Description=GBrain Minions worker
After=postgresql.service

[Service]
ExecStart=/usr/local/bin/gbrain minions worker --concurrency 4
Restart=always
EnvironmentFile=/opt/claudia/.env

[Install]
WantedBy=multi-user.target
```

### Enqueue a job

```bash
# CLI
gbrain minions enqueue \
  --queue "intel-scan" \
  --name "scan-openclaw" \
  --payload '{"targets": ["@garrytan", "@openclawHQ"]}' \
  --attempts 3 \
  --backoff exponential

# From TypeScript (Claudia, AgentWave)
import { enqueueJob } from "gbrain/minions";
await enqueueJob("intel-scan", { name: "scan-openclaw", payload: {...} });
```

### Inspect / manage

```bash
gbrain minions list --queue intel-scan          # pending + active
gbrain minions failed --queue intel-scan        # failed jobs
gbrain minions retry <job-id>                   # re-enqueue
gbrain minions drain --queue intel-scan         # clear queue
gbrain minions stats                            # global health
```

### When to use Minions vs Task/TeamCreate

| Pattern                              | Use Minions? | Reason                                |
| ------------------------------------ | ------------ | ------------------------------------- |
| Scheduled background task (cron)     | **Yes**      | Retry + durability > systemd cron     |
| Agent subtask likely to timeout      | **Yes**      | Workflow needs guaranteed completion  |
| Long-running ingest (brain, docs)    | **Yes**      | Idempotent + checkpointed             |
| Short interactive subagent (<30s)    | No           | Task tool is lower overhead           |
| Real-time cross-agent coordination   | No           | Use TeamCreate/SendMessage — messaging, not work queue |

## MCP Tools (30)

When running as MCP server (`gbrain serve`), these tools are available:

| Category | Tools                                                                     |
| -------- | ------------------------------------------------------------------------- |
| Pages    | `get_page`, `put_page`, `delete_page`, `list_pages`                       |
| Search   | `search` (FTS), `query` (hybrid + expansion)                              |
| Tags     | `add_tag`, `remove_tag`, `get_tags`                                       |
| Links    | `add_link`, `remove_link`, `get_links`, `get_backlinks`, `traverse_graph` |
| Timeline | `add_timeline_entry`, `get_timeline`                                      |
| Admin    | `get_stats`, `get_health`, `get_versions`, `revert_version`               |
| Sync     | `sync_brain`                                                              |
| Raw Data | `put_raw_data`, `get_raw_data`                                            |
| Resolve  | `resolve_slugs`, `get_chunks`                                             |
| Ingest   | `log_ingest`, `get_ingest_log`                                            |
| Files    | `file_list`, `file_upload`, `file_url`                                    |

## Claudia Integration

GBrain is wired as Source 5 in Claudia's memory context builder (`src/memory/context.ts`).
Before every inference call, Claudia searches the brain for relevant pages and injects
compiled truth into the system prompt. This is a direct Postgres query — no MCP overhead.

**Client:** `src/memory/gbrain-client.ts`
**Pool:** `src/db/gbrain-pool.ts` (separate from mcp-memory-pg, max 3 connections)
**Database:** `gbrain` on `127.0.0.1:5432` (same Postgres instance as `claudia` db)

## Page Format

```markdown
---
type: person
tags: [investor, ceo, nuvini]
---

# Pierre Schurmann

CEO of Nuvini Group (NVNI, Nasdaq). Based in São Paulo.
Manages M&A, investor relations, and portfolio companies
(ExampleProject, SourceRank, AgentWave).

---

## Timeline

- **2026-04-10** — [meeting] Discussed Q1 results with board (Source: calendar)
- **2026-04-05** — [research] Evaluated GBrain for Claudia integration (Source: session)
```

## Always-On Skills (GBrain Skillpacks)

Three skills adopted from GBrain skillpacks that run as background behaviors in Claude Code
sessions. They make the brain compound automatically from every interaction.

### Signal Detector

Runs in parallel on every substantive user message. Captures two things:

1. **Original thinking** — user ideas, observations, theses, frameworks. Create or update
   pages in `originals/`, `concepts/`, or `ideas/` directories. Preserve exact user phrasing.
2. **Entity mentions** — people, companies, media references. Search brain for existing pages,
   create new ones for notable mentions, add timeline entries for new facts.

**How it fires in Claude Code:**

- After processing each user message, evaluate if it contains signal (skip "ok", "thanks", operational noise)
- If signal detected, capture entities/ideas via `mcp__memory__create_entities` and `mcp__memory__add_observations`
- For VPS brain: SSH `gbrain put_page <slug>` or use GBrain MCP tools if connected
- Runs silently — never blocks the main response

**Iron Law: Back-Linking** — every page creation/update that mentions a person or company
MUST add a reverse link from that entity's page:
`- **YYYY-MM-DD** | Referenced in [page title](path) — brief context`

### Brain-Ops

Brain-first lookup protocol. Before answering questions about people, companies, deals,
or concepts:

1. **Search brain first** — keyword search, hybrid query, backlink check
2. **Only then** consult external APIs (web search, Exa, Brave)
3. **Read-Enrich-Write** — after answering, update the brain page with any new facts learned

**Tools (in priority order):**

- `mcp__memory__search_nodes` → `mcp__memory__open_nodes` (MCP memory graph)
- SSH `gbrain query "<question>"` (VPS brain, hybrid RAG)
- Then external: Brave, Exa, WebSearch

**Anti-patterns:**

- Answering about a known entity without checking the brain first
- Using web search when the brain already has the answer
- Learning new facts and NOT writing them back to the brain

### Conventions

Non-negotiable quality rules for all brain writes:

1. **Citations** — every fact needs `[Source: {type} — {detail}]`. User statements = highest authority.
2. **Back-linking** — every entity mention with an existing page gets a reciprocal link. No exceptions.
3. **Notability gate** — before creating a new page, assess: will we reference this again?
   People: future interaction likely. Companies: relevant to work/investments. Concepts: reusable mental model.
4. **Compiled truth gets rewritten** — don't append, rewrite the current understanding when evidence changes.
5. **Timeline is append-only** — reverse-chronological, never edited.

## Nightly Dream Cycle

Schedule as Claudia proactive task at 02:00 BRT:

1. Scan all conversations from the day
2. Extract entities, update/create pages
3. Fix broken cross-references
4. Consolidate fragmented timeline entries
5. Flag contradictions for human review
