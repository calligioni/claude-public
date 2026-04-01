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

### Local Model Tier (Tier 0)

Tier 0 is production-viable today thanks to two converging breakthroughs:

**1. TurboQuant (Google Research, ICLR 2026)** — compresses transformer KV cache from 16-bit to ~3-bit per value. 6x memory reduction, 8x faster attention on H100, zero accuracy loss, no retraining. Two components: PolarQuant (rotation that normalizes vector distributions) and QJL (reduces residual error to a single sign bit). Approaches the Shannon limit — there is almost no room left for compression-only improvements. Community rebuilt it from paper math within 24 hours across PyTorch Triton, Apple MLX, and llama.cpp/CUDA.

**Hardware impact with TurboQuant:**

| Model Size | KV Cache Before | KV Cache After | Runs On                   |
| ---------- | --------------- | -------------- | ------------------------- |
| 8B         | ~2 GB           | ~330 MB        | Any Mac, any GPU          |
| 35B        | ~10 GB          | ~1.7 GB        | Mac Mini M4, RTX 3060     |
| 70B        | ~80 GB          | ~13 GB         | RTX 4090 solo, Mac Studio |

**Caveats:** 8x speedup is for attention logits specifically, not full inference. Testing validated up to ~8B; 70B+ is unproven in the wild. Naive QJL implementation (without proper bias correction) produces garbage — the math must be followed exactly.

**2. OpenClaw-RL (Princeton, 2026)** — fully async RL framework that turns conversations into training signals. Every reply, tool output, and environment state change becomes a reward signal. A personal agent improved from score 0.17 → 0.81 after 36 conversations. Architecture: four async loops — agent serving, rollout collection, PRM/judge evaluation, policy training (PPO/GRPO). Models deploy as OpenAI-compatible APIs.

**Reference model: Nvidia Nemotron 3 Super** — 120B MoE (12B active params), 1M native context, DeepSeek-R1-style chain-of-thought, native tool-call support, 85.6% on PinchBench. With TurboQuant, its ~35 GB KV cache drops to ~6 GB — comfortably fits on a single RTX 4090 or Mac Studio.

| Tier        | Model                                              | Cost   | Use For                                                                                                            |
| ----------- | -------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------ |
| **Tier 0a** | Cloud (Qwen 3.6 Plus via OpenRouter)               | Free\* | 1M context, cloud-hosted — no setup, use while preview pricing lasts                                               |
| **Tier 0b** | Local (Qwen3.5-27B-Claude-Opus-Distilled, primary) | Free   | Agentic coding, tool-calling subagent loops, feature implementation — proven 9+ min autonomous runs in Claude Code |
| **Tier 1**  | Haiku                                              | Low    | Deterministic execution with tool use                                                                              |
| **Tier 2**  | Sonnet                                             | Medium | Nuanced judgment, code review, implementation                                                                      |
| **Tier 3**  | Opus                                               | High   | Architecture, security, complex reasoning                                                                          |

\* Qwen 3.6 Plus Preview is free on OpenRouter as of March 2026 ($0/$0 per 1M tokens, 1M context). Previous gen (Qwen 3.5) went to $0.1/$0.3 after preview ended — expect similar. Any integration should fall back to Tier 0b or Tier 1 when pricing changes.

**Primary Tier 0b model: Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled** (`Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled`). SFT+LoRA fine-tune on Claude 4.6 Opus reasoning traces. Q4_K_M runs at ~16.5 GB VRAM, 29–35 tok/s on RTX 3090, full 262K context. Native tool-calling, thinking mode, self-correction — validated in Claude Code agentic loops (9+ min autonomous runs, zero human intervention). 353K+ HF downloads. Variants: GGUF (llama.cpp), v2 GGUF, MLX 4-bit (`mlx-community/Qwen3.5-27B-Claude-4.6-Opus-Distilled-MLX-4bit`).

**Deployment path:** Qwen 3.6 Plus via OpenRouter (cloud, free while preview lasts) for tasks that don't require local isolation. Qwen3.5-27B-Claude-Opus-Distilled via Ollama/llama.cpp (local, primary for agentic coding). Nemotron 3 Super via Ollama + TurboQuant (local, alternative for non-coding generation) + OpenClaw-RL for continuous improvement. Fallback: Qwen 3.5-4B (edge) or Qwen 3.5-8B (quality) via Ollama/LM Studio. MLX-optimized variants available for Apple Silicon.

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
**If the task is agentic coding with tool calls → Tier 0b (Qwen3.5-27B-Claude-Opus-Distilled via Ollama/llama.cpp).**
**If the task is pure text generation or formatting → Tier 0a (Qwen 3.6 Plus via OpenRouter) or Tier 0b.**
