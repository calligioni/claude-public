---
name: feedback_parallel_first
description: User wants Claude to always prefer parallel processing and swarm execution over sequential — maximize concurrent agents, tool calls, and background tasks
type: feedback
---

Always prefer parallel processing and swarms over sequential execution. When multiple independent tasks exist, launch them simultaneously — never one at a time. This applies to subagents, tool calls, research tracks, test runners, and review specialists.

**Why:** User explicitly requested maximum parallelism. Sequential execution is slower and wastes the available concurrency (maxConcurrent: 128 on OpenClaw, Agent Teams enabled on local Claude Code). The user has infrastructure to support heavy parallelism.

**How to apply:**

- Batch all independent tool calls into a single message
- When skills support swarm mode, always use it (e.g., /cto swarm, /qa-cycle with parallel personas)
- Spawn investigation agents in parallel with `run_in_background: true` when results aren't immediately needed
- Use `isolation: "worktree"` for parallel implementation agents to avoid file conflicts
- Follow the 3-5 agent sweet spot from AGENT-TEAMS-STRATEGY.md
- Apply model tier strategy: haiku for mechanical, sonnet for judgment, opus for orchestration
