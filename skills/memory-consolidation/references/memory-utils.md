# Memory Utility Functions

Reusable functions for memory operations across all skills.

---

## Core Memory Loading

```javascript
/**
 * Load core memory with defaults
 */
async function loadCoreMemory() {
  try {
    const content = await readFile('~/.claude-setup/memory/core-memory.json');
    return JSON.parse(content);
  } catch {
    // Return sensible defaults if not found
    return {
      memoryConfig: {
        relevanceThreshold: 5,
        decayThresholdDays: 90,
        minUsesToRetain: 3
      },
      preferences: {},
      stablePatterns: {},
      beliefs: []
    };
  }
}
```

---

## Sensory Filter (Relevance Scoring)

```javascript
/**
 * Calculate relevance score for a potential memory.
 *
 * @param {Object} learning - The learning to evaluate
 * @param {string} learning.name - Entity name (e.g., "pattern:early-returns")
 * @param {string} learning.summary - Brief description
 * @param {string[]} learning.observations - Detailed observations
 * @param {string[]} learning.appliesTo - Technologies/contexts this applies to
 * @param {string} learning.severity - 'critical' | 'high' | 'medium' | 'low'
 * @param {string} learning.source - 'mistake' | 'success' | 'explicit_user_feedback' | 'implementation'
 * @param {string} learning.frequencyHint - 'common' | 'rare' | 'occasional'
 * @param {Object[]} existingMemories - Current memories from Memory MCP
 * @param {Object} coreMemory - Core memory config
 * @returns {Object} { score, reasons, save, threshold }
 */
function calculateRelevance(learning, existingMemories, coreMemory) {
  let score = 0;
  const reasons = [];

  // 1. NOVELTY CHECK
  const similar = findSimilarMemories(learning, existingMemories);
  if (similar.length > 0 && similar[0].similarity > 0.85) {
    return {
      score: 0,
      reasons: [`Duplicate of: ${similar[0].memory.name}`],
      save: false,
      threshold: coreMemory.memoryConfig?.relevanceThreshold || 5
    };
  }
  if (similar.length > 0 && similar[0].similarity > 0.6) {
    score -= 2;
    reasons.push(`Similar to ${similar[0].memory.name} (-2)`);
  }

  // 2. GENERALITY
  const appliesTo = learning.appliesTo || [];
  if (appliesTo.length > 2) {
    score += 3;
    reasons.push(`Broadly applicable: ${appliesTo.join(', ')} (+3)`);
  } else if (appliesTo.length > 1) {
    score += 2;
    reasons.push(`Multiple contexts: ${appliesTo.join(', ')} (+2)`);
  }

  // 3. SEVERITY
  const severityScores = { critical: 5, high: 3, medium: 2, low: 1 };
  if (learning.severity && severityScores[learning.severity]) {
    score += severityScores[learning.severity];
    reasons.push(`Severity ${learning.severity} (+${severityScores[learning.severity]})`);
  }

  // 4. SOURCE
  if (learning.source === 'mistake' || learning.source === 'failure') {
    score += 2;
    reasons.push("Learned from failure (+2)");
  }
  if (learning.source === 'explicit_user_feedback') {
    score += 3;
    reasons.push("User explicitly shared (+3)");
  }

  // 5. FREQUENCY POTENTIAL
  if (learning.frequencyHint === 'common') {
    score += 2;
    reasons.push("Common scenario (+2)");
  }

  const threshold = coreMemory.memoryConfig?.relevanceThreshold || 5;

  return {
    score,
    reasons,
    save: score >= threshold,
    threshold
  };
}

/**
 * Find similar existing memories using keyword overlap
 */
function findSimilarMemories(learning, existingMemories) {
  const learningWords = extractKeywords(
    [learning.name, learning.summary, ...(learning.observations || [])].join(' ')
  );

  return existingMemories
    .map(memory => {
      const memoryWords = extractKeywords(
        [memory.name, ...(memory.observations || [])].join(' ')
      );

      const intersection = learningWords.filter(w => memoryWords.includes(w));
      const union = [...new Set([...learningWords, ...memoryWords])];
      const similarity = intersection.length / union.length;

      return { memory, similarity };
    })
    .filter(m => m.similarity > 0.3)
    .sort((a, b) => b.similarity - a.similarity);
}

/**
 * Extract meaningful keywords from text
 */
function extractKeywords(text) {
  const stopWords = new Set([
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'must', 'shall', 'can', 'to', 'of', 'in',
    'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through',
    'during', 'before', 'after', 'above', 'below', 'between', 'under',
    'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where',
    'why', 'how', 'all', 'each', 'few', 'more', 'most', 'other', 'some',
    'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than',
    'too', 'very', 'just', 'and', 'but', 'if', 'or', 'because', 'until',
    'while', 'this', 'that', 'these', 'those', 'it', 'its'
  ]);

  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter(word => word.length > 2 && !stopWords.has(word));
}
```

---

## Memory Statistics

```javascript
/**
 * Analyze a memory entity for statistics
 */
function analyzeMemory(entity) {
  const observations = entity.observations || [];

  // Extract dates
  const discoveredObs = observations.find(o =>
    o.match(/^(Discovered|Researched|Created):/i)
  );
  const discoveredAt = discoveredObs
    ? parseDate(discoveredObs.split(':')[1]?.trim())
    : null;

  // Extract usage
  const appliedIn = observations.filter(o => o.startsWith('Applied in'));
  const helpfulCount = appliedIn.filter(o => o.includes('HELPFUL')).length;
  const notHelpfulCount = appliedIn.filter(o => o.includes('NOT HELPFUL')).length;

  // Find last use
  const lastUsedObs = observations.find(o => o.startsWith('Last used:'));
  const lastUsed = lastUsedObs
    ? parseDate(lastUsedObs.split(':')[1]?.trim())
    : (appliedIn.length > 0 ? extractDateFromApplied(appliedIn[appliedIn.length - 1]) : null);

  return {
    name: entity.name,
    type: entity.entityType,
    observationCount: observations.length,
    discoveredAt,
    useCount: appliedIn.length,
    helpfulCount,
    notHelpfulCount,
    effectiveness: appliedIn.length > 0 ? helpfulCount / appliedIn.length : null,
    ageInDays: discoveredAt ? daysSince(discoveredAt) : null,
    lastUsed,
    daysSinceLastUse: lastUsed ? daysSince(lastUsed) : null,
    isCritical: observations.some(o => o.includes('critical: true')),
    isPromoted: observations.some(o => o.includes('Promoted to core'))
  };
}

/**
 * Calculate days since a date
 */
function daysSince(date) {
  if (!date) return Infinity;
  const d = typeof date === 'string' ? new Date(date) : date;
  const now = new Date();
  return Math.floor((now - d) / (1000 * 60 * 60 * 24));
}

/**
 * Parse various date formats
 */
function parseDate(dateStr) {
  if (!dateStr) return null;

  // Try ISO format
  let d = new Date(dateStr.trim());
  if (!isNaN(d)) return d;

  // Try YYYY-MM-DD
  const match = dateStr.match(/(\d{4})-(\d{2})-(\d{2})/);
  if (match) {
    return new Date(parseInt(match[1]), parseInt(match[2]) - 1, parseInt(match[3]));
  }

  return null;
}
```

---

## Memory CRUD with Tracking

```javascript
/**
 * Save memory with relevance filter and tracking metadata
 */
async function saveToMemoryWithFilter(learning) {
  const coreMemory = await loadCoreMemory();
  const existing = await mcp__memory__search_nodes({ query: "" });

  const relevance = calculateRelevance(learning, existing.entities || [], coreMemory);

  if (!relevance.save) {
    console.log(`⊘ Memory filtered: score ${relevance.score} < ${relevance.threshold}`);
    relevance.reasons.forEach(r => console.log(`  - ${r}`));
    return { saved: false, relevance };
  }

  // Enrich with tracking metadata
  const enrichedLearning = {
    name: learning.name,
    entityType: learning.entityType || inferEntityType(learning.name),
    observations: [
      ...(learning.observations || []),
      `Discovered: ${new Date().toISOString().split('T')[0]}`,
      `Relevance score: ${relevance.score}`,
      `Source: ${learning.source || 'implementation'}`,
      learning.appliesTo ? `Applies to: ${learning.appliesTo.join(', ')}` : null
    ].filter(Boolean)
  };

  await mcp__memory__create_entities({ entities: [enrichedLearning] });

  console.log(`✓ Memory saved: ${learning.name} (score: ${relevance.score})`);
  return { saved: true, relevance };
}

/**
 * Track memory usage (call when a memory is applied)
 */
async function trackMemoryUsage(memoryName, context, wasHelpful) {
  await mcp__memory__add_observations({
    observations: [{
      entityName: memoryName,
      contents: [
        `Applied in ${context.storyId || context.project}: ${wasHelpful ? 'HELPFUL' : 'NOT HELPFUL'}`,
        `Context: ${context.description || context.title}`,
        `Last used: ${new Date().toISOString().split('T')[0]}`
      ]
    }]
  });
}

/**
 * Infer entity type from name prefix
 */
function inferEntityType(name) {
  const prefix = name.split(':')[0];
  const typeMap = {
    'pattern': 'pattern',
    'mistake': 'mistake',
    'preference': 'preference',
    'tech-insight': 'tech-insight',
    'architecture': 'architecture-decision',
    'research': 'market-research',
    'competitor': 'competitor-profile',
    'design': 'design-pattern',
    'stack': 'tech-stack-recommendation',
    'security': 'security-insight'
  };
  return typeMap[prefix] || 'general';
}
```

---

## Graph Relationships

```javascript
/**
 * Create memory with relationships
 */
async function createMemoryWithRelations(memory, relations) {
  // Create the memory first
  await mcp__memory__create_entities({ entities: [memory] });

  if (relations && relations.length > 0) {
    await mcp__memory__create_relations({
      relations: relations.map(r => ({
        from: memory.name,
        relationType: r.relation,
        to: r.target
      }))
    });
  }

  return { memory: memory.name, relationCount: relations?.length || 0 };
}

/**
 * Find related memories via graph traversal
 */
async function findRelatedMemories(memoryName, maxDepth = 2) {
  const visited = new Set();
  const related = [];

  async function traverse(name, depth) {
    if (depth > maxDepth || visited.has(name)) return;
    visited.add(name);

    const nodes = await mcp__memory__open_nodes({ names: [name] });
    const node = nodes.nodes?.[0];

    if (node?.relations) {
      for (const rel of node.relations) {
        const targetName = rel.to === name ? rel.from : rel.to;
        if (!visited.has(targetName)) {
          related.push({
            name: targetName,
            relation: rel.relationType,
            depth
          });
          await traverse(targetName, depth + 1);
        }
      }
    }
  }

  await traverse(memoryName, 1);
  return related;
}

/**
 * Standard relationship types
 */
const RELATION_TYPES = {
  RELATED_TO: 'related_to',       // Conceptually similar
  SUPERSEDES: 'supersedes',       // Replaces older memory
  APPLIES_TO: 'applies_to',       // Works with technology
  DERIVED_FROM: 'derived_from',   // Based on another
  COMPETES_IN: 'competes_in',     // Competitor in market
  PART_OF: 'part_of'              // Component of larger
};
```

---

## Decay and Forgetting

```javascript
/**
 * Identify memories that should be forgotten
 */
function identifyStaleMemories(memories, coreMemory) {
  const config = coreMemory.memoryConfig || {
    decayThresholdDays: 90,
    minUsesToRetain: 3
  };

  return memories.filter(memory => {
    const stats = analyzeMemory(memory);

    // Never forget critical or promoted
    if (stats.isCritical || stats.isPromoted) return false;

    // Never forget recently used
    if (stats.daysSinceLastUse !== null && stats.daysSinceLastUse < 30) return false;

    // Forget if old AND (rarely used OR ineffective)
    const isOld = (stats.daysSinceLastUse || stats.ageInDays || 0) > config.decayThresholdDays;
    const isRarelyUsed = stats.useCount < config.minUsesToRetain;
    const isIneffective = stats.effectiveness !== null && stats.effectiveness < 0.3;

    return isOld && (isRarelyUsed || isIneffective);
  });
}

/**
 * Archive memories before forgetting
 */
async function archiveAndForget(memories) {
  if (memories.length === 0) return { forgotten: 0 };

  const archiveDir = '~/.claude-setup/memory/archive';
  const archiveFile = `${archiveDir}/${new Date().toISOString().split('T')[0]}-forgotten.json`;

  // Create archive directory if needed
  await Bash({ command: `mkdir -p "${archiveDir.replace('~', process.env.HOME)}"` });

  // Read existing or create new archive
  let archive = [];
  try {
    const existing = await readFile(archiveFile);
    archive = JSON.parse(existing);
  } catch {
    // New file
  }

  // Add to archive with metadata
  archive.push(...memories.map(m => ({
    ...m,
    forgottenAt: new Date().toISOString(),
    reason: 'decay'
  })));

  await writeFile(archiveFile, JSON.stringify(archive, null, 2));

  // Delete from Memory MCP
  for (const m of memories) {
    await mcp__memory__delete_entities({ entityNames: [m.name] });
  }

  return {
    forgotten: memories.length,
    archived: archiveFile,
    names: memories.map(m => m.name)
  };
}
```

---

## Usage Examples

### In autonomous-dev (after story completion)

```javascript
// Step 3.4: After successful story
if (storyPassed && learningDiscovered) {
  const learning = {
    name: `pattern:${kebabCase(learningTitle)}`,
    summary: learningSummary,
    observations: [learningDetails],
    appliesTo: [detectedStack],
    severity: 'medium',
    source: 'implementation'
  };

  const { saved, relevance } = await saveToMemoryWithFilter(learning);

  if (saved) {
    // Also create relationships
    await createMemoryWithRelations(learning, [
      { target: `tech-insight:${detectedStack}`, relation: 'applies_to' }
    ]);
  }
}
```

### In cto (after architecture decision)

```javascript
// After creating ADR
const decision = {
  name: `architecture:${decisionName}`,
  observations: [context, decision, consequences],
  appliesTo: ['all-projects'],
  severity: 'high',
  source: 'explicit_user_feedback'
};

await saveToMemoryWithFilter(decision);
await createMemoryWithRelations(decision, [
  { target: `tech-insight:${relatedTech}`, relation: 'applies_to' },
  { target: `pattern:${relatedPattern}`, relation: 'derived_from' }
]);
```

### Track usage when memory helps

```javascript
// When applying a memory during implementation
const relevantPattern = await mcp__memory__search_nodes({ query: "early-returns" });

// After story completes
await trackMemoryUsage(
  relevantPattern.entities[0].name,
  { storyId: 'US-005', title: 'Refactor validation logic' },
  true // wasHelpful
);
```
