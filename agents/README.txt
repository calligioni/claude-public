# Agents

Specialized agents for Claude Code. Each agent is a focused specialist that can be spawned by the orchestrator or invoked directly.

## Active Agents

| Agent | Model | Description |
|-------|-------|-------------|
| **backend-agent** | opus | Backend development for Node.js, Python, Go, and serverless. Handles APIs (REST, GraphQL, gRPC, OpenAPI), databases, auth, background jobs, and performance optimization. |
| **code-review-agent** | opus | Multi-perspective review orchestrator. Spawns parallel specialist reviewers (security, performance, architecture, stack-specific) before PR submission. Lives in `review/`. |
| **database-agent** | sonnet | Schema design, migrations, query optimization, indexing, and data modeling. Supports PostgreSQL, MySQL, MongoDB, Redis. |
| **devops-agent** | sonnet | CI/CD pipelines, Docker, Kubernetes, cloud deployments (Railway, Vercel, DigitalOcean), and infrastructure as code. |
| **frontend-agent** | opus | Frontend development for React, Vue, Angular, Next.js, Svelte, and vanilla TS/JS. Covers components, state management, styling (Tailwind/shadcn), and accessibility. |
| **oncall-guide** | opus | Production incident diagnosis. Correlates git history, database health (Postgres MCP), infrastructure status (DigitalOcean MCP), and external dependencies to identify root causes. |
| **performance-agent** | sonnet | Profiling, Lighthouse audits, load testing, query optimization, and bundle analysis for web apps, APIs, and databases. |
| **project-orchestrator** | opus | Full project lifecycle: analyze codebase, create plan, coordinate frontend/backend/database agents, run tests until passing, deploy to GitHub and Railway. |
| **security-agent** | sonnet | Vulnerability scanning, OWASP checks, dependency audits, and security best practice enforcement. Read-only review. |

## Archived Agents

Located in `_archive/`. These were consolidated or demoted:

| Agent | Reason |
|-------|--------|
| api-agent | Merged into backend-agent (API scope already covered) |
| codereview-agent | Superseded by code-review-agent (parallel orchestrator covers all review use cases) |
| documentation-agent | Demoted — documentation is a task, not an agent |
| fulltesting-agent | Subagent of fulltest-skill, not needed at top level |
| page-tester | Subagent of fulltest-skill, not needed at top level |
| test-analyst | Subagent of fulltest-skill, not needed at top level |
