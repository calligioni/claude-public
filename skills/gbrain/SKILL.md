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
(Contably, SourceRank, AgentWave).

---

## Timeline

- **2026-04-10** — [meeting] Discussed Q1 results with board (Source: calendar)
- **2026-04-05** — [research] Evaluated GBrain for Claudia integration (Source: session)
```

## Nightly Dream Cycle (Future)

Schedule as Claudia proactive task at 02:00 BRT:

1. Scan all conversations from the day
2. Extract entities, update/create pages
3. Fix broken cross-references
4. Consolidate fragmented timeline entries
5. Flag contradictions for human review
