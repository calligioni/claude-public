# Setup Baseline Inventory

**Last verified:** 2026-04-10
**Next review:** Biweekly (Wednesday + Sunday, 6am)

---

## MCP Servers (18)

| #   | Server              | Purpose                         | Status                                      |
| --- | ------------------- | ------------------------------- | ------------------------------------------- |
| 1   | sequential-thinking | Structured problem solving      | Active                                      |
| 2   | memory              | Knowledge graph (Turso-backed)  | Active                                      |
| 3   | playwright          | Browser automation              | Active                                      |
| 4   | github              | GitHub API                      | Active                                      |
| 5   | brave-search        | Web search (LLM Context API)    | Active                                      |
| 6   | exa                 | Neural search with highlights   | Active                                      |
| 7   | postgres            | PostgreSQL (Claudia on Contabo) | Active                                      |
| 8   | resend              | Transactional email             | Active                                      |
| 9   | slack               | Slack integration               | Active                                      |
| 10  | notion              | Notion workspace                | Active                                      |
| 11  | digitalocean        | DO App Platform, DBs, Spaces    | Active                                      |
| 12  | chrome-devtools     | Chrome DevTools automation      | Active                                      |
| 13  | firecrawl           | Web scraping/crawling           | Active                                      |
| 14  | ScraplingServer     | Stealth scraping, anti-bot      | Active                                      |
| 15  | context-mode        | Context window compression      | Active                                      |
| 16  | qmd                 | Hybrid search over markdown     | Active                                      |
| 17  | google-workspace    | GWS (p@nuvini.ai)               | Active (uvx workspace-mcp, not in settings) |
| 18  | officecli           | Office doc creation/editing     | Active                                      |

**Note:** plugin:discord and plugin:swift-lsp moved to `enabledPlugins` system. google-workspace is active but configured outside settings.json (uvx workspace-mcp).

## Skills (130+)

### Developer Workflow (24)

ship, deep-plan, cto, first-principles, verify, test-and-fix, review-changes, cpr, sc, cs, run-local, parallel-dev, codebase-cleanup, website-design, project-orchestrator, maketree, revert-track, simplify, get-api-docs, architecture, mini-remote, architect, tech-audit, local-inference

### QA & Testing (9)

qa-cycle, qa-conta, qa-sourcerank, qa-stonegeo, qa-fix, qa-verify, fulltest-skill, virtual-user-testing, health-report

### Deploy & Ops (5)

deploy-conta-staging, deploy-conta-production, deploy-sourcerank, contably-guardian, sourcerank-guardian, oci-health

### Research & Scraping (9)

deep-research, research, firecrawl, scrapling, browserless, pinchtab, qmd, last30days, wiki

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

### Finance & M&A (12+)

finance-dcf, finance-comps, finance-lbo, finance-model, finance-memo, finance-pitch, finance-cim, finance-dataroom, finance-ic, finance-nda, finance-loi, finance-spa, mna-pipeline, mna-diligence, mna-synergies, mna-integration, ir-deck, ir-earnings, ir-model, compliance-kyc, compliance-aml, compliance-reporting, legal-review, legal-redline, analyze-deal, committee-presenter, aimpact, generate-deck, portfolio-monitor, portfolio-report, portfolio-valuation, financial-model

## Agents (9)

backend-agent, database-agent, devops-agent, frontend-agent, oncall-guide, performance-agent, project-orchestrator, security-agent, review/ (multi-perspective)

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

### M&A Analyst (Secondary) — Coverage: HIGH

- Deep research for due diligence (deep-research, mna-diligence)
- Financial modeling: DCF, LBO, comps, valuation (finance-dcf, finance-lbo, finance-comps, financial-model)
- Deal pipeline and memo generation (mna-pipeline, finance-memo, finance-cim)
- IC and board presentation (committee-presenter, generate-deck, ir-deck)
- Legal document review and redlining (legal-review, legal-redline, finance-nda, finance-loi, finance-spa)
- Portfolio monitoring and reporting (portfolio-monitor, portfolio-report, portfolio-valuation)
- Compliance: KYC, AML, regulatory reporting (compliance-kyc, compliance-aml, compliance-reporting)
- AI impact analysis (aimpact)
- IR materials: earnings decks, investor model (ir-earnings, ir-model)
- Google Workspace for docs/sheets

### Gaps Identified

#### Developer Gaps (Minor)

- No dedicated monitoring/alerting skill
- No load testing / performance benchmarking skill
- No database migration management skill
