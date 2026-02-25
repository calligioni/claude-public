# Metacognition System (Self-Reflection)

> "That's where intelligence begins: not in retrieval, but in reflection."
> — Manthan Gupta

Metacognition is the ability to **think about thinking** — to reflect on which memories helped, which didn't, and what to learn from that. This transforms memory from passive storage into an active part of reasoning.

---

## Concept

```
┌─────────────────────────────────────────────────────────────────┐
│                    METACOGNITION LOOP                            │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  APPLY   │───►│  TRACK   │───►│ REFLECT  │───►│  LEARN   │  │
│  │  memory  │    │ outcome  │    │ on what  │    │ & update │  │
│  │          │    │          │    │ worked   │    │ memory   │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       │                                                │        │
│       └────────────────────────────────────────────────┘        │
│                     feedback loop                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Memory Effectiveness Tracking

### Data Model

Each memory tracks its application history:

```javascript
// Observations added to memory entities
const memoryObservations = [
  // ... original observations ...
  "Applied in US-005: HELPFUL",
  "Context: Implementing JWT authentication",
  "Applied in US-012: NOT HELPFUL",
  "Context: Setting up database schema (irrelevant)",
  "Applied in US-018: HELPFUL",
  "Context: Adding session management",
  "Last used: 2026-01-27",
  "Effectiveness: 66% (2/3 helpful)"
];
```

### Track Application

```javascript
/**
 * Track when a memory is applied during implementation
 * Call this when you consciously use a memory to guide work
 */
async function trackMemoryApplication(memoryName, storyId, context) {
  // Log in session context
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );

  sessionContext.memoryApplicationLog.applications.push({
    memoryName,
    storyId,
    appliedAt: new Date().toISOString(),
    context,
    helpful: null  // Filled in after story completion
  });

  await writeFile('~/.claude-setup/memory/session-context.json',
    JSON.stringify(sessionContext, null, 2));
}
```

### Evaluate Helpfulness

```javascript
/**
 * After story completion, evaluate if applied memories were helpful
 */
async function evaluateMemoryHelpfulness(storyId, storyOutcome) {
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );

  // Find all memories applied to this story
  const applicationsForStory = sessionContext.memoryApplicationLog.applications
    .filter(a => a.storyId === storyId && a.helpful === null);

  for (const application of applicationsForStory) {
    // Determine helpfulness based on outcome
    const wasHelpful = determineHelpfulness(application, storyOutcome);

    // Update session log
    application.helpful = wasHelpful;

    // Update memory in Memory MCP
    await mcp__memory__add_observations({
      observations: [{
        entityName: application.memoryName,
        contents: [
          `Applied in ${storyId}: ${wasHelpful ? 'HELPFUL' : 'NOT HELPFUL'}`,
          `Context: ${application.context}`,
          `Last used: ${new Date().toISOString().split('T')[0]}`
        ]
      }]
    });

    console.log(`Memory ${application.memoryName}: ${wasHelpful ? '✓' : '✗'} helpful`);
  }

  await writeFile('~/.claude-setup/memory/session-context.json',
    JSON.stringify(sessionContext, null, 2));
}

/**
 * Determine if a memory application was helpful based on story outcome
 */
function determineHelpfulness(application, storyOutcome) {
  // Helpful if:
  // - Story passed on first attempt
  // - Memory's pattern was followed in final code
  // - No rollback of memory-guided changes

  if (!storyOutcome.passed) {
    // Story failed - check if memory was related to failure
    if (storyOutcome.failureReason?.includes(application.context)) {
      return false;  // Memory may have contributed to failure
    }
    // Inconclusive - don't mark either way
    return null;
  }

  // Story passed
  if (storyOutcome.attempts === 1) {
    return true;  // First-attempt pass = memory helped
  }

  // Multiple attempts - check if memory context survived
  if (storyOutcome.finalNotes?.includes(application.context.split(' ')[0])) {
    return true;  // Pattern was used in final solution
  }

  return null;  // Inconclusive
}
```

---

## Reflection Cycles

### Post-Story Reflection (Automatic)

After each story completion, brief reflection:

```javascript
/**
 * Quick reflection after story completion
 */
async function postStoryReflection(story, outcome) {
  console.log(`\n--- Reflection: ${story.id} ---`);

  // 1. What memories were applied?
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );
  const applied = sessionContext.memoryApplicationLog.applications
    .filter(a => a.storyId === story.id);

  console.log(`Memories applied: ${applied.length}`);
  applied.forEach(a => {
    console.log(`  - ${a.memoryName}: ${a.helpful === true ? '✓' : a.helpful === false ? '✗' : '?'}`);
  });

  // 2. Any new learning worth saving?
  if (outcome.passed && outcome.notes) {
    const potentialLearning = extractLearningFromNotes(outcome.notes);
    if (potentialLearning) {
      console.log(`Potential learning detected: ${potentialLearning.summary}`);
      // This goes through the sensory filter before saving
    }
  }

  // 3. Update memory effectiveness
  await evaluateMemoryHelpfulness(story.id, outcome);
}
```

### Periodic Deep Reflection (Every 10 Stories)

```javascript
/**
 * Deep reflection cycle - run every 10 stories or on demand
 */
async function deepReflectionCycle() {
  console.log('\n========== METACOGNITION: Deep Reflection ==========\n');

  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );
  const coreMemory = JSON.parse(
    await readFile('~/.claude-setup/memory/core-memory.json')
  );

  // 1. WHAT WORKED? (High-value memories)
  console.log('## What Worked Well\n');
  const highValueMemories = await findHighValueMemories();
  if (highValueMemories.length > 0) {
    console.log('These memories consistently helped:');
    highValueMemories.forEach(m => {
      console.log(`  ✓ ${m.name} (${m.effectiveness}% effective, ${m.useCount} uses)`);
    });

    // Consider promotion to core memory
    for (const m of highValueMemories) {
      if (m.useCount >= 15 && m.effectiveness >= 85) {
        console.log(`  → Candidate for core memory: ${m.name}`);
      }
    }
  } else {
    console.log('  No standout high-value memories yet.');
  }

  // 2. WHAT DIDN'T WORK? (Low-value memories)
  console.log('\n## What Didn\'t Work\n');
  const lowValueMemories = await findLowValueMemories();
  if (lowValueMemories.length > 0) {
    console.log('These memories were often unhelpful:');
    lowValueMemories.forEach(m => {
      console.log(`  ✗ ${m.name} (${m.effectiveness}% effective, ${m.useCount} uses)`);
    });

    console.log('\nOptions:');
    console.log('  1. Update these memories with better guidance');
    console.log('  2. Mark for deletion in next consolidation');
    console.log('  3. Investigate why they\'re not helping');
  } else {
    console.log('  No consistently unhelpful memories found.');
  }

  // 3. WHAT DID WE LEARN THAT WE DIDN'T SAVE?
  console.log('\n## Unsaved Learnings\n');
  const recentLearnings = extractUnsavedLearnings(sessionContext);
  if (recentLearnings.length > 0) {
    console.log('Learnings from this session not yet saved:');
    recentLearnings.forEach(l => {
      console.log(`  ? ${l.summary}`);
      console.log(`    Source: ${l.source}`);
    });
    console.log('\nConsider saving these with sensory filter.');
  } else {
    console.log('  All significant learnings appear to be captured.');
  }

  // 4. BELIEF VALIDATION
  console.log('\n## Core Belief Validation\n');
  const beliefValidation = await validateCoreBeliefs(coreMemory.beliefs);
  beliefValidation.forEach(b => {
    const status = b.supported ? '✓' : b.contradicted ? '✗' : '?';
    console.log(`  ${status} "${b.belief}"`);
    if (b.evidence) {
      console.log(`    Evidence: ${b.evidence}`);
    }
  });

  // 5. SUMMARY STATISTICS
  console.log('\n## Session Statistics\n');
  const stats = calculateSessionStats(sessionContext);
  console.log(`  Stories completed: ${stats.storiesCompleted}`);
  console.log(`  Memories applied: ${stats.memoriesApplied}`);
  console.log(`  Helpful rate: ${stats.helpfulRate}%`);
  console.log(`  New learnings saved: ${stats.newLearningsSaved}`);
  console.log(`  Focus topics: ${stats.focusTopics.join(', ')}`);

  console.log('\n========== End Reflection ==========\n');

  return {
    highValueMemories,
    lowValueMemories,
    recentLearnings,
    beliefValidation,
    stats
  };
}
```

---

## Helper Functions

### Find High/Low Value Memories

```javascript
/**
 * Find memories with high effectiveness (worth promoting)
 */
async function findHighValueMemories() {
  const allMemories = await mcp__memory__search_nodes({ query: "" });

  return (allMemories.entities || [])
    .map(m => {
      const stats = analyzeMemoryEffectiveness(m);
      return { ...m, ...stats };
    })
    .filter(m => m.useCount >= 5 && m.effectiveness >= 70)
    .sort((a, b) => b.effectiveness - a.effectiveness)
    .slice(0, 10);
}

/**
 * Find memories with low effectiveness (candidates for review/deletion)
 */
async function findLowValueMemories() {
  const allMemories = await mcp__memory__search_nodes({ query: "" });

  return (allMemories.entities || [])
    .map(m => {
      const stats = analyzeMemoryEffectiveness(m);
      return { ...m, ...stats };
    })
    .filter(m => m.useCount >= 3 && m.effectiveness < 40)
    .sort((a, b) => a.effectiveness - b.effectiveness)
    .slice(0, 10);
}

/**
 * Analyze effectiveness from memory observations
 */
function analyzeMemoryEffectiveness(memory) {
  const observations = memory.observations || [];

  const applications = observations.filter(o => o.startsWith('Applied in'));
  const helpful = applications.filter(o => o.includes('HELPFUL')).length;
  const notHelpful = applications.filter(o => o.includes('NOT HELPFUL')).length;
  const total = helpful + notHelpful;

  return {
    useCount: applications.length,
    helpfulCount: helpful,
    notHelpfulCount: notHelpful,
    effectiveness: total > 0 ? Math.round((helpful / total) * 100) : null
  };
}
```

### Validate Core Beliefs

```javascript
/**
 * Check if core beliefs are supported or contradicted by memory evidence
 */
async function validateCoreBeliefs(beliefs) {
  const results = [];

  for (const belief of beliefs) {
    const validation = {
      belief,
      supported: false,
      contradicted: false,
      evidence: null
    };

    // Search for evidence in memories
    const keywords = belief.toLowerCase().split(' ')
      .filter(w => w.length > 4)
      .slice(0, 3);

    for (const keyword of keywords) {
      const memories = await mcp__memory__search_nodes({ query: keyword });

      for (const memory of memories.entities || []) {
        // Check if memory supports or contradicts belief
        const relevance = checkBeliefRelevance(belief, memory);
        if (relevance.supports) {
          validation.supported = true;
          validation.evidence = `${memory.name}: ${relevance.reason}`;
          break;
        }
        if (relevance.contradicts) {
          validation.contradicted = true;
          validation.evidence = `${memory.name}: ${relevance.reason}`;
          break;
        }
      }

      if (validation.supported || validation.contradicted) break;
    }

    results.push(validation);
  }

  return results;
}

/**
 * Check if a memory supports or contradicts a belief
 */
function checkBeliefRelevance(belief, memory) {
  const beliefLower = belief.toLowerCase();
  const memoryText = (memory.observations || []).join(' ').toLowerCase();

  // Example: belief "Simple solutions are better than clever ones"
  if (beliefLower.includes('simple')) {
    if (memoryText.includes('simple') && memoryText.includes('helpful')) {
      return { supports: true, reason: 'Simple approach was helpful' };
    }
    if (memoryText.includes('complex') && memoryText.includes('helpful')) {
      return { contradicts: true, reason: 'Complex approach was helpful' };
    }
  }

  return { supports: false, contradicts: false };
}
```

### Extract Unsaved Learnings

```javascript
/**
 * Find learnings from recent work that weren't saved to memory
 */
function extractUnsavedLearnings(sessionContext) {
  const learnings = [];

  // Check key decisions that might be worth saving
  const keyDecisions = sessionContext.currentFocus.keyDecisions || [];
  for (const decision of keyDecisions) {
    if (isPotentialLearning(decision)) {
      learnings.push({
        summary: decision,
        source: 'key decision',
        context: sessionContext.currentFocus.topic
      });
    }
  }

  // Check recent context outcomes
  for (const entry of sessionContext.recentContext.entries || []) {
    if (entry.outcome && isPotentialLearning(entry.outcome)) {
      learnings.push({
        summary: entry.outcome,
        source: `completed ${entry.topic}`,
        context: entry.topic
      });
    }
  }

  return learnings;
}

/**
 * Heuristic: is this statement a potential learning worth saving?
 */
function isPotentialLearning(text) {
  const learningIndicators = [
    /discovered that/i,
    /learned that/i,
    /turns out/i,
    /important to/i,
    /must always/i,
    /never do/i,
    /better to/i,
    /instead of/i,
    /gotcha:/i,
    /tip:/i,
    /pattern:/i
  ];

  return learningIndicators.some(pattern => pattern.test(text));
}
```

---

## Integration with autonomous-dev

### Step 3.4 Enhancement: Post-Story Reflection

```javascript
// After verification passes in Step 3.4

// 1. Run quick reflection
await postStoryReflection(currentStory, {
  passed: true,
  attempts: story.attempts,
  notes: story.notes,
  failureReason: null
});

// 2. Check if deep reflection needed
const completedCount = prd.userStories.filter(s => s.passes).length;
if (completedCount % 10 === 0) {
  console.log('\n🧠 Triggering deep reflection (every 10 stories)...\n');
  await deepReflectionCycle();
}

// 3. Extract and potentially save learnings
if (story.notes) {
  const learning = extractLearningFromNotes(story.notes);
  if (learning) {
    const { saved } = await saveToMemoryWithFilter({
      name: `pattern:${kebabCase(learning.title)}`,
      observations: [learning.detail],
      appliesTo: [detectStack()],
      severity: 'medium',
      source: 'implementation'
    });

    if (saved) {
      console.log(`✓ New learning saved: ${learning.title}`);
    }
  }
}
```

---

## Commands

| Command | Action |
|---------|--------|
| `/reflect` | Trigger deep reflection cycle |
| `/reflect --quick` | Quick reflection on current session |
| `/reflect --beliefs` | Validate core beliefs against evidence |
| `/reflect --memories` | Show memory effectiveness rankings |

---

## Reflection Triggers

Automatic triggers for reflection:

| Trigger | Action |
|---------|--------|
| Every 10 stories completed | Deep reflection cycle |
| End of session | Session summary and unsaved learnings |
| Memory consolidation | Include reflection metrics |
| Story failure after using memory | Flag memory for review |
| First use of core belief | Log for belief validation |

---

## Metrics Dashboard

After reflection, generate metrics:

```markdown
## Metacognition Metrics

### Memory Effectiveness
| Category | Count | Avg Effectiveness |
|----------|-------|-------------------|
| Patterns | 15 | 72% |
| Mistakes | 8 | 85% |
| Tech Insights | 12 | 68% |
| Preferences | 5 | 90% |

### Top 5 Most Helpful Memories
1. pattern:early-returns (95%, 23 uses)
2. mistake:env-in-repo (90%, 12 uses)
3. tech-insight:supabase-rls (88%, 15 uses)
4. pattern:guard-clauses (85%, 18 uses)
5. preference:pnpm (82%, 30 uses)

### Needs Review (Low Effectiveness)
1. pattern:complex-validation (25%, 8 uses) ⚠️
2. tech-insight:old-api-pattern (30%, 5 uses) ⚠️

### Core Beliefs Status
- ✓ "Simple solutions are better" - Supported by 12 memories
- ? "Delete code rather than comment" - No evidence yet
- ✓ "Tests should verify behavior" - Supported by 5 memories

### Session Impact
- Memories influenced 8/12 stories
- First-attempt pass rate: 75%
- Memories contributed to 2 failures (flagged for review)
```
