---
name: project_benchmark_loop_scaleup
description: RESOLVED — Benchmark loop removed (2026-04-09). Too dangerous for autonomous execution.
type: project
originSessionId: f190a821-92df-48a8-b2e2-9fcc886dbb6f
---

AutoAgent-style benchmark loop was deployed 2026-04-04 for claudia agent only (src/benchmark/).

**Status: REMOVED (2026-04-09)**

The benchmark-loop and auto-compound tasks were permanently removed from default-tasks.ts:

- Auto-compound modified agent persona files autonomously, destabilized the VPS
- Benchmark-loop sent `rm -rf /opt/claudia` via Agent SDK running as root — nuked the deployment twice
- No ledger was ever generated (no benchmark-ledger.json exists)

**Why removed:** Autonomous self-modification without human review is too risky. The compound-review (Phase 1, observe-only) was kept — it just logs findings to data/autoimprove/review-{date}.json.

**How to apply:** Use `/meditate` at session end for human-in-the-loop self-improvement. Do not re-enable autonomous overnight loops.
