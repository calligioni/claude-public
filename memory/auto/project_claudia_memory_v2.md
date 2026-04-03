---
name: claudia-memory-v2-architecture
description: Claudia Memory v2 — best-of-breed composite memory system, ALL 5 PHASES COMPLETE
type: project
---

## Claudia Memory v2 — Best-of-Breed Composite (COMPLETE)

Design combining winning ideas from Hindsight (91.4% LongMemEval), Mem0, Zep/Graphiti, ASMR, and Hermes into a single system built on the existing mcp-memory-pg pgvector infrastructure.

### Phase Status (as of 2026-04-03) — ALL COMPLETE

- **Phase 1: COMPLETE** — wired mcp-memory-pg into router pipeline
  - `src/memory/kg-client.ts`: direct PostgreSQL client with 4-strategy retrieval
  - `src/memory/context.ts`: 3-source parallel fan-out (files + skills + KG) with 3s timeout
  - `src/skills/`: auto-skill generation from complex conversations (Hermes-inspired)
  - Dashboard API: GET/DELETE /api/skills/:agent endpoints

- **Phase 2: COMPLETE** — schema extensions
  - Migration SQL: `mcp-memory-pg/migrations/001_memory_v2.sql`
  - New columns: agent_id, user_id, valid_from, invalid_at, memory_type, tsv (tsvector)
  - GIN index for BM25, composite indexes for agent-scoped temporal queries
  - `observations.ts`: updated createObservation() with CreateObservationOptions, invalidateObservation(), searchByTsVector()
  - MCP server: add_observations accepts agentId/userId/memoryType, new invalidate_observation tool (16 tools total)

- **Phase 3: COMPLETE** — write pipeline
  - `src/memory/fact-extractor.ts`: heuristic fact extraction (preference/decision/procedural/factual classification)
  - Router calls maybeExtractAndStoreFacts() async after each response
  - Facts stored with agent_id, user_id, memory_type, auto-embedded

- **Phase 4: COMPLETE** — 4-strategy retrieval + RRF
  - kg-client.ts upgraded: semantic + keyword + BM25 tsvector + graph traversal
  - All 4 strategies run in PARALLEL via Promise.all
  - Reciprocal rank fusion merge
  - Temporal filtering (invalid_at), agent-scope boost (20% for same-agent facts)

- **Phase 5: COMPLETE** — reflect + maintain
  - `src/scheduler/memory-maintain.ts`: daily cron at 03:00 BRT
  - Temporal invalidation: 90d factual, 180d procedural (preserves important keywords)
  - Duplicate consolidation: exact-match dedup
  - Reflect: weekly synthesis into insight observations for entities with 3+ recent facts
  - Registered in default-tasks.ts as "memory-maintenance"

### Deployment Checklist (VPS)

1. `pnpm add postgres` — add PostgreSQL client dependency
2. Add to `.env`: `OPENAI_API_KEY`, `KG_PG_HOST=127.0.0.1`, `KG_PG_PORT=5432`
3. Run migration: `psql -U postgres -d claudia -f mcp-memory-pg/migrations/001_memory_v2.sql`
4. Rebuild mcp-memory-pg: `cd mcp-memory-pg && pnpm build`
5. Restart `claudia.service`

### Ideas Borrowed From

| System            | Idea                                       | Status |
| ----------------- | ------------------------------------------ | ------ |
| Hindsight (91.4%) | Multi-strategy retrieval + RRF + reflect() | DONE   |
| Mem0              | agent_id/user_id scoping, actor-aware      | DONE   |
| Zep/Graphiti      | Temporal validity windows                  | DONE   |
| ASMR              | Parallel fan-out retrieval                 | DONE   |
| Hermes            | Auto-skill generation                      | DONE   |

### Embedding Cost Optimization (Future)

Currently uses OpenAI text-embedding-3-small ($). Mac Mini has nomic-embed-text-v1.5 on LM Studio at mini:1234 (free). Switch would make memory system zero-cost for embeddings.

**Why:** Agents need cross-session recall with semantic relevance, not just flat file journals.
**How to apply:** All code is deployed. Future improvements: switch to local embeddings, add LLM-powered fact extraction via Mac Mini, add cross-agent fact promotion.
