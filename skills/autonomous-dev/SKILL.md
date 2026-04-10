---
name: autonomous-dev
description: "Autonomous coding agent that breaks features into small user stories and implements them iteratively with fresh context per iteration. Use when asked to: build a feature autonomously, create a PRD, implement a feature from scratch, run an autonomous coding loop, break down a feature into user stories. Triggers on: autonomous agent, build this autonomously, autonomous mode, implement this feature, create prd, prd to json, user stories, iterative implementation, ralph."
user-invocable: true
context: fork
memory: project
effort: high
---

# Autonomous Coding Agent

An autonomous workflow that breaks features into small, testable user stories and implements them one at a time with fresh context per iteration.

## Core Architecture

**Memory persists across iterations via:**

- `prd.json` - Task list with completion status
- `progress.md` - Learnings and implementation notes
- `AGENTS.md` - Long-term patterns for the repository
- Git history - All code changes
- **Memory MCP** - Cross-codebase learnings (patterns, mistakes, preferences)

**Each iteration is stateless** - read these files to understand context.

---

## Memory Integration (Cross-Codebase Learning)

The agent uses the Memory MCP server to learn across different projects. This enables:

- Remembering patterns that work well
- Avoiding mistakes made in other codebases
- Applying user preferences consistently

### Memory Entity Types

| Type                    | Purpose                      | Example                              |
| ----------------------- | ---------------------------- | ------------------------------------ |
| `pattern`               | Reusable solutions           | `pattern:early-returns`              |
| `mistake`               | Things to avoid              | `mistake:env-in-repo`                |
| `preference`            | User's preferred approaches  | `preference:package-manager`         |
| `tech-insight`          | Framework-specific knowledge | `tech-insight:supabase-rls`          |
| `architecture-decision` | High-level design choices    | `architecture-decision:multi-tenant` |

### When to Query Memory

1. **Phase 1 Start** - Query preferences and patterns before asking clarifying questions
2. **Phase 3 Start** - Load relevant tech-insights for the detected stack
3. **Before Implementation** - Check for related mistakes/patterns

### When to Save to Memory

1. **After successful story** - Extract reusable patterns
2. **After fixing a bug** - Save as mistake to avoid
3. **When discovering codebase convention** - Save if broadly applicable

---

## Entry Point Detection

When this skill activates, determine which phase to enter:

| Condition                              | Action                                     |
| -------------------------------------- | ------------------------------------------ |
| No `prd.json` exists                   | Start Phase 1 (PRD Generation)             |
| `prd.json` exists but no markdown PRD  | Start Phase 2 (JSON Conversion)            |
| `prd.json` exists with pending stories | Start Phase 3 (Autonomous Loop)            |
| All stories `passes: true`             | Report completion, ask if more work needed |

**First Action:** Check for existing files:

```bash
ls -la prd.json progress.md tasks/*.md 2>/dev/null
```

---

## Phase 1: PRD Generation

**Goal:** Create a Product Requirements Document from a feature idea.

### Step 1.0: Load User Preferences from Memory

**First action:** Query the Memory MCP for user preferences and patterns:

```
mcp__memory__search_nodes({ query: "preference" })
mcp__memory__search_nodes({ query: "pattern" })
mcp__memory__search_nodes({ query: "architecture-decision" })
```

**Apply learned preferences:**

- Package manager preference (pnpm vs npm vs yarn)
- Deployment targets (Railway, Vercel, Cloudflare)
- Code organization patterns (feature folders, etc.)
- Testing preferences

These preferences inform your clarifying questions and PRD structure.

### Step 1.1: Parallel Research Phase

Before asking questions, spawn **parallel research subagents** to gather comprehensive context. This happens in a SINGLE message with MULTIPLE Task calls for true parallelism:

```xml
<!-- Spawn these research agents IN PARALLEL -->
<Task subagent_type="Explore" prompt="
CODEBASE PATTERN ANALYZER

Analyze this codebase to understand existing patterns:

1. **Project Structure**
   - What's the folder organization? (feature-based, layer-based, etc.)
   - Where do components/modules live?
   - How are tests organized?

2. **Code Patterns**
   - How are API endpoints structured?
   - What state management is used?
   - How is error handling done?
   - What's the logging approach?

3. **Conventions**
   - Naming conventions (camelCase, snake_case, etc.)
   - File naming patterns
   - Import organization
   - Comment/documentation style

4. **Dependencies**
   - Key libraries/frameworks in use
   - Version patterns (pinned, ranges, etc.)

Return a structured summary I can use to match existing patterns.
"/>

<Task subagent_type="Explore" prompt="
BEST PRACTICES RESEARCHER

For this codebase's detected stack, research current best practices:

1. **Detect Stack**: Look at package.json, requirements.txt, go.mod, etc.

2. **Query Memory** for existing learnings:
   - mcp__memory__search_nodes({ query: '[detected-framework]' })
   - mcp__memory__search_nodes({ query: 'pattern' })
   - mcp__memory__search_nodes({ query: 'mistake' })

3. **Check .solutions/ directory** for previously documented solutions

4. **Identify Anti-Patterns** to avoid based on:
   - Memory MCP 'mistake' entries
   - Common pitfalls for the detected stack

Return: Patterns to follow, mistakes to avoid, relevant prior solutions.
"/>

<Task subagent_type="Explore" prompt="
FRAMEWORK DOCS RESEARCHER

For the feature being built, research official documentation:

1. **Identify relevant frameworks** from the codebase

2. **Use Context7 MCP** to fetch current documentation:
   - mcp__context7__resolve-library-id for each major dependency
   - mcp__context7__query-docs for feature-relevant topics

3. **Focus on**:
   - Official recommended patterns for the feature type
   - API references for libraries we'll use
   - Migration guides if upgrading patterns

Return: Key documentation excerpts and official recommendations.
"/>
```

**Research Output Integration:**

After parallel research completes, synthesize findings into:

```markdown
## Research Summary

### Codebase Patterns (must follow)
- [Pattern 1 from codebase analyzer]
- [Pattern 2]

### Best Practices (should follow)
- [Practice 1 from best practices researcher]
- [Practice 2]

### Framework Guidance (reference)
- [Doc excerpt 1 from framework docs researcher]
- [Doc excerpt 2]

### Mistakes to Avoid
- [Mistake 1 from Memory MCP]
- [Mistake 2]

### Relevant Prior Solutions
- [Link to .solutions/related-feature.md if exists]
```

This research informs both the clarifying questions and the PRD structure.

### Step 1.2: Clarifying Questions

Ask 3-5 essential questions with lettered options:

```
I'll help you build [feature]. First, a few quick questions:

1. What's the primary goal?
   A. [Goal 1]  B. [Goal 2]  C. [Goal 3]  D. Other

2. Who's the target user?
   A. [User type 1]  B. [User type 2]  C. All users  D. Other

3. What's the scope?
   A. MVP only  B. Full-featured  C. Backend only  D. Frontend only

Reply with: "1A, 2C, 3B" (or type your own answers)
```

### Step 1.3: Generate PRD

Create `tasks/prd-[feature-name].md`:

```markdown
# PRD: [Feature Name]

## Overview

Brief description of the feature and its value.

## Goals

- Specific, measurable objective 1
- Specific, measurable objective 2

## Non-Goals

- Explicitly what this feature will NOT do
- Scope boundaries

## User Stories

### US-001: [Title]

**Description:** As a [user type], I want [capability] so that [benefit].

**Acceptance Criteria:**

- [ ] Specific, verifiable criterion
- [ ] Another testable criterion
- [ ] Typecheck passes
- [ ] Tests pass (if applicable)

### US-002: [Title]

...

## Technical Approach

- Key architectural decisions
- Integration points with existing code
- Dependencies between stories

## Success Metrics

How we'll know this feature is working correctly.
```

**Story Sizing Rules:**

| Right-sized (1 iteration)         | Too big (split)             |
| --------------------------------- | --------------------------- |
| Add a database column             | Build entire dashboard      |
| Create single API endpoint        | Add authentication system   |
| Add UI component to existing page | Refactor the API            |
| Add filter dropdown               | Complete feature end-to-end |

**Rule:** If you can't describe the change in 2-3 sentences, split it.

### Step 1.4: Get Approval

```
I've created the PRD at `tasks/prd-[feature-name].md`.

Summary:
- [N] user stories identified
- Estimated complexity: [Low/Medium/High]
- Key dependencies: [list]

Please review the PRD. Reply with:
- "approved" - Convert to prd.json and begin implementation
- "edit [story]" - Modify a specific story
- "add [story]" - Add a new story
- "questions" - Ask me anything about the approach
```

---

## Phase 2: JSON Conversion

**Goal:** Convert approved PRD to machine-readable `prd.json`.

### Step 2.1: Archive Previous Run (if needed)

```bash
# If prd.json exists with different branch
if [ -f prd.json ]; then
  BRANCH=$(jq -r '.branchName' prd.json)
  if [ "$BRANCH" != "current-branch-name" ]; then
    mkdir -p archive/$(date +%Y-%m-%d)-$BRANCH
    mv prd.json progress.md archive/$(date +%Y-%m-%d)-$BRANCH/
  fi
fi
```

### Step 2.2: Create Feature Branch

```bash
git checkout -b feature/[feature-name]
```

### Step 2.2a: Create Feature Worktree (Optional)

If `.worktree-scaffold.json` exists in the project root, create an isolated worktree for this feature. This keeps development separate from the main working directory.

**When to use worktrees:**
- Large features with many stories
- Features that need isolation from other work
- Parallel feature development

**How to create:**

```bash
# Check if worktree-scaffold config exists
if [ -f .worktree-scaffold.json ]; then
  # Read config
  WORKTREE_DIR=$(jq -r '.worktreeDir // "../"' .worktree-scaffold.json)
  BRANCH_PREFIX=$(jq -r '.branchPrefix // "feature/"' .worktree-scaffold.json)

  # Feature name without prefix
  FEATURE_NAME="${BRANCH_NAME#${BRANCH_PREFIX}}"
  WORKTREE_PATH="${WORKTREE_DIR}${FEATURE_NAME}"

  # Create worktree
  git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"

  # Run scaffolding if configured
  SCAFFOLD_TYPE=$(jq -r '.defaultScaffold // "default"' .worktree-scaffold.json)
  # Generate scaffold files based on config templates

  echo "Worktree created at: $WORKTREE_PATH"
  echo "Continuing autonomous loop in worktree..."
  cd "$WORKTREE_PATH"
fi
```

**Store worktree info in prd.json:**

```json
{
  "worktree": {
    "enabled": true,
    "path": "../feature-name",
    "mainRepoPath": "/original/repo/path"
  }
}
```

### Step 2.3: Generate prd.json

```json
{
  "project": "[Project Name]",
  "branchName": "feature/[feature-name]",
  "description": "[Feature description]",
  "createdAt": "2024-01-15T10:00:00Z",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Title]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Specific criterion 1",
        "Typecheck passes",
        "Tests pass"
      ],
      "priority": 1,
      "dependsOn": [],
      "passes": false,
      "attempts": 0,
      "notes": ""
    }
  ]
}
```

### Step 2.4: Initialize Progress File

Create `progress.md`:

```markdown
# Progress Log: [Feature Name]

Branch: `feature/[feature-name]`
Started: [Date]

---
```

### Step 2.5: Detect Verification Commands

Scan the codebase to find the right commands:

```bash
# Check for common patterns
grep -l "typecheck\|tsc\|type-check" package.json 2>/dev/null
grep -l "test\|jest\|vitest\|pytest" package.json pyproject.toml 2>/dev/null
grep -l "lint\|eslint" package.json 2>/dev/null
```

Store in prd.json:

```json
{
  "verification": {
    "typecheck": "npm run typecheck",
    "test": "npm run test",
    "lint": "npm run lint",
    "build": "npm run build"
  }
}
```

---

## Phase 3: Autonomous Loop

**Goal:** Implement one story per iteration until complete.

### Step 3.0: Load Context

At the start of EVERY iteration:

```bash
# Read current state
cat prd.json
cat progress.md
cat AGENTS.md 2>/dev/null
```

**Load cross-codebase learnings:**

```
# Query memory for relevant insights based on detected tech stack
mcp__memory__search_nodes({ query: "[detected-framework]" })  # e.g., "nextjs", "fastapi"
mcp__memory__search_nodes({ query: "mistake" })               # Avoid past mistakes
mcp__memory__search_nodes({ query: "pattern" })               # Apply known patterns
```

**Stack detection -> memory queries:**

| Detected Stack | Memory Queries                         |
| -------------- | -------------------------------------- |
| Next.js        | `nextjs`, `react`, `server-components` |
| Supabase       | `supabase`, `rls`, `postgres`          |
| FastAPI        | `fastapi`, `python`, `api`             |
| React          | `react`, `hooks`, `state-management`   |

Find the next story: first `passes: false` ordered by `priority`, respecting `dependsOn`.

### Step 3.1: Announce Task

```
## Starting: US-[XXX] - [Title]

**Goal:** [One-line description]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Typecheck passes

**Approach:** [2-3 sentences on how you'll implement this]
```

### Step 3.2: Implement Code

1. Read relevant existing files first
2. Follow patterns from `AGENTS.md` and existing code
3. Write code for ONLY this user story
4. Keep changes minimal and focused

**Implementation Checklist:**

- [ ] Read existing code patterns first
- [ ] Make minimal necessary changes
- [ ] Add tests if acceptance criteria requires them
- [ ] Don't refactor unrelated code

### Step 3.3: Run Verification

Execute verification commands from prd.json:

```bash
# Run typecheck
npm run typecheck

# Run tests (if applicable to this story)
npm run test

# Run lint (optional but recommended)
npm run lint
```

### Step 3.4: Handle Results

**If verification passes:**

1. Update `prd.json`:

   ```json
   {
     "passes": true,
     "attempts": 1,
     "completedAt": "2024-01-15T11:30:00Z"
   }
   ```

2. Commit the work:

   ```bash
   git add -A
   git commit -m "feat(US-XXX): [Title]

   - [What was implemented]
   - [Key decisions made]"
   ```

3. Update `progress.md`:

   ```markdown
   ## [Timestamp] - US-XXX: [Title]

   **Implementation:**

   - [What was done]
   - [Files changed]

   **Learnings:**

   - [Patterns discovered]
   - [Gotchas encountered]

   ---
   ```

4. **Extract and save learnings to Memory:**

   After each successful story, evaluate if any learnings are broadly applicable:

   ```
   # Ask yourself:
   # 1. Did I discover a pattern that would help in other projects?
   # 2. Did I make a mistake that should be avoided elsewhere?
   # 3. Did I learn something about a framework/tool?

   # If yes, save to memory:
   mcp__memory__create_entities({
     entities: [{
       name: "pattern:descriptive-name",
       entityType: "pattern",
       observations: [
         "What the pattern is",
         "When to apply it",
         "Applies to: [frameworks/languages]"
       ]
     }]
   })
   ```

   **Learning extraction criteria:**

   | Save as                 | When                                      |
   | ----------------------- | ----------------------------------------- |
   | `pattern`               | Solution worked well and is reusable      |
   | `mistake`               | Made an error, had to fix it              |
   | `tech-insight`          | Learned something about a specific tool   |
   | `architecture-decision` | Made a structural choice that proved good |

   **Skip saving if:**
   - Learning is project-specific (put in AGENTS.md instead)
   - Already exists in memory (check first)
   - Too trivial to be useful

5. Check completion and continue:

   ```
   US-XXX complete. [N] stories remaining.

   Continuing to next story...
   ```

**If verification fails:**

1. Increment attempts: `"attempts": N+1`

2. Analyze failure:

   ```
   Verification failed for US-XXX (attempt N).

   Error: [error message]

   Analysis: [what went wrong]

   Fix: [what I'll change]
   ```

3. If `attempts < 3`: Fix and retry step 3.3

4. **After fixing a failure, save the mistake to memory:**

   ```
   mcp__memory__create_entities({
     entities: [{
       name: "mistake:descriptive-name",
       entityType: "mistake",
       observations: [
         "What went wrong: [description]",
         "How to avoid: [prevention strategy]",
         "Applies to: [frameworks/languages]",
         "Severity: [low/medium/high/critical]"
       ]
     }]
   })
   ```

5. If `attempts >= 3`:

   ```
   US-XXX failed after 3 attempts.

   Last error: [message]

   Options:
   1. Split this story into smaller pieces
   2. Get user help with the blockers
   3. Skip and continue with next story
   4. Pause autonomous mode

   What would you like to do?
   ```

### Step 3.5: Completion Check

After each story:

```javascript
const remaining = stories.filter((s) => !s.passes);
if (remaining.length === 0) {
  // All done!
  output("COMPLETE");
} else {
  // Continue to next story
  continueLoop();
}
```

**When all stories complete:**

```
===== FEATURE COMPLETE =====

Branch: feature/[name]
Stories completed: [N]
Total commits: [M]

Summary:
- [Key accomplishments]
- [Files changed]

Next steps:
1. Review the changes: git log --oneline feature/[name]
2. Run full test suite: npm test
3. Create PR when ready: gh pr create

Would you like me to:
A. Run code review (spawn parallel reviewers)
B. Create a pull request
C. Show a detailed summary
D. Continue with more features
E. Clean up worktree (if used)
```

### Step 3.6: Code Review Phase (Recommended)

Before creating a PR, spawn the **code-review-agent** to get multi-perspective feedback:

```xml
<Task subagent_type="code-review-agent" prompt="
Review the changes on branch feature/[name] before PR submission.

Changed files: [list from git diff --name-only main...HEAD]
Feature context: [brief description]

Run parallel specialist reviewers and return synthesized findings.
"/>
```

The code review agent will spawn parallel reviewers (security, performance, architecture, stack-specific) and return:
- Critical issues (must fix before PR)
- High priority suggestions
- Auto-fixable improvements

**If critical issues found:** Fix them before proceeding to PR.

**If clean:** Proceed to PR creation.

### Step 3.7: Solution Documentation (Knowledge Compounding)

**Philosophy:** "First time: 30 minutes. Documented: next time is 5 minutes."

After completing a non-trivial feature, document the solution for future reuse:

```bash
# Create solutions directory if it doesn't exist
mkdir -p .solutions
```

**Create `.solutions/[feature-name].md`:**

```markdown
# Solution: [Feature Name]

**Date:** [YYYY-MM-DD]
**Branch:** feature/[name]
**Complexity:** [Low/Medium/High]

## Problem

What problem did this feature solve? What was the user need?

- [Problem statement]
- [Context/constraints]

## Solution

How did we solve it?

### Approach

[2-3 paragraphs explaining the approach taken]

### Key Files

| File | Purpose |
|------|---------|
| `path/to/file.ts` | [What this file does] |
| `path/to/other.ts` | [What this file does] |

### Code Snippets

Key implementation patterns worth remembering:

```[language]
// [Description of what this does]
[relevant code snippet]
```

## Gotchas & Edge Cases

Things that tripped us up or required special handling:

1. **[Gotcha 1]**: [Description and how we handled it]
2. **[Gotcha 2]**: [Description and how we handled it]

## Testing Strategy

How we verified this works:

- [Test type 1]: [What it covers]
- [Test type 2]: [What it covers]

## Future Improvements

Things we'd do differently or enhance later:

- [ ] [Improvement 1]
- [ ] [Improvement 2]

## Related

- [Link to similar solutions]
- [Relevant Memory MCP entities]
- [External documentation references]
```

**When to Create Solution Docs:**

| Feature Type | Document? |
|--------------|-----------|
| New major feature | Yes |
| Complex integration | Yes |
| Tricky bug fix | Yes (as mini-doc) |
| Simple CRUD | No |
| Config change | No |
| Minor UI tweak | No |

**Also save to Memory MCP** for cross-project learning:

```
mcp__memory__create_entities({
  entities: [{
    name: "solution:[feature-name]",
    entityType: "solution",
    observations: [
      "Problem: [brief problem statement]",
      "Approach: [key approach taken]",
      "Stack: [frameworks/languages used]",
      "Gotcha: [main gotcha encountered]",
      "Location: .solutions/[feature-name].md"
    ]
  }]
})
```

### Step 3.9: Worktree Cleanup (If Used)

If the feature was developed in a worktree, offer cleanup:

```bash
# Check if worktree was used
if [ -n "$(jq -r '.worktree.path // empty' prd.json)" ]; then
  WORKTREE_PATH=$(jq -r '.worktree.path' prd.json)
  MAIN_REPO=$(jq -r '.worktree.mainRepoPath' prd.json)

  echo "Feature developed in worktree: $WORKTREE_PATH"
  echo ""
  echo "Cleanup options:"
  echo "1. Keep worktree (for future reference)"
  echo "2. Remove worktree, keep branch"
  echo "3. Remove worktree and merge branch to main"
fi
```

**To remove worktree:**

```bash
# From main repo
cd "$MAIN_REPO"
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

---

## Error Recovery

### Story Breaks Previous Functionality

```
Detected: Tests that passed before are now failing.

Affected tests: [list]

Options:
1. Rollback this story: git reset --hard HEAD~1
2. Fix the regression before continuing
3. Mark as known issue and continue
```

### Context Overflow Prevention

If a story is taking too many tokens:

1. Commit partial progress
2. Log current state to `progress.md`
3. Suggest splitting the story

### Stuck on Dependencies

If a story needs something not yet implemented:

1. Check if dependency story exists
2. If not, suggest adding it as US-00X
3. Reorder priorities if needed

---

## Key Files Reference

| File                        | Purpose                          | Created            |
| --------------------------- | -------------------------------- | ------------------ |
| `tasks/prd-*.md`            | Human-readable PRD               | Phase 1            |
| `prd.json`                  | Machine-readable task list       | Phase 2            |
| `progress.md`               | Append-only learnings            | Phase 2+           |
| `AGENTS.md`                 | Long-term repo patterns          | Anytime            |
| `.solutions/`               | Documented solutions for reuse   | After feature      |
| `archive/`                  | Previous completed PRDs          | Before new feature |
| `.worktree-scaffold.json`   | Worktree config (optional)       | User creates       |

---

## Worktree Integration

The autonomous-agent integrates with the `worktree-scaffold` skill for parallel development.

**Setup worktree support:**

1. Create `.worktree-scaffold.json` in project root (run `/worktree-scaffold` → `init worktree config`)
2. The agent will detect this file in Phase 2 and offer worktree creation
3. Each feature gets its own isolated workspace

**Benefits:**
- Isolate feature development from main repo
- Work on multiple features in parallel
- Keep main directory clean during development

**See also:** `/worktree-scaffold` skill for standalone worktree management.

---

## AGENTS.md Patterns to Document

When you discover patterns, add them to AGENTS.md:

```markdown
# Repository Patterns

## API Conventions

- All endpoints use REST conventions
- Error responses follow format: { error: string, code: number }

## Component Patterns

- UI components in src/components/
- Server actions in src/actions/

## Database

- Migrations in db/migrations/
- Schema in db/schema.ts

## Testing

- Unit tests alongside source files
- Integration tests in tests/

## Gotchas

- Must run db:generate after schema changes
- Server actions need revalidatePath for cache
```

---

## Quick Commands

| Command         | What it does                         |
| --------------- | ------------------------------------ |
| "status"        | Show current progress and next story |
| "skip"          | Skip current story, move to next     |
| "pause"         | Stop autonomous mode, wait for input |
| "split [story]" | Break a story into smaller pieces    |
| "retry"         | Retry the current story              |
| "complete"      | Force-mark current story as done     |

---

## Examples

See [references/examples.md](references/examples.md) for:

- Story splitting patterns
- Acceptance criteria templates
- Complete prd.json examples
- progress.md format
