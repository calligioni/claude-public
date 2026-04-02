# Model Tier Strategy for Subagents

Route subagent tasks to the cheapest model that can handle the work. This saves tokens without sacrificing quality.

## Tier Definitions

| Tier       | Model  | Cost   | Use For                                                                     |
| ---------- | ------ | ------ | --------------------------------------------------------------------------- |
| **Tier 1** | Haiku  | Low    | Deterministic execution, template-driven, report formatting, scaffolding    |
| **Tier 2** | Sonnet | Medium | Nuanced judgment, code review, investigation, moderate complexity           |
| **Tier 3** | Opus   | High   | Architecture decisions, security audits, complex reasoning, production code |

## Decision Matrix

| Task Type                        | Model  | Rationale                                   |
| -------------------------------- | ------ | ------------------------------------------- |
| Run typecheck / lint / tests     | haiku  | Pure execution, no judgment needed          |
| Format or generate reports       | haiku  | Template-driven output                      |
| Explore codebase (Explore agent) | haiku  | File discovery, grep, glob — deterministic  |
| Page testing / smoke testing     | haiku  | Navigate + check console — mechanical       |
| Fix lint/type errors             | sonnet | Needs understanding of code context         |
| Code review (single file)        | sonnet | Nuanced but bounded scope                   |
| Implement a feature in worktree  | sonnet | Judgment + code writing, bounded by spec    |
| Investigate a bug                | sonnet | Requires reasoning about code behavior      |
| Security audit                   | opus   | Critical findings require deep reasoning    |
| Architecture review              | opus   | Cross-system reasoning, trade-off analysis  |
| Full CTO review (orchestrator)   | opus   | Synthesizes across multiple domains         |
| Product spec / PRD generation    | opus   | Requires product thinking + technical depth |

## Per-Skill Recommendations

| Skill              | Orchestrator | Subagent Tasks                                   | Recommended Model |
| ------------------ | ------------ | ------------------------------------------------ | ----------------- |
| **parallel-dev**   | opus         | Feature implementation in worktree               | sonnet            |
| **parallel-dev**   | opus         | CI fix agent                                     | sonnet            |
| **cto**            | opus         | Explore agent (codebase discovery)               | haiku             |
| **cto**            | opus         | Security analyst (swarm)                         | sonnet            |
| **cto**            | opus         | Architecture/performance/quality analyst (swarm) | sonnet            |
| **deep-plan**      | opus         | Explore agent (scope identification)             | haiku             |
| **deep-research**  | opus         | Research track investigators                     | sonnet            |
| **fulltest-skill** | sonnet       | Page testers (navigate + check)                  | haiku             |
| **fulltest-skill** | sonnet       | CSS/JS fixers                                    | sonnet            |
| **qa-cycle**       | opus         | Discovery (Explore)                              | haiku             |
| **qa-cycle**       | opus         | Persona testers                                  | haiku             |
| **qa-cycle**       | opus         | Fix agents                                       | sonnet            |
| **qa-fix**         | sonnet       | Investigation + fix                              | sonnet            |
| **qa-verify**      | sonnet       | Verification testing                             | haiku             |
| **qa-sourcerank**  | opus         | Persona testers (currently sonnet — downgrade)   | haiku             |
| **chief-geo**      | opus         | Knowledge researchers (×2)                       | sonnet            |
| **chief-geo**      | opus         | Knowledge indexer                                | haiku             |
| **chief-geo**      | opus         | Product audit specialists (×3)                   | sonnet            |
| **chief-geo**      | opus         | Visibility testers (×4)                          | haiku             |

## How to Apply

When spawning a subagent via the Agent tool, always include the `model` parameter:

```
Agent(subagent_type="general-purpose", model="haiku", prompt="...")
Agent(subagent_type="Explore", model="haiku", prompt="...")
Agent(subagent_type="general-purpose", model="sonnet", prompt="...")
```

When spawning teammates via Agent Teams, include model guidance in the spawn prompt:
"Use model: sonnet for this teammate" (Agent Teams inherits from parent by default).

## Model Delegation Pattern (OpenClaw-Inspired)

Beyond routing subagents to cheaper Claude tiers, a more aggressive cost optimization is **model delegation**: use an expensive model (Opus) strictly for orchestration and reasoning, while delegating text generation to a cheap or free model.

### How It Works

```
Orchestrator (Opus/Sonnet) → decides WHAT to do
  ↓
Generator (Haiku / local model) → does the mechanical work
```

The orchestrator handles planning, tool selection, and judgment calls. The generator handles scaffolding, formatting, template expansion, and deterministic output. This mirrors the OpenClaw pattern where Claude Opus orchestrates while a local model handles generation, cutting API costs ~10x.

### Where This Applies Today

Within the current Claude API ecosystem, this is already partially implemented via the tier strategy (Opus orchestrates, Haiku executes). The key insight is to be **more aggressive** about pushing work down:

| Current Pattern                                   | Delegation Pattern                                           |
| ------------------------------------------------- | ------------------------------------------------------------ |
| Opus orchestrator reads files itself              | Opus delegates file reading to Haiku Explore agent           |
| Sonnet subagent formats its own report            | Sonnet produces findings, Haiku formats the report           |
| Each subagent explores the codebase independently | Orchestrator pre-computes context, passes it in spawn prompt |

### Local Model Tier (Tier 0) — Claudia Infrastructure

Tier 0 is **production-deployed** via Claudia's 3-tier inference chain. These models handle message routing, text generation, and lightweight agentic tasks outside of Claude Code.

**Note:** Claude Code subagents can only route to Anthropic models (Haiku/Sonnet/Opus). Tier 0 applies to Claudia and other systems that can call local/cloud endpoints directly.

#### Deployed Infrastructure

| Location                    | Model                                  | Runtime        | Endpoint           | Speed           |
| --------------------------- | -------------------------------------- | -------------- | ------------------ | --------------- |
| **Mac Mini M4 Pro (48 GB)** | Qwen3.5-35B-A3B-4bit (MoE, 3B active)  | MLX LM v0.31.1 | `mini:1235`        | ~103 tok/s      |
| **Mac Mini**                | Qwen3.5-9B-4bit                        | MLX LM         | `mini:1235` (swap) | ~46-52 tok/s    |
| **Mac Mini**                | nanoLLaVA-1.5-8bit (vision)            | MLX VLM        | `mini:8001`        | —               |
| **Mac Mini**                | nomic-embed-text-v1.5 (embeddings)     | LM Studio      | `mini:1234`        | —               |
| **VPS (Contabo)**           | Nemotron 3 Super 120B MoE (12B active) | Ollama         | `vps:11434`        | CPU-bound, slow |
| **VPS**                     | Qwen3:8B, Qwen2.5:14B                  | Ollama         | `vps:11434`        | CPU-bound, slow |
| **Cloud**                   | Qwen 3.6 Plus                          | OpenRouter     | API                | Fast            |

#### Claudia's Fallback Chain

```
Tier 1: Claude Max (Agent SDK) — primary for all reasoning
  ↓ fallback
Tier 2: Mac Mini MLX — Qwen3.5-35B-A3B (via Tailscale)
  ↓ fallback
Tier 3: VPS Ollama — Nemotron 3 Super
  ↓ fallback
Tier 0R: OpenRouter — Qwen 3.6 Plus (cloud, free while preview lasts)
```

#### Combined Tier Table

| Tier        | Model                                                  | Cost   | Where Used                      |
| ----------- | ------------------------------------------------------ | ------ | ------------------------------- |
| **Tier 0a** | Qwen 3.6 Plus via OpenRouter (1M ctx, native tool use) | Free\* | Claudia fallback                |
| **Tier 0b** | Qwen3.5-35B-A3B-4bit via MLX (Mac Mini)                | Free   | Claudia Tier 2, text generation |
| **Tier 0c** | Nemotron 3 Super via Ollama (VPS)                      | Free   | Claudia Tier 3, CEO agents      |
| **Tier 1**  | Haiku                                                  | Low    | Claude Code subagents           |
| **Tier 2**  | Sonnet                                                 | Medium | Claude Code subagents           |
| **Tier 3**  | Opus                                                   | High   | Claude Code orchestration       |

\* Qwen 3.6 Plus Preview is free on OpenRouter as of March 2026. Previous gen went to $0.1/$0.3 after preview ended — expect similar.

#### Candidate: Qwen3.5-27B-Claude-Opus-Distilled

`Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled` — SFT+LoRA fine-tune on Claude 4.6 Opus reasoning traces. Q4_K_M at ~16.5 GB, 29-35 tok/s on RTX 3090, 262K context. Native tool-calling, thinking mode, self-correction. Validated in Claude Code agentic loops (9+ min autonomous, 353K+ HF downloads). MLX 4-bit variant available. **Not yet deployed** — the Qwen3.5-35B-A3B already running on Mini is faster (103 vs ~30 tok/s) though lacks the reasoning distillation. Worth A/B testing for agentic quality vs speed tradeoff.

### Practical Takeaway

Even without local models, apply the delegation mindset now:

1. **Pre-compute context** in the orchestrator instead of letting each subagent rediscover it
2. **Split reasoning from generation** — if a subagent needs to analyze AND format, consider two passes
3. **Push formatting to Haiku** — any subagent whose final step is "format findings as markdown table" could delegate that step

## Context Window Considerations

As of v2.1.75, Opus 4.6 defaults to **1M context** for Max/Team/Enterprise. This changes the cost calculus:

- Orchestrator skills (cto, ship, parallel-dev) can hold more codebase context without aggressive compaction
- Spawn prompts can include richer pre-computed context (Section 3.5) without crowding the window
- Subagents inheriting Opus also get 1M, reducing the need for aggressive scope-limiting in spawn prompts

## Rule of Thumb

**If the subagent only reads files and reports results → haiku.**
**If the subagent writes code or makes judgment calls → sonnet.**
**If the subagent makes architectural or security decisions → opus.**
**If the task runs via Claudia (not Claude Code) → Tier 0b (Qwen3.5-35B-A3B on Mac Mini) or Tier 0a (OpenRouter).**
