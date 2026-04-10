---
name: tech_gbrain_integration
description: GBrain world-knowledge brain integrated into Claudia as Source 5 — separate Postgres DB, 30 MCP tools, compiled truth + timeline pattern
type: project
originSessionId: 9a9e5be7-5727-42a4-87b4-ce88e7457231
---

GBrain (garrytan/gbrain v0.4.1) installed as Claudia's world-knowledge layer. Stores people, companies, concepts, meetings as pages with compiled truth + append-only timelines. Separate `gbrain` database on the same Postgres instance (127.0.0.1:5432), uses OpenAI text-embedding-3-large (1536-dim) — different from mcp-memory-pg which uses Ollama nomic-embed-text (768-dim).

**Why:** Fills the long-term factual memory gap. mcp-memory-pg handles operational state (preferences, decisions). GBrain handles world knowledge (people Pierre knows, companies, deals, concepts). The brain-agent loop makes Claudia compound knowledge across sessions.

**How to apply:** GBrain context auto-injects into all 10 agents via Source 5 in memory context builder. Direct Postgres queries (no MCP protocol overhead). Install on VPS via `scripts/install-gbrain.sh`. Manage via `/gbrain` Claude Code skill.

---

## Timeline

- **2026-04-10** — [implementation] Integrated GBrain into Claudia: gbrain-pool.ts, gbrain-client.ts, context.ts Source 5, BRAIN.md shared prompt, types.ts + registry.ts + system-prompt.ts + index.ts updates (Source: session — /research garrytan/gbrain)
- **2026-04-10** — [implementation] Created /gbrain Claude Code skill at ~/.claude-setup/skills/gbrain/SKILL.md (Source: session)
- **2026-04-10** — [implementation] Created install script at scripts/install-gbrain.sh for VPS deployment (Source: session)
- **2026-04-10** — [research] GBrain discovered via Garry Tan tweet — Postgres-native personal knowledge brain with hybrid RAG search, 30 MCP tools (Source: research — github.com/garrytan/gbrain)
