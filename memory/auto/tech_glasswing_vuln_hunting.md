---
name: tech_glasswing_vuln_hunting
description: Anthropic Project Glasswing — $100M+ AI vulnerability initiative using Claude Mythos Preview (83.1% CyberGym repro rate). Glasswing-style prompting added to /cto security analyst.
type: project
---

**Project Glasswing** — Anthropic's initiative to find critical software vulnerabilities using Claude Mythos Preview.

Key facts:

- Claude Mythos Preview: 83.1% vulnerability reproduction rate on CyberGym benchmarks (vs Opus 66.6%)
- Found thousands of zero-days including 27-year-old OpenBSD flaw and 16-year FFmpeg bug
- Partners: AWS, Apple, Cisco, Google, Microsoft; extending to 40+ critical infrastructure orgs
- Announced via https://anthropic.com/glasswing

**Applied:** Updated `/cto` security-analyst spawn prompt with "CODE ARCHAEOLOGY" section — Glasswing-style deep vulnerability hunting targeting:

- Stale code paths (files unchanged 2+ years)
- Integer overflow in length/size calculations
- Use-after-free / dangling references
- FFI/C boundary trust violations
- Parser edge cases
- Implicit type coercion in security checks

**Why:** Code that survived years of review unchanged is where the highest-impact vulnerabilities hide. This prompting pattern works with current models (Sonnet/Opus) — no need to wait for Mythos API.

**Future:** When Claude Mythos Preview becomes API-available, route `/cto` security-analyst to it instead of Sonnet. The 83.1% vs 66.6% gap is material for vuln detection.

Discovered: 2026-04-07
Source: research — https://x.com/AnthropicAI/status/2041578392852517128
