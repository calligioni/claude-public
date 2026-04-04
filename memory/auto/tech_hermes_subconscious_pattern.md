---
name: tech-insight:hermes-subconscious-pattern
description: Hermes agent patterns implemented in Claudia — periodic nudge, auto-skill generation, session consolidation, skill self-patch policy
type: reference
---

## Hermes "Subconscious" Patterns — Implementation Reference

Patterns from @gkisokay's Hermes Agent article (Apr 2026), adapted and implemented across Claudia and /meditate skill.

### Pattern 1: Periodic Nudge (Score 9/10)

- **Concept:** Inject memory curation prompt every N turns instead of only at session end
- **Implemented in:** `src/memory/nudge.ts` (Claudia) + `/meditate` Phase 0 (Claude Code)
- **Mechanism:** Turn counter per session → Mac Mini LLM evaluates "worth persisting?" → delegates to fact-extractor
- **Config:** NUDGE_INTERVAL env var (default 10)

### Pattern 2: Auto-Skill Generation (Score 8/10)

- **Concept:** Complex sessions auto-generate SKILL.md stubs for future reuse
- **Implemented in:** `src/skills/complexity-tracker.ts` (Claudia) + `/meditate` Phase 6 (Claude Code)
- **Claudia:** Tracks code blocks, error recovery, user corrections, step patterns. Triggers when 2+ thresholds crossed.
- **Meditate:** Heuristic check at end-of-session. Drafts SKILL.md stubs to ~/.claude/skills/.

### Pattern 3: Session Consolidation / Sentinel (Score 7/10)

- **Concept:** Before dropping sessions, extract summary + facts and store as "session sentinel"
- **Implemented in:** `src/memory/consolidate.ts` (Claudia)
- **Mechanism:** Rolling window of 10 exchanges → LLM summarization → stored in KG as session-sentinel entity

### Pattern 4: Skill Self-Patch Policy (Score 6/10)

- **Concept:** Prefer Edit (patch) over full rewrite when updating skill files
- **Implemented in:** `~/.claude-setup/rules/skill-authoring-conventions.md`
- **Key rules:** auto-generated skills are drafts, use model: sonnet, include review notes, lifecycle tracking

### Source

- X article: @gkisokay, Apr 3 2026 — "I Gave My Hermes + OpenClaw Agents a Subconscious"
- Key insight: the periodic nudge is the single mechanism that makes memory compound autonomously

**How to apply:** When building agent memory systems or extending Claudia's memory pipeline, reference these patterns. The nudge interval and complexity thresholds are tunable per agent.
