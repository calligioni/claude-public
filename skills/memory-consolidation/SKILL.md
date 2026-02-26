---
name: memory-consolidation
description: "Human-like memory maintenance for AI agents. Consolidates learnings, prunes unused memories, applies relevance filtering, and promotes patterns to core memory. Run weekly or after project milestones. Triggers on: consolidate memory, memory maintenance, clean up memories, /consolidate, memory health."
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - mcp__memory__*
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
  mcp__memory__delete_observations:
    { destructiveHint: true, idempotentHint: true }
  mcp__memory__delete_relations: { destructiveHint: true, idempotentHint: true }
  mcp__memory__create_entities: { readOnlyHint: false, idempotentHint: false }
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
---

# Memory Consolidation Skill

A human-inspired memory maintenance system that implements the cognitive processes of consolidation, forgetting, and metacognition for AI agents.

Based on: [Towards Human-like Memory for AI Agents](https://manthanguptaa.in/posts/towards_human_like_memory_for_ai_agents/)

## Core Concepts

### Memory Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                     CORE MEMORY                              │
│  ~/.claude-setup/memory/core-memory.json │
│  - Stable preferences, beliefs, patterns                     │
│  - Rarely changes, high confidence                           │
│  - Loaded at session start                                   │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Promotion (high usage + effectiveness)
                              │
┌─────────────────────────────────────────────────────────────┐
│                   LONG-TERM MEMORY                           │
│  Memory MCP (patterns, mistakes, tech-insights)             │
│  - Cross-project learnings                                   │
│  - Subject to decay and consolidation                        │
│  - Conceptual graph with relationships                       │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Sensory Filter (relevance >= 5)
                              │
┌─────────────────────────────────────────────────────────────┐
│                  SHORT-TERM / SESSION                        │
│  progress.md, progress-summary.md, prd.json                 │
│  - Project-specific learnings                                │
│  - Evaluated for long-term storage at session end           │
└─────────────────────────────────────────────────────────────┘
```

---

## Auto-Memory Awareness

Since Claude Code v2.1.59, auto-memory captures context automatically during sessions. This skill should focus on **consolidation, pruning, and promotion** rather than raw capture:

- **Do NOT** duplicate what auto-memory already captures (session context, file paths, tool usage)
- **DO** consolidate auto-memory entries into structured patterns/insights
- **DO** prune redundant auto-memory entries that overlap with existing Memory MCP entities
- **DO** promote high-value auto-memory observations to the Memory MCP graph

When running consolidation, also scan `~/.claude/memory/` (auto-memory directory) for entries that should be:

1. **Promoted** to Memory MCP as structured entities (if relevance score >= 5)
2. **Pruned** if they duplicate existing Memory MCP content
3. **Left alone** if they're session-specific context that auto-memory handles well

## Entry Point Detection

When this skill activates:

| Condition                | Action                             |
| ------------------------ | ---------------------------------- |
| `/consolidate` invoked   | Run full consolidation cycle       |
| `memory health` asked    | Generate health report only        |
| Automatic (post-project) | Run if 10+ new memories since last |

**First Action:** Load current state:

```bash
cat ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-setup/memory/core-memory.json
ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-setup/memory/archive/ 2>/dev/null | wc -l
```

---

## Phase 1: Analyze Memory Health

### Step 1.1: Load All Memories

```javascript
// Query all memories from Memory MCP
const allMemories = await mcp__memory__search_nodes({ query: "" });

// Also query by specific types
const patterns = await mcp__memory__search_nodes({ query: "pattern:" });
const mistakes = await mcp__memory__search_nodes({ query: "mistake:" });
const techInsights = await mcp__memory__search_nodes({
  query: "tech-insight:",
});
const preferences = await mcp__memory__search_nodes({ query: "preference:" });
const research = await mcp__memory__search_nodes({ query: "research:" });
const competitors = await mcp__memory__search_nodes({ query: "competitor:" });
const designs = await mcp__memory__search_nodes({ query: "design:" });
const stacks = await mcp__memory__search_nodes({ query: "stack:" });

// Also scan auto-memory for consolidation candidates
const autoMemoryDir = `${HOME}/.claude/memory`;
const autoMemoryFiles = await glob(`${autoMemoryDir}/*.md`);
// Auto-memory entries are evaluated in Step 1.3 for promotion/pruning
```

### Step 1.2: Calculate Memory Statistics

For each memory, extract or infer:

```javascript
function analyzeMemory(entity) {
  const observations = entity.observations || [];

  // Extract metadata from observations (stored as structured strings)
  const discoveredAt = observations.find(
    (o) => o.startsWith("Researched:") || o.startsWith("Discovered:"),
  );
  const appliedIn = observations.filter((o) => o.startsWith("Applied in"));
  const helpfulCount = appliedIn.filter((o) => o.includes("HELPFUL")).length;
  const notHelpfulCount = appliedIn.filter((o) =>
    o.includes("NOT HELPFUL"),
  ).length;

  return {
    name: entity.name,
    type: entity.entityType,
    observationCount: observations.length,
    discoveredAt: parseDate(discoveredAt),
    useCount: appliedIn.length,
    helpfulCount,
    notHelpfulCount,
    effectiveness:
      appliedIn.length > 0 ? helpfulCount / appliedIn.length : null,
    ageInDays: daysSince(parseDate(discoveredAt)),
    lastUsed: findLastUsed(appliedIn),
    daysSinceLastUse: daysSince(findLastUsed(appliedIn)),
  };
}
```

### Step 1.3: Generate Health Report

```markdown
## Memory Health Report

**Generated:** [timestamp]
**Last Consolidation:** [date or "Never"]

### Summary Statistics

| Metric            | Value |
| ----------------- | ----- |
| Total memories    | X     |
| Patterns          | Y     |
| Mistakes          | Z     |
| Tech insights     | A     |
| Research cache    | B     |
| Avg age (days)    | C     |
| Avg effectiveness | D%    |

### Health Indicators

| Indicator         | Status  | Details                      |
| ----------------- | ------- | ---------------------------- |
| Memory count      | OK/WARN | X memories (threshold: 200)  |
| Stale memories    | OK/WARN | Y unused >90 days            |
| Low effectiveness | OK/WARN | Z memories <30% effective    |
| Duplicates        | OK/WARN | A potential duplicates       |
| Orphaned          | OK/WARN | B memories with no relations |

### Recommendations

1. [Recommendation based on findings]
2. [Another recommendation]
```

---

## Phase 2: Sensory Filter (Relevance Scoring)

This logic is used by other skills BEFORE saving to memory. Document here for reference.

### Relevance Score Calculation

```javascript
/**
 * Calculate relevance score for a potential memory.
 * Only save to long-term memory if score >= threshold (default: 5)
 */
function calculateRelevance(learning, existingMemories, coreMemory) {
  let score = 0;
  const reasons = [];

  // 1. NOVELTY CHECK (-∞ if duplicate)
  const similar = findSimilarMemories(learning, existingMemories);
  if (similar.length > 0 && similar[0].similarity > 0.85) {
    return { score: 0, reasons: ["Duplicate of existing memory"], save: false };
  }
  if (similar.length > 0 && similar[0].similarity > 0.6) {
    score -= 2;
    reasons.push("Similar memory exists (-2)");
  }

  // 2. GENERALITY - Applies to multiple projects/frameworks?
  if (learning.appliesTo && learning.appliesTo.length > 2) {
    score += 3;
    reasons.push("Broadly applicable (+3)");
  } else if (learning.appliesTo && learning.appliesTo.length > 1) {
    score += 2;
    reasons.push("Applies to multiple contexts (+2)");
  }

  // 3. SEVERITY - How important is this?
  const severityScores = {
    critical: 5,
    high: 3,
    medium: 2,
    low: 1,
  };
  if (learning.severity) {
    score += severityScores[learning.severity] || 1;
    reasons.push(
      `Severity: ${learning.severity} (+${severityScores[learning.severity]})`,
    );
  }

  // 4. SOURCE - How was this learned?
  if (learning.source === "mistake" || learning.source === "failure") {
    score += 2;
    reasons.push("Learned from failure (+2)");
  }
  if (learning.source === "explicit_user_feedback") {
    score += 3;
    reasons.push("User explicitly shared (+3)");
  }

  // 5. ALIGNMENT - Matches core memory patterns?
  if (alignsWithCoreMemory(learning, coreMemory)) {
    score += 1;
    reasons.push("Aligns with existing patterns (+1)");
  }

  // 6. FREQUENCY POTENTIAL - Will encounter often?
  if (learning.frequencyHint === "common") {
    score += 2;
    reasons.push("Common scenario (+2)");
  }

  const threshold = coreMemory.memoryConfig?.relevanceThreshold || 5;

  return {
    score,
    reasons,
    save: score >= threshold,
    threshold,
  };
}

/**
 * Find similar existing memories using text overlap
 */
function findSimilarMemories(learning, existingMemories) {
  const learningText = [
    learning.name,
    learning.summary,
    ...(learning.observations || []),
  ]
    .join(" ")
    .toLowerCase();

  return existingMemories
    .map((memory) => {
      const memoryText = [memory.name, ...(memory.observations || [])]
        .join(" ")
        .toLowerCase();

      return {
        memory,
        similarity: calculateTextSimilarity(learningText, memoryText),
      };
    })
    .filter((m) => m.similarity > 0.3)
    .sort((a, b) => b.similarity - a.similarity);
}
```

### Integration Point

Other skills should call this before saving:

```javascript
// In autonomous-dev, cto, cpo-ai-skill, etc.
async function saveToMemoryWithFilter(learning) {
  const coreMemory = JSON.parse(
    await readFile("~/.claude-setup/memory/core-memory.json"),
  );
  const existingMemories = await mcp__memory__search_nodes({ query: "" });

  const relevance = calculateRelevance(
    learning,
    existingMemories.entities,
    coreMemory,
  );

  if (!relevance.save) {
    console.log(
      `Skipping memory save: score ${relevance.score} < ${relevance.threshold}`,
    );
    console.log(`Reasons: ${relevance.reasons.join(", ")}`);
    return { saved: false, relevance };
  }

  // Add metadata observations for tracking
  const enrichedLearning = {
    ...learning,
    observations: [
      ...(learning.observations || []),
      `Discovered: ${new Date().toISOString().split("T")[0]}`,
      `Relevance score: ${relevance.score}`,
      `Source: ${learning.source || "implementation"}`,
    ],
  };

  await mcp__memory__create_entities({ entities: [enrichedLearning] });

  return { saved: true, relevance };
}
```

---

## Phase 3: Memory Consolidation

### Step 3.1: Identify Consolidation Candidates

**Merge similar patterns:**

```javascript
function findMergeCandidates(memories) {
  const candidates = [];

  for (let i = 0; i < memories.length; i++) {
    for (let j = i + 1; j < memories.length; j++) {
      const similarity = calculateSimilarity(memories[i], memories[j]);

      if (similarity > 0.7 && sameEntityType(memories[i], memories[j])) {
        candidates.push({
          memory1: memories[i],
          memory2: memories[j],
          similarity,
          recommendation: similarity > 0.85 ? "merge" : "review",
        });
      }
    }
  }

  return candidates.sort((a, b) => b.similarity - a.similarity);
}
```

### Step 3.2: Merge Memories

```javascript
async function mergeMemories(memory1, memory2) {
  // Combine observations, deduplicating
  const combinedObservations = [
    ...new Set([...memory1.observations, ...memory2.observations]),
  ];

  // Keep the more descriptive name
  const mergedName =
    memory1.name.length > memory2.name.length ? memory1.name : memory2.name;

  // Calculate combined stats
  const useCount1 = extractUseCount(memory1);
  const useCount2 = extractUseCount(memory2);

  // Add merge note
  combinedObservations.push(
    `Merged from: ${memory1.name}, ${memory2.name} on ${new Date().toISOString().split("T")[0]}`,
  );

  // Delete old memories
  await mcp__memory__delete_entities({
    entityNames: [memory1.name, memory2.name],
  });

  // Create merged memory
  await mcp__memory__create_entities({
    entities: [
      {
        name: mergedName,
        entityType: memory1.entityType,
        observations: combinedObservations,
      },
    ],
  });

  return { merged: mergedName, from: [memory1.name, memory2.name] };
}
```

### Step 3.3: Promote to Core Memory

Patterns with high usage and effectiveness should become stable preferences:

```javascript
async function promoteToCore(memory, coreMemory) {
  const stats = analyzeMemory(memory);

  // Promotion criteria
  const shouldPromote =
    stats.useCount >= 15 &&
    stats.effectiveness >= 0.85 &&
    stats.ageInDays >= 30; // Must be proven over time

  if (!shouldPromote) return false;

  // Determine where in core memory this belongs
  if (memory.entityType === "pattern") {
    coreMemory.stablePatterns[memory.name.replace("pattern:", "")] =
      extractSummary(memory);
  } else if (memory.entityType === "preference") {
    // Parse and add to preferences
    const prefKey = memory.name.replace("preference:", "");
    coreMemory.preferences[prefKey] = extractPreferenceValue(memory);
  }

  // Mark as promoted in observations
  await mcp__memory__add_observations({
    observations: [
      {
        entityName: memory.name,
        contents: [
          `Promoted to core memory: ${new Date().toISOString().split("T")[0]}`,
        ],
      },
    ],
  });

  // Update core memory file
  coreMemory.lastUpdated = new Date().toISOString().split("T")[0];
  await writeFile(
    "~/.claude-setup/memory/core-memory.json",
    JSON.stringify(coreMemory, null, 2),
  );

  return true;
}
```

---

## Phase 4: Selective Forgetting

### Step 4.1: Identify Stale Memories

```javascript
function identifyStaleMemories(memories, coreMemory) {
  const config = coreMemory.memoryConfig || {
    decayThresholdDays: 90,
    minUsesToRetain: 3,
  };

  return memories.filter((memory) => {
    const stats = analyzeMemory(memory);

    // Never forget critical memories
    if (memory.observations?.some((o) => o.includes("critical: true"))) {
      return false;
    }

    // Never forget recently used
    if (stats.daysSinceLastUse < 30) {
      return false;
    }

    // Forget if: old AND rarely used
    const isOld = stats.daysSinceLastUse > config.decayThresholdDays;
    const isRarelyUsed = stats.useCount < config.minUsesToRetain;
    const isIneffective =
      stats.effectiveness !== null && stats.effectiveness < 0.3;

    return isOld && (isRarelyUsed || isIneffective);
  });
}
```

### Step 4.2: Archive Before Forgetting

```javascript
async function archiveMemories(memories) {
  const archiveDir = "~/.claude-setup/memory/archive";
  const archiveFile = `${archiveDir}/${new Date().toISOString().split("T")[0]}-forgotten.json`;

  // Read existing archive or create new
  let archive = [];
  try {
    archive = JSON.parse(await readFile(archiveFile));
  } catch {
    // File doesn't exist yet
  }

  // Add memories to archive
  archive.push(
    ...memories.map((m) => ({
      ...m,
      forgottenAt: new Date().toISOString(),
      reason: "decay",
    })),
  );

  await writeFile(archiveFile, JSON.stringify(archive, null, 2));

  return archiveFile;
}
```

### Step 4.3: Delete Stale Memories

```javascript
async function forgetMemories(memories) {
  // Archive first (safety net)
  const archiveFile = await archiveMemories(memories);

  // Delete from Memory MCP
  const names = memories.map((m) => m.name);

  for (const name of names) {
    await mcp__memory__delete_entities({ entityNames: [name] });
  }

  return {
    forgotten: names.length,
    archived: archiveFile,
  };
}
```

---

## Phase 5: Enhanced Graph Structure

### Step 5.1: Add Relationships

When creating memories, establish relationships:

```javascript
async function createMemoryWithRelations(memory, relatedMemories) {
  // Create the memory
  await mcp__memory__create_entities({ entities: [memory] });

  // Create relationships
  const relations = [];

  for (const related of relatedMemories) {
    relations.push({
      from: memory.name,
      relationType: related.relation, // 'related_to', 'supersedes', 'applies_to', 'derived_from'
      to: related.name,
    });
  }

  if (relations.length > 0) {
    await mcp__memory__create_relations({ relations });
  }

  return { memory, relations };
}
```

### Step 5.2: Standard Relationship Types

| Relation       | Meaning               | Example                                          |
| -------------- | --------------------- | ------------------------------------------------ |
| `related_to`   | Conceptually similar  | pattern:early-returns → pattern:guard-clauses    |
| `supersedes`   | Replaces older memory | pattern:v2 → pattern:v1                          |
| `applies_to`   | Works with technology | pattern:rls → tech-insight:supabase              |
| `derived_from` | Based on another      | mistake:auth-bug → pattern:auth-validation       |
| `competes_in`  | Competitor in market  | competitor:linear → research:task-management     |
| `part_of`      | Component of larger   | design:button-styles → design:dashboard-patterns |

### Step 5.3: Find Orphaned Memories

```javascript
async function findOrphanedMemories(memories) {
  const allRelations = await mcp__memory__open_nodes({
    names: memories.map((m) => m.name),
  });

  const connectedNames = new Set();
  for (const node of allRelations.nodes || []) {
    if (node.relations?.length > 0) {
      connectedNames.add(node.name);
      node.relations.forEach((r) => {
        connectedNames.add(r.to);
        connectedNames.add(r.from);
      });
    }
  }

  return memories.filter((m) => !connectedNames.has(m.name));
}
```

---

## Phase 6: Generate Consolidation Report

### Final Report Template

```markdown
# Memory Consolidation Report

**Date:** [timestamp]
**Previous Consolidation:** [date]
**Duration:** [X minutes]

---

## Summary

| Action                | Count |
| --------------------- | ----- |
| Memories analyzed     | X     |
| Merged                | Y     |
| Promoted to core      | Z     |
| Forgotten (archived)  | A     |
| Relationships created | B     |
| Orphans identified    | C     |

---

## Merges Performed

| Original Memories    | Merged Into      | Similarity |
| -------------------- | ---------------- | ---------- |
| pattern:a, pattern:b | pattern:combined | 87%        |

---

## Promoted to Core Memory

| Memory                | Use Count | Effectiveness | Promoted As                 |
| --------------------- | --------- | ------------- | --------------------------- |
| pattern:early-returns | 23        | 95%           | stablePatterns.earlyReturns |

---

## Forgotten (Archived)

| Memory          | Age (days) | Last Used    | Use Count | Reason          |
| --------------- | ---------- | ------------ | --------- | --------------- |
| mistake:old-api | 180        | 150 days ago | 1         | Decay threshold |

**Archive location:** ~/.claude-setup/memory/archive/2026-01-27-forgotten.json

---

## Orphaned Memories (No Relations)

Consider adding relationships or reviewing:

1. tech-insight:random-thing - No connections, consider relating to patterns
2. competitor:old-company - Market research may be stale

---

## Health After Consolidation

| Metric              | Before | After | Change |
| ------------------- | ------ | ----- | ------ |
| Total memories      | 150    | 142   | -8     |
| Avg effectiveness   | 68%    | 72%   | +4%    |
| Orphaned            | 12     | 8     | -4     |
| Stale (>90d unused) | 15     | 0     | -15    |

---

## Recommendations

1. **Run `/consolidate` again in 7 days** - Memory count healthy
2. **Review orphaned memories** - 8 memories have no relationships
3. **Consider archiving research:** - 3 market research entries >60 days old

---

## Next Consolidation Triggers

- Memory count exceeds 200
- 7 days since last consolidation
- Major project completion
```

---

## Quick Commands

### Consolidation

| Command                      | Action                           |
| ---------------------------- | -------------------------------- |
| `/consolidate`               | Full consolidation cycle         |
| `/consolidate --dry-run`     | Preview changes without applying |
| `/consolidate --health`      | Health report only               |
| `/consolidate --forget-only` | Only run forgetting phase        |
| `/consolidate --merge-only`  | Only run merge phase             |

### Reflection (Metacognition)

| Command               | Action                                           |
| --------------------- | ------------------------------------------------ |
| `/reflect`            | Deep reflection cycle (what worked, what didn't) |
| `/reflect --quick`    | Quick reflection on current session              |
| `/reflect --beliefs`  | Validate core beliefs against evidence           |
| `/reflect --memories` | Show memory effectiveness rankings               |

### Attention

| Command                      | Action                         |
| ---------------------------- | ------------------------------ |
| `/attention`                 | Show current attention weights |
| `/attention --focus [topic]` | Manually set focus topic       |
| `/attention --reset`         | Reset attention weights        |

---

## Automation Hooks

Add to `~/.claude/hooks/post-project.sh`:

```bash
#!/bin/bash
# Run consolidation after project completion

# Check if consolidation needed
MEMORY_COUNT=$(claude --print "How many memories in Memory MCP?" 2>/dev/null | grep -o '[0-9]*')
LAST_CONSOLIDATION=$(jq -r '.lastConsolidation' ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-setup/memory/core-memory.json)

if [ "$MEMORY_COUNT" -gt 200 ] || [ "$LAST_CONSOLIDATION" = "null" ]; then
  echo "Running memory consolidation..."
  claude "/consolidate"
fi
```

---

## Integration with Other Skills

### autonomous-dev

Before saving memories, call sensory filter:

```javascript
// In Step 3.4 after story completion
const relevance = calculateRelevance(learning, existingMemories, coreMemory);
if (relevance.save) {
  await mcp__memory__create_entities({ entities: [learning] });
}
```

### cpo-ai-skill

Research caching uses same relevance logic:

```javascript
// In Phase 1.4 after research completes
const research = { name: 'research:...', entityType: 'market-research', ... };
const { saved } = await saveToMemoryWithFilter(research);
```

### cto

Architecture decisions saved with relationships:

```javascript
// After generating ADR
await createMemoryWithRelations(
  { name: 'architecture:decision-name', ... },
  [{ name: 'tech-insight:related-tech', relation: 'applies_to' }]
);
```

---

---

## Reference Documents

| Document                                              | Purpose                                    |
| ----------------------------------------------------- | ------------------------------------------ |
| [memory-utils.md](references/memory-utils.md)         | Reusable functions for memory operations   |
| [attention-system.md](references/attention-system.md) | Short-term attention and focus tracking    |
| [metacognition.md](references/metacognition.md)       | Self-reflection and effectiveness tracking |

---

---

## Self-Learning System

The memory system now includes automated learning capabilities that extract patterns from sessions and git history.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    LEARNING SOURCES                          │
├─────────────────────────────────────────────────────────────┤
│  Session Hooks          Git History         Existing Memory  │
│  (learning-log.jsonl)   (commits)           (usage tracking) │
└──────────┬────────────────────┬────────────────────┬────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXTRACTORS                                │
├─────────────────────────────────────────────────────────────┤
│  session-analyzer.py    git-pattern-extractor.py             │
│  - Pattern detection    - Commit analysis                    │
│  - Language usage       - Code pattern extraction            │
│  - Success/failure      - Commit type analysis               │
└──────────┬────────────────────┬────────────────────┬────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                 EXTRACTED CANDIDATES                         │
│            ~/...claude-setup/memory/extracted/*.json         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  RELEVANCE FILTER                            │
│  memory-importer.py - Score >= threshold (default: 5)        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   MEMORY MCP                                 │
│  Long-term storage with graph relationships                  │
└─────────────────────────────────────────────────────────────┘
```

### Components

#### 1. Learning Capture Hook (`hooks/learning-capture.sh`)

Captures file changes during sessions:

- Detects patterns in code (early-returns, async, react-hooks, etc.)
- Tracks success/failure of operations
- Identifies project and language
- Writes to `learning-log.jsonl`

#### 2. Session Analyzer (`bin/session-analyzer.py`)

Processes the learning log:

```bash
# Analyze all unprocessed entries
python3 ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-setup/bin/session-analyzer.py

# Preview without saving
python3 session-analyzer.py --dry-run

# Only last 24 hours
python3 session-analyzer.py --last-24h

# Filter by project
python3 session-analyzer.py --project Contably
```

#### 3. Git Pattern Extractor (`bin/git-pattern-extractor.py`)

Learns from git commits:

```bash
# Analyze specific repo
python3 git-pattern-extractor.py /path/to/repo

# Analyze all known projects
python3 git-pattern-extractor.py --all-projects

# Since specific time
python3 git-pattern-extractor.py --since="1 month ago"
```

#### 4. Memory Importer (`bin/memory-importer.py`)

Imports qualified candidates:

```bash
# Import all pending extractions
python3 memory-importer.py

# Lower threshold for more imports
python3 memory-importer.py --threshold 3

# Preview only
python3 memory-importer.py --dry-run
```

#### 5. Auto-Consolidation (`bin/memory-auto-consolidate.sh`)

Orchestrates the full pipeline:

```bash
# Check if consolidation needed
./memory-auto-consolidate.sh --check

# Force consolidation
./memory-auto-consolidate.sh --force

# Normal run (consolidates if needed)
./memory-auto-consolidate.sh
```

### Automated Triggers

#### Weekly Consolidation (launchd)

Install the launchd agent:

```bash
cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-setup/launchd/com.claude.memory-consolidation.plist \
   ~/Library/LaunchAgents/

launchctl load ~/Library/LaunchAgents/com.claude.memory-consolidation.plist
```

Runs every Sunday at 3:00 AM.

#### Threshold-Based Triggers

Consolidation triggers automatically when:

- 7+ days since last consolidation
- 50+ unprocessed learning entries
- Any pending extractions exist

### Learning Flow

1. **During Sessions**
   - `learning-capture.sh` hook logs all Edit/Write operations
   - Patterns detected in code changes
   - Success/failure tracked

2. **Periodically (Manual or Cron)**
   - `session-analyzer.py` processes learning log
   - `git-pattern-extractor.py` analyzes commits
   - Candidates written to `extracted/` directory

3. **Import Phase**
   - `memory-importer.py` filters by relevance
   - Qualified candidates prepared for MCP import
   - Run `/consolidate` in Claude to complete import

4. **Memory Evolution**
   - Usage tracked with "Applied in:" observations
   - Effectiveness measured (HELPFUL/NOT HELPFUL)
   - High-usage patterns promoted to core memory
   - Stale memories archived and forgotten

### File Locations

| File                        | Purpose                             |
| --------------------------- | ----------------------------------- |
| `memory/learning-log.jsonl` | Raw learning entries from sessions  |
| `memory/extracted/*.json`   | Extracted candidates pending import |
| `memory/imported/*.json`    | Successfully imported extractions   |
| `memory/archive/*.json`     | Archived/forgotten memories         |
| `memory/sessions/*.json`    | Session metadata                    |
| `memory/consolidation.log`  | Auto-consolidation log              |

### Manual Workflow

If you prefer manual control:

```bash
# 1. Extract patterns from git (run after coding sessions)
python3 ~/...claude-setup/bin/git-pattern-extractor.py --all-projects

# 2. Analyze session logs
python3 ~/...claude-setup/bin/session-analyzer.py

# 3. Review candidates
cat ~/...claude-setup/memory/extracted/*.json | jq '.candidates[].name'

# 4. Import in Claude session
# Run /consolidate or manually call mcp__memory__create_entities
```

---

## Version History

- **2.0.0** (2026-02-02): Added self-learning system with hooks, analyzers, and automated consolidation
- **1.1.0** (2026-01-27): Added attention system and metacognition
- **1.0.0** (2026-01-27): Initial release with full consolidation, forgetting, and graph support
