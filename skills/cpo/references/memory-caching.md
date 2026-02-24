# Memory MCP Caching for Research

Caching research findings in Memory MCP for cross-project reuse and faster discovery phases.

**Integrates with:** [memory-consolidation skill](../../memory-consolidation/SKILL.md) for human-like memory management.

## Human-Like Memory Architecture

Research caching follows the three-tier memory system:

```
┌─────────────────────────────────────────────────────────────┐
│                     CORE MEMORY                              │
│  ~/Library/Mobile Documents/com~apple~CloudDocs/claude-setup/memory/core-memory.json                          │
│  - User preferences (deployment targets, tech stack)         │
│  - Stable beliefs about product development                  │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Promotion after multiple successful uses
                              │
┌─────────────────────────────────────────────────────────────┐
│                   LONG-TERM MEMORY                           │
│  Memory MCP research entities                                │
│  - Market research (30-day freshness)                        │
│  - Competitor profiles (90-day freshness)                    │
│  - Design patterns (180-day freshness)                       │
│  - Stack recommendations (90-day freshness)                  │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ Sensory Filter (relevance >= 5)
                              │
┌─────────────────────────────────────────────────────────────┐
│                  SESSION RESEARCH                            │
│  Raw research outputs (competitor-analysis.md, etc.)        │
│  - Evaluated for caching after research completes           │
└─────────────────────────────────────────────────────────────┘
```

## Why Cache Research Across Projects

Research is expensive - it requires multiple web searches, source evaluation, and synthesis. Caching enables:

- **Faster Discovery**: Skip redundant searches for common product types
- **Consistent Insights**: Reuse validated competitor analysis across similar projects
- **Design Pattern Library**: Build a reusable reference of proven UI/UX patterns
- **Tech Stack Decisions**: Cache vetted stack recommendations by use case
- **Cross-Project Learning**: Insights from one project inform the next

### When to Read vs Write to Memory

| Action | When to Read | When to Write |
|--------|--------------|---------------|
| **Core Memory** | Session start (always) | After preferences proven stable |
| **Market Research** | Before running Product Research Agent | After research completes with fresh data |
| **Competitor Profiles** | When building similar product type | After deep competitor analysis |
| **Design Patterns** | Before Frontend Design Agent runs | After discovering effective patterns |
| **Stack Recommendations** | Phase 2 before CTO Advisor | After successful project deployment |

---

## Sensory Filter for Research

Before saving research to Memory MCP, apply relevance scoring:

```javascript
async function saveResearchWithFilter(research) {
  // Load core memory for threshold
  const coreMemory = JSON.parse(
    await readFile('~/Library/Mobile Documents/com~apple~CloudDocs/claude-setup/memory/core-memory.json')
  );
  const existingMemories = await mcp__memory__search_nodes({ query: "" });

  // Calculate relevance
  let score = 0;
  const reasons = [];

  // Research typically scores well on:
  // - Generality: market research applies to multiple projects (+3)
  // - Severity: strategic decisions are high impact (+3)
  // - Source: web research is validated (+1)

  if (research.appliesTo?.length > 1) {
    score += 3;
    reasons.push("Applies to multiple product types (+3)");
  }

  if (research.entityType === 'market-research') {
    score += 3; // Market research is always strategic
    reasons.push("Strategic market intelligence (+3)");
  }

  if (research.entityType === 'competitor-profile') {
    score += 2; // Competitors inform strategy
    reasons.push("Competitive intelligence (+2)");
  }

  // Check for duplicates
  const similar = existingMemories.entities?.filter(m =>
    m.name.includes(research.name.split(':')[1]) ||
    m.observations?.some(o => research.observations?.some(r =>
      calculateSimilarity(o, r) > 0.7
    ))
  );

  if (similar?.length > 0) {
    // Update existing instead of creating duplicate
    console.log(`Updating existing: ${similar[0].name}`);
    await mcp__memory__add_observations({
      observations: [{
        entityName: similar[0].name,
        contents: [
          ...research.observations,
          `Updated: ${new Date().toISOString().split('T')[0]}`
        ]
      }]
    });
    return { saved: false, updated: similar[0].name };
  }

  const threshold = coreMemory.memoryConfig?.relevanceThreshold || 5;

  if (score >= threshold) {
    // Add tracking metadata
    research.observations.push(
      `Researched: ${new Date().toISOString().split('T')[0]}`,
      `Relevance score: ${score}`
    );

    await mcp__memory__create_entities({ entities: [research] });
    console.log(`✓ Research cached: ${research.name} (score: ${score})`);
    return { saved: true, score, reasons };
  }

  console.log(`⊘ Research not cached: score ${score} < ${threshold}`);
  return { saved: false, score, reasons };
}
```

---

## Research Entity Types

```javascript
const RESEARCH_ENTITIES = {
  'market-research': {
    // Competitor analysis, market size, trends
    // Refresh: 30 days
    // Default relevance: +3 (strategic)
    example: 'research:task-management-apps-2025'
  },
  'design-pattern': {
    // UI/UX patterns for specific product types
    // Refresh: 180 days (patterns evolve slowly)
    // Default relevance: +2 (reusable)
    example: 'design:dashboard-patterns'
  },
  'tech-stack-recommendation': {
    // Proven stack combinations with rationale
    // Refresh: 90 days (ecosystem changes)
    // Default relevance: +3 (validated through deployment)
    example: 'stack:saas-mvp-nextjs-supabase'
  },
  'competitor-profile': {
    // Individual competitor deep dives
    // Refresh: 90 days
    // Default relevance: +2 (competitive intelligence)
    example: 'competitor:linear-app'
  }
};
```

---

## Saving Research to Memory

### After Market Research Completes

Save structured findings that can be reused across projects:

```javascript
// Save market research after Product Research Agent completes
await mcp__memory__create_entities({
  entities: [{
    name: "research:task-management-apps-2025",
    entityType: "market-research",
    observations: [
      "Market size: $4.5B globally, growing 12% annually",
      "Key players: Asana, Linear, Notion, Monday, ClickUp",
      "Trend: AI-powered task prioritization and auto-scheduling",
      "Trend: Deep integrations with communication tools",
      "Gap: Simple tools for small teams (5-15 people)",
      "Gap: Developer-focused task management with Git integration",
      "User expectation: Sub-second task creation",
      "User expectation: Keyboard-first navigation",
      "Pricing benchmark: $8-15/user/month for team plans",
      "Researched: 2025-01-25"
    ]
  }]
});
```

### After Competitor Analysis

Save individual competitor profiles for reference:

```javascript
// Save detailed competitor profile
await mcp__memory__create_entities({
  entities: [{
    name: "competitor:linear-app",
    entityType: "competitor-profile",
    observations: [
      "Target: Engineering and product teams",
      "Positioning: Fast, keyboard-first issue tracking",
      "Strength: Exceptional performance and UX polish",
      "Strength: Clean, minimalist dark mode UI",
      "Strength: Cycles feature for sprint planning",
      "Weakness: Limited customization options",
      "Weakness: No time tracking built-in",
      "Pricing: $8/user/month (Standard), $14/user/month (Plus)",
      "Tech: React, GraphQL, real-time sync",
      "Design: Minimalist, dark mode default, keyboard shortcuts",
      "Founded: 2019, Series B funded",
      "Researched: 2025-01-25"
    ]
  }]
});

// Create relation to market research
await mcp__memory__create_relations({
  relations: [{
    from: "competitor:linear-app",
    relationType: "competes_in",
    to: "research:task-management-apps-2025"
  }]
});
```

### After Design Research

Cache proven design patterns by product type:

```javascript
// Save design patterns discovered during research
await mcp__memory__create_entities({
  entities: [{
    name: "design:dashboard-patterns",
    entityType: "design-pattern",
    observations: [
      "Layout: Left sidebar nav with collapsible sections",
      "Layout: Top bar for search, notifications, profile",
      "Cards: Use subtle shadows, not borders, for elevation",
      "Data viz: Prefer line charts for trends, bar for comparisons",
      "Empty states: Always show helpful actions, not just text",
      "Loading: Skeleton screens over spinners for perceived speed",
      "Color: Limit to 2-3 accent colors for focus",
      "Typography: System fonts for performance, 14-16px base",
      "Spacing: 8px grid system for consistency",
      "Reference: Linear - exceptional keyboard navigation",
      "Reference: Notion - flexible block-based content",
      "Reference: Vercel Dashboard - clean data presentation",
      "Researched: 2025-01-25"
    ]
  }]
});
```

### After Successful Tech Stack Deployment

Cache validated stack combinations:

```javascript
// Save proven stack after successful deployment
await mcp__memory__create_entities({
  entities: [{
    name: "stack:saas-mvp-nextjs-supabase",
    entityType: "tech-stack-recommendation",
    observations: [
      "Use case: SaaS MVP with auth, database, real-time",
      "Frontend: Next.js 14 App Router with TypeScript",
      "Styling: Tailwind CSS + shadcn/ui components",
      "Backend: Next.js API Routes or Server Actions",
      "Database: Supabase PostgreSQL with RLS",
      "Auth: Supabase Auth with social providers",
      "Hosting: Vercel (seamless Next.js integration)",
      "Cost: ~$25/month at MVP scale",
      "Scale: Handles 10K+ users without changes",
      "Pros: Fast development, excellent DX, built-in real-time",
      "Cons: Vendor lock-in risk, cold starts on serverless",
      "Validated: TaskFlow project deployed successfully",
      "Researched: 2025-01-25"
    ]
  }]
});
```

---

## Querying Cached Research

### Before Running Product Research Agent

Check if relevant research exists and is fresh:

```javascript
// Check for existing research before starting Phase 1.4
const cached = await mcp__memory__search_nodes({
  query: "task-management"
});

if (cached.entities && cached.entities.length > 0) {
  const research = cached.entities[0];

  // Find the research date
  const dateObs = research.observations.find(o =>
    o.startsWith("Researched:")
  );

  if (dateObs) {
    const researchDate = dateObs.replace("Researched: ", "");
    const daysSince = daysBetween(researchDate, new Date());

    if (daysSince < 30) {
      console.log(`Using cached research from ${researchDate}`);
      console.log(`Days since research: ${daysSince}`);
      return research.observations;
    } else {
      console.log(`Research stale (${daysSince} days old), refreshing...`);
    }
  }
}

// No valid cache - run full research
console.log("No cached research found, running Product Research Agent...");
```

### Query for Related Competitors

```javascript
// Get all competitors in a market
const competitors = await mcp__memory__search_nodes({
  query: "competitor:"
});

// Filter to specific market
const taskManagementCompetitors = competitors.entities.filter(e =>
  e.name.startsWith("competitor:") &&
  e.relations?.some(r =>
    r.relationType === "competes_in" &&
    r.to.includes("task-management")
  )
);
```

### Query for Design Patterns

```javascript
// Before invoking Frontend Design Agent
const patterns = await mcp__memory__search_nodes({
  query: "design:dashboard"
});

if (patterns.entities?.length > 0) {
  const dashboardPatterns = patterns.entities[0].observations;
  // Pass to Frontend Design Agent in prompt
}
```

---

## Cache Invalidation Rules

| Entity Type | Max Age | Reason |
|-------------|---------|--------|
| `market-research` | 30 days | Markets evolve, new players emerge |
| `competitor-profile` | 90 days | Products update, pricing changes |
| `design-pattern` | 180 days | Visual trends evolve slowly |
| `tech-stack-recommendation` | 90 days | Ecosystem changes, new tools |

### Checking Freshness

```javascript
function isFresh(entity, maxAgeDays) {
  const dateObs = entity.observations.find(o =>
    o.startsWith("Researched:")
  );

  if (!dateObs) return false; // No date = stale

  const researchDate = new Date(dateObs.replace("Researched: ", ""));
  const today = new Date();
  const daysSince = Math.floor(
    (today - researchDate) / (1000 * 60 * 60 * 24)
  );

  return daysSince < maxAgeDays;
}

// Usage
const maxAge = {
  'market-research': 30,
  'competitor-profile': 90,
  'design-pattern': 180,
  'tech-stack-recommendation': 90
};

if (!isFresh(entity, maxAge[entity.entityType])) {
  console.log("Cache stale, refreshing...");
}
```

---

## Research Reuse Workflow

```
Phase 1 Discovery Start
        │
        ▼
┌───────────────────────────────┐
│ Query Memory for              │
│ "[product-type]"              │
└───────────────────────────────┘
        │
        ├── Found & Fresh ─────────────────────┐
        │                                      │
        │                                      ▼
        │                        ┌─────────────────────────────┐
        │                        │ Use cached research         │
        │                        │ Supplement with specific    │
        │                        │ queries only if needed      │
        │                        └─────────────────────────────┘
        │
        └── Not Found / Stale ─────────────────┐
                                               │
                                               ▼
                             ┌─────────────────────────────────┐
                             │ Run Product Research Agent      │
                             │ (full research)                 │
                             └─────────────────────────────────┘
                                               │
                                               ▼
                             ┌─────────────────────────────────┐
                             │ Save findings to Memory MCP     │
                             │ with "Researched: [date]"       │
                             └─────────────────────────────────┘
```

---

## Memory Entity Naming Convention

Consistent naming enables reliable queries:

```
research:[product-category]-[year]
  Example: research:task-management-apps-2025
  Example: research:ecommerce-platforms-2025

competitor:[company-name]
  Example: competitor:linear-app
  Example: competitor:notion-so

design:[pattern-type]
  Example: design:dashboard-patterns
  Example: design:onboarding-flows
  Example: design:pricing-page-layouts

stack:[use-case]-[primary-tech]
  Example: stack:saas-mvp-nextjs-supabase
  Example: stack:api-only-fastapi-postgres
  Example: stack:mobile-app-expo-supabase
```

---

## Integration with CPO Workflow

### Phase 1.3: Check Memory Before Research

```javascript
// In Phase 1 Discovery, before invoking Product Research Agent
const productType = extractProductType(userDescription);

// Check for cached market research
const marketCache = await mcp__memory__search_nodes({
  query: `research:${productType}`
});

// Check for cached competitor profiles
const competitorCache = await mcp__memory__search_nodes({
  query: "competitor:"
});

// Check for relevant design patterns
const designCache = await mcp__memory__search_nodes({
  query: `design:${getRelevantPatterns(productType)}`
});

// Compile what we have vs what we need
const cachedResearch = compileCachedResearch(
  marketCache,
  competitorCache,
  designCache
);

if (cachedResearch.coverage > 0.7) {
  // Use cached data, only research gaps
  console.log("Using 70%+ cached research, filling gaps...");
} else {
  // Run full research
  console.log("Insufficient cache, running full research...");
}
```

### Phase 1.4: Save New Research to Memory

```javascript
// After Product Research Agent completes
const researchOutputs = [
  'competitor-analysis.md',
  'design-references.md',
  'market-insights.md'
];

// Parse and save to Memory MCP
for (const file of researchOutputs) {
  const content = await readFile(file);
  const entities = parseResearchToEntities(content);
  await mcp__memory__create_entities({ entities });
}
```

### Phase 2.0: Check Memory for Stack Recommendations

```javascript
// Before invoking CTO Advisor Agent
const stackCache = await mcp__memory__search_nodes({
  query: `stack:${productScope}-${preferredTech}`
});

if (stackCache.entities?.length > 0 && isFresh(stackCache.entities[0], 90)) {
  console.log("Found cached stack recommendation");
  // Pass to CTO Advisor as starting point
} else {
  // Let CTO Advisor research fresh
}
```

---

## Example: Full Research Cycle

Complete flow from query to save for a task management app:

### Step 1: Check for Cached Research

```javascript
// Query memory for existing research
const cached = await mcp__memory__search_nodes({
  query: "task-management"
});

console.log(`Found ${cached.entities?.length || 0} cached entities`);
// Output: Found 0 cached entities
```

### Step 2: Run Product Research Agent

Since no cache exists, run full research (see product-research-agent.md).

### Step 3: Save Market Research

```javascript
await mcp__memory__create_entities({
  entities: [{
    name: "research:task-management-apps-2025",
    entityType: "market-research",
    observations: [
      "Market size: $4.5B globally, growing 12% annually",
      "Key players: Asana, Linear, Notion, Monday, ClickUp",
      "Trend: AI-powered task prioritization",
      "Trend: Real-time collaboration features",
      "Gap: Simple tools for small teams",
      "Gap: Developer-focused with Git integration",
      "Pricing benchmark: $8-15/user/month",
      "Researched: 2025-01-25"
    ]
  }]
});
```

### Step 4: Save Competitor Profiles

```javascript
await mcp__memory__create_entities({
  entities: [
    {
      name: "competitor:linear-app",
      entityType: "competitor-profile",
      observations: [
        "Target: Engineering teams",
        "Strength: Keyboard-first, exceptional performance",
        "Weakness: Limited customization",
        "Pricing: $8/user/month",
        "Researched: 2025-01-25"
      ]
    },
    {
      name: "competitor:notion-so",
      entityType: "competitor-profile",
      observations: [
        "Target: Knowledge workers, all team types",
        "Strength: Flexible blocks, databases, wiki",
        "Weakness: Can be slow, learning curve",
        "Pricing: $10/user/month",
        "Researched: 2025-01-25"
      ]
    }
  ]
});
```

### Step 5: Create Relations

```javascript
await mcp__memory__create_relations({
  relations: [
    {
      from: "competitor:linear-app",
      relationType: "competes_in",
      to: "research:task-management-apps-2025"
    },
    {
      from: "competitor:notion-so",
      relationType: "competes_in",
      to: "research:task-management-apps-2025"
    }
  ]
});
```

### Step 6: Future Project Reuse

```javascript
// 2 weeks later, new task management project starts

const cached = await mcp__memory__search_nodes({
  query: "task-management"
});

// Found: research:task-management-apps-2025
// Age: 14 days (fresh, under 30-day threshold)

console.log("Using cached research from 2025-01-25");
console.log("Skipping full market research, checking for updates only...");

// Only research specific gaps or recent changes
```

---

## Updating Cached Research

When refreshing stale research, add new observations:

```javascript
// Research is 45 days old, need to refresh
await mcp__memory__add_observations({
  observations: [{
    entityName: "research:task-management-apps-2025",
    contents: [
      "Update: ClickUp launched AI features in Feb 2025",
      "Update: Notion acquired calendar startup",
      "Trend: Voice-to-task becoming standard",
      "Researched: 2025-03-10"
    ]
  }]
});
```

---

## Summary

| Phase | Memory Action | Entity Types |
|-------|---------------|--------------|
| 1.3 Discovery | Read | market-research, competitor-profile |
| 1.4 Research | Write | market-research, competitor-profile, design-pattern |
| 2.0 Planning | Read | tech-stack-recommendation |
| 3.x UI Stages | Read | design-pattern |
| 5.0 Deployment | Write | tech-stack-recommendation (validated) |
