---
name: fulltest-skill
description: "Swarm-enabled full-spectrum testing for websites and applications. Uses TeammateTool for true parallel page testers that share failure patterns in real-time. Maps sites, spawns concurrent testers, detects cross-page patterns, auto-fixes with parallel fixers, generates comprehensive reports."
user-invocable: true
context: fork
model: sonnet # Orchestration-focused; spawns haiku agents for parallel page testing
allowed-tools:
  - Task(agent_type=general-purpose)
  - Task(agent_type=Explore)
  - TeamCreate
  - TeamDelete
  - SendMessage
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - AskUserQuestion
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - mcp__chrome-devtools__*
  - mcp__browserless__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__chrome-devtools__click: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__fill: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__navigate_page:
    { readOnlyHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
  SendMessage: { openWorldHint: true, idempotentHint: false }
  TeamDelete: { destructiveHint: true, idempotentHint: true }
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

# Full-Spectrum Testing Skill (v4.0 - Swarm Mode)

Comprehensive website testing with **true parallel execution** via TeammateTool, real-time failure sharing, and cross-page pattern detection.

## What It Does

When you run `/fulltest`, it will:

1. Map your entire site structure
2. **Spawn concurrent page testers** via TeammateTool (not sequential Task calls)
3. **Share failures in real-time** - when one tester finds CSS issue, others check immediately
4. **Detect cross-page patterns** - same error on multiple pages = systemic issue
5. **Learn from failures** and store patterns in MCP memory
6. **Spawn parallel fixers** by category (CSS, JS, assets, etc.)
7. Re-test until all tests pass (max 3 iterations)
8. Generate comprehensive report with live progress

## Execution Modes

| Mode           | Description                    | When to Use                 |
| -------------- | ------------------------------ | --------------------------- |
| **Sequential** | Task-based parallel (standard) | Small sites, debugging      |
| **Swarm**      | TeammateTool true concurrency  | Large sites, speed priority |

## Swarm Mode Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FULLTEST SWARM ORCHESTRATOR                       │
│                                                                      │
│   Phase 1: Site Mapping                                             │
│          │                                                          │
│          ▼                                                          │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │              PHASE 2: SWARM PAGE TESTING                     │   │
│   │                                                              │   │
│   │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐            │   │
│   │  │Tester 1│  │Tester 2│  │Tester 3│  │Tester N│            │   │
│   │  │ /home  │◀─▶│ /about │◀─▶│ /blog  │◀─▶│ /...   │            │   │
│   │  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘            │   │
│   │      │           │           │           │                  │   │
│   │      └───────────┴───────────┴───────────┘                  │   │
│   │                      │                                       │   │
│   │         ┌────────────┴────────────┐                         │   │
│   │         │   REAL-TIME MESSAGING    │                         │   │
│   │         │ • Failure broadcasts     │                         │   │
│   │         │ • CSS issue alerts       │                         │   │
│   │         │ • Pattern sharing        │                         │   │
│   │         └─────────────────────────┘                         │   │
│   └─────────────────────────────────────────────────────────────┘   │
│          │                                                          │
│          ▼                                                          │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │              PHASE 3: SWARM PARALLEL FIXING                  │   │
│   │              (each fixer in isolation: "worktree")           │   │
│   │                                                              │   │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │   │
│   │  │CSS Fixer │  │ JS Fixer │  │Asset Fix │  │Layout Fix│    │   │
│   │  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │   │
│   └─────────────────────────────────────────────────────────────┘   │
│          │                                                          │
│          ▼                                                          │
│   Phase 4: Report Generation                                        │
└─────────────────────────────────────────────────────────────────────┘
```

## New in v3.0: Visual Verification + Learning

### Visual Verification (Always On)

Every page test now includes:

- **CSS Load Check**: Verify all CSS files return 200 and styles apply
- **Computed Style Check**: Sample key elements for expected styles (dark background, proper fonts)
- **Asset Check**: Verify images and fonts load correctly
- **Screenshot Capture**: On failure only, for debugging

### Pattern Learning

After each test:

- Extract patterns from failures (visual and functional)
- Store patterns in MCP memory for future reference
- Get fix recommendations based on past successful fixes
- Share patterns across similar projects

## Usage

The skill forwards your request to the specialized `fulltesting-agent` which handles all testing logic.

**Your task**: Invoke the fulltesting-agent with the user's request.

## Example

```
User: "Test http://localhost:3000 and fix any issues"

You: [Use Task tool with subagent_type="fulltesting-agent" and pass the URL and user's requirements]
```

## Enhanced Testing Flow

The fulltesting-agent should now follow this enhanced flow:

### Phase 1: Discovery

- Navigate to the site
- Extract all internal links
- Build page map

### Phase 2: Parallel Testing (Per Page)

For each page, run these checks:

#### 2a. Basic Checks (existing)

- Console errors
- Network failures (4xx/5xx)
- Broken links

#### 2b. Visual Verification (NEW)

Execute this JavaScript via `mcp__chrome-devtools__evaluate_script`:

```javascript
() => {
  const body = document.body;
  const computedStyle = window.getComputedStyle(body);
  const bgColor = computedStyle.backgroundColor;
  const fontFamily = computedStyle.fontFamily;

  // Check for unstyled page (CSS not loaded)
  const defaultBgs = ["rgba(0, 0, 0, 0)", "rgb(255, 255, 255)", "transparent"];
  const defaultFonts = ["times new roman", "times", "serif"];

  const bgIsDefault = defaultBgs.some((d) =>
    bgColor.toLowerCase().includes(d.toLowerCase()),
  );
  const fontIsDefault = defaultFonts.some((d) =>
    fontFamily.toLowerCase().includes(d.toLowerCase()),
  );

  // Count loaded CSS files
  const cssLinks = document.querySelectorAll('link[rel="stylesheet"]');
  const cssCount = cssLinks.length;

  // Check for visible styled content
  const hasStyledContent = !bgIsDefault || !fontIsDefault || cssCount > 0;

  return {
    cssLoaded: hasStyledContent,
    backgroundColor: bgColor,
    fontFamily: fontFamily,
    cssFileCount: cssCount,
    isUnstyled: bgIsDefault && fontIsDefault,
    issue:
      bgIsDefault && fontIsDefault
        ? "CSS appears not loaded - page has default unstyled appearance"
        : null,
  };
};
```

If `isUnstyled` is true, this is a **CRITICAL** visual issue that should fail the test.

### Phase 3: Pattern Learning (NEW)

After testing each page, if there are failures:

1. **For console errors**, check if they're visual issues:
   - CSS load failures: `/failed to load resource.*\.css/i`
   - Font issues: `/failed to decode font/i`
   - Image broken: `/failed to load resource.*\.(png|jpg|svg)/i`

2. **Store patterns** in MCP memory using `mcp__memory__create_entities`:

   ```
   Entity name: failure-pattern:visual:{fingerprint}
   Entity type: failure-pattern
   Observations:
   - "visual_type: css-not-loaded"
   - "affected_url: {url}"
   - "message_pattern: {normalized message}"
   - "category: css-load-error"
   - "severity: critical"
   - "occurrence_count: 1"
   - "first_seen: {ISO date}"
   ```

3. **Search for existing patterns** using `mcp__memory__search_nodes`:
   - Query: "css-load-error" or the normalized error message
   - If found, check for associated fixes

4. **Get fix recommendations**:
   - Search memory for `fix-solution` entities linked to the pattern
   - Include recommendations in the report

### Phase 4: Screenshot on Failure (NEW)

When visual issues are detected:

```
mcp__chrome-devtools__take_screenshot with filePath to save for debugging
```

### Phase 5: Analysis & Auto-Fix

- Aggregate all issues
- Prioritize by severity (visual issues = critical)
- **Spawn parallel fixers with `isolation: "worktree"`** to prevent concurrent file edit conflicts
- Apply fixes for known patterns
- Re-test affected pages

### Phase 6: Report Generation

Include in the report:

- All pages tested
- Visual verification results
- Pattern matches found
- Fix recommendations with confidence scores
- Screenshots of failures

## Pattern Categories

The system recognizes these visual pattern categories:

- `css-load-error`: CSS file failed to load
- `style-missing`: Element missing expected styles
- `layout-error`: Layout/responsive issues
- `visual-regression`: Visual difference detected
- `asset-missing`: Image/font/icon not loaded

## Fix Categories

When storing fixes, use these categories:

- `css-fix`: CSS/style changes
- `layout-fix`: Layout/flexbox/grid fixes
- `asset-fix`: Image/font path corrections
- `responsive-fix`: Media query additions

## Integration with smart-testing

The testing-learning library at `src/lib/testing-learning/` provides:

- `processBrowserTestResult()`: Main hook for recording results
- `verifyCSSLoaded()`: Check CSS is properly loaded
- `hasVisualIssues()`: Quick check for visual problems
- `getVisualIssuesSummary()`: Summary for reporting

These functions can be called by reading the TypeScript source and understanding the interface, then using MCP memory tools to store/retrieve the same entity structures.

---

## Swarm Mode Summary

### When Swarm Mode Activates

- Site has >10 pages
- User requests "swarm test" or "fast test"
- Explicit `mode: swarm` in config

### Swarm Capabilities

| Feature               | Description                                                           |
| --------------------- | --------------------------------------------------------------------- |
| **Parallel Testers**  | One tester per page via TeammateTool                                  |
| **Failure Broadcast** | CSS issue found → all testers notified                                |
| **Pattern Detection** | Same error on 3+ pages = systemic issue                               |
| **Parallel Fixers**   | CSS, JS, assets, config fixers run concurrently in isolated worktrees |
| **Live Dashboard**    | Real-time progress during testing                                     |

### Example Swarm Output

```
## Test Progress (Live)

[0:02] Spawned 15 page testers
[0:08] tester-0 (/): ✅ Pass
[0:10] tester-3 (/blog): 🚨 CSS 404 - broadcasting to all
[0:11] tester-* received known_issue: skip CSS check
[0:15] tester-5 (/products): ❌ JS error (new)
[0:18] Pattern detected: JS error on 3 pages (systemic)
[0:25] All testers complete: 12 pass, 3 fail

[0:26] Spawned 2 parallel fixers: css-fixer, js-fixer
[0:35] css-fixer: Fixed /styles/main.css path
[0:42] js-fixer: Fixed null reference in bundle.js
[0:45] All fixers complete

[0:46] Re-testing 3 failed pages...
[0:52] All tests pass!

Total: 52 seconds (vs ~3 minutes sequential)
```

### TeammateTool Message Formatting

> **Note:** TeammateTool messages support **rich Markdown rendering**. Use headers, bold, code blocks, tables, and lists for clear communication between testers and fixers.

#### Failure Broadcast Example

> **Isolation Note:** When spawning parallel fixers (CSS fixer, JS fixer, asset fixer, layout fixer) via the Task tool, always use `isolation: "worktree"` to prevent concurrent file edit conflicts. Page testers are read-only (browser testing) and do not need worktree isolation.

```javascript
// Tester broadcasts CSS failure to all other testers
TeammateTool.message({
  from: "tester-3",
  to: ["orchestrator", "tester-*"],
  type: "failure_broadcast",
  message: `## CSS Load Failure Detected

**Page:** \`/blog\`
**Severity:** Critical

### Error Details
| Resource | Status | Path |
|----------|--------|------|
| main.css | 404 | \`/styles/main.css\` |

### Console Error
\`\`\`
GET http://localhost:3000/styles/main.css 404 (Not Found)
\`\`\`

### Action for Other Testers
Skip CSS verification until this is fixed - mark as **known_issue**.`,
});
```

#### Fix Completion Example

```javascript
// CSS fixer reports completion
TeammateTool.message({
  from: "css-fixer",
  to: ["orchestrator"],
  type: "fix_completed",
  message: `## Fix Applied: CSS Path Correction

### Summary
- **Issue:** CSS file returning 404
- **Root Cause:** Incorrect path in HTML template
- **Status:** Fixed

### Changes Made
\`\`\`diff
- <link rel="stylesheet" href="/styles/main.css">
+ <link rel="stylesheet" href="/css/main.css">
\`\`\`

### Files Modified
- \`src/templates/base.html\`
- \`src/templates/blog.html\`

### Verification
Ready for re-test on affected pages: \`/\`, \`/blog\`, \`/about\``,
});
```

#### Pattern Detection Example

```javascript
// Orchestrator announces systemic pattern
TeammateTool.message({
  from: "orchestrator",
  to: ["all-workers"],
  type: "pattern_detected",
  message: `## Systemic Pattern Detected

**Pattern:** JavaScript null reference error
**Occurrences:** 3 pages

### Affected Pages
1. \`/products\` - line 45
2. \`/cart\` - line 23
3. \`/checkout\` - line 89

### Common Stack Trace
\`\`\`javascript
TypeError: Cannot read property 'items' of null
    at renderCart (bundle.js:1234)
\`\`\`

### Recommended Fix
Add null check before accessing \`cart.items\`:
\`\`\`javascript
const items = cart?.items || []
\`\`\`

**Assigning to:** js-fixer`,
});
```

---

## Version

**Current Version:** 4.0.0 (Swarm-enabled)
**Last Updated:** January 2026

### Changelog

- **4.0.0**: Added swarm mode
  - True parallel testers via TeammateTool
  - Real-time failure sharing between testers
  - Cross-page pattern detection
  - Parallel category-based fixers
  - Live progress dashboard
- **3.0.0**: Added visual verification + pattern learning
- **2.0.0**: Added parallel testing via Task batches
- **1.0.0**: Initial release

### Requirements

- **Both Modes**: Chrome DevTools MCP or Browserless MCP (cloud), Memory MCP
- **Sequential Mode**: Standard Claude Code
- **Swarm Mode**: Requires `claude-sneakpeek` or official TeammateTool support

---

## Completion Signals

This skill explicitly signals completion via structured status returns. Never rely on heuristics like "consecutive iterations without tool calls" to detect completion.

### Completion Signal Format

At the end of testing, return:

```json
{
  "status": "complete|partial|blocked|failed",
  "testingMode": "sequential|swarm",
  "summary": "Brief description of test results",
  "testMetrics": {
    "pagesTotal": 0,
    "pagesTested": 0,
    "pagesPassed": 0,
    "pagesFailed": 0
  },
  "reports": ["List of generated reports"],
  "userActionRequired": "What user should do next (if any)"
}
```

### Success Signal (All Tests Pass)

```json
{
  "status": "complete",
  "testingMode": "swarm",
  "summary": "All 15 pages tested successfully with no failures",
  "testMetrics": {
    "pagesTotal": 15,
    "pagesTested": 15,
    "pagesPassed": 15,
    "pagesFailed": 0,
    "duration": "52 seconds",
    "visualIssues": 0,
    "consoleErrors": 0,
    "brokenLinks": 0
  },
  "reports": [
    ".testing/reports/fulltest-report-2026-01-30.md",
    ".testing/screenshots/"
  ],
  "siteCoverage": "100%",
  "allTestsPassing": true
}
```

### Success Signal (Tests Complete with Fixes Applied)

```json
{
  "status": "complete",
  "testingMode": "swarm",
  "summary": "Testing complete - found and fixed 3 issues",
  "testMetrics": {
    "pagesTotal": 15,
    "pagesTested": 15,
    "pagesPassed": 15,
    "pagesFailed": 0,
    "duration": "3 minutes 15 seconds",
    "issuesFound": 3,
    "issuesFixed": 3,
    "retestsPassed": true
  },
  "fixesSummary": {
    "css": 1,
    "js": 1,
    "assets": 1
  },
  "reports": [
    ".testing/reports/fulltest-report-2026-01-30.md",
    ".testing/screenshots/"
  ],
  "allTestsPassing": true
}
```

### Partial Completion Signal

```json
{
  "status": "partial",
  "testingMode": "swarm",
  "summary": "Testing complete but 2 pages still failing",
  "testMetrics": {
    "pagesTotal": 15,
    "pagesTested": 15,
    "pagesPassed": 13,
    "pagesFailed": 2,
    "duration": "2 minutes 45 seconds"
  },
  "failedPages": [
    {
      "url": "/products",
      "issues": ["JS error: Cannot read property 'items' of null"],
      "severity": "high"
    },
    {
      "url": "/checkout",
      "issues": ["CSS not loading - 404"],
      "severity": "critical"
    }
  ],
  "fixAttempts": 3,
  "fixesSuccessful": 1,
  "fixesFailed": 2,
  "reports": [".testing/reports/fulltest-report-2026-01-30.md"],
  "userActionRequired": "Review failed pages and approve manual intervention"
}
```

### Blocked Signal

```json
{
  "status": "blocked",
  "testingMode": "swarm",
  "summary": "Cannot access website - connection refused",
  "blockers": [
    "Website not accessible at http://localhost:3000",
    "Connection refused - is dev server running?",
    "Chrome DevTools cannot connect"
  ],
  "testedSoFar": 0,
  "userInputRequired": "Please start development server and ensure it's running on port 3000"
}
```

### Troubleshooting

If you encounter unexpected test behavior or unclear failures, use the `/debug` command:

```
/debug
```

Claude will analyze the current session and help identify configuration issues, MCP connection problems, or other blockers.

````

### Failed Signal
```json
{
  "status": "failed",
  "testingMode": "swarm",
  "summary": "Testing failed - critical error in test infrastructure",
  "errors": [
    "Chrome DevTools MCP not available",
    "TeammateTool spawn failed - cannot create parallel testers",
    "Memory allocation error during screenshot capture"
  ],
  "pagesTestedBeforeFailure": 5,
  "partialResults": ".testing/reports/partial-results.json",
  "recoverySuggestions": [
    "Retry with sequential mode instead of swarm",
    "Check Chrome DevTools MCP connection",
    "Reduce number of parallel testers",
    "Clear .testing/ directory and restart"
  ]
}
````

### When to Signal

- **After all pages tested successfully**: Signal "complete" with all tests passing
- **After fixes applied and retests pass**: Signal "complete" with fix summary
- **After max fix iterations with failures**: Signal "partial" with failed pages list
- **Website not accessible**: Signal "blocked" immediately with connection details
- **Infrastructure failure**: Signal "failed" with errors and recovery suggestions
- **Before asking user**: Signal status THEN ask for input, don't wait in "running" state

### Special Cases

**Max iterations reached:**

```json
{
  "status": "partial",
  "summary": "Reached max 3 test/fix iterations with 2 persistent failures",
  "iterationsCompleted": 3,
  "persistentFailures": ["Page /products", "Page /checkout"],
  "userActionRequired": "Manual review needed for complex issues"
}
```

**Swarm mode unavailable:**

```json
{
  "status": "complete",
  "testingMode": "sequential",
  "summary": "Completed testing in sequential mode (swarm unavailable)",
  "fallbackReason": "TeammateTool not available - used sequential testing",
  "testMetrics": {
    /* normal metrics */
  }
}
```

---

## Hook Events

This skill leverages:

- **TeammateIdle**: Triggers when a tester/fixer goes idle (swarm mode)
- **TaskCompleted**: Triggers when a test task is marked completed

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains:

```json
{ "taskId": "1", "status": "deleted" }
```

This prevents task list clutter during long testing sessions.
