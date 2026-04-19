---
name: architect
description: "Multi-feature architecture pipeline — parallel implement → verify → review → commit. Triggers on: architect, evolve, implement plan, parallel implement, multi-feature."
user-invocable: true
context: inline
model: opus
effort: high
skills: [verify, review-changes]
allowed-tools:
  - Monitor
  - PushNotification
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - WebSearch
  - WebFetch
  - Skill
  - AskUserQuestion
---

## Purpose

Orchestrate multi-feature architectural changes using parallel worktree agents. Designed for plans with N independent features that can be implemented simultaneously, then verified, reviewed, and shipped as a coherent batch.

## Comparison to /ship

| Dimension   | /architect                                                       | /ship                                        |
| ----------- | ---------------------------------------------------------------- | -------------------------------------------- |
| Scope       | Multiple independent features                                    | Single feature end-to-end                    |
| Parallelism | Yes (worktree per feature)                                       | No (sequential)                              |
| QA/Testing  | Typecheck + build + diff review                                  | Full QA cycle with fix loops                 |
| Best for    | Architecture refactors, config migrations, multi-concern changes | New features, bug fixes, single-concern work |
| Input       | A plan with N items                                              | A feature description                        |

## Usage Examples

```
/architect implement the 5 action items from research.md
/architect evolve the auth module: add JWT refresh, add rate limiting, add audit logging
/architect from plan.md
```

---

## Phase 1: Plan Intake

1. Accept the plan input — one of:
   - Inline text (feature list in the user's message)
   - File path (`research.md`, `plan.md`, any markdown file)
   - Reference to prior session output

2. Parse into discrete, independent features. For each feature extract:
   - **Name** — short slug (e.g. `jwt-refresh`)
   - **Description** — what changes and why
   - **Files to modify** — existing files that need changes
   - **Files to create** — new files required
   - **Implementation spec** — concrete instructions the agent will follow
   - **Commit message** — `feat(name): description` format

3. Validate independence: if any feature depends on another feature's output, split into sequential batches. Handle each batch as a separate parallel round.

4. If the plan is ambiguous or features cannot be cleanly separated, call `AskUserQuestion` to clarify before proceeding.

5. Display the parsed feature list as a numbered table. Get user confirmation (`AskUserQuestion`) before starting Phase 2.

## Phase 2: Parallel Implementation

Spawn one Agent per feature, all in parallel (all Agent calls in a single message):

```
Agent(
  model="sonnet",
  isolation="worktree",
  run_in_background=true,
  prompt="..."
)
```

Each agent prompt must include:

- The feature name and commit message to use
- The exact files to modify and create
- The implementation spec
- Constraints: match existing code style, imports, conventions — read surrounding files first
- Final instruction: commit all changes with the specified commit message

Wait for all background agents to complete. Report results:

- Which features succeeded (worktree path + commit hash)
- Which features failed (error summary)
- If any failed, offer to retry or skip before continuing

**Model tiers:**

- Orchestrator (this session): opus
- Implementation agents: sonnet
- Any explore/discovery sub-agents: haiku

## Phase 3: Verify

Detect the project's build tooling (check `package.json`, `Makefile`, `pyproject.toml`, etc.) and run the appropriate commands sequentially:

1. **Typecheck** — `pnpm typecheck` / `npm run typecheck` / `tsc --noEmit` / equivalent
2. **Build** — `pnpm build` / `npm run build` / equivalent

If either fails:

- Diagnose the error (read the relevant files, trace the failure)
- Fix the issue directly in the main branch (not in worktrees — they are already committed)
- Re-run the failing command
- Repeat until clean

Do not proceed to Phase 4 until both checks pass.

## Phase 4: Review

1. Count the commits from this session: `git log --oneline -N` where N = number of features implemented.
2. Run `git diff HEAD~N` (or `git diff <base-sha>`) to get the full diff.
3. Scan the diff for:
   - Security issues (exposed secrets, injection vectors, missing auth checks)
   - Type safety gaps (missing types, unsafe casts, `any` usage)
   - Missing error handling (uncaught promises, unhandled exceptions)
   - Inconsistencies between features (conflicting patterns, naming mismatches)
   - Obvious regressions

4. Report findings to the user with file:line references.
5. If critical issues are found, fix them before proceeding. Non-critical findings can be noted for follow-up.

## Phase 5: Ship

1. Display the full commit log from this session:

   ```bash
   git log --oneline HEAD~N..HEAD
   ```

2. Ask the user (`AskUserQuestion`):

   > "Ready to ship. Choose:
   >
   > 1. Push to remote + create PR
   > 2. Push to remote only
   > 3. Leave local (done)"

3. Execute based on user choice:
   - **PR:** `git push origin <branch>` then `gh pr create --title "..." --body "..."`
   - **Push only:** `git push origin <branch>`
   - **Local:** report completion summary and stop

---

## Key Rules

1. **Independence is required** — if features share files or depend on each other's output, batch them sequentially. Never run conflicting agents in parallel.
2. **Fail fast** — if a worktree agent fails, report it immediately rather than waiting for all agents to finish.
3. **Verify is mandatory** — typecheck and build must pass before review. Never skip.
4. **Review before ship** — never push without reading the diff.
5. **Preserve patterns** — implementation agents must read surrounding code before writing. Match existing imports, naming, and style conventions.
6. **Model discipline** — sonnet for implementation, haiku for exploration, opus stays in the orchestrator.
7. **Commit hygiene** — each feature gets exactly one commit with a conventional commit message. No squashing needed; the feature set reads naturally in `git log`.
