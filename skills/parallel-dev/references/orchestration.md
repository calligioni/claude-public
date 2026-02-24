# Orchestration Logic

Detailed implementation patterns for the parallel-dev orchestrator.

## Pre-flight Verification (Phase 0)

**CRITICAL**: Before spawning agents, verify features haven't already been implemented.

### Verification Checks

```javascript
async function runPreflightVerification(features, projectRoot) {
  const results = [];

  for (const feature of features) {
    const verification = {
      featureId: feature.id,
      featureName: feature.name,
      status: "clear",
      warnings: [],
      blockers: [],
    };

    // 1. Check master-project.json status
    const stageStatus = getStageStatus(feature.id);
    if (stageStatus === "completed" || stageStatus === "tested") {
      verification.status = "skip";
      verification.blockers.push(`Stage already marked as ${stageStatus}`);
      results.push(verification);
      continue;
    }

    // 2. Check for existing implementation files
    const keyFiles = await findImplementationFiles(feature, projectRoot);
    if (keyFiles.length > 0) {
      verification.warnings.push({
        type: "existing_files",
        message: `Found ${keyFiles.length} potentially related files`,
        files: keyFiles.slice(0, 5),
      });
    }

    // 3. Check git history for related commits
    const relatedCommits = await findRelatedCommits(feature, projectRoot);
    if (relatedCommits.length > 0) {
      verification.warnings.push({
        type: "git_history",
        message: `Found ${relatedCommits.length} related commits`,
        commits: relatedCommits,
      });
    }

    // 4. Check progress.md or tracking files
    const progressMentions = await checkProgressFiles(feature, projectRoot);
    if (progressMentions.length > 0) {
      verification.warnings.push({
        type: "progress_tracking",
        message: "Feature mentioned in progress tracking",
        mentions: progressMentions,
      });
    }

    // 5. Check if acceptance criteria are met
    const criteriaStatus = await checkAcceptanceCriteria(feature, projectRoot);
    if (criteriaStatus.metCount > 0) {
      verification.warnings.push({
        type: "criteria_met",
        message: `${criteriaStatus.metCount}/${criteriaStatus.totalCount} acceptance criteria may be satisfied`,
        details: criteriaStatus.met,
      });
    }

    // Set status based on findings
    if (verification.warnings.length > 0) {
      verification.status = "review";
    }

    results.push(verification);
  }

  return results;
}

// Find files that might contain implementation
async function findImplementationFiles(feature, projectRoot) {
  const patterns = [];

  // Extract keywords from feature name and tasks
  const keywords = extractKeywords(feature);

  for (const keyword of keywords) {
    // Search for files containing the keyword
    const globPattern = `**/*${keyword}*`;
    const files = await glob(globPattern, {
      cwd: projectRoot,
      ignore: ["node_modules/**", ".git/**", "dist/**"],
    });
    patterns.push(...files);
  }

  // Also grep for specific identifiers
  for (const story of feature.tasks) {
    const storyId = story.id || "";
    if (storyId) {
      const grepResult = await exec(
        `grep -rl "${storyId}" --include="*.ts" --include="*.tsx" . 2>/dev/null || true`,
        { cwd: projectRoot },
      );
      if (grepResult.stdout.trim()) {
        patterns.push(...grepResult.stdout.trim().split("\n"));
      }
    }
  }

  return [...new Set(patterns)];
}

// Find commits related to feature
async function findRelatedCommits(feature, projectRoot) {
  const searchTerms = [
    feature.id,
    feature.name,
    ...feature.tasks.map((t) => t.id).filter(Boolean),
  ];

  const commits = [];
  for (const term of searchTerms) {
    const result = await exec(
      `git log --oneline --all --grep="${term}" -n 3 2>/dev/null || true`,
      { cwd: projectRoot },
    );
    if (result.stdout.trim()) {
      commits.push(...result.stdout.trim().split("\n"));
    }
  }

  return [...new Set(commits)];
}

// Extract searchable keywords from feature
function extractKeywords(feature) {
  const keywords = new Set();

  // From feature name (convert to likely filenames)
  const nameWords = feature.name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, "")
    .split(/\s+/)
    .filter((w) => w.length > 3);
  nameWords.forEach((w) => keywords.add(w));

  // Technical terms from tasks
  const techTerms = [
    "stripe",
    "sentry",
    "posthog",
    "oauth",
    "jwt",
    "csp",
    "cors",
    "prisma",
    "redis",
    "webhook",
    "billing",
    "subscription",
    "payment",
  ];

  for (const task of feature.tasks) {
    const taskLower = (task.title || task).toLowerCase();
    for (const term of techTerms) {
      if (taskLower.includes(term)) {
        keywords.add(term);
      }
    }
  }

  return [...keywords];
}
```

### User Interaction on Warnings

```javascript
async function handleVerificationWarnings(results) {
  const needsReview = results.filter((r) => r.status === "review");
  const blocked = results.filter((r) => r.status === "skip");
  const clear = results.filter((r) => r.status === "clear");

  // Display summary
  console.log(
    "\n╔══════════════════════════════════════════════════════════════╗",
  );
  console.log(
    "║ PRE-FLIGHT VERIFICATION RESULTS                              ║",
  );
  console.log(
    "╠══════════════════════════════════════════════════════════════╣",
  );

  for (const r of results) {
    const icon = r.status === "clear" ? "✓" : r.status === "skip" ? "✗" : "⚠";
    const statusText = r.status.toUpperCase().padEnd(8);
    console.log(
      `║ ${icon} ${r.featureName.padEnd(25)} │ ${statusText} │ ${r.warnings.length} warnings`,
    );
  }

  console.log(
    "╚══════════════════════════════════════════════════════════════╝",
  );

  // If any need review, ask user
  if (needsReview.length > 0) {
    console.log("\n⚠ Some features have warnings that need review:\n");

    for (const r of needsReview) {
      console.log(`\n### ${r.featureName}`);
      for (const w of r.warnings) {
        console.log(`  - ${w.type}: ${w.message}`);
        if (w.files) console.log(`    Files: ${w.files.join(", ")}`);
        if (w.commits) console.log(`    Commits: ${w.commits.join(", ")}`);
      }
    }

    // Ask user what to do
    const response = await askUser({
      question: "How do you want to proceed with features that have warnings?",
      options: [
        { label: "Review each", value: "review" },
        { label: "Skip all with warnings", value: "skip" },
        { label: "Proceed anyway", value: "proceed" },
        { label: "Abort", value: "abort" },
      ],
    });

    return handleUserResponse(response, results);
  }

  // Auto-proceed if all clear
  return results.filter((r) => r.status === "clear");
}
```

## Dependency Graph

### Building the Graph

```javascript
class DependencyGraph {
  constructor(features) {
    this.features = new Map(); // id -> Feature
    this.edges = new Map(); // id -> Set<dependentIds>
    this.reverseEdges = new Map(); // id -> Set<dependencyIds>

    for (const feature of features) {
      this.features.set(feature.id, feature);
      this.edges.set(feature.id, new Set());
      this.reverseEdges.set(feature.id, new Set(feature.dependsOn));

      for (const depId of feature.dependsOn) {
        if (!this.edges.has(depId)) {
          this.edges.set(depId, new Set());
        }
        this.edges.get(depId).add(feature.id);
      }
    }
  }

  // Features with no unmet dependencies
  getReadyFeatures() {
    const ready = [];
    for (const [id, feature] of this.features) {
      if (feature.status !== "pending") continue;

      const deps = this.reverseEdges.get(id);
      const allDepsMet = [...deps].every((depId) => {
        const dep = this.features.get(depId);
        return dep && (dep.status === "merged" || dep.status === "completed");
      });

      if (allDepsMet) {
        ready.push(feature);
      }
    }
    return ready;
  }

  // Detect cycles using DFS
  hasCycle() {
    const visited = new Set();
    const recursionStack = new Set();

    const dfs = (id) => {
      visited.add(id);
      recursionStack.add(id);

      for (const depId of this.reverseEdges.get(id) || []) {
        if (!visited.has(depId)) {
          if (dfs(depId)) return true;
        } else if (recursionStack.has(depId)) {
          return true;
        }
      }

      recursionStack.delete(id);
      return false;
    };

    for (const id of this.features.keys()) {
      if (!visited.has(id) && dfs(id)) {
        return true;
      }
    }
    return false;
  }

  // Mark feature as complete and check what's unblocked
  markComplete(id) {
    const feature = this.features.get(id);
    feature.status = "completed";

    const unblocked = [];
    for (const dependentId of this.edges.get(id) || []) {
      const dependent = this.features.get(dependentId);
      if (dependent.status === "pending") {
        const deps = this.reverseEdges.get(dependentId);
        const allMet = [...deps].every((d) => {
          const dep = this.features.get(d);
          return dep.status === "merged" || dep.status === "completed";
        });
        if (allMet) {
          unblocked.push(dependent);
        }
      }
    }
    return unblocked;
  }
}
```

### Topological Sort (Execution Order)

```javascript
function topologicalSort(graph) {
  const result = [];
  const visited = new Set();
  const temp = new Set();

  function visit(id) {
    if (temp.has(id)) throw new Error("Cycle detected");
    if (visited.has(id)) return;

    temp.add(id);
    for (const depId of graph.reverseEdges.get(id) || []) {
      visit(depId);
    }
    temp.delete(id);
    visited.add(id);
    result.push(id);
  }

  for (const id of graph.features.keys()) {
    if (!visited.has(id)) {
      visit(id);
    }
  }

  return result;
}
```

## Agent Dispatch Pattern

### Spawning Background Agents

```xml
<!-- Spawn multiple agents in a single message for true parallelism -->

<Task
  subagent_type="backend-agent"
  run_in_background="true"
  description="Develop auth feature"
  prompt="
    ## Context
    Working directory: /path/to/worktree/auth
    Feature: User Authentication
    Type: backend

    ## Tasks
    1. Add OAuth2 login with Google/GitHub
    2. Implement session management with Redis
    3. Add JWT token refresh endpoint

    ## Instructions
    - Implement all tasks in this isolated worktree
    - Write tests for each component
    - Run tests and fix failures
    - Commit changes with descriptive messages
    - Create .feature-complete file when done

    ## Completion Signal
    When finished, create: /path/to/worktree/auth/.feature-complete
    Content: JSON with summary of changes
  "
/>

<Task
  subagent_type="api-agent"
  run_in_background="true"
  description="Develop API endpoints"
  prompt="
    ## Context
    Working directory: /path/to/worktree/api-endpoints
    Feature: API Endpoints
    Type: api

    ## Tasks
    1. User CRUD endpoints
    2. Rate limiting middleware
    3. OpenAPI documentation

    ## Instructions
    ...
  "
/>
```

### Tracking Agent Progress

```javascript
// State structure for tracking agents
const agentTracker = {
  agents: new Map(), // featureId -> { agentId, outputFile, startedAt }

  spawn(feature, agentType) {
    // Task tool returns agentId
    const result = spawnAgent(agentType, feature);
    this.agents.set(feature.id, {
      agentId: result.agentId,
      outputFile: result.outputFile,
      startedAt: new Date(),
      feature: feature,
    });
  },

  async checkProgress(featureId) {
    const agent = this.agents.get(featureId);
    if (!agent) return null;

    // Read output file for progress
    const output = await readFile(agent.outputFile);

    // Check for completion marker
    const completePath = `${agent.feature.worktree}/.feature-complete`;
    const isComplete = await fileExists(completePath);

    return {
      output,
      isComplete,
      elapsed: Date.now() - agent.startedAt.getTime(),
    };
  },
};
```

## Progress Monitoring Loop

```javascript
async function monitorProgress(state) {
  const POLL_INTERVAL = 30000; // 30 seconds
  const MAX_RUNTIME = 3600000; // 1 hour per feature

  while (hasActiveFeatures(state)) {
    // Check each active feature
    for (const feature of getActiveFeatures(state)) {
      const progress = await agentTracker.checkProgress(feature.id);

      if (progress.isComplete) {
        // Feature completed by agent
        await handleFeatureComplete(feature, state);
      } else if (progress.elapsed > MAX_RUNTIME) {
        // Timeout - mark as failed
        feature.status = "failed";
        feature.failureReason = "Timeout";
        notify(`Feature ${feature.name} timed out after 1 hour`);
      }
    }

    // Check for newly unblocked features
    const ready = state.graph.getReadyFeatures();
    for (const feature of ready) {
      if (feature.status === "pending") {
        await spawnFeatureAgent(feature, state);
      }
    }

    // Update dashboard display
    renderDashboard(state);

    // Wait before next poll
    await sleep(POLL_INTERVAL);
  }

  return generateFinalReport(state);
}

async function handleFeatureComplete(feature, state) {
  // 1. Read completion summary
  const summary = await readCompletionSummary(feature);

  // 2. Run tests in worktree
  const testResult = await runTests(feature.worktree);

  if (testResult.passed) {
    feature.status = "completed";
    feature.completedAt = new Date();

    // 3. Attempt merge to integration
    await attemptMerge(feature, state);
  } else {
    // Tests failed - agent needs to fix
    feature.status = "testing-failed";
    feature.testFailures = testResult.failures;

    // Optionally: respawn agent to fix
    await respawnForFix(feature, testResult.failures);
  }
}
```

## CI Reaction Loop

Integrated into the monitoring loop (Phase 4). Polls GitHub Actions for CI failures and routes them back to responsible agents.

```javascript
// Called every CI_POLL_INTERVAL within monitorProgress()
async function runCIReactionLoop(state) {
  if (state.slots?.ci === "none") return;

  for (const feature of getActiveFeatures(state)) {
    if (!feature.branch) continue;

    // Poll latest CI run
    const result = await exec(
      `gh run list --branch ${feature.branch} --limit 1 --json status,conclusion,databaseId`,
    );
    const run = JSON.parse(result)[0];
    if (!run || run.status === "in_progress" || run.conclusion === "success")
      continue;

    if (run.conclusion === "failure") {
      feature.ciFailures = (feature.ciFailures || 0) + 1;

      // Extract failure context
      const log = await exec(
        `gh run view ${run.databaseId} --log-failed 2>/dev/null | tail -100`,
      );

      if (feature.ciFailures <= 2) {
        // Route back to agent
        await respawnForCIFix(feature, log.trim());
      } else {
        // Escalate to human
        feature.status = "ci-failed";
        notify(
          `CI for ${feature.name} failed ${feature.ciFailures} times. Manual intervention needed.`,
        );
      }
    }
  }
}

async function respawnForCIFix(feature, failureLog) {
  const agentType = selectAgentType(feature.type);
  await spawnAgent(agentType, {
    ...feature,
    prompt: `Fix CI failure for ${feature.name}.\n\nFailure log:\n${failureLog}\n\nFix the issue, commit, and push.`,
    isFixAgent: true,
  });
}
```

### CI Reaction State Tracking

```json
{
  "id": "dashboard",
  "ciFailures": 1,
  "ciHistory": [
    {
      "runId": 12345,
      "conclusion": "failure",
      "autoFixed": true,
      "fixCommit": "abc1234"
    }
  ]
}
```

### When `ao` is Available

If `slots.agent === 'ao'`, skip the custom CI reaction loop entirely — `ao spawn --ci-react` handles this natively. The `ao` CLI monitors GitHub Actions and re-routes failures to the responsible agent session automatically.

---

## Merge Coordination

```javascript
async function attemptMerge(feature, state) {
  const integrationBranch = state.integrationBranch;

  try {
    // 1. Ensure integration branch exists
    await ensureBranch(integrationBranch, "main");

    // 2. Attempt merge
    await exec(`git checkout ${integrationBranch}`, { cwd: state.mainRepo });
    await exec(
      `git merge feature/${feature.id} --no-ff -m "Merge ${feature.name}"`,
      {
        cwd: state.mainRepo,
      },
    );

    // 3. Run integration tests
    const integrationTests = await runIntegrationTests(state.mainRepo);

    if (integrationTests.passed) {
      feature.status = "merged";
      feature.mergedAt = new Date();
      state.graph.markComplete(feature.id);
    } else {
      // Integration tests failed after merge
      await exec(`git reset --hard HEAD~1`, { cwd: state.mainRepo });
      feature.status = "integration-failed";
      feature.integrationFailures = integrationTests.failures;
    }
  } catch (error) {
    if (error.message.includes("CONFLICT")) {
      // Merge conflict
      await exec(`git merge --abort`, { cwd: state.mainRepo });
      feature.status = "conflict";
      feature.conflictDetails = await getConflictDetails();

      // Pause all merging
      state.mergingPaused = true;
      notify(`Merge conflict in ${feature.name}. Manual resolution required.`);
    } else {
      throw error;
    }
  }
}
```

## State Persistence

```javascript
// Save state to disk for recovery
function saveState(state) {
  const serializable = {
    projectName: state.projectName,
    startedAt: state.startedAt,
    integrationBranch: state.integrationBranch,
    mainRepo: state.mainRepo,
    features: Array.from(state.features.values()).map((f) => ({
      id: f.id,
      name: f.name,
      type: f.type,
      dependsOn: f.dependsOn,
      tasks: f.tasks,
      status: f.status,
      worktree: f.worktree,
      branch: f.branch,
      agentId: f.agentId,
      completedAt: f.completedAt,
      mergedAt: f.mergedAt,
      failureReason: f.failureReason,
    })),
    mergingPaused: state.mergingPaused,
    conflicts: state.conflicts,
  };

  fs.writeFileSync(
    ".parallel-dev-state.json",
    JSON.stringify(serializable, null, 2),
  );
}

// Load state for resume
function loadState() {
  if (!fs.existsSync(".parallel-dev-state.json")) {
    return null;
  }

  const data = JSON.parse(fs.readFileSync(".parallel-dev-state.json", "utf-8"));

  // Reconstruct graph
  data.graph = new DependencyGraph(data.features);

  // Verify worktrees still exist
  for (const feature of data.features) {
    if (feature.worktree && !fs.existsSync(feature.worktree)) {
      feature.worktree = null;
      feature.status = "pending"; // Reset if worktree gone
    }
  }

  return data;
}
```

## Error Recovery

### Agent Failure Recovery

```javascript
async function handleAgentFailure(feature, error, state) {
  const MAX_RETRIES = 2;

  feature.retryCount = (feature.retryCount || 0) + 1;

  if (feature.retryCount <= MAX_RETRIES) {
    // Retry with same agent
    notify(`Retrying ${feature.name} (attempt ${feature.retryCount + 1})`);
    await spawnFeatureAgent(feature, state);
  } else {
    // Max retries exceeded
    feature.status = "failed";
    feature.failureReason = error.message;

    // Check if this blocks other features
    const blocked = getBlockedFeatures(feature, state);
    if (blocked.length > 0) {
      notify(
        `${feature.name} failed after ${MAX_RETRIES} retries. ` +
          `Blocked features: ${blocked.map((f) => f.name).join(", ")}`,
      );
    }
  }
}
```

### Conflict Resolution Flow

```javascript
async function handleConflictResolution(state) {
  // User has manually resolved conflicts
  // Verify resolution
  const hasConflicts = await exec("git diff --check", {
    cwd: state.mainRepo,
  }).catch(() => true);

  if (hasConflicts) {
    notify("Conflicts still present. Please resolve all conflicts.");
    return false;
  }

  // Complete the merge
  await exec("git add .", { cwd: state.mainRepo });
  await exec("git commit --no-edit", { cwd: state.mainRepo });

  // Run integration tests
  const tests = await runIntegrationTests(state.mainRepo);

  if (tests.passed) {
    // Find the feature that was conflicted
    const conflictedFeature = state.features.find(
      (f) => f.status === "conflict",
    );
    conflictedFeature.status = "merged";
    conflictedFeature.mergedAt = new Date();

    state.mergingPaused = false;
    notify(`Conflict resolved. ${conflictedFeature.name} merged successfully.`);

    // Resume merging other completed features
    await resumeMerging(state);
    return true;
  } else {
    notify("Integration tests failed after conflict resolution.");
    return false;
  }
}
```
