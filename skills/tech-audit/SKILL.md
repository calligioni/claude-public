---
name: tech-audit
description: "Audit project tech stack against current market — compare versions, find EOL libs, recommend upgrades. Triggers on: tech audit, stack audit, dependency audit, upgrade check, what should we upgrade, outdated dependencies"
user-invocable: true
context: fork
model: opus
effort: high
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - WebSearch
  - WebFetch
  - mcp__brave-search__brave_web_search
  - mcp__exa__web_search_exa
  - AskUserQuestion
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

# Tech Stack Audit

Comprehensive audit of a project's tech stack against current market state. Identifies EOL libraries, security risks, version drift, and upgrade opportunities with prioritized recommendations.

## Workflow

### Phase 1: Stack Discovery (Orchestrator)

Scan the project to extract the full dependency tree:

1. **Package manifests:** Find all `package.json`, `pyproject.toml`, `requirements*.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json` files
2. **Framework detection:** Identify primary frameworks (Next.js, FastAPI, Rails, etc.) and their versions
3. **Infrastructure:** Check for Docker, CI configs, cloud provider files, ORM configs
4. **Categorize dependencies** into groups:
   - Frontend (framework, UI, state, routing, build tools)
   - Backend (framework, ORM, auth, cache, task queue, HTTP clients)
   - Infrastructure (package manager, monorepo tool, CI/CD, TypeScript/language version, linting)
   - AI/ML (if applicable: SDKs, vector DBs, embeddings)
   - Data (if applicable: data processing, analytics)

Pre-compute this context once — pass it to all research agents.

### Phase 2: Parallel Market Research (3-4 Agents)

Spawn parallel research agents by domain. Each agent receives the pre-computed stack context and researches using web search.

**Agent allocation:**

- **research-frontend** (model: sonnet) — frameworks, UI libs, state management, build tools, mobile
- **research-backend** (model: sonnet) — server framework, ORM, auth, cache, task queues, HTTP clients, data processing
- **research-infra** (model: sonnet) — language versions, package managers, monorepo tools, CI/CD, linting, databases
- **research-ai** (model: sonnet, optional) — AI SDKs, vector DBs, embeddings, ML tools (only if project has AI dependencies)

Each agent must use web search to verify current versions — never guess. Report format per dependency:

```
### [Category]: [Library]
- Current in project: vX.Y.Z
- Latest stable: vX.Y.Z (verified via npm/PyPI/GitHub)
- Key improvements: ...
- Breaking changes: yes/no + details
- Migration effort: low/medium/high
- Alternative worth considering: [name] or "none"
- Verdict: UPGRADE / KEEP / WATCH / REPLACE
```

### Phase 3: Synthesis (Orchestrator)

Once all research agents complete, synthesize into a single report:

1. **Triage by severity:**
   - CRITICAL: EOL/abandoned/security risk — fix within 2 weeks
   - HIGH: Major version behind, significant gains — fix within 1 month
   - MEDIUM: Notable version gap — fix within 1 quarter
   - LOW: Minor bumps or watch items

2. **Identify version alignment issues** — where the same library has different versions across apps/packages in a monorepo

3. **Group into upgrade waves** — batch compatible upgrades together, respecting dependency chains (e.g., upgrade React before React Router)

4. **Strategic observations** — patterns, consolidation opportunities, upcoming changes to plan for

### Phase 4: Output

Write the report to `TECH-AUDIT-{YYYY-MM}.md` in the project root.

The report should include:

- Executive summary with critical findings count
- Severity-ordered dependency list with verdicts
- Version alignment table (for monorepos)
- Recommended upgrade waves with timeline
- Strategic observations

## Configuration

### Scope Control

By default, audits all dependencies. User can narrow scope:

- `/tech-audit frontend` — only frontend dependencies
- `/tech-audit backend` — only backend dependencies
- `/tech-audit infra` — only infrastructure/tooling
- `/tech-audit critical` — only check for EOL/security issues (fastest)

### Agent Count

- Full audit: 3-4 parallel research agents (sonnet)
- Scoped audit: 1 research agent for the specified domain
- Critical-only: 1 agent checking EOL status and CVEs

## Key Principles

1. **Verify versions via web search** — never rely on training data for current version numbers
2. **Practical verdicts** — UPGRADE means "worth the effort now", not "newer exists"
3. **Migration effort is honest** — account for breaking changes, testing, and rollback risk
4. **Alternatives must be production-ready** — no bleeding-edge experiments
5. **Respect the existing stack** — don't recommend rewrites, recommend upgrades
6. **Pre-compute context** — orchestrator gathers stack info once, passes to all agents to avoid redundant file reads
