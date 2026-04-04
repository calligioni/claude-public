---
name: claudia-memory-v2-architecture
description: Claudia Memory v2 — 5-layer composite memory system with nudge, consolidation, and complexity-aware skill generation (ALL PHASES COMPLETE)
type: project
---

## Claudia Memory v2 — Best-of-Breed Composite (COMPLETE)

Design combining winning ideas from Hindsight (91.4% LongMemEval), Mem0, Zep/Graphiti, ASMR, Hermes, and Karpathy's compounding pattern into a 5-layer system built on mcp-memory-pg pgvector infrastructure.

### Layer Architecture (as of 2026-04-04)

| Layer                    | File                | Purpose                                    | Trigger                |
| ------------------------ | ------------------- | ------------------------------------------ | ---------------------- |
| 1. File journals         | `files.ts`          | Raw per-agent daily logs                   | Every response         |
| 2. Knowledge graph       | `kg-client.ts`      | 4-strategy semantic search + RRF           | Pre-inference context  |
| 3. Fact extraction       | `fact-extractor.ts` | LLM (Mac Mini) + heuristic fact extraction | Every response (async) |
| 4. Periodic nudge        | `nudge.ts`          | Lightweight memory curation every N turns  | Every 10th message     |
| 5. Session consolidation | `consolidate.ts`    | Extract summary before session drop        | On session cleanup     |

### Phase Status — ALL COMPLETE

- **Phases 1-5** — original memory v2 (KG integration, schema extensions, write pipeline, 4-strategy retrieval, reflect/maintain)
- **Phase 6: Periodic Nudge (Hermes)** — `src/memory/nudge.ts`
  - Turn counter per session (configurable via NUDGE_INTERVAL env, default 10)
  - Buffers recent 5 exchanges per session
  - Mac Mini LLM evaluates "worth persisting?" → delegates to fact-extractor
  - Falls back to always-extract if Mac Mini offline
- **Phase 7: Session Consolidation (Hermes Sentinel)** — `src/memory/consolidate.ts`
  - Registers exchanges in rolling window (10 per session)
  - On session drop: generates LLM summary → stores as "session-sentinel" entity in KG
  - Heuristic fallback (first+last exchange) if Mac Mini offline
  - `consolidateAllSessions()` for graceful shutdown
- **Phase 8: Session Complexity Tracker** — `src/skills/complexity-tracker.ts`
  - Tracks: turn count, code blocks, error recovery, user corrections, step patterns
  - Eligible agents: arnold, swarmy, claudia
  - Triggers skill auto-generation when 2+ thresholds crossed
  - Delegates to existing maybeGenerateSkill with synthesized session context

### Integration Points (Router Steps 8-13)

```
Step  8: saveConversationMemory → daily journal (Layer 1)
Step  9: maybeGenerateSkill → per-exchange skill detection
Step 10: maybeExtractAndStoreFacts → fact extraction (Layer 3)
Step 11: maybeCompoundResponse → knowledge articles (Karpathy)
Step 12: registerExchange + trackTurn → nudge + consolidation (Layers 4-5)
Step 13: trackComplexity → session-level skill auto-generation
```

### Ideas Borrowed From

| System            | Idea                                                         | Status |
| ----------------- | ------------------------------------------------------------ | ------ |
| Hindsight (91.4%) | Multi-strategy retrieval + RRF + reflect()                   | DONE   |
| Mem0              | agent_id/user_id scoping, actor-aware                        | DONE   |
| Zep/Graphiti      | Temporal validity windows                                    | DONE   |
| ASMR              | Parallel fan-out retrieval                                   | DONE   |
| Hermes            | Auto-skill generation, periodic nudge, session consolidation | DONE   |
| Karpathy          | Response compounding (output-as-input)                       | DONE   |

### Embedding Cost Optimization (Future)

Currently uses OpenAI text-embedding-3-small ($). Mac Mini has nomic-embed-text-v1.5 on LM Studio at mini:1234 (free). Switch would make memory system zero-cost.

**Why:** Agents need cross-session recall with semantic relevance, not just flat file journals.
**How to apply:** All code is deployed. Future improvements: switch to local embeddings, add cross-agent fact promotion, tune nudge interval per agent.
