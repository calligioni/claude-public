---
name: deep-plan
description: "Three-phase research→plan→implement workflow with persistent markdown artifacts and annotation cycles. Deep-reads codebase, writes research.md, generates plan.md with code snippets and trade-offs, iterates on user annotations, then implements. Triggers on: deep plan, plan feature, research and plan, plan this."
argument-hint: "<feature or task description>"
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
  - WebSearch
  - WebFetch
  - Agent
  - AskUserQuestion
  - mcp__firecrawl__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
  mcp__firecrawl__*: { readOnlyHint: true, openWorldHint: true }
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

# Deep Plan — Research → Plan → Implement

A disciplined three-phase workflow that produces persistent markdown artifacts. Never write code until the user has reviewed and approved a written plan.

## Session State & Resumability

This skill persists session state to `.deep-plan-state.json` in the project root. On activation, **always check for an existing state file first**:

```bash
cat .deep-plan-state.json 2>/dev/null
```

### State File Format

```json
{
  "feature": "Feature/task name",
  "startedAt": "2026-02-28T10:00:00Z",
  "currentPhase": "research|plan|implement",
  "research": {
    "status": "pending|in_progress|complete",
    "scopeIdentified": true,
    "filesRead": ["src/auth/login.ts", "src/api/routes.ts"],
    "artifactWritten": false
  },
  "plan": {
    "status": "pending|in_progress|approved",
    "artifactWritten": false,
    "annotationCycles": 0,
    "approvedAt": null
  },
  "implement": {
    "status": "pending|in_progress|complete",
    "stepsTotal": 0,
    "stepsCompleted": 0,
    "lastCompletedStep": null
  },
  "commits": []
}
```

### Resume Logic

```
IF .deep-plan-state.json exists:
  Read state file
  IF currentPhase == "research" AND research.status != "complete":
    → Resume Phase 1 (skip already-read files from research.filesRead)
  IF currentPhase == "plan" AND plan.status == "in_progress":
    → Resume Phase 2 (re-read plan.md, continue annotation cycle)
  IF currentPhase == "implement":
    → Resume Phase 3 (skip completed steps, start from lastCompletedStep + 1)
  Tell user: "Resuming from {currentPhase} phase. {context summary}"
ELSE:
  → Start fresh from Phase 1
```

### State Updates

Update `.deep-plan-state.json` at each checkpoint:

- After identifying scope (Phase 1.1)
- After reading each batch of files (Phase 1.2)
- After writing research.md (Phase 1.3)
- After writing plan.md (Phase 2.1)
- After each annotation cycle (Phase 2.2)
- After plan approval
- After completing each implementation step (Phase 3.2)
- After all steps complete (Phase 3.3)

Track commits made during implementation in the `commits` array for potential revert via `/revert-track`.

---

## Phase 1: Deep Research

Deeply read the relevant parts of the codebase. Understand all intricacies.

### 1.1 Identify Scope

Based on the user's description, determine which files and directories to read:

```
- Entry points (pages, routes, API handlers)
- Data models and schemas
- Related components and utilities
- Configuration files
- Existing tests
```

Use Glob + Grep to find relevant files. Use Task(agent_type=Explore) for broad discovery if needed.

### 1.2 Deep Read

Read every relevant file **in great detail**. Trace data flows, understand edge cases, identify patterns and anti-patterns.

### 1.3 Write research.md

Write findings to `research.md` in the project root:

```markdown
# Research: [Feature/Task Name]

**Date:** [date]
**Scope:** [what was analyzed]

## Current Architecture

[How the relevant system works today. Include file paths and line numbers.]

## Data Flow

[How data moves through the system for this feature area.]

## Existing Patterns

[Patterns already used in the codebase that we should follow.]

## Dependencies

[External libraries, APIs, services involved.]

## Constraints

[Technical limitations, compatibility requirements, things that must NOT change.]

## Key Files

| File              | Purpose        | Relevance        |
| ----------------- | -------------- | ---------------- |
| `path/to/file.ts` | [what it does] | [why it matters] |

## Open Questions

[Anything unclear that needs user input before planning.]
```

Tell the user: "Research written to `research.md` — review it and let me know if anything is missing or wrong."

If there are open questions, use AskUserQuestion to resolve them before proceeding to Phase 2.

## Phase 2: Plan

Generate a detailed implementation plan based on the research.

### 2.1 Write plan.md

Write the plan to `plan.md` in the project root:

````markdown
# Plan: [Feature/Task Name]

**Date:** [date]
**Based on:** research.md
**Estimated files to change:** [N]

## Approach

[2-3 sentences: what we're going to do and why this approach over alternatives.]

## Trade-offs Considered

| Option       | Pros   | Cons   | Verdict                 |
| ------------ | ------ | ------ | ----------------------- |
| [Approach A] | [pros] | [cons] | **Selected** / Rejected |
| [Approach B] | [pros] | [cons] | Selected / **Rejected** |

## Implementation Steps

### Step 1: [Description]

**File:** `path/to/file.ts`
**What:** [specific change]
**Why:** [rationale]

```typescript
// Proposed code or pseudocode
```
````

### Step 2: ...

## Files to Create

| File                  | Purpose        |
| --------------------- | -------------- |
| `path/to/new-file.ts` | [what it does] |

## Files to Modify

| File              | Change         | Lines |
| ----------------- | -------------- | ----- |
| `path/to/file.ts` | [what changes] | ~[N]  |

## Files to Delete

| File            | Reason |
| --------------- | ------ |
| (none expected) |        |

## Testing Strategy

- [ ] [Test 1: what to test and how]
- [ ] [Test 2: ...]

## Rollback Plan

[How to undo this if something goes wrong.]

## Anti-Patterns to Avoid

- No unnecessary comments or jsdocs
- No `any` or `unknown` types
- No disabled linter rules without justification
- Run verify triple (typecheck + tests + build) after each step

```

Tell the user: "Plan written to `plan.md` — review it, add inline annotations (comments, questions, corrections), and I'll iterate."

### 2.2 Annotation Cycle

When the user says they've annotated the plan:

1. Re-read `plan.md`
2. Find all inline annotations (look for `<!-- ... -->`, `// COMMENT:`, `> NOTE:`, or any text that wasn't in the original)
3. Address each annotation — update the plan accordingly
4. Write the updated plan back to `plan.md`
5. Tell the user: "Plan updated — review changes and approve when ready"

Repeat until the user approves. **Do not proceed to Phase 3 without explicit approval.**

## Phase 3: Implement

Execute the approved plan step by step.

### 3.1 Pre-Implementation Checklist

Before writing any code:
- [ ] Plan is approved by user
- [ ] All open questions are resolved
- [ ] Reference implementations identified (if any)

### 3.2 Execute Steps

For each step in the plan:

1. Announce which step you're working on
2. Update `.deep-plan-state.json`: set `implement.status = "in_progress"`, update `implement.lastCompletedStep`
3. Implement the change
4. Run verify triple (skip any that aren't available, fix failures before proceeding):
   - Typecheck: `tsc --noEmit` (TypeScript), `mypy .` (Python), `go build ./...` (Go)
   - Tests: `pnpm test` / `pytest` / `go test ./...` / `cargo test`
   - Build: `pnpm build` / `cargo build` / `go build ./...`
5. Update `.deep-plan-state.json`: increment `implement.stepsCompleted`, add commit SHA to `commits` array
6. Update `plan.md` — mark the step as done:
```

### Step 1: [Description] ✅

````
5. Move to the next step

### 3.3 Post-Implementation

After all steps are complete, run the final verify triple:

1. Run typecheck (skip if unavailable) — must pass
2. Run tests (skip if unavailable) — must pass
3. Run build (skip if unavailable) — must pass
4. Fix any failures before marking complete
5. Update `.deep-plan-state.json`: set `implement.status = "complete"`, `currentPhase = "complete"`
4. Update `plan.md` with final status:
```markdown
## Status: ✅ Complete

**Completed:** [date]
**Files changed:** [list]
**Tests:** [pass/fail]
````

4. Summarize what was done

## Reference-Based Planning

If the user provides reference implementations (open-source repos, blog posts, docs):

1. Read/fetch the reference material in Phase 1
2. Include a "Reference Implementations" section in `research.md`
3. In `plan.md`, note which parts follow the reference and which diverge
4. Use reference patterns as the basis for proposed code snippets

## Model Tier Strategy

Per `model-tier-strategy.md`, subagents spawned by this skill use tiered models:

| Agent Task               | Model  | Rationale                         |
| ------------------------ | ------ | --------------------------------- |
| Orchestrator (this)      | opus   | Deep reasoning, plan synthesis    |
| Explore (scope finding)  | haiku  | File search, grep — deterministic |
| General-purpose research | sonnet | Nuanced investigation             |

When spawning Explore agents, always pass `model: "haiku"`. When spawning general-purpose agents for deeper investigation, use `model: "sonnet"`.

## Rules

- **Never write code before Phase 2 approval** — this is the core principle
- Write to `research.md` and `plan.md` — persistent artifacts over chat
- Be thorough in research — "understand all intricacies" before planning
- Include concrete code snippets in the plan, not just descriptions
- Track progress in `plan.md` during implementation
- If the plan needs to change during implementation, stop and update the plan first
