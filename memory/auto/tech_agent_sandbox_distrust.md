---
name: agent-sandbox-design-for-distrust
description: Security principle for multi-agent systems — enforce isolation at OS/VM layer, not by trusting agent behavior. NanoClaw + Docker Sandbox as reference implementation.
type: reference
---

Enforce security outside the agentic surface (at the OS/VM layer), not by relying on agent behavior.

**Reference implementation:** NanoClaw uses a two-layer model:

1. Container isolation (Docker/Apple Container) — ephemeral per-agent containers with mount allowlists
2. Micro-VM isolation (Docker Sandbox) — hypervisor-level boundaries, proxy-managed API keys

**Why:** Agents are unpredictable. Permission-based security (whitelists, codes) fails when agents find creative workarounds. OS-level isolation makes the security boundary orthogonal to agent behavior.

**How to apply:** Relevant to any multi-agent skill — `parallel-dev` (worktree isolation is git-level, not OS-level), `cto` swarm, `fulltest-skill`, `qa-cycle`. When evaluating agent isolation strategies, prefer container/VM boundaries over behavioral trust.

**Source:** https://nanoclaw.dev/blog/nanoclaw-docker-sandboxes/ (2026-03-13)
