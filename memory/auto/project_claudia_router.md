---
name: project:claudia-router
description: Claudia — TypeScript multi-channel AI agent router on VPS, 10 agents, 6 channels, 4-tier inference, 5-layer memory, 20+ scheduled tasks, dashboard, dispatch queue
type: project
---

## Claudia Router — Full Architecture

Single-process TypeScript service replacing OpenClaw. Routes messages from 6 channels through 10 specialized agents to a 4-tier inference cascade. Runs on Contabo VPS as systemd service.

**Why:** OpenClaw was a walled garden — agents could only chat. Claudia gives every agent full Claude Code powers (filesystem, git, skills, MCP, tools). Eliminates dependency on the `openclaw` npm package.

**How to apply:** When working on VPS infrastructure, agent orchestration, channel integrations, memory systems, or scheduling. Claudia is the production agent runtime.

### Core Architecture

- **Repo:** escotilha/claudia, local at ~/code/claudia, VPS at /opt/claudia
- **10 agents:** claudia, buzz, marco, cris, julia, arnold, bella, rex, swarmy, north
- **6 channels:** Discord (15+ bindings), Telegram, Slack (2 workspaces), WhatsApp, Voice (Twilio), Video (PikaStream)
- **4-tier inference:** claudia → Agent SDK Opus → Sonnet → Mac Mini MLX → VPS Ollama; others → OpenRouter (free) → Mac Mini → Ollama
- **Session persistence:** SQLite (better-sqlite3), 7-day TTL, cleared on restart
- **Process:** Single Node.js 22, systemd claudia.service, port 3001
- **Concurrency:** p-queue — max 8 parallel, serial per peer

### 5-Layer Composite Memory

1. **File journals** — per-agent daily markdown logs in agents/{name}/memory/
2. **Knowledge graph** — PostgreSQL + pgvector, 4-strategy retrieval (semantic + keyword + BM25 + graph), reciprocal rank fusion
3. **Fact extraction** — LLM-powered (Mac Mini Qwen3.5-35B, free) with heuristic fallback, extracts after every response
4. **Periodic nudge** — fires every 10 turns per session, Mac Mini evaluates if recent exchanges have facts worth persisting
5. **Session consolidation** — Hermes sentinel pattern, extracts summary + facts before session drop/cleanup

### Scheduler (20+ cron tasks)

croner-based, timezone-aware (America/Sao_Paulo). Includes: daily briefings, competitive intel, email triage, memory maintenance, trend research, auto-improve, roundtable standups, meeting prep, follow-up reminders.

### Additional Subsystems

- **Dashboard:** REST API + SSE events + static web UI on same HTTP server
- **Claude Code Dispatch:** Detects coding tasks in messages, queues for `claude -p` execution in project dirs
- **Knowledge Pipeline:** URLs from Discord #drop → structured intelligence briefs → routed to topic channels
- **Skills System:** Auto-learns reusable procedures from conversations + session complexity tracker for arnold/swarmy
- **Voice Pipeline:** Deepgram Nova-3 STT (Groq fallback) + ElevenLabs v3 TTS

### Key Files

- Architecture doc: docs/architecture/ARCHITECTURE.md (39KB, 10 sections, 8 Mermaid diagrams, 7 ADRs)
- Router: src/router.ts
- Dispatcher: src/dispatcher.ts
- Agent Registry: src/agents/registry.ts
- Inference Cascade: src/inference/fallback.ts
- Memory Context: src/memory/context.ts
- KG Client: src/memory/kg-client.ts
- Nudge: src/memory/nudge.ts
- Consolidation: src/memory/consolidate.ts
- Fact Extractor: src/memory/fact-extractor.ts
- Complexity Tracker: src/skills/complexity-tracker.ts
- Config: src/config.ts

### Status (2026-04-04)

Fully operational. All channels active. Memory v2 with all 5 layers deployed. Architecture doc generated.
