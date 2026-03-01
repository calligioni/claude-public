---
name: meditate
description: "End-of-session judgment extraction. Structured capture of learnings, patterns, and mistakes after completing /ship, /cto, /parallel-dev, /deep-plan, or any substantial session. Feeds the memory pipeline with high-quality, pre-scored observations. Triggers on: meditate, reflect on session, extract learnings, /meditate."
user-invocable: true
context: fork
model: haiku
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - mcp__memory__search_nodes
  - mcp__memory__create_entities
  - mcp__memory__create_relations
  - mcp__memory__add_observations
memory: user
tool-annotations:
  mcp__memory__create_entities: { readOnlyHint: false, idempotentHint: false }
  mcp__memory__add_observations: { readOnlyHint: false, idempotentHint: false }
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: false
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
---

# Meditate Skill

End-of-session judgment extraction. Runs after completing substantial work (`/ship`, `/cto`, `/parallel-dev`, `/deep-plan`, or any long session) to capture learnings before context is lost.

This is the **intake step** for the memory pipeline. `/consolidate` is the **maintenance step**. Together they form the full memory lifecycle: meditate captures, consolidate prunes and promotes.

## When to Run

- After completing a `/ship` cycle
- After a `/cto` review (especially swarm mode)
- After `/parallel-dev` finishes all features
- After `/deep-plan` implementation
- After any session >30 minutes with meaningful code changes
- When the user says `/meditate` or "reflect on session"

## Phase 1: Gather Session Context

Scan the current session for what happened. Read these sources (skip any that don't exist):

```
1. Git log (last 20 commits on current branch)
2. Git diff --stat HEAD~10..HEAD (what files changed)
3. Any state files from recent skills:
   - .ship/state.json
   - .deep-plan/plan.md
   - .parallel-dev/features.json
   - .cto/last-review.md
4. Auto-memory entries from this session:
   - ~/.claude/memory/*.md (check timestamps for today)
```

Build a mental model of: **what was built, what broke, what was fixed, what was learned**.

## Phase 2: Extract Judgments

For each significant event in the session, ask these 5 questions:

| #   | Question                                  | Maps To                |
| --- | ----------------------------------------- | ---------------------- |
| 1   | Did something break that shouldn't have?  | `mistake:` entity      |
| 2   | Did I discover a reusable pattern?        | `pattern:` entity      |
| 3   | Did I learn something about a technology? | `tech-insight:` entity |
| 4   | Did the user express a preference?        | `preference:` entity   |
| 5   | Was an architecture decision made?        | `architecture:` entity |

### Extraction Rules

- **Be specific.** "Supabase RLS policies need to be tested with anon key, not service key" is good. "Supabase is tricky" is useless.
- **Include the fix.** Every `mistake:` should include what the correct approach is.
- **Include the trigger.** Every `pattern:` should include when to apply it.
- **Max 5 entities per session.** If you find more, keep only the 5 most generalizable. Quality over quantity.

## Phase 3: Score and Filter

For each candidate, calculate a quick relevance score using the criteria from memory-consolidation:

| Factor                       | Points    | Check                                        |
| ---------------------------- | --------- | -------------------------------------------- |
| Applies to multiple projects | +2 to +3  | Would this help in Contably AND SourceRank?  |
| Learned from failure         | +2        | Did something break?                         |
| User explicitly stated       | +3        | Did the user say "always do X"?              |
| High severity                | +3 to +5  | Could ignoring this cause production issues? |
| Common scenario              | +2        | Will this come up again within a week?       |
| Similar memory exists        | -2        | Check Memory MCP first                       |
| Duplicate (>85%)             | -Infinity | Skip entirely                                |

**Threshold: 5.** Only save entities scoring >= 5.

## Phase 4: Save to Memory MCP

For each entity that passes the filter:

```javascript
await mcp__memory__create_entities({
  entities: [
    {
      name: "{type}:{kebab-case-identifier}",
      entityType: "{type}", // pattern, mistake, tech-insight, preference, architecture
      observations: [
        "{the actual learning — specific, actionable, includes context}",
        "Discovered: {today's date}",
        "Source: session — {skill or context that triggered this}",
        "Relevance score: {calculated score}",
        "Use count: 0",
      ],
    },
  ],
});
```

### Create Relations

If the new entity relates to existing memories, create relations:

```javascript
// Check for related existing memories
const related = await mcp__memory__search_nodes({
  query: "{relevant keyword}",
});

// If found, create relation
await mcp__memory__create_relations({
  relations: [
    {
      from: "{new-entity-name}",
      relationType: "related_to", // or derived_from, applies_to, supersedes
      to: "{existing-entity-name}",
    },
  ],
});
```

### Update Existing Memories

If a session **confirms** an existing memory works, update it:

```javascript
await mcp__memory__add_observations({
  observations: [
    {
      entityName: "{existing-entity-name}",
      contents: ["Applied in: {project} - {today's date} - HELPFUL"],
    },
  ],
});
```

## Phase 5: Report

Output a concise summary:

```markdown
## Meditation Report

**Session:** {what was done}
**Duration context:** {skill used or manual work}

### Captured ({N} entities)

| Entity      | Type    | Score | Summary |
| ----------- | ------- | ----- | ------- |
| pattern:xyz | pattern | 7     | ...     |
| mistake:abc | mistake | 6     | ...     |

### Updated ({N} existing)

| Entity                    | Update                         |
| ------------------------- | ------------------------------ |
| tech-insight:supabase-rls | Applied in: Contably - HELPFUL |

### Skipped ({N} below threshold)

| Candidate | Score | Reason               |
| --------- | ----- | -------------------- |
| ...       | 3     | Too project-specific |

---

Next consolidation: run `/consolidate` when memory count > 200 or weekly.
```

## Integration with Other Skills

### Auto-trigger after /ship

The `/ship` skill can call `/meditate` at the end of its cycle. Add to ship's post-implementation phase:

```
After QA passes and code is committed, run /meditate to capture learnings.
```

### Auto-trigger after /cto swarm

The `/cto` swarm mode generates cross-concern findings. After the final report, `/meditate` captures the most generalizable insights.

### Standalone use

The user can run `/meditate` at any time to reflect on recent work. The skill adapts to whatever context is available (git log, state files, or just the conversation history).
