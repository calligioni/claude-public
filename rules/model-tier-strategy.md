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

### Future: Local Model Tier (Tier 0)

When local model infrastructure matures (Ollama, LM Studio MLX), a **Tier 0** becomes viable:

| Tier       | Model                       | Cost   | Use For                                              |
| ---------- | --------------------------- | ------ | ---------------------------------------------------- |
| **Tier 0** | Local (Qwen 3.5-9B, Ollama) | Free   | Pure text generation, template expansion, formatting |
| **Tier 1** | Haiku                       | Low    | Deterministic execution with tool use                |
| **Tier 2** | Sonnet                      | Medium | Nuanced judgment, code review, implementation        |
| **Tier 3** | Opus                        | High   | Architecture, security, complex reasoning            |

**Not actionable yet** — requires Ollama integration in Claude Code subagent spawning. Documented here for when the infrastructure supports it. Candidate models: Qwen 3.5-4B (edge), Qwen 3.5-9B (quality), both multimodal and MLX-optimized for Apple Silicon.

### Practical Takeaway

Even without local models, apply the delegation mindset now:

1. **Pre-compute context** in the orchestrator instead of letting each subagent rediscover it
2. **Split reasoning from generation** — if a subagent needs to analyze AND format, consider two passes
3. **Push formatting to Haiku** — any subagent whose final step is "format findings as markdown table" could delegate that step

## Rule of Thumb

**If the subagent only reads files and reports results → haiku.**
**If the subagent writes code or makes judgment calls → sonnet.**
**If the subagent makes architectural or security decisions → opus.**
**If the task is pure text generation with no tool use → candidate for Tier 0 (future).**
