---
name: parallel-dev
description: "Parallel feature development using git worktrees and specialized agents. Orchestrates multiple features in isolation with CI reaction loops, progress monitoring, and progressive merge. Delegates to `ao` CLI when available."
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
slots:
  runtime:
    default: "node"
    options: ["node", "bun", "deno"]
    description: "JS runtime for orchestration scripts"
  agent:
    default: "claude-code"
    options: ["claude-code", "codex", "aider", "ao"]
    description: "Agent backend for worktree execution"
  workspace:
    default: "git-worktree"
    options: ["git-worktree", "docker", "devcontainer"]
    description: "Isolation strategy for parallel features"
  tracker:
    default: "state-file"
    options: ["state-file", "github-issues", "linear"]
    description: "Progress tracking backend"
  notifier:
    default: "console"
    options: ["console", "slack", "discord", "telegram"]
    description: "Where completion/failure notifications go"
  terminal:
    default: "inline"
    options: ["inline", "tmux", "ao-dashboard"]
    description: "How agent sessions are managed"
  ci:
    default: "github-actions"
    options: ["github-actions", "none"]
    description: "CI system to poll for reaction loops"
  merger:
    default: "git-merge"
    options: ["git-merge", "gh-pr"]
    description: "How completed features are integrated"
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

## Startup Prompt (MANDATORY)

Before any execution, present the user with a configuration summary and ask for adjustments. This runs every time unless `--quick` is passed.

### Step 1: Environment Detection

Silently detect what's available:

```bash
# Check ao CLI
command -v ao &>/dev/null && AO_AVAILABLE=true

# Check gh CLI + auth
gh auth status &>/dev/null && GH_AVAILABLE=true

# Check CI config
[ -d .github/workflows ] && CI_CONFIGURED=true

# Check existing config file
[ -f .parallel-dev-config.json ] && CONFIG_EXISTS=true

# Check Docker
command -v docker &>/dev/null && DOCKER_AVAILABLE=true
```

### Step 2: Present Configuration Card

Use AskUserQuestion to show the resolved configuration and ask for changes:

```
╔══════════════════════════════════════════════════════════════╗
║ /parallel-dev — Configuration                                ║
╠══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Slot        │ Value          │ Why                           ║
║  ────────────┼────────────────┼─────────────────────────────  ║
║  agent       │ claude-code    │ default (ao not detected)     ║
║  workspace   │ git-worktree   │ default                       ║
║  tracker     │ state-file     │ default                       ║
║  notifier    │ console        │ default                       ║
║  terminal    │ inline         │ default                       ║
║  ci          │ github-actions │ .github/workflows/ detected   ║
║  merger      │ git-merge      │ default                       ║
║                                                               ║
║  Features: 3 parsed │ Parallel: 2 │ Blocked: 1               ║
║                                                               ║
╠══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Recommendations based on your environment:                   ║
║  • gh CLI authenticated → consider merger=gh-pr for PRs       ║
║  • Docker available → consider workspace=docker for isolation ║
║  • No CI workflows → ci will be set to none automatically     ║
║                                                               ║
╠══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Options:                                                     ║
║  [1] Proceed with these settings                              ║
║  [2] Change slots (I'll ask which ones)                       ║
║  [3] Save these settings as project default                   ║
║  [4] Show me what each slot does                              ║
║                                                               ║
╚══════════════════════════════════════════════════════════════╝
```

### Step 3: Handle Response

- **Option 1** → proceed directly
- **Option 2** → ask "Which slots do you want to change?" then present each selected slot with its options
- **Option 3** → write `.parallel-dev-config.json` with current resolved slots, then proceed
- **Option 4** → show the full slot reference table (below), then re-prompt

### Step 4: Feature Summary

After slot confirmation, show parsed features before spawning:

```
╔══════════════════════════════════════════════════════════════╗
║ Features to build:                                           ║
╠──────────────────┬────────────┬──────────────────────────────╣
║ Feature          │ Type       │ Depends On                   ║
╠──────────────────┼────────────┼──────────────────────────────╣
║ auth             │ backend    │ —                            ║
║ api-endpoints    │ api        │ —                            ║
║ dashboard        │ frontend   │ auth, api-endpoints          ║
╠──────────────────────────────────────────────────────────────╣
║ Execution plan: Round 1 → auth + api-endpoints (parallel)    ║
║                  Round 2 → dashboard (after deps complete)   ║
╠──────────────────────────────────────────────────────────────╣
║ Ready to start? [Y/n]                                        ║
╚══════════════════════════════════════════════════════════════╝
```

### Skip Prompt

To bypass the interactive prompt (e.g., when invoked by another skill):

```bash
/parallel-dev --quick    # Uses defaults + config file, no prompt
```

In `agent-spawned` invocation context, the prompt is automatically skipped (verbosity: minimal).

---

## Slot Configuration

This skill uses a plugin-slot architecture. Each slot has a default implementation but can be swapped without rewriting the skill. Override slots via `--slot.<name>=<value>` or in `.parallel-dev-config.json`.

| Slot        | Default        | Alternatives             | Purpose                      |
| ----------- | -------------- | ------------------------ | ---------------------------- |
| `runtime`   | node           | bun, deno                | JS runtime for orchestration |
| `agent`     | claude-code    | codex, aider, ao         | Agent backend per worktree   |
| `workspace` | git-worktree   | docker, devcontainer     | Feature isolation strategy   |
| `tracker`   | state-file     | github-issues, linear    | Progress tracking backend    |
| `notifier`  | console        | slack, discord, telegram | Notification delivery        |
| `terminal`  | inline         | tmux, ao-dashboard       | Agent session management     |
| `ci`        | github-actions | none                     | CI system for reaction loops |
| `merger`    | git-merge      | gh-pr                    | Feature integration method   |

### Slot Resolution

```javascript
function resolveSlots(cliArgs, configFile) {
  const defaults = {
    runtime: "node",
    agent: "claude-code",
    workspace: "git-worktree",
    tracker: "state-file",
    notifier: "console",
    terminal: "inline",
    ci: "github-actions",
    merger: "git-merge",
  };

  // 1. Start with defaults
  const slots = { ...defaults };

  // 2. Override from config file
  if (configFile?.slots) Object.assign(slots, configFile.slots);

  // 3. Override from CLI args (highest priority)
  for (const [key, value] of Object.entries(cliArgs)) {
    if (key.startsWith("slot.")) {
      const slotName = key.replace("slot.", "");
      if (slotName in defaults) slots[slotName] = value;
    }
  }

  // 4. Auto-detect ao CLI
  if (slots.agent === "claude-code") {
    const aoAvailable = execSync("which ao 2>/dev/null").toString().trim();
    if (aoAvailable) {
      slots.agent = "ao";
      slots.terminal = "ao-dashboard";
      console.log(
        "Detected `ao` CLI — delegating session management to agent-orchestrator",
      );
    }
  }

  return slots;
}
```

### Example Override

```bash
# Use Docker isolation + Linear tracking + Slack notifications
/parallel-dev --slot.workspace=docker --slot.tracker=linear --slot.notifier=slack

# Or via config file
echo '{ "slots": { "workspace": "docker", "tracker": "linear" } }' > .parallel-dev-config.json
/parallel-dev
```

---

## `ao` CLI Delegation

When `ao` (agent-orchestrator) is detected on PATH, the skill delegates session management to it instead of managing tmux/worktrees manually.

### Detection

```bash
# Run at skill startup, before Phase 0
if command -v ao &>/dev/null; then
  AO_AVAILABLE=true
  AO_VERSION=$(ao --version 2>/dev/null || echo "unknown")
  echo "agent-orchestrator detected (${AO_VERSION}) — delegating to ao"
fi
```

### Delegation Flow

When `ao` is available and `slots.agent === 'ao'`:

```javascript
async function delegateToAO(features, projectRoot) {
  // 1. Generate ao-compatible manifest from parsed features
  const manifest = {
    project: projectRoot,
    agents: features.map((f) => ({
      name: f.id,
      branch: `feature/${f.id}`,
      agent: selectAOAgent(f.type), // claude|codex|aider
      prompt: buildAgentPrompt(f),
      dependsOn: f.dependsOn.map((d) => `feature/${d}`),
    })),
  };

  // 2. Write manifest
  fs.writeFileSync(".ao-manifest.json", JSON.stringify(manifest, null, 2));

  // 3. Spawn via ao CLI
  await exec(`ao spawn --manifest .ao-manifest.json --ci-react`);

  // 4. Monitor via ao dashboard (opens localhost:3000)
  await exec(`ao dashboard &`);

  // 5. Poll ao status instead of custom monitoring
  return pollAOStatus(features);
}

async function pollAOStatus(features) {
  while (true) {
    const status = JSON.parse(await exec("ao status --json"));

    for (const agent of status.agents) {
      const feature = features.find((f) => f.id === agent.name);
      if (!feature) continue;

      feature.status = mapAOStatus(agent.status);
      // ao handles CI reaction internally with --ci-react flag

      if (agent.status === "merged") {
        feature.mergedAt = agent.completedAt;
      }
    }

    if (features.every((f) => ["merged", "failed"].includes(f.status))) break;
    await sleep(15000);
  }
}

function selectAOAgent(featureType) {
  // ao supports claude, codex, aider as agent backends
  // Default to claude for all types; user can override via slots
  return "claude";
}
```

### Fallback

If `ao` is NOT available, the skill falls back to the native worktree + Task tool approach (Phase 2-5 below).

---

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

For each feature, create an isolated worktree using the native CLI:

```bash
# Create feature branch if not exists
git checkout -b feature/{feature-id} main

# Create worktree using claude CLI
claude --worktree feature/{feature-id}
```

The `claude --worktree` flag is the native CLI mechanism for launching isolated worktrees. Integration with existing `maketree` skill:

- Use `.worktree-scaffold.json` format for compatibility
- Leverage existing branch detection and cleanup

### Phase 3: Agent Dispatch

#### Execution Mode Selection

```
IF TeamCreate is available AND ready features >= 2:
  → Agent Teams mode (preferred — real-time coordination)
ELSE:
  → Task mode (fallback — fully supported)
```

Both modes produce identical outputs. Agent Teams mode adds real-time cross-feature coordination, immediate blocker detection, and no polling overhead.

#### Agent Teams Mode (Preferred)

For each ready feature (no unmet dependencies), spawn a teammate:

```
Create a team for parallel feature development.

For each feature, spawn a teammate:

Teammate "{feature-id}":
  Working directory: {worktree-path}
  Task: Implement {feature-name} in this git worktree.

  Requirements:
  {task-list}

  Instructions:
  1. Read the codebase in this worktree for context
  2. Implement all requirements
  3. Write tests for each component
  4. Run tests and fix any failures
  5. Commit with message: feat({feature-id}): {description}
  6. Message the lead: "Complete. {summary of what was built}"
  7. If you need an API/interface from another feature,
     message that teammate directly to coordinate.

  Do NOT modify files outside {worktree-path}.
```

**Lead orchestrator instructions:**

- When a teammate messages completion, update feature status and shut them down immediately
- Check if newly-unblocked features can be spawned
- When a teammate reports a blocker, try to resolve or notify user
- When all features complete, begin Phase 5 (merge)

**Messaging discipline:** Teammates should use direct messages only. Never broadcast for progress updates or individual findings. Only broadcast for blocking discoveries that change everyone's approach.

#### Task Mode (Fallback)

When Agent Teams is unavailable, use the Task tool with `run_in_background: true` and `isolation: "worktree"`:

```xml
<Task
  subagent_type="{selected-agent}"
  run_in_background="true"
  isolation="worktree"
  prompt="
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

The `isolation: "worktree"` parameter is the officially supported pattern for agent isolation in parallel development workflows. It ensures each agent operates in its own isolated worktree context.

> **Remote Monitoring:** After dispatching agents, remind the user: _"To monitor this session from another device, run `/remote-control` or `/rc`."_ This lets you step away from the terminal while agents work.

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

> **Tip:** Agents are now running in parallel in isolated worktrees. This session will be active for a while. Run `/remote-control` (or `/rc`) to connect from your phone or another browser — your local filesystem, MCP servers, and project config all stay available. Requires Pro/Max plan.

> **Note:** As of v2.1.63, project configs (`.claude/`) and auto-memory are automatically shared across all git worktrees of the same repository. Worktree agents inherit the same skill/agent definitions as the main session.

### Phase 4: Progress Monitoring

#### Agent Teams Mode

The polling loop is unnecessary — the lead receives idle notifications and direct messages from teammates automatically:

- **Teammate completes** → receives completion message → updates status → shuts down teammate → checks for unblocked features
- **Teammate hits blocker** → receives blocker message → resolves or escalates to user
- **All teammates done** → proceeds to Phase 5

No sleep loops, no marker files. The Agent Teams messaging infrastructure handles coordination.

#### Task Mode (Fallback)

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

### Phase 4.5: CI Reaction Loop

When `slots.ci !== 'none'`, the monitoring loop (Phase 4) also polls GitHub Actions for CI failures on feature branches and routes failure logs back to the responsible agent for autonomous remediation.

**Key principle:** Human notifications are reserved only for decisions requiring genuine judgment. CI failures, lint errors, and test regressions are routed back to agents automatically.

```javascript
async function ciReactionLoop(features, state) {
  const CI_POLL_INTERVAL = 45000; // 45 seconds (avoid rate limits)
  const MAX_CI_RETRIES = 2; // Max times to re-route a failure to agent

  for (const feature of getActiveFeatures(state)) {
    if (!feature.branch) continue;

    // 1. Check latest CI run for this branch
    const runs = await exec(
      `gh run list --branch ${feature.branch} --limit 1 --json status,conclusion,databaseId,name`,
    );
    const latestRun = JSON.parse(runs)[0];
    if (!latestRun) continue;

    // 2. Skip if still running or already succeeded
    if (
      latestRun.status === "in_progress" ||
      latestRun.conclusion === "success"
    )
      continue;

    // 3. CI failed — extract failure logs
    if (latestRun.conclusion === "failure") {
      const failedJobs = await exec(
        `gh run view ${latestRun.databaseId} --json jobs --jq '.jobs[] | select(.conclusion=="failure") | .name'`,
      );
      const failureLog = await exec(
        `gh run view ${latestRun.databaseId} --log-failed 2>/dev/null | tail -100`,
      );

      // 4. Track CI failure count per feature
      feature.ciFailures = (feature.ciFailures || 0) + 1;

      if (feature.ciFailures <= MAX_CI_RETRIES) {
        // 5. Route failure back to the responsible agent
        console.log(
          `CI failed for ${feature.name} (attempt ${feature.ciFailures}) — routing to agent`,
        );

        await respawnAgentWithCIFix(feature, {
          failedJobs: failedJobs.trim().split("\n"),
          log: failureLog.trim(),
          runId: latestRun.databaseId,
          runName: latestRun.name,
        });
      } else {
        // 6. Max retries exceeded — escalate to human
        feature.status = "ci-failed";
        notify(
          `CI for ${feature.name} failed ${MAX_CI_RETRIES} times. ` +
            `Failed jobs: ${failedJobs.trim()}. Manual intervention needed.`,
        );
      }
    }
  }
}

async function respawnAgentWithCIFix(feature, ciContext) {
  const agentType = selectAgentType(feature.type);

  // Spawn a fix agent with CI context
  const fixPrompt = `
## CI Failure Fix: ${feature.name}

The CI pipeline failed for branch \`${feature.branch}\`.

### Failed Jobs
${ciContext.failedJobs.map((j) => `- ${j}`).join("\n")}

### Failure Log (last 100 lines)
\`\`\`
${ciContext.log}
\`\`\`

### Instructions
1. Read the failure log carefully
2. Identify the root cause (test failure, lint error, type error, build error)
3. Fix the issue in the relevant files
4. Run the failing command locally to verify
5. Commit the fix: \`fix(${feature.id}): resolve CI failure - ${ciContext.failedJobs[0]}\`
6. Push to trigger a new CI run

### Constraints
- Only fix what's broken — do not refactor unrelated code
- If the failure is a flaky test, add a retry or skip with TODO comment
- If the failure requires architectural changes, create .ci-escalate marker instead
  `;

  // Respawn agent in the same worktree
  await spawnAgent(agentType, {
    ...feature,
    prompt: fixPrompt,
    isFixAgent: true,
  });
}
```

**CI Reaction Dashboard Extension:**

```
╔══════════════════════════════════════════════════════════════╗
║ Feature          │ Agent      │ Status      │ CI             ║
╠──────────────────┼────────────┼─────────────┼────────────────╣
║ auth             │ backend    │ ████████░░  │ ✓ passing      ║
║ api-endpoints    │ api-agent  │ ██████████  │ ✓ merged       ║
║ dashboard        │ frontend   │ ██████░░░░  │ ⟳ fixing (#2)  ║
║ payment          │ backend    │ ░░░░░░░░░░  │ — blocked      ║
╠══════════════════════════════════════════════════════════════╣
║ CI Reactions: 3 total │ 2 auto-fixed │ 1 in-progress        ║
╚══════════════════════════════════════════════════════════════╝
```

**State Persistence for CI:**

```json
{
  "features": [
    {
      "id": "dashboard",
      "ciFailures": 2,
      "ciHistory": [
        {
          "runId": 12345,
          "conclusion": "failure",
          "autoFixed": true,
          "fixCommit": "abc1234"
        },
        {
          "runId": 12350,
          "conclusion": "failure",
          "autoFixed": false,
          "escalated": true
        }
      ]
    }
  ]
}
```

---

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

## Version History

**v2.0.0** — Added CI reaction loops (Phase 4.5), eight-slot plugin architecture, and `ao` CLI delegation. Inspired by [ComposioHQ/agent-orchestrator](https://github.com/ComposioHQ/agent-orchestrator).
**v1.0.0** — Initial release with worktree-based parallel development, dependency graphs, and progressive merge.

## Model Configuration

This skill uses Claude Opus 4.6 as the orchestrator. Feature agents use tiered model selection per `model-tier-strategy.md`:

| Agent Task                   | Model  | Rationale                                   |
| ---------------------------- | ------ | ------------------------------------------- |
| Orchestrator (this skill)    | opus   | Dependency resolution, synthesis, decisions |
| Feature implementation       | sonnet | Code writing with bounded spec              |
| CI fix agent                 | sonnet | Bug diagnosis + code fix                    |
| Explore (codebase discovery) | haiku  | File search, grep — deterministic           |
| Pre-flight verification      | haiku  | Check git log, glob — no judgment needed    |

When spawning feature agents, always pass `model: "sonnet"`. When spawning Explore agents for pre-flight checks, pass `model: "haiku"`.

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
