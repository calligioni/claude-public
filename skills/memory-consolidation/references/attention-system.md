# Attention System (Short-term Memory)

Human working memory maintains **focus** and **relevance** - not everything is equally accessible at all times. This system implements attention-weighted memory retrieval.

---

## Concept

```
┌─────────────────────────────────────────────────────────────────┐
│                    ATTENTION MECHANISM                           │
│                                                                  │
│   Current Focus: "authentication"                                │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  Attention Weights (topic → relevance)                    │  │
│   │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │  │
│   │  authentication ████████████████████████████████ 0.95    │  │
│   │  security       ██████████████████████          0.70    │  │
│   │  database       ████████████                    0.40    │  │
│   │  ui-components  ██████                          0.20    │  │
│   │  deployment     ███                             0.10    │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│   Memory Query: "JWT patterns"                                   │
│   → Boosted by authentication weight (0.95)                      │
│   → Related security memories also surfaced (0.70)               │
│   → Unrelated UI memories suppressed                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Session Context File

**Location:** `~/.claude-setup/memory/session-context.json`

```json
{
  "currentSession": {
    "startedAt": "2026-01-27T10:00:00Z",
    "project": "contably",
    "workingDirectory": "/Volumes/AI/Code/contably"
  },

  "currentFocus": {
    "topic": "authentication",
    "since": "2026-01-27T10:15:00Z",
    "relatedFiles": ["src/auth/*", "lib/session.ts", "middleware.ts"],
    "keyDecisions": [
      "Using Supabase Auth with RLS",
      "Session stored in httpOnly cookie"
    ],
    "memoriesApplied": ["pattern:supabase-rls", "tech-insight:session-management"]
  },

  "attentionWeights": {
    "weights": {
      "authentication": 0.95,
      "security": 0.70,
      "supabase": 0.60,
      "database": 0.40,
      "api": 0.30,
      "ui-components": 0.10
    }
  },

  "recentContext": {
    "entries": [
      {
        "topic": "database-schema",
        "duration": "45min",
        "outcome": "completed users and accounts tables",
        "timestamp": "2026-01-27T09:30:00Z"
      },
      {
        "topic": "authentication",
        "duration": "ongoing",
        "outcome": null,
        "timestamp": "2026-01-27T10:15:00Z"
      }
    ]
  },

  "memoryApplicationLog": {
    "applications": [
      {
        "memoryName": "pattern:supabase-rls",
        "appliedAt": "2026-01-27T10:20:00Z",
        "context": "Setting up row-level security for users table",
        "helpful": null
      }
    ]
  }
}
```

---

## Attention Weight Calculation

### When Topic Changes

```javascript
/**
 * Update attention weights when focus shifts to a new topic
 */
function updateAttentionWeights(newTopic, sessionContext) {
  const weights = sessionContext.attentionWeights.weights;
  const DECAY_RATE = 0.7;  // Previous topics decay by 30%
  const BOOST_AMOUNT = 0.95;  // New topic gets near-full attention

  // Decay all existing weights
  for (const topic in weights) {
    weights[topic] = Math.max(0.05, weights[topic] * DECAY_RATE);
  }

  // Boost new topic
  weights[newTopic] = BOOST_AMOUNT;

  // Boost related topics
  const relatedTopics = findRelatedTopics(newTopic);
  for (const related of relatedTopics) {
    weights[related.topic] = Math.min(1.0, (weights[related.topic] || 0) + related.boost);
  }

  return weights;
}

/**
 * Find topics related to the current focus
 */
function findRelatedTopics(topic) {
  const relationships = {
    'authentication': [
      { topic: 'security', boost: 0.3 },
      { topic: 'session', boost: 0.25 },
      { topic: 'middleware', boost: 0.2 },
      { topic: 'cookies', boost: 0.15 }
    ],
    'database': [
      { topic: 'schema', boost: 0.3 },
      { topic: 'migrations', boost: 0.25 },
      { topic: 'queries', boost: 0.2 },
      { topic: 'supabase', boost: 0.15 }
    ],
    'api': [
      { topic: 'endpoints', boost: 0.3 },
      { topic: 'validation', boost: 0.2 },
      { topic: 'authentication', boost: 0.15 }
    ],
    'frontend': [
      { topic: 'components', boost: 0.3 },
      { topic: 'styling', boost: 0.2 },
      { topic: 'state', boost: 0.15 }
    ],
    'deployment': [
      { topic: 'devops', boost: 0.3 },
      { topic: 'environment', boost: 0.25 },
      { topic: 'railway', boost: 0.2 }
    ]
  };

  return relationships[topic] || [];
}
```

### Continuous Decay

```javascript
/**
 * Apply time-based decay to attention weights
 * Call periodically (e.g., every 10 minutes of active work)
 */
function applyTimeDecay(sessionContext) {
  const weights = sessionContext.attentionWeights.weights;
  const currentTopic = sessionContext.currentFocus.topic;
  const PASSIVE_DECAY = 0.95;  // 5% decay over time

  for (const topic in weights) {
    if (topic !== currentTopic) {
      weights[topic] = Math.max(0.05, weights[topic] * PASSIVE_DECAY);
    }
  }

  return weights;
}
```

---

## Attention-Weighted Memory Retrieval

### Query with Attention

```javascript
/**
 * Query memories with attention weighting
 */
async function queryMemoriesWithAttention(query, sessionContext) {
  const weights = sessionContext.attentionWeights.weights;

  // Get all potentially relevant memories
  const allMemories = await mcp__memory__search_nodes({ query });

  if (!allMemories.entities || allMemories.entities.length === 0) {
    return [];
  }

  // Score and rank by attention relevance
  const scored = allMemories.entities.map(memory => {
    const baseRelevance = calculateQueryRelevance(memory, query);
    const attentionBoost = calculateAttentionBoost(memory, weights);

    return {
      memory,
      baseRelevance,
      attentionBoost,
      finalScore: baseRelevance * (1 + attentionBoost)
    };
  });

  // Sort by final score
  scored.sort((a, b) => b.finalScore - a.finalScore);

  // Return top results with scores
  return scored.slice(0, 10).map(s => ({
    ...s.memory,
    _relevanceScore: s.finalScore,
    _attentionBoost: s.attentionBoost
  }));
}

/**
 * Calculate attention boost based on memory's topics matching attention weights
 */
function calculateAttentionBoost(memory, weights) {
  let boost = 0;

  // Extract topics from memory
  const memoryTopics = extractTopicsFromMemory(memory);

  for (const topic of memoryTopics) {
    const weight = weights[topic] || 0;
    boost += weight * 0.5;  // Each matching topic adds up to 0.5 boost
  }

  return Math.min(1.0, boost);  // Cap at 1.0
}

/**
 * Extract topics from a memory entity
 */
function extractTopicsFromMemory(memory) {
  const topics = new Set();

  // From name prefix
  const prefix = memory.name.split(':')[0];
  topics.add(prefix);

  // From "Applies to" observations
  const appliesToObs = memory.observations?.find(o => o.startsWith('Applies to:'));
  if (appliesToObs) {
    const appliesTo = appliesToObs.replace('Applies to:', '').trim().split(',');
    appliesTo.forEach(t => topics.add(t.trim().toLowerCase()));
  }

  // From keywords in observations
  const keywords = ['authentication', 'database', 'api', 'frontend', 'deployment',
                    'security', 'testing', 'supabase', 'nextjs', 'react'];
  for (const obs of memory.observations || []) {
    for (const kw of keywords) {
      if (obs.toLowerCase().includes(kw)) {
        topics.add(kw);
      }
    }
  }

  return [...topics];
}
```

---

## Session Management

### Start Session

```javascript
/**
 * Initialize session context when starting work
 */
async function startSession(project, workingDirectory) {
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );

  sessionContext.currentSession = {
    startedAt: new Date().toISOString(),
    project,
    workingDirectory
  };

  // Reset attention weights with slight bias toward project's tech stack
  const projectStack = await detectProjectStack(workingDirectory);
  sessionContext.attentionWeights.weights = {};
  for (const tech of projectStack) {
    sessionContext.attentionWeights.weights[tech] = 0.3;  // Baseline awareness
  }

  // Clear current focus
  sessionContext.currentFocus = {
    topic: null,
    since: null,
    relatedFiles: [],
    keyDecisions: [],
    memoriesApplied: []
  };

  // Keep recent context from previous sessions (continuity)
  // But trim to maxEntries
  sessionContext.recentContext.entries =
    sessionContext.recentContext.entries.slice(-sessionContext.recentContext.maxEntries);

  await writeFile('~/.claude-setup/memory/session-context.json',
    JSON.stringify(sessionContext, null, 2));

  return sessionContext;
}
```

### Update Focus

```javascript
/**
 * Update current focus when starting a new task/story
 */
async function updateFocus(topic, relatedFiles = []) {
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );

  // Archive previous focus to recent context
  if (sessionContext.currentFocus.topic) {
    const previousFocus = sessionContext.currentFocus;
    const duration = calculateDuration(previousFocus.since, new Date());

    sessionContext.recentContext.entries.push({
      topic: previousFocus.topic,
      duration,
      outcome: previousFocus.keyDecisions.length > 0
        ? previousFocus.keyDecisions[previousFocus.keyDecisions.length - 1]
        : null,
      timestamp: previousFocus.since,
      memoriesUsed: previousFocus.memoriesApplied.length
    });

    // Trim to max entries
    if (sessionContext.recentContext.entries.length > sessionContext.recentContext.maxEntries) {
      sessionContext.recentContext.entries.shift();
    }
  }

  // Set new focus
  sessionContext.currentFocus = {
    topic,
    since: new Date().toISOString(),
    relatedFiles,
    keyDecisions: [],
    memoriesApplied: []
  };

  // Update attention weights
  sessionContext.attentionWeights.weights = updateAttentionWeights(
    topic,
    sessionContext
  );

  await writeFile('~/.claude-setup/memory/session-context.json',
    JSON.stringify(sessionContext, null, 2));

  return sessionContext;
}
```

### Log Memory Application

```javascript
/**
 * Log when a memory is applied during work
 */
async function logMemoryApplication(memoryName, context) {
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );

  // Add to current focus
  if (!sessionContext.currentFocus.memoriesApplied.includes(memoryName)) {
    sessionContext.currentFocus.memoriesApplied.push(memoryName);
  }

  // Add to application log
  sessionContext.memoryApplicationLog.applications.push({
    memoryName,
    appliedAt: new Date().toISOString(),
    context,
    helpful: null  // To be filled in by metacognition
  });

  await writeFile('~/.claude-setup/memory/session-context.json',
    JSON.stringify(sessionContext, null, 2));
}
```

---

## Integration with Skills

### In autonomous-dev Phase 3

```javascript
// Step 3.0: Load context with attention
async function loadContextWithAttention(story, prd) {
  // Update focus to current story
  await updateFocus(
    story.detectedType || 'implementation',
    inferRelatedFiles(story)
  );

  // Load session context
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );

  // Query memories with attention weighting
  const relevantMemories = await queryMemoriesWithAttention(
    `${story.title} ${story.description}`,
    sessionContext
  );

  console.log(`Loaded ${relevantMemories.length} attention-weighted memories`);
  console.log(`Current focus: ${sessionContext.currentFocus.topic}`);
  console.log(`Top attention weights:`);
  Object.entries(sessionContext.attentionWeights.weights)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .forEach(([topic, weight]) => {
      console.log(`  ${topic}: ${(weight * 100).toFixed(0)}%`);
    });

  return { sessionContext, relevantMemories };
}
```

### Record Key Decision

```javascript
// When making an important decision during implementation
async function recordKeyDecision(decision) {
  const sessionContext = JSON.parse(
    await readFile('~/.claude-setup/memory/session-context.json')
  );

  sessionContext.currentFocus.keyDecisions.push(decision);

  await writeFile('~/.claude-setup/memory/session-context.json',
    JSON.stringify(sessionContext, null, 2));
}
```

---

## Topic Detection

```javascript
/**
 * Automatically detect topic from story or task
 */
function detectTopic(story) {
  const text = `${story.title} ${story.description} ${story.acceptanceCriteria?.join(' ')}`.toLowerCase();

  const topicPatterns = {
    'authentication': /\b(auth|login|logout|session|jwt|oauth|password|signin|signup)\b/,
    'database': /\b(database|schema|migration|table|column|query|sql|postgres)\b/,
    'api': /\b(endpoint|api|route|rest|graphql|request|response)\b/,
    'frontend': /\b(component|ui|page|form|button|modal|layout|render)\b/,
    'styling': /\b(style|css|tailwind|theme|color|font|responsive)\b/,
    'testing': /\b(test|spec|jest|vitest|playwright|coverage)\b/,
    'deployment': /\b(deploy|ci|cd|docker|railway|vercel|production)\b/,
    'security': /\b(security|xss|csrf|injection|sanitize|validate)\b/,
    'performance': /\b(performance|optimize|cache|lazy|bundle|speed)\b/
  };

  for (const [topic, pattern] of Object.entries(topicPatterns)) {
    if (pattern.test(text)) {
      return topic;
    }
  }

  return 'general';
}
```
