---
name: ship
description: "End-to-end feature shipping: CPO product spec → CTO tech spec → sequential thinking implementation plan → swarm execution (haiku for simple, sonnet for complex) → QA testing → fix cycles → documentation. Resumable across context clears. Triggers on: ship, ship feature, build and ship, full cycle, end to end, /ship."
argument-hint: "<feature description, sprint plan, or --resume>"
user-invocable: true
context: fork
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task(agent_type=general-purpose)
  - Task(agent_type=frontend-agent)
  - Task(agent_type=backend-agent)
  - Task(agent_type=database-agent)
  - Task(agent_type=Explore)
  - Task(agent_type=Plan)
  - TeamCreate
  - TeamDelete
  - SendMessage
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - AskUserQuestion
  - WebSearch
  - WebFetch
  - mcp__sequential-thinking__*
  - mcp__memory__*
  - mcp__chrome-devtools__*
  - mcp__postgres__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__postgres__*:
    { destructiveHint: false, readOnlyHint: true, idempotentHint: true }
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

# Ship — End-to-End Feature Shipping

## Current Environment

- Git branch: !`git branch --show-current 2>/dev/null`
- Recent commits: !`git log --oneline -5 2>/dev/null`
- Changed files: !`git diff --stat HEAD 2>/dev/null | tail -5`

A disciplined 7-phase skill that takes a feature from idea to production. Each phase produces persistent artifacts. Resumable across context clears via state file.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              /ship ORCHESTRATOR                                      │
│                                                                                      │
│  Phase -1       Phase 0       Phase 1        Phase 2        Phase 3                 │
│  ┌──────────┐   ┌──────────┐  ┌──────────┐   ┌──────────┐   ┌──────────┐           │
│  │ PROJECT  │──▶│ PROJECT  │─▶│ PRODUCT  │──▶│  TECH    │──▶│  PLAN    │           │
│  │  INIT    │   │ DETECT   │  │  SPEC    │   │  SPEC    │   │          │           │
│  │          │   │          │  │          │   │          │   │ Seq.     │           │
│  │ git init │   │ Auto     │  │ CPO mind │   │ CTO mind │   │ Thinking │           │
│  │ scaffold │   │          │  └──────────┘   └──────────┘   └─────┬────┘           │
│  └──────────┘   └──────────┘                                      │                 │
│  (conditional)                                                    ▼                 │
│                                 Phase 4         Phase 5                             │
│                                 ┌──────────┐   ┌─────────┐                          │
│                                 │ EXECUTE  │──▶│   QA    │                          │
│                                 │ (Swarm)  │   │  TEST   │                          │
│                                 │ haiku +  │   │         │                          │
│                                 │ sonnet   │   └────┬────┘                          │
│                                 └──────────┘        │                               │
│                                      ▲              │                               │
│  Phase 7        Phase 6              │              │                               │
│  ┌──────────┐   ┌──────────┐         └──────────────┘                               │
│  │   DOC    │◀──│   FIX    │◀── if issues found                                    │
│  │          │   │  CYCLE   │                                                        │
│  └──────────┘   └──────────┘                                                        │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## State Management

All state is persisted to `.claude/ship/{feature-slug}/`. This enables resuming after context clears.

### State File: `state.json`

```json
{
  "featureSlug": "feature-name",
  "featureDescription": "...",
  "currentPhase": "execute",
  "project": {
    "name": "detected-project-name",
    "packageManager": "pnpm",
    "language": "typescript",
    "framework": "next.js",
    "monorepo": true,
    "commands": {
      "install": "pnpm install",
      "typecheck": "pnpm turbo typecheck",
      "test": "pnpm turbo test",
      "build": "pnpm turbo build",
      "dev": "pnpm dev",
      "lint": "pnpm lint"
    },
    "qaSkill": "generic",
    "conventions": ""
  },
  "phases": {
    "project-init": {
      "status": "skipped",
      "reason": "existing project detected"
    },
    "product-spec": { "status": "complete", "artifact": "product-spec.md" },
    "tech-spec": { "status": "complete", "artifact": "tech-spec.md" },
    "plan": { "status": "complete", "artifact": "plan.md" },
    "execute": {
      "status": "in-progress",
      "completedTasks": 4,
      "totalTasks": 8
    },
    "qa": { "status": "pending" },
    "fix": { "status": "pending", "iterations": 0 },
    "document": { "status": "pending" }
  },
  "commits": [],
  "qaIterations": 0,
  "maxQaIterations": 3,
  "createdAt": "2026-02-13T...",
  "updatedAt": "2026-02-13T..."
}
```

### On Every Invocation

```
1. Check for .claude/ship/*/state.json
2. If found and not complete → ask user: "Resume {feature}?" or "Start new?"
3. If --resume flag → auto-resume
4. If new → check for existing project files
   a. No project files found → run Phase -1 (ask for directory, git init, scaffold)
   b. Project files found → skip to Phase 0
5. Create .claude/ship/{feature-slug}/ directory and state.json
```

---

## Phase -1: Project Init (Conditional)

Runs when no existing project is detected in the current directory (no package.json, Cargo.toml, go.mod, pyproject.toml, etc.) OR when the user explicitly wants to start a new project.

### Process

1. **Detect existing project:** Check current directory for project files. If found → skip to Phase 0.
2. **Ask for directory:** Use AskUserQuestion to ask the user where to create the project:
   - Suggest `./` (current directory) as default
   - Let user provide a custom path (e.g., `~/code/my-project`)
3. **Ask for project name** if not already provided in the feature description
4. **Create directory** if it doesn't exist: `mkdir -p {path}`
5. **Initialize git:** `cd {path} && git init`
6. **Create initial structure** based on detected intent from feature description:
   - If TypeScript/Next.js → scaffold with `pnpm create next-app` or equivalent
   - If plain TypeScript → `pnpm init` + tsconfig
   - If Python → `uv init` or basic pyproject.toml
   - If user specified a framework → use that framework's init command
7. **Initial commit:** `git add -A && git commit -m "chore: initial project scaffold"`
8. **Set working directory** to the new project path for all subsequent phases
9. **Update state.json** with the project path

### Skip Condition

If the current directory already has a git repo with project files, skip entirely and proceed to Phase 0.

---

## Phase 0: Project Detection (Auto)

Runs automatically on first invocation. Detects project type and stores config in state.json.

### Detection Logic

1. Read package.json, Cargo.toml, go.mod, pyproject.toml, requirements.txt
2. Detect package manager: pnpm (pnpm-lock.yaml) → npm (package-lock.json) → yarn (yarn.lock) → bun (bun.lockb) → cargo → pip
3. Detect framework: Next.js, Fastify, Express, Django, Flask, etc.
4. Detect monorepo: turbo.json, nx.json, lerna.json, pnpm-workspace.yaml
5. Extract scripts from package.json (or equivalent): build, test, typecheck, lint, dev
6. Check for CLAUDE.md, .claude/ directory, existing conventions
7. Detect QA skill: if project has qa-sourcerank → use it, if qa-cycle → use it, else → generic Chrome DevTools testing

### Store in state.json `project` field

```json
{
  "project": {
    "name": "from package.json or directory name",
    "packageManager": "pnpm|npm|yarn|bun|cargo|pip",
    "language": "typescript|javascript|python|rust|go",
    "framework": "next.js|fastify|django|none",
    "monorepo": true,
    "commands": {
      "install": "pnpm install",
      "typecheck": "pnpm turbo typecheck",
      "test": "pnpm turbo test",
      "build": "pnpm turbo build",
      "dev": "pnpm dev",
      "lint": "pnpm lint"
    },
    "qaSkill": "/qa-sourcerank|/qa-cycle|/fulltest-skill|generic",
    "conventions": "extracted from CLAUDE.md or detected patterns"
  }
}
```

---

## Phase 1: Product Spec (CPO Mindset)

**Goal:** Define WHAT to build and WHY.

**Model:** Sonnet (product thinking, not code generation)

### Process

1. **Read context:** If a sprint plan or feature description was provided, read it thoroughly. Also read:
   - CLAUDE.md, package.json, existing feature files
   - Recent git history for context
   - Any existing .claude/ship/ artifacts

2. **Analyze as CPO:**
   - Who is the user? What problem does this solve?
   - What's the competitive landscape?
   - What's the MVP scope vs nice-to-have?
   - What are the success metrics?
   - What are the risks?

3. **Write product-spec.md:**

```markdown
# Product Spec: {Feature Name}

## Problem Statement

[What user pain this solves]

## Target Users

[Who benefits and how]

## Scope

### In Scope (MVP)

- [Feature 1]
- [Feature 2]

### Out of Scope

- [Deferred item]

## User Stories

- As a [user], I want to [action] so that [benefit]

## Success Metrics

- [Metric 1]
- [Metric 2]

## Competitive Context

[How competitors handle this, what we do differently]

## Risks & Mitigations

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |
```

4. **Update state.json** → phase complete

### Skip Condition

If user provides a detailed sprint plan (like the Sprint 1 example), treat it as an already-approved product spec. Extract the key product decisions and write a condensed product-spec.md, then move directly to Phase 2.

---

## Phase 2: Tech Spec (CTO Mindset)

**Goal:** Define HOW to build it technically.

**Model:** Sonnet (architectural decisions)

### Process

1. **Deep-read the codebase** relevant to this feature:
   - Use Glob/Grep to find related files
   - Read existing patterns (routes, schemas, components, hooks)
   - Understand the tech stack, conventions, and dependencies

2. **Analyze as CTO:**
   - Database schema changes needed
   - API endpoints and contracts
   - Frontend components and state management
   - Service layer architecture
   - Dependencies to add/update
   - Migration strategy
   - Performance considerations
   - Security implications

3. **Write tech-spec.md:**

```markdown
# Tech Spec: {Feature Name}

## Architecture Decision

[Approach chosen and why]

## Database Changes

### New Tables

| Table | Columns | Indices |
| ----- | ------- | ------- |

### Schema File

`{detected path to schema directory}/{name}.ts`

## API Design

### Endpoints

| Method | Path | Description | Auth |
| ------ | ---- | ----------- | ---- |

### Route File

`{detected path to routes directory}/{name}/index.ts`

## Service Layer

### New Services

| Service | Purpose | Location |
| ------- | ------- | -------- |

## Frontend Changes

### New Files

| File | Purpose |
| ---- | ------- |

### Modified Files

| File | Change |
| ---- | ------ |

## Dependencies

| Package | Version | Where |
| ------- | ------- | ----- |

## Files to Create

[Ordered list]

## Files to Modify

[Ordered list]

## Implementation Order

[Numbered sequence respecting dependencies]
```

4. **Update state.json** → phase complete

---

## Phase 3: Implementation Plan (Sequential Thinking)

**Goal:** Break the tech spec into an ordered, dependency-aware task list with model routing.

### Process

1. **Query learnings before planning:**
   - Read `.claude/ship/learnings.json` for project-local history
   - Query MCP Memory: `ship-learning:*` for cross-project patterns
   - Identify: model routing overrides, known failure areas, dependency gotchas

2. **Use sequential thinking MCP** to decompose the tech spec:

```
For each item in the tech spec:
  - What are its dependencies? (must come after X)
  - What's the complexity? (simple / moderate / complex)
  - What type of work? (database / api / frontend / config)
  - Can it run in parallel with other tasks?
  - Any learnings from past runs that apply? (check learnings.json)
```

3. **Classify each task for model routing:**

| Complexity        | Model  | Examples                                                                                              |
| ----------------- | ------ | ----------------------------------------------------------------------------------------------------- |
| **simple**        | haiku  | Translations, boilerplate files, re-exports, schema exports, simple CRUD, config changes              |
| **moderate**      | sonnet | Business logic, API routes with validation, React components with state, hooks, service orchestrators |
| **complex**       | opus   | Novel algorithms, complex state machines, architectural decisions mid-implementation                  |
| **lang-specific** | varies | Python: pytest, Go: go test, Rust: cargo test — detected automatically via Phase 0                    |

**Override from learnings:** If `learnings.json` records that a task type was mis-routed in a past run (e.g. "hooks" classified as simple but failed, needed sonnet), bump its complexity up.

4. **Write plan.md** with the ordered task list:

```markdown
# Implementation Plan: {Feature Name}

## Task List

### Task 1: {Description}

- **Type:** database
- **Complexity:** simple → haiku
- **Files:** packages/database/src/schema/foo.ts
- **Depends on:** none
- **Parallel group:** A

### Task 2: {Description}

- **Type:** api
- **Complexity:** moderate → sonnet
- **Files:** apps/api/src/services/foo/bar.ts
- **Depends on:** Task 1
- **Parallel group:** B

## Execution Groups

Group A (parallel): Tasks 1, 3, 5 (no dependencies between them)
Group B (parallel): Tasks 2, 4 (depend on Group A)
Group C (sequential): Task 6 (depends on Group B)

## Checkpoint Strategy

- Commit after each group completes
- Typecheck after each task
```

5. **Create TaskList** from the plan for tracking
6. **Update state.json** → phase complete

---

## Phase 4: Execution (Swarm)

**Goal:** Implement all tasks using model-appropriate agents in parallel where possible.

### Process

1. **Create team** via TeamCreate for the feature
2. **Execute by groups:**

For each execution group:

a. **Spawn agents** based on task complexity:

- Simple tasks → `Task(model=haiku, subagent_type=general-purpose)`
- Moderate tasks → `Task(model=sonnet, subagent_type=general-purpose)` or `Task(model=sonnet, subagent_type=frontend-agent)` / `backend-agent` based on type
- Complex tasks → Keep in main context (opus) or `Task(model=sonnet, subagent_type=general-purpose)` with detailed prompt

b. **Each agent gets:**

- The specific task from the plan
- Relevant file contents (pre-read and included in prompt)
- Coding conventions from the codebase
- Clear acceptance criteria

c. **After each group completes:**

- Run `{project.commands.typecheck}` (skip if not available)
- If typecheck fails, fix inline before proceeding
- Commit the group: `git add <specific files> && git commit -m "feat(feature): implement group X"`
- Update state.json with completed tasks

3. **Context checkpoint:** If context usage approaches 80%:
   - Commit all current work
   - Update state.json with exact progress
   - Tell user: "Context getting full. Committed progress. Run `/ship --resume` to continue."

### Agent Prompt Template

```
You are implementing a specific task for the {feature} feature in the {project.name} codebase.

**Task:** {task description}
**Files to create/modify:** {file list}
**Dependencies:** {what other tasks produce that this needs}

**Codebase conventions:**
{extracted patterns from existing code}

**Acceptance criteria:**
- Code compiles/passes checks with no errors ({project.commands.typecheck} if available)
- Follows existing patterns in the codebase
- {specific criteria from task}

**Learnings from past runs:**
{relevant entries from learnings.json for this task type, e.g.:}
- "API routes without input validation fail QA 80% of the time — use zod/joi"
- "This task type was previously mis-routed as simple — take extra care"
(omit this section if no relevant learnings exist)

**Important:**
- Do NOT add comments, docstrings, or type annotations beyond what's needed
- Match the style of existing code exactly
- Keep it minimal - only implement what's specified
```

---

## Phase 5: QA Testing

**Goal:** Verify the feature works end-to-end.

### Process

1. **Run typecheck:** `{project.commands.typecheck}` (skip if not available)
2. **Run tests:** `{project.commands.test}` (skip if not available)
3. **Run lint:** `{project.commands.lint}` (skip if not available)
4. **Project-specific QA:** Based on detected `project.qaSkill`:
   - If `/qa-sourcerank` available AND project is SourceRank → invoke it
   - If `/qa-cycle` available → invoke it
   - If `/fulltest-skill` available → invoke it
   - Otherwise → use Chrome DevTools MCP to test key flows manually
5. **Collect results** into `qa-report.md`:

```markdown
# QA Report: {Feature Name}

## Typecheck: PASS/FAIL

## Unit Tests: PASS/FAIL/SKIPPED

## E2E Testing:

### Tested Flows

| Flow | Status    | Notes |
| ---- | --------- | ----- |
| ...  | PASS/FAIL | ...   |

### Issues Found

| #   | Severity | Description | Location  |
| --- | -------- | ----------- | --------- |
| 1   | P0/P1/P2 | ...         | file:line |

## Verdict: PASS / NEEDS FIXES
```

6. **Update state.json**
7. If issues found → go to Phase 6
8. If all clear → go to Phase 7

---

## Phase 6: Fix Cycle

**Goal:** Fix QA issues and re-test. Max 3 iterations.

### Process

1. **Read qa-report.md** for issues
2. **Check learnings.json** for known fix patterns matching these error types
3. **For each issue:**
   - Check if a known fix pattern exists in learnings → try it first
   - If no known pattern, investigate root cause
   - Fix using appropriate model (haiku for typos, sonnet for logic bugs)
   - Run typecheck after each fix
   - **Record** the error type and fix applied to learnings.json
4. **Commit fixes:** `fix(feature): resolve QA issues - iteration N`
5. **Re-run QA** (Phase 5)
6. **If still failing after 3 iterations:**
   - Write remaining issues to `qa-remaining.md`
   - Ask user for guidance
7. **Update state.json** with iteration count

---

## Phase 7: Documentation

**Goal:** Document what was built and finalize.

### Process

1. **Write ship-log.md:**

```markdown
# Ship Log: {Feature Name}

## Summary

[What was built in 2-3 sentences]

## Changes

### Files Created

- path/to/file.ts - description

### Files Modified

- path/to/file.ts - what changed

### Database Changes

- Table: {table_name} (new)

### Dependencies Added

- {dependency} ({location})

## QA Summary

- Typecheck: PASS
- QA iterations: 1
- Issues found: 2, all fixed

## Commits

- abc1234 feat(readiness): add database schema
- def5678 feat(readiness): implement service layer
- ...
```

2. **Final commit** if anything uncommitted
3. **Update state.json** → all phases complete
4. **Clean up** team if swarm was used

---

## Context Management

### The 80% Rule

Monitor context usage throughout execution. When approaching limits:

1. **At ~70%:** Finish current task, commit, update state.json
2. **At ~80%:** Stop execution, commit everything, save full state
3. **Tell user:** "Committed all progress through {phase}, {N}/{total} tasks complete. Run `/ship --resume` to continue from where I left off."

### Resume Protocol

When `/ship --resume` or `/ship` finds existing state:

1. Read state.json
2. Read all artifacts (product-spec.md, tech-spec.md, plan.md)
3. Check git status for any uncommitted work
4. Identify next incomplete phase/task
5. Continue from that exact point
6. Skip re-reading files that haven't changed

---

## Model Routing Decision Tree

```
Is this task...
├── Scaffolding, boilerplate, config, translations, re-exports?
│   └── haiku (fast, cheap, good enough)
├── Business logic, API routes, React components, hooks, services?
│   └── sonnet (needs reasoning but not maximum capability)
├── Novel architecture, complex state, debugging tricky issues?
│   └── opus (or keep in main context)
└── Research, codebase exploration, pattern discovery?
    └── Task(agent_type=Explore) with sonnet
```

---

## Usage Examples

```bash
# Ship a new feature from scratch
/ship "Add user notification preferences with email and in-app channels"

# Ship from an existing sprint plan
/ship "Read .claude/ship/sprint-2/plan.md and execute"

# Resume after context clear
/ship --resume

# Ship with specific phase only
/ship --phase=qa    # Only run QA on current state
/ship --phase=fix   # Only run fix cycle
/ship --phase=doc   # Only generate documentation
```

---

## Quick Commands

| Command    | Action                                       |
| ---------- | -------------------------------------------- |
| `status`   | Show current phase, progress, and next steps |
| `skip`     | Skip current task/phase                      |
| `pause`    | Commit and save state for later              |
| `replan`   | Go back to Phase 3 and re-plan               |
| `qa only`  | Jump to Phase 5                              |
| `doc only` | Jump to Phase 7                              |

---

## Integration with Existing Skills

| Skill           | When Used           | How                                                                                   |
| --------------- | ------------------- | ------------------------------------------------------------------------------------- |
| `/cpo-ai-skill` | Phase 1 inspiration | CPO mindset for product analysis (not invoked directly - pattern followed)            |
| `/cto`          | Phase 2 inspiration | CTO mindset for tech decisions (not invoked directly - pattern followed)              |
| QA skill        | Phase 5             | Auto-detected: /qa-sourcerank, /qa-cycle, /fulltest-skill, or generic Chrome DevTools |
| `/verify`       | Phase 4-5           | Typecheck and build verification                                                      |
| `/cpr`          | Phase 7             | Final commit-push-PR if requested                                                     |

**Note:** Rather than invoking CPO/CTO as separate skills (which would fork context), this skill embodies their mindsets directly in Phases 1 and 2. This keeps everything in one context flow.

---

## Learnings System

A two-layer learning system that makes each `/ship` run smarter than the last.

### Layer 1: Project-Local Learnings DB

**File:** `.claude/ship/learnings.json`

Accumulates structured data after every run. Read by Phase 3 (planning), Phase 4 (agent prompts), and Phase 6 (fix cycle).

```json
{
  "runs": [
    {
      "feature": "notification-preferences",
      "date": "2026-02-13",
      "tasks": 8,
      "qaIterations": 2,
      "totalFixesApplied": 3
    }
  ],
  "modelRouting": [
    {
      "taskType": "react-hooks-with-useEffect",
      "assigned": "haiku",
      "shouldBe": "sonnet",
      "reason": "Hook cleanup logic too complex for haiku",
      "count": 2
    }
  ],
  "qaFailures": [
    {
      "pattern": "API route missing input validation",
      "frequency": 3,
      "severity": "P1",
      "preventionHint": "Always add zod schema validation to API routes"
    }
  ],
  "fixPatterns": [
    {
      "errorType": "TypeError: Cannot read property of undefined",
      "rootCause": "Missing null check on optional API response field",
      "fix": "Add optional chaining or early return guard",
      "successRate": 1.0,
      "timesApplied": 4
    }
  ],
  "dependencyGotchas": [
    {
      "package": "date-fns",
      "issue": "v3 breaking change: import paths changed",
      "workaround": "Use date-fns/format instead of date-fns"
    }
  ]
}
```

### Layer 2: Cross-Project MCP Memory

After the retrospective (Phase 7), generalize patterns that aren't project-specific and save to MCP Memory for use across all projects.

**Entity naming:** `ship-learning:{category}`

```javascript
// Save a cross-project learning
mcp__memory__create_entities({
  entities: [
    {
      name: "ship-learning:react-hooks-moderate",
      entityType: "ship-learning",
      observations: [
        "React hooks with useEffect/cleanup are moderate complexity, not simple",
        "Haiku fails on cleanup logic — always route to sonnet",
        "Discovered: 2026-02-13",
        "Source: model-misroute",
        "Applies to: React, Next.js",
        "Use count: 2",
      ],
    },
  ],
});

// Save a QA prevention pattern
mcp__memory__create_entities({
  entities: [
    {
      name: "ship-learning:api-validation-required",
      entityType: "ship-learning",
      observations: [
        "API routes without input validation fail QA 80% of the time",
        "Always include zod/joi validation in API route agent prompts",
        "Discovered: 2026-02-13",
        "Source: qa-failure-pattern",
        "Applies to: Express, Fastify, Next.js API routes",
        "Use count: 3",
      ],
    },
  ],
});
```

### Query Points

| When    | What to query                                                               | Why                                        |
| ------- | --------------------------------------------------------------------------- | ------------------------------------------ |
| Phase 0 | `learnings.json` existence                                                  | Initialize if first run                    |
| Phase 3 | `learnings.json` + `mcp__memory__search_nodes({ query: "ship-learning:" })` | Adjust model routing, add task warnings    |
| Phase 4 | `learnings.json.fixPatterns` + `learnings.json.qaFailures`                  | Enrich agent prompts with prevention hints |
| Phase 6 | `learnings.json.fixPatterns`                                                | Try known fixes before investigating       |
| Phase 7 | Write to both layers                                                        | Capture new learnings                      |

### Phase 7 Extension: Retrospective

After writing ship-log.md, automatically run a retrospective:

1. **Analyze the run:**
   - Which tasks were re-routed? (haiku → sonnet escalation) → record in `modelRouting`
   - Which QA issues were found? → record in `qaFailures`
   - What fixes worked? → record in `fixPatterns`
   - Any dependency issues? → record in `dependencyGotchas`
   - Update run summary in `runs`

2. **Update learnings.json:**
   - Increment `count`/`frequency`/`timesApplied` for existing patterns
   - Add new patterns discovered this run
   - Update `successRate` for fix patterns (did the fix actually work?)

3. **Generalize to MCP Memory:**
   - If a pattern has appeared 2+ times → save as `ship-learning:` entity
   - If a pattern is project-specific → keep only in learnings.json
   - If an existing `ship-learning:` was used → add "Applied in: {project} - {date} - HELPFUL/NOT HELPFUL"

4. **Log to ship-log.md:**
   Append a "Learnings" section:

   ```markdown
   ## Learnings Captured

   - Model routing: 1 correction (hooks: haiku → sonnet)
   - QA patterns: 2 new failure patterns recorded
   - Fix patterns: 1 new fix pattern, 2 existing patterns applied successfully
   - Cross-project: 1 new ship-learning saved to MCP Memory
   ```

---

## Error Recovery

| Situation                   | Action                                     |
| --------------------------- | ------------------------------------------ |
| Typecheck fails after task  | Fix inline, don't proceed until clean      |
| Agent produces wrong output | Re-run with more specific prompt           |
| QA finds critical bugs      | Fix cycle (max 3 iterations)               |
| Context approaching limit   | Commit, save state, tell user to resume    |
| Database migration fails    | Roll back, adjust schema, retry            |
| Dependency conflict         | Investigate, resolve, document in ship-log |

---

## Version

**v3.0.0** — Added Phase -1: Project Init. When no existing project is detected, asks for directory, initializes git, and scaffolds the project before proceeding.
**v2.1.0** — Added two-layer learnings system: project-local learnings.json + cross-project MCP Memory. Each run gets smarter from past runs via model routing corrections, QA failure patterns, fix solutions, and dependency gotchas.
**v2.0.0** — Project-agnostic: auto-detects project type, package manager, commands, and QA skill via Phase 0
