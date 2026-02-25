# Memory Consolidation - Quick Reference

## Commands

### Consolidation
```bash
/consolidate              # Full consolidation cycle
/consolidate --dry-run    # Preview changes without applying
/consolidate --health     # Health report only
```

### Reflection (Metacognition)
```bash
/reflect                  # Deep reflection: what worked, what didn't
/reflect --quick          # Quick session summary
/reflect --beliefs        # Validate core beliefs against evidence
/reflect --memories       # Memory effectiveness rankings
```

### Attention
```bash
/attention                # Show current attention weights
/attention --focus auth   # Set focus to "authentication"
/attention --reset        # Reset all attention weights
```

## What Consolidation Does

1. **Analyzes** all memories in Memory MCP
2. **Merges** similar memories (>70% overlap)
3. **Promotes** high-performing patterns to core-memory.json
4. **Forgets** stale memories (archives them first)
5. **Reports** health metrics and recommendations

## What Reflection Does

1. **Evaluates** which memories were helpful vs not
2. **Identifies** high-value patterns (candidates for promotion)
3. **Flags** low-value patterns (candidates for deletion)
4. **Checks** for unsaved learnings from recent work
5. **Validates** core beliefs against evidence

## Thresholds (from core-memory.json)

| Setting | Default | Meaning |
|---------|---------|---------|
| `relevanceThreshold` | 5 | Minimum score to save new memory |
| `decayThresholdDays` | 90 | Days unused before decay eligible |
| `minUsesToRetain` | 3 | Minimum uses to keep memory |

## Promotion Criteria

Memory promoted to core when:
- `useCount >= 15`
- `effectiveness >= 85%`
- `age >= 30 days` (proven over time)

## Forgetting Criteria

Memory archived when:
- `daysSinceLastUse > 90`
- `useCount < 3`
- `effectiveness < 30%` (if tracked)
- NOT marked as `critical: true`

## Files

| File | Purpose |
|------|---------|
| `~/.claude-setup/memory/core-memory.json` | Stable preferences and beliefs |
| `~/.claude-setup/memory/archive/*.json` | Archived forgotten memories |
| Memory MCP | Long-term cross-project learnings |

## Attention Weights

Topics are weighted by relevance to current work (0.0 to 1.0):

```
authentication ████████████████████████████ 0.95  ← current focus
security       ██████████████████          0.70  ← related
database       ██████████                  0.40  ← recent
ui-components  ████                        0.15  ← background
```

**How it works:**
- Current focus gets ~0.95 weight
- Related topics get boost (0.2-0.3)
- Previous topics decay by 30% on focus change
- Memory queries prioritize high-weight topics

## Run Regularly

| When | Command |
|------|---------|
| Every Monday | `/consolidate` |
| After major project | `/consolidate` |
| Every 10 stories | `/reflect` (auto-triggered) |
| Before new project | `/consolidate --health` |
| Feeling "cluttered" | `/reflect --memories` |
