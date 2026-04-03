---
name: claudia-memory-v2-architecture
description: Claudia Memory v2 — best-of-breed composite memory system with 5-phase rollout plan, Phase 1 complete
type: project
---

## Claudia Memory v2 — Best-of-Breed Composite

Design combining winning ideas from Hindsight (91.4% LongMemEval), Mem0, Zep/Graphiti, ASMR, and Hermes into a single system built on the existing mcp-memory-pg pgvector infrastructure.

### Phase Status (as of 2026-04-03)

- **Phase 1: COMPLETE** — wired mcp-memory-pg into router pipeline
  - `src/memory/kg-client.ts`: direct PostgreSQL client with multi-strategy retrieval (semantic + keyword in parallel, reciprocal rank fusion)
  - `src/memory/context.ts`: 3-source parallel fan-out (files + skills + KG) with 3s timeout
  - `src/index.ts`: KG connection test on startup, cleanup on shutdown
  - `src/config.ts`: KG\_\* env vars (KG_PG_HOST, KG_PG_PORT, KG_PG_DB, etc.)
  - `src/skills/`: auto-skill generation from complex conversations (Hermes-inspired)
  - Dashboard API: GET/DELETE /api/skills/:agent endpoints
  - **Deployment note:** needs `pnpm add postgres` on VPS and OPENAI_API_KEY in .env

- **Phase 2: PENDING** — schema extensions (agent_id, temporal validity, tsvector BM25)
  - Add columns: agent_id, user_id, valid_from, invalid_at, memory_type, tsv (tsvector)
  - GIN index for BM25 full-text search
  - Update mcp-memory-pg MCP server code to support new fields

- **Phase 3: PENDING** — write pipeline (auto-extract facts from conversations)
  - Heuristic fact extraction after each message
  - Optional: use Mac Mini Qwen3.5-35B for better extraction
  - Store with agent_id, user_id, temporal metadata

- **Phase 4: PENDING** — multi-strategy retrieval + RRF (add BM25 tsvector + graph traversal)
  - 3-strategy parallel: semantic + BM25 + graph multi-hop
  - Full reciprocal rank fusion with temporal filtering + agent-scope boost

- **Phase 5: PENDING** — reflect + maintain (daily cron synthesis)
  - LLM synthesis over accumulated facts (Hindsight reflect() pattern)
  - Temporal invalidation of stale facts (Zep pattern)
  - Cross-agent fact promotion (Mem0 pattern)

### Ideas Borrowed From

| System            | Idea                                              | Phase             |
| ----------------- | ------------------------------------------------- | ----------------- |
| Hindsight (91.4%) | Multi-strategy retrieval + RRF + reflect()        | 1 (partial), 4, 5 |
| Mem0              | agent_id/user_id scoping, actor-aware             | 2                 |
| Zep/Graphiti      | Temporal validity windows (valid_from/invalid_at) | 2, 5              |
| ASMR              | Parallel fan-out retrieval                        | 1 (done)          |
| Hermes            | Auto-skill generation                             | 1 (done)          |

### Embedding Cost Optimization (Future)

Currently uses OpenAI text-embedding-3-small ($). Mac Mini has nomic-embed-text-v1.5 on LM Studio at mini:1234 (free). Switch would make memory system zero-cost for embeddings.

**Why:** Agents need cross-session recall with semantic relevance, not just flat file journals.
**How to apply:** When continuing Claudia memory work, start from Phase 2. All Phase 1 code is in src/memory/kg-client.ts, src/skills/, and src/memory/context.ts.
