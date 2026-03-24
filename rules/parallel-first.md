# Parallel-First Execution Rule

## Default Behavior

Always prefer parallel execution over sequential when tasks are independent. This applies to:

1. **Subagent spawning** — launch all independent agents simultaneously, never sequentially
2. **Tool calls** — batch all independent reads, greps, globs, and web fetches into a single message
3. **Skill execution** — when a skill supports swarm mode (e.g., `/cto`, `/fulltest-skill`, `/qa-cycle`, `/qa-sourcerank`), always use swarm mode unless the user explicitly asks for sequential
4. **Research** — spawn parallel research tracks instead of sequential lookups
5. **Testing** — run page testers, persona testers, and fixers in parallel batches

## When to Parallelize

| Scenario                      | Action                                                 |
| ----------------------------- | ------------------------------------------------------ |
| Multiple files to read        | Parallel Read calls in one message                     |
| Multiple searches needed      | Parallel Grep/Glob calls in one message                |
| Independent features to build | Parallel agents in worktrees (`isolation: "worktree"`) |
| Multiple reviewers needed     | Parallel review agents (security, perf, architecture)  |
| Multiple pages to test        | Batch 3-5 pages per parallel agent                     |
| Research with multiple angles | Parallel research agents per track                     |
| Independent API calls         | Parallel tool calls in one message                     |

## When NOT to Parallelize

- Tasks with data dependencies (B needs A's output)
- File edits to the same file (sequential to avoid conflicts)
- Git operations (sequential — shared state)
- Database migrations (sequential — order matters)

## Agent Spawning Patterns

### For investigation/research (read-only):

```
Agent(model="haiku", subagent_type="Explore", ...)  # Cheapest for read-only
```

### For implementation (writes code):

```
Agent(model="sonnet", isolation="worktree", ...)  # Isolated, mid-tier
```

### For architecture/security decisions:

```
Agent(model="opus", ...)  # Full reasoning for critical decisions
```

### Swarm pattern (3-5 parallel specialists):

```
# Launch all in a single message:
Agent(name="security", model="sonnet", ...)
Agent(name="performance", model="sonnet", ...)
Agent(name="architecture", model="sonnet", ...)
Agent(name="quality", model="sonnet", ...)
```

## Maximizing Parallelism in Practice

1. **Pre-compute shared context** — gather codebase info once, pass to all agents in spawn prompts
2. **Batch tool calls aggressively** — if you need 5 file reads, do all 5 in one message
3. **Use background agents** — for long-running tasks, use `run_in_background: true` and continue other work
4. **Shut down finished agents immediately** — idle agents waste tokens on every broadcast
5. **Never poll** — use hooks (TeammateIdle, TaskCompleted) instead of sleep loops

## Token Budget Awareness

Parallel execution multiplies context windows. Apply the model tier strategy:

- Haiku for mechanical tasks (explore, test, format)
- Sonnet for judgment tasks (review, implement, fix)
- Opus only for orchestration and critical decisions

The sweet spot is 3-5 parallel agents. Below 3, overhead exceeds benefit. Above 5, token costs explode and coordination degrades.
