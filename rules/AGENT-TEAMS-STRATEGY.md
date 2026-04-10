# Agent Teams Migration Strategy

A practical strategy for integrating Agent Teams into the Claude Code skills system. Focuses on cost-effectiveness, minimal over-engineering, and incremental rollout.

**Created:** 2026-02-05
**Status:** Draft

---

## Table of Contents

1. [Evaluation Matrix: Which Skills Migrate](#1-evaluation-matrix)
2. [Decision Framework: Teams vs Subagents](#2-decision-framework)
3. [Token Minimization Techniques](#3-token-minimization)
4. [Implementation Patterns](#4-implementation-patterns)
5. [Phased Rollout Plan](#5-phased-rollout)

---

## 1. Evaluation Matrix

### Scoring Criteria

Each skill is scored on three dimensions (1-5 scale):

| Criterion              | Description                                                     | Weight |
| ---------------------- | --------------------------------------------------------------- | ------ |
| **Communication Need** | Do workers need to talk to each other, or just report results?  | 40%    |
| **Independence**       | Can workers operate on separate files/areas without conflict?   | 30%    |
| **Token ROI**          | Does the parallelism payoff justify N separate context windows? | 30%    |

### Skill-by-Skill Evaluation

| Skill              | Comm Need | Independence | Token ROI | Weighted | Verdict                 |
| ------------------ | --------- | ------------ | --------- | -------- | ----------------------- |
| **cto**            | 4         | 5            | 3         | 3.9      | **Hybrid**              |
| **fulltest-skill** | 3         | 5            | 2         | 3.2      | **Stay subagents**      |
| **parallel-dev**   | 2         | 5            | 4         | 3.5      | **Migrate**             |
| **cpo-ai-skill**   | 2         | 4            | 2         | 2.6      | **Stay subagents**      |
| **review-changes** | 1         | N/A          | 1         | 1.0      | **Stay single session** |
| **cpr**            | 1         | N/A          | 1         | 1.0      | **Stay single session** |
| **test-and-fix**   | 1         | N/A          | 1         | 1.0      | **Stay single session** |
| **website-design** | 1         | N/A          | 1         | 1.0      | **Stay single session** |

### Verdicts Explained

#### MIGRATE to Agent Teams: `parallel-dev`

**Why:** This is the strongest candidate. Features run in isolated git worktrees -- perfect file independence, zero conflict risk. Teammates working on `feature/auth` and `feature/notifications` never touch the same files. The current Task-based approach means the orchestrator gets no real-time updates; Agent Teams gives teammates the ability to message the lead when they hit blockers or finish, and to message each other when cross-feature coordination is needed (e.g., "I'm exposing the user API at `/api/users` -- use this endpoint"). The worktree isolation eliminates the biggest Agent Teams risk (file conflicts) entirely.

**Token justification:** Each feature agent needs its own context anyway (reading the full codebase for its worktree). The coordination overhead is offset by real-time messaging replacing the polling loop in Phase 4 of the current implementation.

#### HYBRID (Teams for complex, subagents for simple): `cto`

**Why:** The CTO skill has two modes -- sequential and swarm. Sequential mode (focused questions like "Is our auth secure?") should remain a single session. Swarm mode (full codebase review) already describes inter-analyst communication (security telling performance about N+1 queries, stack telling security about vulnerable deps). This cross-concern detection genuinely benefits from Agent Teams' direct messaging. However, a simple "review the auth module" does not need five separate context windows.

**Token justification:** Swarm mode already burns 5x context. The question is whether Agent Teams' messaging overhead is worth the real-time cross-concern detection. For full reviews: yes. For focused reviews: no.

#### STAY with subagents: `fulltest-skill`

**Why:** Despite the skill already documenting a "swarm mode" with TeammateTool, the actual testing workflow is report-back, not collaborative. Tester-3 finds a CSS 404 and broadcasts it -- but other testers just skip that check. This is a notification, not a discussion. Subagents can achieve this by writing results to a shared file that the orchestrator reads. The fixers (CSS fixer, JS fixer) similarly just report completion. No real inter-agent reasoning happens.

**Token justification:** With 15 page testers, Agent Teams would spawn 15 full context windows. Each page test is lightweight (navigate, check console, check network, screenshot). The per-tester token cost far exceeds the benefit vs. batched Task calls (3-5 pages per subagent).

#### STAY with subagents: `cpo-ai-skill`

**Why:** The CPO skill orchestrates sequential phases (Discovery, Planning, Execution). Within execution, it spawns specialist subagents (frontend-design-agent, backend-api-agent, database-setup-agent) that work on different stages. These agents do not need to discuss with each other -- they implement their assigned stage and report back. The CPO lead synthesizes. This is exactly the subagent model: focused tasks, only the result matters.

**Token justification:** CPO sessions are already extremely long and token-heavy (full product lifecycle). Adding Agent Teams overhead to an already expensive workflow is wasteful. The subagent model (results summarized back) is more token-efficient here.

#### STAY single session: `review-changes`, `cpr`, `test-and-fix`, `website-design`

**Why:** These skills are single-purpose, fast, and sequential. No parallelism needed. Adding any multi-agent coordination would be pure overhead.

---

## 2. Decision Framework

Use this flowchart before adding Agent Teams to any skill, current or future:

```
START: Does the skill spawn multiple workers?
  │
  NO ──► Single session. Stop here.
  │
  YES
  │
  ▼
Do workers need to DISCUSS findings with each other?
(Not just report back, but react to each other's output)
  │
  NO ──► Use subagents (Task tool). Stop here.
  │
  YES
  │
  ▼
Can workers operate on SEPARATE files/directories?
  │
  NO ──► Use subagents with sequential hand-off.
  │       Agent Teams + file conflicts = wasted tokens on merge failures.
  │
  YES
  │
  ▼
Is the task COMPLEX enough to justify N full context windows?
(Rule of thumb: each teammate costs ~$0.50-2.00 in tokens)
  │
  NO ──► Use subagents. The discussion benefit doesn't justify the cost.
  │
  YES
  │
  ▼
USE AGENT TEAMS.
```

### Quick Reference Table

| Signal                              | Use This                          |
| ----------------------------------- | --------------------------------- |
| Workers report results only         | Subagents                         |
| Workers need to react to each other | Agent Teams                       |
| Same files being edited             | Subagents (sequential)            |
| Isolated directories/worktrees      | Agent Teams candidate             |
| < 3 workers                         | Subagents (overhead not worth it) |
| > 5 workers                         | Subagents (token cost explodes)   |
| 3-5 workers with cross-talk         | Agent Teams sweet spot            |

### The "3-5 Rule"

Agent Teams are cost-effective with **3-5 teammates**. Below 3, the coordination overhead exceeds the benefit. Above 5, token costs scale linearly but coordination quality degrades (broadcast messages flood everyone, the lead struggles to synthesize).

---

## 3. Token Minimization Techniques

### 3.1 Spawn Prompt Engineering

**Bad: Kitchen-sink context**

```
Create a teammate called "security-reviewer" with access to the full
codebase. Review all files for security issues. Check OWASP Top 10,
authentication, authorization, input validation, output encoding,
session management, CSRF, XSS, SQL injection, secrets management,
dependency vulnerabilities, security headers, encryption at rest,
encryption in transit, PII handling...
```

**Good: Minimal, focused context**

```
Spawn teammate "security-reviewer":
Review src/auth/ and src/api/ for auth bypass and injection risks.
Key files: src/auth/jwt.ts, src/api/middleware.ts, src/api/routes/*.ts
Report: severity, file:line, issue, fix. Message lead when done.
```

**Rules for spawn prompts:**

1. Name the specific directories/files to review -- do not say "full codebase"
2. List 2-3 priority checks, not exhaustive checklists
3. Tell the teammate what format to report in
4. Tell them when to message (on completion, on critical findings) vs. when to stay silent

### 3.2 Messaging Discipline

| Pattern             | When                                   | Token Cost                      |
| ------------------- | -------------------------------------- | ------------------------------- |
| **Direct message**  | One teammate needs info from one other | Low (2 context windows touched) |
| **Message to lead** | Reporting findings or completion       | Low (1 + lead)                  |
| **Broadcast**       | Genuinely affects all teammates' work  | High (all N context windows)    |

**Never broadcast for:**

- Progress updates ("I'm 50% done") -- the lead gets idle notifications
- Individual findings ("I found a bug in file X") -- message the lead only
- Acknowledgments ("Got it, thanks") -- pure token waste

**Only broadcast for:**

- Blocking discoveries that change everyone's approach ("The database schema is completely different from what we assumed")
- Shared resource conflicts ("I'm modifying the config file, everyone else wait")

### 3.3 Early Shutdown

Teammates do not self-terminate. The lead must ask them to shut down. Build these patterns into your orchestration:

```
When spawning the team, include in the lead's instructions:
"After each teammate reports completion, immediately ask them to shut down.
Do not wait for all teammates before shutting down finished ones."
```

**Why this matters:** An idle teammate still consumes tokens in its context window for every subsequent message it receives, including broadcasts. Shutting down finished teammates before others complete saves significant tokens.

### 3.4 Task Granularity

**Bad:** 1 task per teammate (too coarse, no checkpoint)

```
Task 1: "Review entire backend for issues"
```

**Good:** 3-5 tasks per teammate (checkpoints, reassignable)

```
Task 1: "Review auth module for bypass risks"
Task 2: "Review API routes for injection"
Task 3: "Review middleware for missing validation"
Task 4: "Check dependency versions for CVEs"
```

This lets the lead:

- Track progress without asking
- Reassign unfinished tasks if a teammate gets stuck
- Shut down teammates who finish their batch early

### 3.5 Avoid Re-Reading

When spawning teammates that need codebase context, pre-compute and include key information in the spawn prompt instead of making each teammate discover it independently:

```
Spawn teammate "perf-reviewer":
Tech stack: Next.js 15, Prisma 6, PostgreSQL
Database models: User, Order, Product, OrderItem (see prisma/schema.prisma)
Known bottleneck: orders query on line 78 of src/services/orders.ts
Focus: N+1 queries, missing indexes, uncached expensive operations.
```

Each teammate reading `package.json`, running `find`, and exploring the directory structure wastes tokens that the lead already spent gathering.

---

## 4. Implementation Patterns

### 4.1 CTO Skill: Hybrid Pattern

**Modification to SKILL.md header:**

```yaml
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - WebSearch
  - WebFetch
  - Task # Keep for sequential mode
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeammateTool # Add for swarm mode
  - AskUserQuestion
  - mcp__memory__*
```

**Mode selection logic (add to Step 3 of the workflow):**

```
IF user asks focused question OR specifies single area:
  → Sequential mode (single session, no spawning)

ELSE IF user asks for full review AND TeammateTool is available:
  → Agent Teams mode (spawn 3-4 specialist teammates)

ELSE IF user asks for full review AND TeammateTool is NOT available:
  → Subagent mode (spawn via Task tool, current behavior)
```

**Agent Teams implementation for swarm mode:**

```
Create a team with 4 specialist reviewers for this codebase:

1. "security" - Focus on auth, injection, secrets in: {auth_files}, {api_files}
2. "architecture" - Focus on coupling, patterns in: {src_dirs}
3. "performance" - Focus on queries, caching in: {db_files}, {api_files}
4. "quality" - Focus on tests, debt, conventions in: {test_files}, {src_dirs}

Rules for all teammates:
- Report findings as: severity | file:line | issue | recommendation
- Message the lead with critical findings immediately
- Message another teammate directly ONLY if your finding affects their domain
  (e.g., security finds auth bypass → message architecture about design flaw)
- Do NOT broadcast. Use direct messages only.
- When done, message the lead with your summary and shut down.
```

**Key difference from current swarm approach:** The current SKILL.md describes 5 analysts with elaborate JSON message schemas. The Agent Teams version drops to 4 (stack-analyst findings can be folded into security and quality) and uses natural language messages instead of structured JSON. Agent Teams handles the coordination infrastructure -- no need to define `can_message` arrays or `TeammateTool.sync()` calls, which are aspirational pseudocode anyway.

**What to remove from the current SKILL.md:**

- Section 3.2 (Inter-Analyst Communication) -- replace with "teammates message each other directly using natural language"
- Section 3.3 (Live Progress Dashboard) -- the lead tracks progress via the shared task list
- Section 3.4 (Swarm Synchronization) -- Agent Teams handles this via idle notifications
- The elaborate `TeammateTool.message()` and `TeammateTool.sync()` pseudocode blocks -- these are not real API calls

### 4.2 Parallel-Dev Skill: Full Migration

**Current approach (Phase 3-4):**

```
Spawn agents via Task tool with run_in_background: true
→ Monitor tool watches task registry for completion signals (event-driven, ~2s latency)
→ Fallback: CronCreate (1-min schedule) or inline polling (30s sleep)
→ No communication between feature agents
```

> **Note (2026-04-10):** The Monitor tool now covers the polling elimination use case that was a primary motivation for migrating parallel-dev to Agent Teams. Monitor provides event-driven notifications without requiring Agent Teams infrastructure. The remaining unique value of Agent Teams for parallel-dev is **cross-feature messaging** — teammates coordinating APIs/interfaces directly (e.g., "I'm exposing `/api/users`, use that endpoint"). If your features are truly independent (no shared APIs), Monitor + Task mode is sufficient. Migrate to Agent Teams only when cross-feature coordination is a real need.

**Agent Teams approach:**

```yaml
# New SKILL.md header
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - TeammateTool # Replace Task
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - AskUserQuestion
```

**Phase 3 replacement:**

```
For each ready feature (no unmet dependencies), spawn a teammate:

Spawn teammate "{feature-id}":
  Working directory: {worktree-path}
  Task: Implement {feature-name} in this git worktree.

  Requirements:
  {task-list}

  Instructions:
  1. Read the codebase in this worktree for context
  2. Implement all requirements
  3. Write tests
  4. Run tests, fix failures
  5. Commit with message: feat({feature-id}): {description}
  6. Message the lead: "Complete. {summary of what was built}"
  7. If you need an API/interface from another feature,
     message that teammate directly to coordinate.

  Do NOT modify files outside {worktree-path}.
```

**Phase 4 replacement (monitoring):**

The polling loop disappears entirely. Instead:

```
Lead instructions:
- When a teammate messages completion, update the feature status
- Check if newly-unblocked features can be spawned
- When a teammate reports a blocker, try to resolve or notify user
- Shut down completed teammates immediately
- When all features complete, begin Phase 5 (merge)
```

**What this fixes over the current approach:**

1. ~~No polling loop (idle notifications replace it)~~ — **Now solved by Monitor tool without Agent Teams**
2. Feature agents can coordinate APIs/interfaces directly ("I'm exposing `/api/users`, use that endpoint") — **Unique to Agent Teams**
3. ~~Blocker detection is immediate, not on a 30-second poll cycle~~ — **Now solved by Monitor (~2s latency)**
4. ~~The lead stays responsive instead of sleeping in a loop~~ — **Now solved by Monitor (non-blocking)**

**Revised justification:** Agent Teams migration for parallel-dev is justified only when features have cross-dependencies requiring real-time coordination (point 2). For independent features, Monitor + Task mode delivers equivalent responsiveness.

### 4.3 Fulltest Skill: Stay with Subagents (Optimized)

**No migration.** But optimize the current approach:

1. **Batch page tests:** Instead of 1 subagent per page, batch 3-5 pages per subagent
2. **Share failure context:** Write failures to `.testing/failures.json` that subsequent subagents read
3. **Serial fixers:** Run fixers sequentially (CSS fix, then JS fix), not in parallel -- fixes often interact

The "swarm mode" sections in the current SKILL.md are aspirational documentation for TeammateTool that does not exist as described. Consider simplifying those sections to reflect the actual Task-based implementation until Agent Teams is stable enough to warrant migration.

---

## 5. Phased Rollout Plan

### Prerequisites

Before any migration:

```bash
# Enable Agent Teams in settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Verify it works with a manual test:

```
Create a team with 2 teammates. Have one count to 10, the other count
backwards from 10. Have them compare notes when done.
```

If this works reliably in your terminal environment, proceed.

### Phase 1: Manual Validation (Week 1)

**Goal:** Confirm Agent Teams works reliably before touching any skill files.

**Actions:**

1. Run `/cto` in swarm mode on a small project (~10 files) manually
2. When it spawns subagents, note:
   - How long each analyst takes
   - Total token cost (check usage in Claude dashboard)
   - Quality of cross-concern detection
3. Run the same review manually using Agent Teams (just type the prompt yourself, without the skill)
4. Compare:

| Metric               | Subagent Run | Agent Teams Run |
| -------------------- | ------------ | --------------- |
| Total time           |              |                 |
| Token cost           |              |                 |
| Cross-concerns found |              |                 |
| Quality of synthesis |              |                 |

**Success criteria:** Agent Teams finds at least 1 cross-concern that subagents missed. Token cost is within 2x of subagents.

### Phase 2: Parallel-Dev Migration (Week 2-3)

**Why first:** Parallel-dev has the clearest win (worktree isolation, need for cross-feature coordination) and the simplest migration path (replace Task spawning with TeammateTool spawning).

**Actions:**

1. Create a branch: `feature/parallel-dev-agent-teams`
2. Update `parallel-dev/SKILL.md`:
   - Replace `Task` with `TeammateTool` in allowed-tools
   - Rewrite Phase 3 (Agent Dispatch) per pattern 4.2 above
   - Rewrite Phase 4 (Progress Monitoring) to remove polling loop
   - Add fallback: "If TeammateTool is unavailable, fall back to Task tool"
3. Test on a project with 3 independent features
4. Measure: time to completion, token cost, merge conflict rate

**Fallback clause in SKILL.md:**

```
## Execution Mode Selection

IF TeammateTool is available AND features >= 2:
  → Agent Teams mode
ELSE:
  → Task mode (current behavior, fully supported)

Both modes produce identical outputs. Agent Teams mode adds:
- Real-time cross-feature coordination
- Immediate blocker detection
- No polling overhead
```

### Phase 3: CTO Hybrid Mode (Week 4-5)

**Why second:** The CTO skill is more complex (two modes, five analysts vs four teammates) and benefits less clearly from Agent Teams than parallel-dev.

**Actions:**

1. Create branch: `feature/cto-agent-teams`
2. Update `cto/SKILL.md`:
   - Keep sequential mode unchanged
   - Add Agent Teams swarm mode alongside existing swarm pseudocode
   - Reduce analyst count from 5 to 4 (merge stack-analyst into security + quality)
   - Add mode selection logic (Section 4.1)
   - Remove aspirational pseudocode (TeammateTool.sync, structured JSON messages)
3. Test: run a full review on a medium project (50+ files)
4. Compare cross-concern detection quality vs subagent mode

### Phase 4: Measurement and Decision (Week 6)

**Actions:**

1. Collect token usage data from Phase 2-3 runs
2. Fill in this table:

| Skill        | Subagent Tokens | Teams Tokens | Quality Delta | Keep Teams? |
| ------------ | --------------- | ------------ | ------------- | ----------- |
| parallel-dev |                 |              |               |             |
| cto (swarm)  |                 |              |               |             |

3. If Agent Teams costs > 3x subagents with no quality improvement: revert
4. If Agent Teams costs 1-2x with quality improvement: keep
5. If Agent Teams is unstable (crashes, orphaned sessions): keep fallback-only

### Phase 5: Stabilize and Document (Week 7+)

**Actions:**

1. Update memory entities with findings:
   ```
   Entity: tech-insight:agent-teams-vs-subagents
   Observations:
   - "Agent Teams best for: isolated workspaces, cross-agent coordination"
   - "Subagents best for: report-back-only tasks, lightweight workers"
   - "Token multiplier: ~{measured}x vs subagents"
   - "Sweet spot: 3-4 teammates, not 5+"
   ```
2. Add decision framework to a shared reference file
3. Do NOT migrate fulltest-skill or cpo-ai-skill unless new evidence emerges

---

## Summary: What Changes, What Stays

| Skill              | Current                       | Target                                           | Priority            |
| ------------------ | ----------------------------- | ------------------------------------------------ | ------------------- |
| **parallel-dev**   | Task (subagents)              | Agent Teams with Task fallback                   | HIGH                |
| **cto**            | Task (subagents) + pseudocode | Hybrid: sequential stays, swarm gets Agent Teams | MEDIUM              |
| **fulltest-skill** | Task (subagents) + pseudocode | Stays Task-based, optimize batching              | LOW (optimize only) |
| **cpo-ai-skill**   | Task (subagents)              | Stays Task-based                                 | NONE                |
| **review-changes** | Single session                | Stays single session                             | NONE                |
| **cpr**            | Single session                | Stays single session                             | NONE                |
| **test-and-fix**   | Single session                | Stays single session                             | NONE                |
| **website-design** | Single session                | Stays single session                             | NONE                |

### Key Principles

1. **Default to subagents.** Agent Teams is the exception, not the rule.
2. **Never broadcast when direct message works.** Broadcasts cost N context windows.
3. **Shut down finished teammates immediately.** Idle teammates still eat tokens.
4. **3-4 teammates max.** Above that, coordination degrades and costs explode.
5. **Always include a fallback.** Agent Teams is experimental. Every skill that uses it must work without it.
6. **Measure before committing.** No migration is final until token costs are measured on real tasks.
7. **Leverage 1M context (Opus 4.6).** Max/Team plans now get 1M tokens by default. This relaxes context pressure for orchestrator skills — the cost calculus for teammate count and spawn prompt size shifts in favor of richer context.
