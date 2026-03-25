---
name: Anthropic harness design patterns
description: Planner/generator/evaluator three-agent pattern and structured handoff (no compaction) for long-running agent sessions — from Anthropic engineering post on frontend design
type: reference
---

Anthropic engineering published a detailed breakdown of their three-agent harness (planner → generator → evaluator) used for frontend design and multi-hour autonomous software engineering.

**Key findings:**

1. **Self-evaluation bias:** Generators systematically rate their own work 4-5/5 regardless of quality. An independent evaluator (separate agent, no access to generator's conversation) calibrated toward skepticism catches issues self-review misses.

2. **Structured handoff > compaction:** For long-running sessions, full context resets with a structured handoff document outperform compacted contexts. Compaction preserves "context anxiety" — models become cautious, produce shorter outputs, and rush to complete. A clean handoff with explicit state transfer eliminates this.

3. **Harness design is not static:** Every component encodes an assumption about what the model can't do alone. As capabilities improve, audit and remove scaffolding that's no longer load-bearing.

4. **Design rubric:** Four criteria for evaluating frontend output — design quality (coherent visual identity), originality (custom decisions, not template defaults), craft (typography, spacing), functionality.

**Applied in:**

- `/ship` v6.0.0 — Phase 4.7 Interactive Evaluation + structured handoff (2026-03-24)
- `/parallel-dev` v3.0.0 — Phase 4.65 Interactive Evaluation + structured handoff (2026-03-24)

**Source:** https://anthropic.com/engineering/harness-design-long-running-apps
**Discovered:** 2026-03-24
