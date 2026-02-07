---
name: first-principles
description: "Break down a problem to its fundamentals before implementing. Use for complex or ambiguous problems."
argument-hint: "<problem description>"
user-invocable: true
context: normal
model: opus
permissionMode: plan
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - mcp__sequential-thinking__sequentialthinking
---

# First Principles Analysis

Structured problem decomposition before jumping into implementation. Forces clarity of thought.

## Process

Walk through these steps with the user, pausing for input at each stage:

### 1. Define the Problem

- What exactly are we trying to solve?
- What does success look like?
- What triggered this need?

### 2. Identify Constraints

- What are the hard technical constraints? (language, framework, infra, budget)
- What are the soft constraints? (timeline, team skills, existing patterns)
- What must NOT change?

### 3. Decompose

- Break the problem into independent subproblems
- Identify which subproblems are already solved (existing code, libraries)
- Identify which subproblems are novel and need design

### 4. Explore Approaches

For each novel subproblem, identify 2-3 approaches:

- What's the simplest approach?
- What's the most robust approach?
- What would an expert do?

### 5. Evaluate Trade-offs

For each approach:

- Complexity (implementation + maintenance)
- Risk (what could go wrong)
- Reversibility (how hard to change later)

### 6. Decide

- Select an approach with clear reasoning
- Document what we're explicitly NOT doing and why
- Define the first concrete step

## Rules

- Use sequential-thinking MCP for structured reasoning when the problem has many dimensions
- Read relevant code before proposing approaches — ground recommendations in reality
- Challenge assumptions — ask "why" at least once for each stated constraint
- Prefer the simplest approach that meets requirements
- If the user's framing of the problem seems wrong, say so
- Output a clear action plan at the end, not just analysis
