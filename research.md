# Research: Claude Managed Agents API Integration into Claudia

**Date:** 2026-04-08
**Scope:** Evaluate and plan integration of Claude Managed Agents API into Claudia's inference and dispatch layers

## Prior Context (from memory)

- **project:claudia-router** — Full architecture documented: 10 agents, 6 channels, 4-tier inference, 5-layer memory, 20+ scheduled tasks. VPS at /opt/claudia, systemd service.
- **tech:claude-managed-agents** — Evaluated on 2026-04-08. Verdict: best as **complement** for specific agents/tasks (swarmy, code dispatch), not a full replacement. Concerns about pricing ($0.08/session-hour), latency for real-time channels, event-driven vs request-response mismatch, and loss of local model fallback.
- **model-tier-strategy.md** — Established tiering: Opus for orchestration, Sonnet for judgment, Haiku for mechanical tasks. Claudia uses Opus for `claudia` agent, Sonnet/Haiku for others.

## Current Architecture

### Inference Layer (`src/inference/`)

Claudia has a **4-tier fallback cascade** split by agent type:

**Claudia agent (useAgentSDK=true):**
1. Claude Opus via Agent SDK (Max plan) — `sendToAgentSDK()` in `agent-sdk.ts`
2. Claude Sonnet via Agent SDK (cheaper fallback) — same function with model override
3. Mac Mini MLX (Qwen3.5-35B-A3B) — `queryMacMini()` in `mac-mini.ts`
4. VPS Ollama (qwen3:8b) — `queryOllama()` in `ollama.ts`

**All other agents (useAgentSDK=false):**
1. OpenRouter (Qwen 3.6 Plus Preview, free) — `queryOpenRouter()` in `openrouter.ts`
2. Mac Mini MLX
3. VPS Ollama

### Agent SDK Integration (`src/inference/agent-sdk.ts`)

Uses `@anthropic-ai/claude-agent-sdk` v0.2.88 (depends on `@anthropic-ai/sdk` v0.74.0):
- Spawns Claude Code CLI sessions via `query()` function
- Passes: systemPrompt (persona + memory + memory context), allowed tools, cwd, maxTurns, model
- Returns session IDs for resume capability
- 5-minute timeout per session
- Session resumption via `resume` option

### Session Management (`src/sessions/`)

- **SQLite-backed** (better-sqlite3) with WAL mode
- Sessions keyed by `(agent_name, channel_type, peer_id)`
- 7-day TTL, stale cleanup every hour
- All sessions cleared on restart (Agent SDK sessions can't survive process restart)
- Session drop triggers memory consolidation

### Dispatch System (`src/scheduler/dispatch.ts`)

- Detects coding tasks in messages via regex patterns
- Queues tasks to JSON file (`data/dispatch-queue.json`)
- Executes via `claude -p` CLI subprocess on VPS
- One task at a time (MAX_CONCURRENT=1)
- Pre-flight checks: CLI binary, project dir, skills synced
- Results delivered back to originating channel

### Memory Context (`src/memory/context.ts`)

Before each inference, builds context from 4 parallel sources:
1. File-based memory (agent's memory/ directory)
2. Auto-learned skills (keyword-matched)
3. Knowledge graph (pgvector semantic search, 3s timeout)
4. Wiki knowledge base

### Dispatcher (`src/dispatcher.ts`)

Wraps the router with concurrency control:
- Global queue: max 8 parallel sessions
- Per-peer queues: serial within same peer (session ordering)
- Dashboard state tracking

## Data Flow

```
Channel Adapter (Discord/Telegram/Slack/WhatsApp/Voice/Video)
    |
Dispatcher (per-peer serial, global max 8 concurrent)
    |
Router (handleMessage)
    +-- resolveAgent() -> agent name from channel binding
    +-- Dispatch intercept -> coding tasks queue for CLI execution
    +-- resolveSession() -> existing session ID from SQLite
    +-- trackInbound() -> follow-up detection
    +-- infer() -> 4-tier cascade
    |   +-- Agent SDK (Opus -> Sonnet)  [claudia + all SDK agents]
    |   +-- OpenRouter -> Mac Mini -> Ollama  [non-SDK agents]
    +-- saveSession() -> persist session ID
    +-- saveConversationMemory() -> file journals
    +-- Post-processing (parallel, non-blocking):
        +-- maybeGenerateSkill()
        +-- maybeExtractAndStoreFacts()
        +-- maybeCompoundResponse()
        +-- registerExchange() (consolidation)
        +-- trackTurn() / executeNudge()
        +-- trackComplexity() / generateSessionSkill()
        +-- executeAnticipations()
```

## Claude Managed Agents API Surface

### Core Resources

| Resource | Endpoint | Purpose |
|----------|----------|---------|
| **Agent** | `POST /v1/agents` | Reusable config: model + system prompt + tools + MCP servers + skills |
| **Environment** | `POST /v1/environments` | Container template: packages, networking rules |
| **Session** | `POST /v1/sessions` | Running instance of agent in environment |
| **Events** | `POST /v1/sessions/{id}/events` | Send user messages, tool results, interrupts |
| **Stream** | `GET /v1/sessions/{id}/stream` | SSE stream of agent/session events |

### Key Technical Details

- **Beta header required:** `anthropic-beta: managed-agents-2026-04-01`
- **SDK support:** `@anthropic-ai/sdk` (TypeScript) has `client.beta.agents.*`, `client.beta.sessions.*`, `client.beta.environments.*`
- **Session states:** `rescheduling` -> `running` -> `idle` -> `terminated`
- **SSE events:** `agent.message`, `agent.tool_use`, `agent.tool_result`, `agent.mcp_tool_use`, `agent.custom_tool_use`, `session.status_idle`, `session.status_running`, `session.requires_action`
- **Tool types:** `agent_toolset_20260401` (bash, read, write, edit, glob, grep, web_fetch, web_search), `custom` (client-executed), `mcp_toolset` (URL-based MCP servers)
- **Custom tools:** Define in agent config, handle via `agent.custom_tool_use` events, respond with `user.custom_tool_result`
- **MCP servers:** Declared on agent with name+URL, auth via vaults at session creation
- **Environment:** Supports packages (pip, npm, apt, cargo, gem, go), networking (unrestricted/limited), GitHub repo mounting
- **Pricing:** Standard API token cost + $0.08/session-hour + $10/1000 web searches
- **Rate limits:** 60 creates/min, 600 reads/min per org
- **Session persistence:** Server-side event history, reconnectable SSE streams
- **Multi-turn:** Send additional `user.message` events to ongoing sessions
- **Interrupt:** Send `user.interrupt` to stop mid-execution
- **Agent versioning:** Auto-incremented on update, sessions can pin to specific version
- **Research preview features:** Outcomes (self-evaluation), multi-agent coordination, persistent memory

### vs Current Agent SDK

| Aspect | Current Agent SDK | Managed Agents API |
|--------|------------------|-------------------|
| **Runtime** | Local CLI process on VPS | Cloud container managed by Anthropic |
| **Session lifecycle** | Process-bound, dies on restart | Server-side, survives disconnects |
| **Tools** | Claude Code full toolset (70+ skills) | 8 built-in + custom + MCP |
| **Local models** | Mac Mini MLX, VPS Ollama fallback | Anthropic models only |
| **Memory** | 5-layer composite (file, KG, nudge, consolidation, skills) | Research preview only |
| **Cost** | Max subscription + VPS ($15/mo) | Per-token + $0.08/session-hour |
| **Concurrency** | Limited by local resources (8 max) | Limited by rate limits (60 creates/min) |
| **Latency** | Local to VPS, fast | Cloud container spin-up, potentially slower |
| **MCP** | Custom adapter wiring | Native first-class support |
| **Customization** | Full control over agent loop | Config-driven, less control |

## Existing Patterns

### Pattern 1: Inference Tier Selection
Agents route to different inference backends based on `useAgentSDK` flag. A new Managed Agents tier would be a third routing path alongside Agent SDK and OpenRouter.

### Pattern 2: Session State Management
Sessions are tracked in SQLite by (agent, channel, peer). Managed Agents sessions have their own server-side state but Claudia still needs to map channel conversations to session IDs.

### Pattern 3: Dispatch Queue
Coding tasks are already queued and executed asynchronously via `claude -p`. Managed Agents could replace this with cloud-based execution, gaining persistence and avoiding VPS resource contention.

### Pattern 4: Custom Tool Pattern
Managed Agents supports custom tools where the client executes the tool and returns results. This could bridge Claudia's memory/KG queries, channel message sending, and other Claudia-specific capabilities into Managed Agents sessions.

## Dependencies

| Dependency | Current Version | Needed |
|------------|----------------|--------|
| `@anthropic-ai/sdk` | 0.74.0 (via claude-agent-sdk) | >= 0.80+ (beta.agents/sessions support) |
| `@anthropic-ai/claude-agent-sdk` | 0.2.88 | Keep for existing Agent SDK path |
| Anthropic API key | Required | Required (same key works) |

## Constraints

1. **Cannot remove Agent SDK path** — it is the primary inference for 9 agents. Managed Agents is additive.
2. **Cannot lose local model fallback** — Managed Agents is Anthropic-only; Mac Mini/Ollama must remain for cost control.
3. **Cannot break session ordering** — per-peer serial execution must be preserved.
4. **Cannot break memory pipeline** — fact extraction, nudge, consolidation, skill generation must still work.
5. **Event-driven architecture** — Claudia receives messages from 6 channels and responds synchronously. Managed Agents is async (SSE). Must bridge async to sync.
6. **VPS resource constraints** — Claudia runs on a single Contabo VPS. Cloud-offloading to Managed Agents reduces VPS load.
7. **Pricing sensitivity** — $0.08/session-hour adds up. A 5-minute session costs $0.007; but an always-on session costs $1.92/day.

## Key Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `src/inference/fallback.ts` | Inference cascade logic | Where new Managed Agents tier gets added |
| `src/inference/agent-sdk.ts` | Current Agent SDK integration | Reference pattern for Managed Agents adapter |
| `src/agents/types.ts` | AgentConfig and InferenceResult types | Must extend for managed agents support |
| `src/agents/registry.ts` | Agent loading and tool assignment | Must add useManagedAgents flag |
| `src/config.ts` | All env vars and bindings | Must add ANTHROPIC_API_KEY, managed agents config |
| `src/sessions/manager.ts` | Session CRUD | Must handle Managed Agents session IDs |
| `src/sessions/db.ts` | SQLite session storage | Must store Managed Agents session IDs |
| `src/scheduler/dispatch.ts` | Code dispatch queue | Primary candidate for Managed Agents replacement |
| `src/dispatcher.ts` | Concurrency control | Must handle async SSE bridging |
| `src/memory/context.ts` | Memory context builder | Must bridge to custom tools for Managed Agents |
| `src/router.ts` | Main message handler | Post-processing hooks must work with Managed Agents responses |
| `package.json` | Dependencies | Must upgrade @anthropic-ai/sdk |

## Open Questions

1. **Which agents should use Managed Agents?** The memory evaluation suggested `swarmy` and dispatch queue. Should `claudia` (primary) also get a Managed Agents path, or is the Agent SDK (with local tools and full skill access) still better?

2. **Session lifecycle strategy:** Should Managed Agents sessions be long-lived (one per agent+peer, reused across messages) or ephemeral (new session per message)? Long-lived saves container spin-up but costs $0.08/hr idle. Ephemeral is cheaper but loses in-session context.

3. **Custom tools scope:** Which Claudia capabilities should be exposed as custom tools to Managed Agents sessions? Candidates: memory query, channel message sending, dispatch queuing, knowledge graph search.

4. **SDK upgrade path:** The current `@anthropic-ai/sdk` is 0.74.0 (via claude-agent-sdk dependency). The latest is 0.86.1. Need to verify the beta.agents API is available and stable in the SDK. Should this be a direct dependency or continue relying on claude-agent-sdk's transitive dependency?

5. **Environment reuse:** Should there be one shared environment or per-agent environments? Per-agent allows different package/networking configs but adds management overhead.

6. **MCP integration:** Should mcp-memory-pg (the knowledge graph) be connected as an MCP server to Managed Agents sessions? This would give the agent direct KG access without custom tool bridging, but requires exposing the MCP endpoint over HTTPS (currently local only).

7. **Feature flag strategy:** Should Managed Agents be enabled globally or per-agent? A per-agent flag (`useManagedAgents: true`) in the registry would allow gradual rollout.
