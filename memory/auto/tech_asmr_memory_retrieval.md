---
name: ASMR Memory Retrieval Architecture
description: Supermemory ASMR pipeline — 3-agent parallel retrieval (facts/context/temporal) replacing vector DB, ~99% on LongMemEval_s. Open-source ~April 2026.
type: tech
---

**ASMR (Agentic Search and Memory Retrieval)** by Supermemory (Dhravya Shah).

## Architecture

- **Ingestion:** 3 parallel Observer agents each read a session subset, extract structured facts across 6 vectors (Personal Info, Preferences, Events, Temporal Data, Updates, Assistant Info)
- **Retrieval:** 3 parallel Search agents — facts (direct), context (implications/relations), temporal (timelines/contradictions)
- **Answering:** 8 specialist prompt variants in parallel (98.60%) OR 12-agent Decision Forest + Aggregator (97.20%)

## Key Insight

Agentic retrieval eliminates the semantic similarity trap on temporal changes. BM25/vector search fails when facts contradict over time ("I like X" then later "I stopped liking X"). Specialist agents reasoning about temporal ordering solve this.

## Applied In

- `/memory-consolidation` — 3-agent retrieval layer (facts/context/temporal) replacing single BM25 query (2026-03-22)
- `/meditate` — 2-3 parallel Observer agents for extraction (code/preference/impact) (2026-03-22)
- `/cto` swarm — 3 parallel synthesis agents (severity/cross-concern/effort) (2026-03-22)

## Watch

- **Open-source release:** ~April 2026 at github.com/supermemoryai
- **Evaluate as:** Drop-in upgrade for `mem-search` tool (replace BM25 with agentic retrieval)
- **Source tweet:** https://x.com/DhravyaShah/status/2035517012647272689
