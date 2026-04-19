# CPO AI Skill

**Chief Product Officer AI** - Transform product ideas into production-ready, deployed applications.

## Quick Start

### `/cpo-go` - New Projects

```bash
/cpo-go <project-name> <description>
```

**Examples:**

```bash
/cpo-go game create an interactive tic-tac-toe game
/cpo-go taskflow build a task management app for small teams
/cpo-go artmarket create a marketplace where artists can sell digital art
```

**Fast Mode:** Reply `"go"` to use defaults and start immediately:
- Creates **public GitHub repo** with project name
- **MVP** scope
- **Web app** (Next.js + Supabase)
- **Speed** priority
- **Auto-deploys** to Vercel

### `/cpo-iterate` - Existing Projects

```bash
/cpo-iterate <description of changes>
```

**Examples:**

```bash
/cpo-iterate add user profile editing and avatar uploads
/cpo-iterate fix the checkout flow bug and improve error messages
/cpo-iterate add dark mode support across all pages
```

Continues development on an existing project with full context preservation.

---

## What's New in v2.1.0

- **`/cpo-iterate` Command** - Continue development with new features/fixes on existing projects
- **Rollback Mechanisms** - Git-based checkpoints with automatic and manual recovery
- **Memory Caching** - Research results cached via Memory MCP for cross-project reuse
- **Visual Progress** - ASCII dashboards and HTML progress reports
- **Production Monitoring** - Automatic Sentry, PostHog, and uptime monitoring setup
- **Modular Architecture** - SKILL.md split into focused reference documents

### v2.0.0 Features

- **Backend API Agent** - REST/GraphQL design, authentication, error handling
- **Database Setup Agent** - Supabase/Neon provisioning, schema generation, migrations
- **Deployment Agent** - Actual deployment execution (Vercel, Railway, DigitalOcean)
- **Cost Estimation** - Infrastructure cost projections shown after planning
- **Environment Configuration** - Automatic `.env.example` generation
- **Testing Integration** - Tighter integration with fulltest-skill, coverage tracking

---

## Overview

The CPO AI Skill orchestrates the entire product development lifecycle:

1. **Discovery** - Qualify ideas through strategic questions
2. **Planning** - Break down into epics, stages, and stories + cost estimate
3. **Execution** - Implement stage-by-stage with specialized agents
4. **Validation** - Full project integration testing
5. **Delivery** - Documentation and **actual deployment**

## Workflow

```
Product Idea → Discovery → Strategic Plan → Stage Implementation → Testing → Deploy → Go Live
                              ↓
                     Cost Estimate Shown
```

## Key Files Generated

| File | Purpose |
|------|---------|
| `master-project.json` | Complete project state and progress |
| `cpo-progress.md` | Detailed progress log |
| `.env.example` | Environment configuration template |
| `docs/user-guide.md` | End-user documentation |
| `docs/technical-docs.md` | Developer documentation |

## Specialized Subagents

The CPO AI orchestrates **six specialized agents** for best-in-class results:

| Agent | Purpose | Phase |
|-------|---------|-------|
| **Product Research Agent** | Market research, competitor analysis, design references | 1, 2 |
| **CTO Advisor Agent** | Tech stack selection, architecture, deployment strategy | 2, 3.1 |
| **Frontend Design Agent** | Distinctive, production-grade UI | 3 (UI) |
| **Backend API Agent** | REST/GraphQL design, auth, error handling | 3 (API) |
| **Database Setup Agent** | Schema design, migrations, Supabase/Neon setup | 3.1 |
| **Deployment Agent** | Vercel/Railway/DigitalOcean deployment execution | 5 |

## Reference Documents

| Reference | Purpose |
|-----------|---------|
| [phase-details.md](./references/phase-details.md) | Detailed phase-by-phase instructions |
| [templates.md](./references/templates.md) | JSON/Markdown templates |
| [environment-config.md](./references/environment-config.md) | Environment variable templates |
| [testing-integration.md](./references/testing-integration.md) | Testing strategy and commands |
| [cost-estimation.md](./references/cost-estimation.md) | Infrastructure cost calculations |
| [rollback-mechanisms.md](./references/rollback-mechanisms.md) | Git checkpoints and recovery |
| [memory-caching.md](./references/memory-caching.md) | Research caching via Memory MCP |
| [visual-progress.md](./references/visual-progress.md) | ASCII/HTML progress displays |
| [iteration-support.md](./references/iteration-support.md) | /cpo-iterate command details |
| [production-monitoring.md](./references/production-monitoring.md) | Sentry, PostHog, uptime setup |
| [examples.md](./references/examples.md) | Complete workflow examples |

## Integration

Works with:
- **autonomous-dev** - Story-level implementation
- **fulltest-skill** - Comprehensive E2E testing
- **worktree-scaffold** - Isolated stage development

## Example

```
User: /cpo-go taskflow build a task management app for small teams

CPO AI: Quick Discovery for "taskflow"...
User: go

CPO AI:
1. [Research Agent] Analyzes Asana, Linear, Notion for best practices
2. [Research Agent] Collects design references and UI patterns
3. [CTO Agent] Recommends Next.js + Supabase stack
4. Creates strategic plan with 5 epics, 12 stages
5. Shows cost estimate: ~$0/month (free tier) → ~$45/month (at scale)
6. [Database Agent] Sets up Supabase, generates Prisma schema
7. Generates .env.example with all required variables
8. Implements Stage 1: Foundation
9. [Frontend Agent] Creates distinctive dashboard UI
10. [Backend Agent] Implements API endpoints with proper error handling
11. Tests each stage via fulltest-skill
12. ... continues until complete
13. Generates user guide and technical docs
14. [Deployment Agent] Deploys to Vercel
15. Verifies deployment with health checks
16. Product is LIVE!
```

## Documentation

- [SKILL.md](./SKILL.md) - Full skill specification
- [subagents/](./subagents/) - Specialized agent definitions
  - [product-research-agent.md](./subagents/product-research-agent.md)
  - [cto-advisor-agent.md](./subagents/cto-advisor-agent.md)
  - [frontend-design-agent.md](./subagents/frontend-design-agent.md)
  - [backend-api-agent.md](./subagents/backend-api-agent.md)
  - [database-setup-agent.md](./subagents/database-setup-agent.md)
  - [deployment-agent.md](./subagents/deployment-agent.md)
- [references/](./references/) - Configuration and examples
  - [phase-details.md](./references/phase-details.md)
  - [templates.md](./references/templates.md)
  - [environment-config.md](./references/environment-config.md)
  - [testing-integration.md](./references/testing-integration.md)
  - [cost-estimation.md](./references/cost-estimation.md)
  - [rollback-mechanisms.md](./references/rollback-mechanisms.md)
  - [memory-caching.md](./references/memory-caching.md)
  - [visual-progress.md](./references/visual-progress.md)
  - [iteration-support.md](./references/iteration-support.md)
  - [production-monitoring.md](./references/production-monitoring.md)
  - [examples.md](./references/examples.md)

## Sources

- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [Anthropic Frontend Design Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design)
- [Claude Agent SDK Demos](https://github.com/anthropics/claude-agent-sdk-demos)
- [VoltAgent Awesome Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)

## Version

2.1.0
