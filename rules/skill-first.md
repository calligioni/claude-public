# Skill-First Rule

## Mandatory Pre-Flight Check

**BEFORE starting ANY task, scan the available skills list in the system reminder and check if a skill covers it.** Never do ad-hoc what a skill already handles. Skills use optimized pipelines, swarms, and established patterns — they are faster and more thorough than improvising.

When you identify a matching skill, tell the user which skill you're invoking and why, then call it via the Skill tool.

## Routing Table

### Development Workflow

| Task                          | Skill                   | When                                                     |
| ----------------------------- | ----------------------- | -------------------------------------------------------- |
| Build a feature end-to-end    | `/ship`                 | Feature requires spec → implement → test                 |
| Plan complex implementation   | `/deep-plan`            | Need research → plan → implement phases                  |
| Quick architecture advice     | `/cto`                  | Technical decision, swarm analysis                       |
| Break down hard problem       | `/first-principles`     | Ambiguous or complex problem                             |
| Run project tests + typecheck | `/verify`               | After making changes, before committing                  |
| Fix failing tests             | `/test-and-fix`         | Tests are broken, need auto-fix loop                     |
| Review code before commit     | `/review-changes`       | Uncommitted changes need review                          |
| Commit + push + PR            | `/cpr`                  | Ready to ship to remote                                  |
| Start local dev server        | `/run-local`            | Need to run project locally                              |
| Parallel feature branches     | `/parallel-dev`         | Multiple independent features                            |
| Clean unused files            | `/codebase-cleanup`     | Project has cruft                                        |
| Design website/landing page   | `/website-design`       | Any web UI design task                                   |
| Full project lifecycle        | `/project-orchestrator` | New project from zero to production                      |
| End-of-session reflection     | `/meditate`             | After /ship, /cto, /parallel-dev, long work              |
| Full product from idea        | `/cpo`                  | Product lifecycle: discovery → spec → build              |
| Git worktree management       | `/maketree`             | Create/manage isolated worktrees                         |
| Refactor for clarity          | `/simplify` (built-in)  | Clean up code after long session or PR                   |
| Parallel codebase migration   | `/batch` (built-in)     | Repetitive changes across many files                     |
| Revert a feature/track        | `/revert-track`         | Undo a feature, phase, or commit range                   |
| Reproducible demo document    | `/demo`                 | Executable narrative with captured output                |
| Recurring interval task       | `/loop` (built-in)      | Poll status, repeat a command on a schedule              |
| Fetch API docs for a library  | `/get-api-docs`         | Before writing code that uses external APIs              |
| Split large docs into tree    | `/skill-tree`           | API docs or references too large for subagent context    |
| Build with Claude API/SDK     | `/claude-api`           | Code imports anthropic SDK or user asks about Claude API |
| Context recovery              | `/primer`               | After compaction, new session, or "where was I?"         |
| Search memory                 | `mem-search "<query>"`  | Find past decisions, patterns, learnings (CLI tool)      |
| Advisory board deliberation   | `/vibc`                 | Complex decision needing diverse perspectives            |
| Office docs (.docx/xlsx/pptx) | `/officecli`            | Create, edit, inspect Word/Excel/PowerPoint documents    |
| Tech stack audit              | `/tech-audit`           | Compare versions, find EOL libs, recommend upgrades      |
| Knowledge base / wiki         | `/wiki`                 | Ingest sources, query knowledge, persistent KB           |
| Local inference gateway       | `/local-inference`      | Set up LiteLLM multi-model gateway, local models         |

### QA & Testing

| Task                        | Skill                   | When                                                                |
| --------------------------- | ----------------------- | ------------------------------------------------------------------- |
| Full QA cycle (any project) | `/qa-cycle`             | Master orchestrator — auto-detects project                          |
| Contably QA specifically    | `/qa-conta`             | Contably-specific testing                                           |
| SourceRank QA specifically  | `/qa-sourcerank`        | SourceRank-specific testing                                         |
| SourceRank GEO strategy     | `/chief-geo`            | GEO knowledge base, product audit, visibility testing, daily runs   |
| Fix issues from QA DB       | `/qa-fix`               | Open QA issues need fixing                                          |
| Verify fixed issues         | `/qa-verify`            | Issues in TESTING status                                            |
| Full-spectrum site testing  | `/fulltest-skill`       | Sub-skill called by qa-cycle; or direct for standalone site testing |
| Persona-based user testing  | `/virtual-user-testing` | Simulate real user journeys                                         |
| Check Contably on OCI       | `/oci-health`           | Is Contably up?                                                     |

### Research & Analysis

| Task                         | Skill            | When                                              |
| ---------------------------- | ---------------- | ------------------------------------------------- |
| Semantic search over notes   | `/qmd`           | Find skills, patterns, decisions, past research   |
| Deep multi-track research    | `/deep-research` | Any research question                             |
| Social + web research (30d)  | `/last30days`    | Reddit/X/YouTube/HN/TikTok trends in last 30 days |
| Analyze URL/image/tool       | `/research`      | Evaluate a specific resource                      |
| Web scraping                 | `/firecrawl`     | Extract data from websites                        |
| Anti-bot / Cloudflare scrape | `/scrapling`     | Stealth scraping, TLS impersonation, anti-bot     |
| Headless browser automation  | `/browserless`   | PDFs, screenshots, Lighthouse                     |
| Local browser automation     | `/pinchtab`      | Token-efficient a11y tree, element refs, local    |

### AI Quality & Growth

| Task                        | Skill       | When                                         |
| --------------------------- | ----------- | -------------------------------------------- |
| Evaluate LLM output quality | `/llm-eval` | Any AI-powered feature needs quality metrics |
| Audit eval pipeline         | `/llm-eval` | Check existing evals for gaps                |
| RAG evaluation              | `/llm-eval` | Retrieval + generation quality               |
| Landing page CRO            | `/growth`   | Optimize conversion on any page              |
| Pricing strategy            | `/growth`   | Analyze/optimize SaaS pricing                |
| Signup/onboarding flow      | `/growth`   | Reduce friction in user acquisition          |
| SEO / AI SEO (GEO) audit    | `/growth`   | Improve organic + AI search visibility       |
| Churn prevention            | `/growth`   | Identify and reduce user churn               |
| Competitor comparison page  | `/growth`   | Build vs-competitor content                  |
| Email lifecycle sequences   | `/growth`   | Design activation/retention emails           |

### Client & Business

| Task                                                 | Skill              | When                                                  |
| ---------------------------------------------------- | ------------------ | ----------------------------------------------------- |
| SourceRank client proposal (GEO diagnostic/research) | `/proposal-source` | Client proposal from conversations, URLs, notes → PDF |

### Communication & Utilities

| Task                           | Skill                     |
| ------------------------------ | ------------------------- |
| Send/manage email              | `/agentmail`              |
| Slack messages / channels      | `/slack`                  |
| Fetch tweet                    | `/tweet`                  |
| Memory maintenance (Turso/MCP) | `/memory-consolidation`   |
| Manage auto-memory (built-in)  | `/memory`                 |
| Optimize claude setup          | `/claude-setup-optimizer` |
| Sync setup repo                | `/cs`                     |
| Build user manual              | `/manual`                 |

## When to Go Ad-Hoc

Only skip skills when:

1. The task is a **single small edit** (fix a typo, change a value)
2. The user explicitly asks for a specific manual approach
3. No skill covers the task at all
4. The task is pure conversation/explanation (no implementation)

> **Tip:** Run `claude agents` in the terminal to list all configured agents (specialist, project, and NuvinOS agents).

## Remote Monitoring (Remote Control)

Long-running skills like `/parallel-dev`, `/cto` (swarm), `/qa-cycle`, and `/fulltest-skill` can be monitored from any browser or mobile device using Claude Code Remote Control (Pro/Max/Team, v2.1.51+).

- **From within a session:** type `/remote-control` or `/rc` — attaches to current conversation with full history
- **From CLI:** `claude remote-control` — starts server mode (persistent, multi-session)
- **Interactive + remote:** `claude --remote-control` — normal interactive session with remote access enabled

### Server Mode Flags

| Flag                         | Description                                                                                                                                                                                                       |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--spawn worktree`           | Each concurrent remote session gets its own git worktree. **Recommended for `/parallel-dev` and `/qa-cycle`** — matches their existing worktree isolation model. Default: `same-dir`. Toggle at runtime with `w`. |
| `--capacity <N>`             | Max concurrent sessions (default: 32). Useful for `/fulltest-skill` with many parallel testers.                                                                                                                   |
| `--name "My Project"`        | Custom session title in the session list.                                                                                                                                                                         |
| `--verbose`                  | Detailed connection/session logs.                                                                                                                                                                                 |
| `--sandbox` / `--no-sandbox` | Filesystem/network isolation (off by default).                                                                                                                                                                    |

### Security Model

- Traffic routes through Anthropic API over TLS with short-lived scoped credentials
- No inbound ports opened — outbound HTTPS only
- Sessions reconnect automatically after network drops

### Access

Connect from another device via the session URL displayed in terminal, the QR code (press spacebar in server mode), or by finding the session in the claude.ai/code session list.

Useful for fire-and-forget workflows: launch the skill locally, then monitor/approve from phone.

## Composing Skills

Many tasks benefit from chaining skills:

- Feature work: `/deep-plan` → `/ship` → `/verify` → `/cpr`
- QA cycle: `/qa-cycle` → `/qa-fix` → `/qa-verify`
- Release: `/review-changes` → `/verify` → `/cpr`
