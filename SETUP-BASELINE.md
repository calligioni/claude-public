# Setup Baseline Inventory

**Last verified:** 2026-03-30
**Next review:** Biweekly (Wednesday + Sunday, 6am)

---

## MCP Servers (19)

| #   | Server              | Purpose                         | Status |
| --- | ------------------- | ------------------------------- | ------ |
| 1   | sequential-thinking | Structured problem solving      | Active |
| 2   | memory              | Knowledge graph (Turso-backed)  | Active |
| 3   | playwright          | Browser automation              | Active |
| 4   | github              | GitHub API                      | Active |
| 5   | brave-search        | Web search (LLM Context API)    | Active |
| 6   | exa                 | Neural search with highlights   | Active |
| 7   | postgres            | PostgreSQL (Claudia on Contabo) | Active |
| 8   | resend              | Transactional email             | Active |
| 9   | slack               | Slack integration               | Active |
| 10  | notion              | Notion workspace                | Active |
| 11  | digitalocean        | DO App Platform, DBs, Spaces    | Active |
| 12  | chrome-devtools     | Chrome DevTools automation      | Active |
| 13  | firecrawl           | Web scraping/crawling           | Active |
| 14  | ScraplingServer     | Stealth scraping, anti-bot      | Active |
| 15  | context-mode        | Context window compression      | Active |
| 16  | qmd                 | Hybrid search over markdown     | Active |
| 17  | google-workspace    | GWS (p@nuvini.ai)               | Active |
| 18  | plugin:discord      | Discord bot                     | Active |
| 19  | plugin:swift-lsp    | Swift LSP                       | Active |

## Skills (69)

### Developer Workflow (21)

ship, deep-plan, cto, first-principles, verify, test-and-fix, review-changes, cpr, sc, cs, run-local, parallel-dev, codebase-cleanup, website-design, project-orchestrator, maketree, revert-track, simplify, get-api-docs, architecture, mini-remote

### QA & Testing (9)

qa-cycle, qa-conta, qa-sourcerank, qa-stonegeo, qa-fix, qa-verify, fulltest-skill, virtual-user-testing, health-report

### Deploy & Ops (5)

deploy-conta-staging, deploy-conta-production, deploy-sourcerank, contably-guardian, sourcerank-guardian, oci-health

### Research & Scraping (7)

deep-research, research, firecrawl, scrapling, browserless, pinchtab, qmd

### AI & Growth (3)

llm-eval, growth, chief-geo

### Communication (4)

agentmail, slack, tweet, gws

### Product & Business (3)

cpo, office-hours, proposal-source

### Meta & Setup (7)

claude-setup-optimizer, memory-consolidation, meditate, primer, skill-tree, demo, manual

### Infra & Agents (4)

nanoclaw, computer-use, paperclip, paperclip-create-agent

### Built-in Extensions (3)

loop, batch, memory

### Security (1)

rex

### Advisory (1)

vibc

## Agents (8)

backend-agent, database-agent, devops-agent, frontend-agent, oncall-guide, performance-agent, project-orchestrator, review/ (multi-perspective)

## Rules (6)

AGENT-TEAMS-STRATEGY.md, memory-strategy.md, model-tier-strategy.md, nuvini-sync-rules.md, parallel-first.md, skill-first.md, tool-annotations.md, web-search-efficiency.md

## Hooks (Active)

| Event              | Purpose                                  |
| ------------------ | ---------------------------------------- |
| SessionStart       | git pull + core memory load              |
| SubagentStart/Stop | Logging                                  |
| PostToolUse        | Auto-formatting, skill execution logging |
| TeammateIdle       | Task assignment prompts                  |
| TaskCompleted      | Auto-assignment for idle teammates       |
| TaskCreated        | Task creation logging                    |
| PostCompact        | State file recovery                      |
| CwdChanged         | Git branch context refresh               |
| StopFailure        | API error logging                        |
| ConfigChange       | Config audit logging                     |
| Elicitation/Result | MCP elicitation logging                  |

## Role Coverage

### Developer (Primary) — Coverage: HIGH

- Full CI/CD: verify → review → commit → push → PR
- Parallel dev with worktrees
- QA cycle with auto-fix
- CTO-level architecture review
- Deep planning and research
- Browser automation (3 options)
- Web scraping (3 options)

### M&A Analyst (Secondary) — Coverage: LOW

- Deep research for due diligence
- Google Workspace for docs/sheets
- No dedicated financial modeling tools
- No deal pipeline tracking
- No valuation templates
- No comparable analysis automation

### Gaps Identified

#### M&A Analyst Gaps

- Financial modeling / DCF templates
- Deal pipeline tracking (CRM-like)
- Comparable company analysis automation
- Market data feeds (financial APIs)
- Board reporting templates

#### Developer Gaps (Minor)

- No dedicated monitoring/alerting skill
- No load testing / performance benchmarking skill
- No database migration management skill
