---
name: tech-insight:hyperskill-skill-tree
description: HyperSkill auto-generates SKILL.md files from live docs; skill-tree command splits deep docs into navigable index + sub-files to avoid context bloat
type: tech
---

# HyperSkill & Skill Tree Pattern

**Entity:** `tech-insight:hyperskill-skill-tree`

## What It Is

HyperSkill is an open-source tool by Hyperbrowser that auto-generates SKILL.md files for AI coding agents. Pipeline: Serper API (search) → Hyperbrowser SDK (scrape to markdown) → GPT-4o (structure into SKILL.md). Supports single-topic and batch modes. Ships with a `/skill-tree` command that splits deep documentation into a navigable index + linked sub-files an agent can traverse hierarchically.

- GitHub: https://github.com/hyperbrowserai/hyperbrowser-app-examples/tree/main/hyperskills
- Skills generator: https://github.com/hyperbrowserai/hyperbrowser-app-examples/tree/main/skills-generator

## Key Insight: Skill Tree Navigation Pattern

One SKILL.md cannot hold deep domain knowledge without flooding context. The `/skill-tree` command creates:

- An index file the agent reads first
- Linked sub-files the agent follows only if relevant
- Skips irrelevant subtrees entirely

This is directly applicable to `/get-api-docs`, `/cto` swarm analysts, and `/deep-research` tracks.

## Recommendations Applied

1. **Skill tree navigation** (Score 8/10): APPLIED — Created `/skill-tree` skill at `~/.claude-setup/skills/skill-tree/SKILL.md`. Added to routing table in `skill-first.md`.
2. **Auto-generate SKILL.md from live docs** (Score 7/10): Use HyperSkill pipeline to bootstrap skill files for new libraries instead of writing by hand. Enhances `/get-api-docs`.
3. **Hyperbrowser SDK as scraping fallback** (Score 5/10): Could slot into `/research` fallback chain between Scrapling and WebFetch.

## Observations

- Discovered: 2026-03-16
- Source: research — https://x.com/hyperbrowser/status/2033608785953267759
- Applied in: claude-setup - 2026-03-16 - HELPFUL
- Use count: 1
