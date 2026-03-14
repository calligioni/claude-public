# Research: VIBC — Variety Independent Board Council

**Date:** 2026-03-14
**Scope:** Full system design for a Claude Code skill that simulates a 12-seat advisory board of maximally diverse human archetypes, providing structured deliberation on any decision or problem.

## Current Architecture (Existing Skill Ecosystem)

### Skill File Structure

All skills live at `~/.claude-setup/skills/<name>/SKILL.md` (symlinked to `~/.claude/skills/<name>/SKILL.md`). Each SKILL.md has:

1. **YAML frontmatter:** name, description, model, allowed-tools, tool-annotations, invocation-contexts, memory
2. **Markdown body:** the full instruction set for the orchestrator

Key patterns observed across 40+ skills:

| Pattern                               | Used In                               | Notes                                   |
| ------------------------------------- | ------------------------------------- | --------------------------------------- |
| YAML `model: opus` for orchestrator   | cto, parallel-dev, cpo, deep-research | Orchestrators that synthesize need Opus |
| YAML `model: sonnet` for orchestrator | fulltest-skill                        | Mechanical orchestration can use Sonnet |
| `context: fork`                       | All multi-agent skills                | Prevents context pollution              |
| Agent Teams (TeamCreate/SendMessage)  | cto, fulltest-skill, parallel-dev     | For cross-agent communication           |
| Task subagents (TaskCreate)           | cto (fallback), qa-cycle, cpo         | For fire-and-forget workers             |
| `mcp__postgres__query`                | chief-geo, qa-cycle, ship             | Direct Supabase/Postgres access         |
| `mcp__memory__*`                      | cto, deep-research, chief-geo         | Long-term knowledge persistence         |
| `mcp__sequential-thinking__*`         | first-principles, chief-geo           | Step-by-step reasoning                  |

### Agent Teams vs Subagents (Decision Framework)

From `AGENT-TEAMS-STRATEGY.md`:

- **Agent Teams (TeamCreate/SendMessage):** 3-5 teammates, need cross-talk, isolated workspaces. Cost: ~$0.50-2.00/teammate.
- **Subagents (Task tool):** Report-back-only, lightweight workers, >5 workers. Cheaper.
- **Sweet spot:** 3-5 teammates with cross-talk need.

**VIBC Assessment:** 12 board members is **above the 5-teammate cap**. Per the strategy doc, "above 5, token costs scale linearly but coordination quality degrades." However, VIBC has a unique property: **board members deliberate blindly and independently** — they do NOT need to cross-talk during initial input. Cross-talk only happens in the adversarial pairing phase (2 agents at a time).

**Verdict:** Use **Task subagents** (not Agent Teams) for the initial 12 blind deliberations. Use **Agent Teams** only for the adversarial pairing phase (2-3 pairs, well within the sweet spot).

### Model Tier Strategy

From `model-tier-strategy.md`:

| Component                                                | Recommended Model | Rationale                                        |
| -------------------------------------------------------- | ----------------- | ------------------------------------------------ |
| **Orchestrator** (collision mapping, synthesis, scoring) | opus              | Cross-domain reasoning, trade-off analysis       |
| **Board members** (persona deliberation)                 | sonnet            | Nuanced judgment, bounded scope per persona      |
| **Adversarial pairs** (steelman debates)                 | sonnet            | Requires reasoning but bounded to 2 perspectives |
| **Database operations** (persist decisions)              | haiku             | Mechanical SQL execution                         |

### Database Access Patterns

Two patterns exist in the codebase:

1. **`mcp__postgres__query`:** Used by chief-geo, qa-cycle, ship. Points to the default MCP-configured Postgres instance (likely Contably/Claudia Supabase).
2. **`psql` via Bash:** Used by qa-sourcerank with explicit connection string. Used when targeting a different database than the MCP default.

**For VIBC:** We should use `mcp__postgres__query` since VIBC data belongs in the general-purpose analytics database (cross-project decision tracking). If the user needs a separate Supabase project, the skill should detect and adapt.

### Existing Deliberation Patterns

The closest existing skills to VIBC:

1. **CTO Swarm:** 4 specialist analysts with domain expertise, parallel execution, cross-concern detection, synthesis into executive report. Similar to VIBC's "diverse perspectives → collision mapping → synthesis."
2. **Deep Research:** Multi-track parallel investigation (primary, literature, expert, contrarian), evidence hierarchy, confidence scoring. Similar to VIBC's evidence-based synthesis.
3. **First Principles:** Structured decomposition, trade-off evaluation, explicit "what we're NOT doing." Similar to VIBC's anti-corruption mechanisms.

## Data Flow

```
User Input (decision/problem)
    │
    ▼
Phase 1: FRAMING (orchestrator)
    │ Parse the decision
    │ Identify decision type (binary, multi-option, strategy, resource allocation)
    │ Set scope boundaries
    │
    ▼
Phase 2: BLIND DELIBERATION (12 parallel sonnet subagents)
    │ Each board member receives IDENTICAL framing
    │ Each produces independent analysis from their archetype's lens
    │ NO cross-contamination between members
    │ Results collected as structured JSON
    │
    ▼
Phase 3: COLLISION MAPPING (orchestrator)
    │ Map agreements (≥6 members align → strong signal)
    │ Map contradictions (direct conflicts between members)
    │ Identify orphan insights (unique perspectives from single member)
    │ Flag unanimity warnings (12/12 agreement = possible groupthink)
    │
    ▼
Phase 4: ADVERSARIAL PAIRING (2-3 sonnet agent pairs)
    │ Top contradictions become steelman debates
    │ Each side must present the STRONGEST version of the opposing argument
    │ Resolution: synthesis, clear winner, or "irreducible tension"
    │
    ▼
Phase 5: OPTION GENERATION (orchestrator)
    │ Generate 2-4 concrete options from deliberation
    │ Each option has: core bets, kill conditions, reversibility score
    │
    ▼
Phase 6: DECISION SCORING MATRIX (orchestrator)
    │ 6 dimensions weighted by relevant board seats
    │ Quantitative scoring with dimensional breakdown
    │
    ▼
Phase 7: PERSIST & PRESENT (orchestrator + database)
    │ Write to Supabase: decision, board input, options, scores
    │ Present executive summary to user
    │ Schedule retrospective if user sets outcome tracking
    │
    ▼
Phase 8: RETROSPECTIVE (triggered later)
    │ User reports actual outcome
    │ Compare prediction vs reality
    │ Update board batting average
    │ Memory MCP: store pattern for future decisions
```

## Existing Patterns

### YAML Frontmatter Pattern (from CTO/fulltest/parallel-dev)

All multi-agent skills share this structure:

- `context: fork` — always
- Both TeamCreate/SendMessage AND TaskCreate for hybrid mode
- `mcp__memory__*` for long-term learning
- `mcp__postgres__query` for database operations
- tool-annotations declaring destructive/idempotent hints
- invocation-contexts for user-direct vs agent-spawned

### Subagent Spawning Pattern

The CTO swarm spawns 4 analysts. VIBC spawns 12 board members. Key differences:

| CTO Swarm                          | VIBC Board                                        |
| ---------------------------------- | ------------------------------------------------- |
| 4 analysts with technical domains  | 12 members with life-experience archetypes        |
| Cross-talk during analysis         | Blind deliberation (no cross-talk)                |
| Report: severity, file:line, issue | Report: position, reasoning, concerns, conditions |
| All analysts see the same codebase | All members see the same decision framing         |

Since VIBC members don't cross-talk during Phase 2, Task subagents (not Agent Teams) are optimal. This avoids the broadcast tax of 12 context windows receiving messages they don't need.

### Persistence Pattern (from qa-cycle, chief-geo)

The qa-cycle schema is the best reference:

- `qa_sessions` → maps to `vibc_decisions`
- `qa_issues` → maps to `vibc_board_inputs`
- Session-based grouping with status tracking
- JSONB for flexible metadata

## Dependencies

### Required MCP Tools

- `mcp__postgres__query` — Supabase persistence (decisions, outcomes, batting average)
- `mcp__memory__*` — Long-term pattern learning
- `mcp__sequential-thinking__sequentialthinking` — Structured deliberation phases

### Required Claude Code Tools

- `TaskCreate/TaskUpdate/TaskList/TaskGet` — 12 parallel blind deliberations
- `TeamCreate/TeamDelete/SendMessage` — Adversarial pairing (optional, for steelman debates)
- `Agent` — General subagent spawning
- `Read/Write/Edit/Glob/Grep/Bash` — Standard file and system operations
- `AskUserQuestion` — User interaction gates

### External Dependencies

- Supabase project with Postgres access (existing MCP config or psql)
- No browser tools needed (pure reasoning skill)
- No web search needed (deliberation from archetypes, not external data)

## Constraints

### Token Budget

12 sonnet subagents × ~$0.50-1.00 each = ~$6-12 per decision for deliberation alone. Plus orchestrator (opus) synthesis. **Total estimated cost: $8-15 per full VIBC run.**

This is expensive. Mitigation:

1. **Batch persona agents:** Run 4 batches of 3 instead of 12 individually (reduces Task overhead)
2. **Compact persona prompts:** Each persona prompt must be minimal — archetype + decision framing only (see Token Minimization in AGENT-TEAMS-STRATEGY.md)
3. **Skip adversarial pairing** if no contradictions found (saves 2-3 sonnet calls)
4. **Quick mode:** Offer a 4-seat "executive committee" mode for simpler decisions

### Anti-Corruption Mechanisms

1. **Blind input:** Board members NEVER see each other's responses during Phase 2
2. **Mandatory dissent detection:** If all 12 agree, flag as potential groupthink. Force the orchestrator to construct a counter-argument.
3. **Unanimity warning:** Display prominently when all seats align. "When everyone agrees, someone isn't thinking." — Patton
4. **Persona integrity:** Each persona prompt must be crafted to produce GENUINELY different perspectives, not just different wording of the same conclusion. The personas must have conflicting values, priorities, and risk tolerances.
5. **No anchoring:** The orchestrator must NOT include its own preliminary opinion in the framing sent to board members.

### The 12 Seats — Archetype Design Principles

Each seat must bring a lens that NO other seat shares. The archetypes are chosen for **value diversity**, not just **demographic diversity**:

| Seat | Archetype                | Primary Lens                             | Unique Value                                         |
| ---- | ------------------------ | ---------------------------------------- | ---------------------------------------------------- |
| 1    | Combat Veteran           | Risk assessment, worst-case planning     | "What's the threat nobody's naming?"                 |
| 2    | Social Worker            | Human impact, unintended consequences    | "Who gets hurt that we're not seeing?"               |
| 3    | Rabbi                    | Ethical frameworks, historical patterns  | "What does tradition teach about this?"              |
| 4    | Pastor                   | Community impact, moral clarity          | "What's the right thing to do for people?"           |
| 5    | Trial Lawyer             | Adversarial thinking, evidence standards | "What's the weakest link in this argument?"          |
| 6    | Farmer                   | Long-term sustainability, patience       | "What happens in 5 years, not 5 months?"             |
| 7    | ER Physician             | Triage, urgency calibration              | "What needs to happen RIGHT NOW vs later?"           |
| 8    | Jazz Musician            | Creative alternatives, improvisation     | "What option hasn't anyone considered?"              |
| 9    | Intelligence Analyst     | Pattern recognition, hidden variables    | "What's the thing we don't know that we don't know?" |
| 10   | Immigrant Business Owner | Resourcefulness, survival instinct       | "How do you do this with half the resources?"        |
| 11   | Hospice Nurse            | What truly matters, regret minimization  | "Will this matter in the end?"                       |
| 12   | Comedian                 | Absurdity detection, truth-telling       | "What's the elephant in the room nobody's saying?"   |

### Decision Scoring Dimensions

6 dimensions, each weighted by the most relevant 2-3 board seats:

| Dimension          | Description                             | Primary Seats                                | Weight Range |
| ------------------ | --------------------------------------- | -------------------------------------------- | ------------ |
| **Risk**           | Downside exposure, worst-case severity  | Veteran, Intelligence Analyst, ER Physician  | 10-30%       |
| **Ethics**         | Moral clarity, stakeholder fairness     | Rabbi, Pastor, Social Worker                 | 10-25%       |
| **Feasibility**    | Practical executability, resource needs | Farmer, Immigrant Owner, ER Physician        | 10-25%       |
| **Creativity**     | Novel approaches, unexplored options    | Jazz Musician, Comedian, Immigrant Owner     | 5-15%        |
| **Sustainability** | Long-term viability, reversibility      | Farmer, Hospice Nurse, Social Worker         | 10-20%       |
| **Clarity**        | Argument strength, evidence quality     | Trial Lawyer, Intelligence Analyst, Comedian | 10-20%       |

Weight ranges are defaults — the orchestrator adjusts based on decision type (e.g., a crisis decision weights Risk and Feasibility higher; an ethical dilemma weights Ethics and Sustainability higher).

## Key Files (to be created)

| File                                      | Purpose                     | Relevance                      |
| ----------------------------------------- | --------------------------- | ------------------------------ |
| `~/.claude-setup/skills/vibc/SKILL.md`    | Main skill definition       | Core orchestrator instructions |
| `~/.claude-setup/skills/vibc/personas/`   | 12 persona prompt files     | Board member system prompts    |
| `~/.claude-setup/skills/vibc/schema.sql`  | Supabase schema             | Decision persistence           |
| `~/.claude-setup/skills/vibc/references/` | Scoring templates, examples | Reference material             |

## Open Questions

1. **Supabase project:** Should VIBC use the existing MCP-connected Postgres (same DB as Contably/Claudia), or should it use a separate Supabase project? The data is cross-project (decisions could be about any domain), so the existing connection seems appropriate. However, this means the schema must be namespaced (`vibc_*` prefix).

2. **Retrospective trigger:** How should retrospective reviews be triggered? Options:
   - Manual: user runs `/vibc retro <decision-id>` when outcome is known
   - Scheduled: set a CronCreate for N days after decision
   - Both: schedule a reminder but allow manual override

3. **Quick mode:** Should there be a 4-seat "executive committee" mode for simpler decisions? This would use only Veteran, Trial Lawyer, Farmer, and ER Physician — covering risk, argument quality, sustainability, and urgency at ~1/3 the cost.

4. **Output format:** Should the final report be written to a file (`vibc-report-<id>.md`) or displayed in chat? The CTO skill writes to file; deep-research writes to file. Consistency suggests file output with a summary in chat.

5. **Adversarial pairing mechanism:** Should steelman debates use Agent Teams (TeamCreate + SendMessage for back-and-forth) or sequential Task subagents (cheaper, but no true dialogue)? Agent Teams allows genuine exchange; Tasks would be "Side A writes steelman of B, then Side B writes steelman of A" in two separate calls.
