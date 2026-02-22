---
name: parallel-dev
description: "Parallel feature development using git worktrees and specialized agents. Orchestrates multiple features in isolation with progress monitoring and progressive merge."
user-invocable: true
context: fork
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task(agent_type=frontend-agent)
  - Task(agent_type=backend-agent)
  - Task(agent_type=database-agent)
  - Task(agent_type=devops-agent)
  - Task(agent_type=general-purpose)
  - Task(agent_type=Explore)
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeamCreate
  - TeamDelete
  - SendMessage
  - AskUserQuestion
disable-model-invocation: true
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
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

# Parallel Feature Development Skill

Orchestrates parallel feature development using git worktrees and specialized agents. Can work standalone or integrate with CPO-AI-Skill as the planning brain.

## Trigger Patterns

- `/parallel-dev` - Start with inline feature definitions
- `/parallel-dev --from-cpo` - Read stages from master-project.json
- `/parallel-dev --config <file>` - Read from config file
- `/parallel-dev status` - Show progress dashboard
- `/parallel-dev merge` - Merge completed features to main

## Input Formats

### Inline Features (Default)

```markdown
/parallel-dev

## Feature: Authentication

type: backend
dependsOn: []

- Add OAuth2 login with Google/GitHub
- Session management with Redis
- JWT token refresh

## Feature: Dashboard UI

type: frontend
dependsOn: [api-endpoints]

- Stats cards with real-time data
- Charts using Recharts
- Dark mode support

## Feature: API Endpoints

type: api
dependsOn: []

- User CRUD endpoints
- Rate limiting middleware
- OpenAPI documentation
```

### From CPO-AI-Skill

```bash
/parallel-dev --from-cpo
```

Reads `master-project.json` and parallelizes stages based on their `dependsOn` arrays.

### Config File

```bash
/parallel-dev --config parallel-features.json
```

## Execution Flow

### Phase 0: Pre-flight Verification (CRITICAL)

Before spawning any agents, verify each feature hasn't already been implemented:

```javascript
async function verifyFeatureNotImplemented(feature, projectRoot) {
  const checks = [];

  // 1. Check master-project.json status
  const masterProject = JSON.parse(fs.readFileSync("master-project.json"));
  const stage = findStage(masterProject, feature.id);
  if (stage?.status === "completed" || stage?.status === "tested") {
    return {
      implemented: true,
      reason: "Stage marked complete in master-project.json",
    };
  }

  // 2. Check git history for related commits
  const commitSearch = await exec(
    `git log --oneline --grep="${feature.id}" --grep="${feature.name}" -n 5`,
    { cwd: projectRoot },
  );
  if (commitSearch.stdout.trim()) {
    checks.push({
      type: "git_commits",
      found: commitSearch.stdout.trim().split("\n"),
      warning: "Related commits found - may be partially implemented",
    });
  }

  // 3. Check for key files that would indicate implementation
  for (const story of feature.tasks) {
    const keywords = extractKeywords(story); // e.g., "Stripe" -> lib/stripe.ts
    for (const keyword of keywords) {
      const files = await glob(`**/*${keyword}*`, { cwd: projectRoot });
      if (files.length > 0) {
        checks.push({
          type: "existing_files",
          keyword,
          files: files.slice(0, 5),
          warning: `Files matching "${keyword}" already exist`,
        });
      }
    }
  }

  // 4. Check acceptance criteria against codebase
  for (const story of feature.stories || []) {
    for (const criteria of story.acceptanceCriteria || []) {
      const implemented = await checkCriteriaImplemented(criteria, projectRoot);
      if (implemented) {
        checks.push({
          type: "criteria_met",
          criteria,
          warning: "Acceptance criteria may already be satisfied",
        });
      }
    }
  }

  // 5. Check progress.md or similar tracking files
  const progressFile = path.join(projectRoot, "progress.md");
  if (fs.existsSync(progressFile)) {
    const progress = fs.readFileSync(progressFile, "utf-8");
    if (progress.includes(feature.id) || progress.includes(feature.name)) {
      checks.push({
        type: "progress_tracked",
        warning: "Feature mentioned in progress.md",
      });
    }
  }

  return {
    implemented: false,
    warnings: checks,
    needsReview: checks.length > 0,
  };
}

// Keyword extraction for file search
function extractKeywords(story) {
  const keywords = [];
  // Extract capitalized terms, technical terms
  const matches = story.match(
    /\b(Stripe|Sentry|PostHog|OAuth|JWT|CSP|CORS|Prisma|Redis)\b/gi,
  );
  if (matches) keywords.push(...matches.map((m) => m.toLowerCase()));

  // Extract file patterns from descriptions
  const fileMatches = story.match(
    /(?:create|add|implement)\s+([\/\w-]+\.\w+)/gi,
  );
  if (fileMatches) keywords.push(...fileMatches);

  return [...new Set(keywords)];
}
```

**Verification Output:**

```
╔══════════════════════════════════════════════════════════════╗
║ PRE-FLIGHT VERIFICATION                                       ║
╠══════════════════════════════════════════════════════════════╣
║ Feature              │ Status       │ Warnings               ║
╠──────────────────────┼──────────────┼────────────────────────╣
║ stripe-foundation    │ ⚠ REVIEW     │ lib/stripe.ts exists   ║
║ testing-infra        │ ✓ CLEAR      │ -                      ║
║ error-boundaries     │ ✓ CLEAR      │ -                      ║
║ security-headers     │ ⚠ REVIEW     │ 2 related commits      ║
╠══════════════════════════════════════════════════════════════╣
║ Action: Review warnings before proceeding? [Y/n/skip-all]    ║
╚══════════════════════════════════════════════════════════════╝
```

If warnings are found, the orchestrator will:

1. **Pause** and show the warnings
2. **Ask user** whether to proceed, skip, or investigate
3. **Log** the decision for audit

### Phase 1: Parse & Analyze

```javascript
// 1. Parse input into normalized feature list
const features = parseFeatures(input);  // Returns Feature[]

// Feature structure:
interface Feature {
  id: string;           // kebab-case identifier
  name: string;         // Human-readable name
  type: FeatureType;    // frontend|backend|api|database|testing|devops|general
  dependsOn: string[];  // Feature IDs this depends on
  tasks: string[];      // List of tasks/requirements
  status: Status;       // pending|in_progress|completed|merged|failed
  worktree?: string;    // Path to worktree when created
  agentId?: string;     // Background agent ID when running
  branch?: string;      // Git branch name
}

// 2. Build dependency graph
const graph = buildDependencyGraph(features);

// 3. Find parallelizable features (no unmet dependencies)
const ready = graph.getReadyFeatures();  // Features with all deps met
```

### Phase 2: Worktree Creation

For each feature, create an isolated worktree:

```bash
# Create feature branch if not exists
git checkout -b feature/{feature-id} main

# Create worktree in parent directory
git worktree add ../{feature-id} feature/{feature-id}
```

Integration with existing `maketree` skill:

- Use `.worktree-scaffold.json` format for compatibility
- Leverage existing branch detection and cleanup

### Phase 3: Agent Dispatch

Spawn specialized agents per worktree using `run_in_background: true`:

```xml
<Task
  subagent_type="{selected-agent}"
  run_in_background="true"
  prompt="
    WORKING DIRECTORY: {worktree-path}

    ## Feature: {feature-name}

    You are developing this feature in an isolated git worktree.

    ### Tasks:
    {task-list}

    ### Instructions:
    1. Implement all tasks
    2. Write tests for each component
    3. Run tests and fix any failures
    4. Commit your changes with descriptive messages
    5. Signal completion by creating .feature-complete marker file

    ### Constraints:
    - Stay within this worktree directory
    - Do not modify files outside your feature scope
    - Follow existing code patterns in the codebase
  "
/>
```

**Agent Selection Logic:**

| Feature Type         | Agent           | Rationale                     |
| -------------------- | --------------- | ----------------------------- |
| `frontend`, `ui`     | frontend-agent  | React, Vue, styling expertise |
| `backend`            | backend-agent   | Node, Python, Go expertise    |
| `api`                | api-agent       | REST/GraphQL, OpenAPI         |
| `database`, `schema` | database-agent  | Migrations, queries           |
| `testing`, `e2e`     | testing-agent   | Test writing, coverage        |
| `devops`, `deploy`   | devops-agent    | CI/CD, Docker, cloud          |
| unspecified          | general-purpose | Flexible, all-around          |

### Phase 4: Progress Monitoring

Poll background agents and update dashboard:

```javascript
// Monitoring loop
while (hasActiveFeatures()) {
  for (const feature of activeFeatures) {
    // Check agent output file
    const output = await readAgentOutput(feature.agentId);

    // Check for completion marker
    const complete = await checkCompletionMarker(feature.worktree);

    if (complete) {
      feature.status = "completed";
      await runFeatureTests(feature);
      if (testsPass) {
        await mergeToIntegration(feature);
      }
    }

    // Update dashboard
    updateProgressDisplay(features);
  }

  // Check if new features can start (deps met)
  const newlyReady = graph.getReadyFeatures();
  for (const feature of newlyReady) {
    await spawnFeatureAgent(feature);
  }

  await sleep(30000); // 30 second polling interval
}
```

### Phase 5: Progressive Merge

```bash
# When feature tests pass in worktree:
cd {worktree-path}
git add .
git commit -m "feat({feature-id}): {description}"

# Merge to integration branch
git checkout integration
git merge feature/{feature-id} --no-ff

# Run integration tests
npm run test:integration

# If conflict:
#   - Pause merging
#   - Notify user with conflict details
#   - Wait for manual resolution

# If all features merged and tests pass:
#   - Prompt user for final merge to main
```

## Progress Dashboard

Display live progress during execution:

```
╔══════════════════════════════════════════════════════════════╗
║ PARALLEL-DEV: {project-name}                                  ║
╠══════════════════════════════════════════════════════════════╣
║ Feature          │ Agent      │ Status      │ Progress       ║
╠──────────────────┼────────────┼─────────────┼────────────────╣
║ auth             │ backend    │ ████████░░  │ 80% - testing  ║
║ api-endpoints    │ api-agent  │ ██████████  │ ✓ merged       ║
║ dashboard        │ frontend   │ ██████░░░░  │ 60% - building ║
║ payment          │ backend    │ ░░░░░░░░░░  │ ⏸ blocked      ║
╠══════════════════════════════════════════════════════════════╣
║ Merged: 1/4 │ Active: 2 │ Blocked: 1 │ Elapsed: 12m         ║
╚══════════════════════════════════════════════════════════════╝
```

## State Persistence

Save state to `.parallel-dev-state.json`:

```json
{
  "projectName": "my-app",
  "startedAt": "2026-01-29T10:00:00Z",
  "integrationBranch": "integration/parallel-dev-20260129",
  "features": [
    {
      "id": "auth",
      "name": "Authentication",
      "type": "backend",
      "status": "completed",
      "worktree": "../auth",
      "branch": "feature/auth",
      "agentId": "abc123",
      "completedAt": "2026-01-29T10:15:00Z",
      "mergedAt": "2026-01-29T10:16:00Z"
    }
  ],
  "conflicts": [],
  "integrationTestsPassing": true
}
```

## CPO Integration

When `--from-cpo` is specified:

```javascript
// 1. Read master-project.json
const project = JSON.parse(fs.readFileSync("master-project.json"));

// 2. CRITICAL: Filter out already-completed stages
const pendingStages = [];
for (const epic of project.epics) {
  for (const stage of epic.stages) {
    // Skip if stage is already done
    if (stage.status === "completed" || stage.status === "tested") {
      console.log(`Skipping ${stage.name}: already ${stage.status}`);
      continue;
    }

    // Skip if all stories in stage are done
    const allStoriesDone = stage.stories.every(
      (s) => s.status === "completed" || s.passes === true,
    );
    if (allStoriesDone) {
      console.log(`Skipping ${stage.name}: all stories complete`);
      continue;
    }

    pendingStages.push({
      ...stage,
      epicId: epic.id,
      epicPriority: epic.priority,
    });
  }
}

// 3. Extract stages with their dependencies
const features = pendingStages.map((stage) => ({
  id: slugify(stage.name),
  name: stage.name,
  type: inferTypeFromStage(stage), // Based on stage name/description
  dependsOn: stage.dependsOn.map((depId) => {
    const depStage = project.stages.find((s) => s.id === depId);
    return slugify(depStage.name);
  }),
  tasks: stage.stories.map((s) => s.title),
  status: "pending",
}));

// 3. Respect epic-level dependencies too
// Stages inherit epic dependencies

// 4. Filter to only stages with status 'pending'
const pendingFeatures = features.filter(
  (f) =>
    project.stages.find((s) => slugify(s.name) === f.id)?.status === "pending",
);
```

**Type Inference from Stage:**

```javascript
function inferTypeFromStage(stage) {
  const name = stage.name.toLowerCase();
  const desc = stage.description.toLowerCase();
  const combined = `${name} ${desc}`;

  if (/frontend|ui|dashboard|component|page|layout/i.test(combined))
    return "frontend";
  if (/api|endpoint|rest|graphql|route/i.test(combined)) return "api";
  if (/backend|server|service|worker/i.test(combined)) return "backend";
  if (/database|schema|migration|model/i.test(combined)) return "database";
  if (/test|e2e|integration test|coverage/i.test(combined)) return "testing";
  if (/deploy|ci|cd|docker|infra/i.test(combined)) return "devops";
  return "general";
}
```

## Commands

### `/parallel-dev` - Start Development

Main entry point. Parses features, creates worktrees, spawns agents.

### `/parallel-dev status` - Show Dashboard

Display current progress without spawning new agents.

### `/parallel-dev merge` - Final Merge

Merge integration branch to main (requires all features complete).

### `/parallel-dev clean` - Cleanup

Remove worktrees, delete feature branches (after merge or abort).

### `/parallel-dev resume` - Resume Session

Resume from `.parallel-dev-state.json` after interruption.

## Error Handling

### Agent Failure

```javascript
if (agentFailed(feature)) {
  feature.status = "failed";
  feature.failureReason = extractFailureReason(output);

  // Notify user
  console.log(`Feature ${feature.name} failed: ${feature.failureReason}`);

  // Options:
  // 1. Retry with same agent
  // 2. Retry with different agent
  // 3. Mark as blocked, continue others
  // 4. Pause all and investigate
}
```

### Merge Conflict

```javascript
if (mergeConflict(feature)) {
  feature.status = "conflict";
  feature.conflictFiles = getConflictFiles();

  // Pause further merges
  pauseMerging = true;

  // Notify user with details
  console.log(`Conflict in ${feature.name}:`);
  console.log(feature.conflictFiles.join("\n"));
  console.log("\nResolve manually, then run: /parallel-dev resume");
}
```

### Dependency Cycle

```javascript
if (hasCycle(graph)) {
  const cycle = findCycle(graph);
  throw new Error(`Dependency cycle detected: ${cycle.join(" -> ")}`);
}
```

## Model Configuration

This skill uses Claude Opus 4.6 for maximum capability. Use `/fast` to toggle faster responses when time is critical.

## Hook Events

This skill leverages:

- **TeammateIdle**: Triggers when a worker agent goes idle
- **TaskCompleted**: Triggers when a feature task is marked completed

## Best Practices

1. **Keep features independent** - Minimize shared file modifications
2. **Small, focused features** - Easier to parallelize and merge
3. **Clear type annotations** - Helps agent selection
4. **Test early** - Catch issues before merge
5. **Regular status checks** - Monitor progress, catch problems early

## Example Session

```bash
# Start with inline features
/parallel-dev

## Feature: User Authentication
type: backend
- OAuth2 with Google
- Session management
- Password reset flow

## Feature: User Dashboard
type: frontend
dependsOn: [user-authentication]
- Profile page
- Settings panel
- Activity feed

## Feature: Notification System
type: backend
- Email notifications
- In-app notifications
- Notification preferences

# Orchestrator output:
# Created worktrees: ../user-authentication, ../notification-system
# Spawned agents: backend-agent (auth), backend-agent (notifications)
# Dashboard started in ../user-dashboard (waiting on auth)
#
# Progress dashboard displayed...
```
