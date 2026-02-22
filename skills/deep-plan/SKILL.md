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
  - Task(agent_type=Explore)
  - Task(agent_type=general-purpose)
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
- Run `tsc --noEmit` after each step

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
2. Implement the change
3. Run `tsc --noEmit` (if TypeScript project) to verify types
4. Update `plan.md` — mark the step as done:
```

### Step 1: [Description] ✅

````
5. Move to the next step

### 3.3 Post-Implementation

After all steps are complete:

1. Run tests if available (`npm test`, `vitest`, etc.)
2. Run typecheck if TypeScript
3. Update `plan.md` with final status:
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

## Rules

- **Never write code before Phase 2 approval** — this is the core principle
- Write to `research.md` and `plan.md` — persistent artifacts over chat
- Be thorough in research — "understand all intricacies" before planning
- Include concrete code snippets in the plan, not just descriptions
- Track progress in `plan.md` during implementation
- If the plan needs to change during implementation, stop and update the plan first
