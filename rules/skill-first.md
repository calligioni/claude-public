# Skill-First Rule

## Mandatory Pre-Flight Check

**BEFORE starting ANY task, scan the available skills list in the system reminder and check if a skill covers it.** Never do ad-hoc what a skill already handles. Skills use optimized pipelines, swarms, and established patterns — they are faster and more thorough than improvising.

When you identify a matching skill, tell the user which skill you're invoking and why, then call it via the Skill tool.

## Routing Table

### Development Workflow

| Task                          | Skill                   | When                                        |
| ----------------------------- | ----------------------- | ------------------------------------------- |
| Build a feature end-to-end    | `/ship`                 | Feature requires spec → implement → test    |
| Plan complex implementation   | `/deep-plan`            | Need research → plan → implement phases     |
| Quick architecture advice     | `/cto`                  | Technical decision, swarm analysis          |
| Break down hard problem       | `/first-principles`     | Ambiguous or complex problem                |
| Run project tests + typecheck | `/verify`               | After making changes, before committing     |
| Fix failing tests             | `/test-and-fix`         | Tests are broken, need auto-fix loop        |
| Review code before commit     | `/review-changes`       | Uncommitted changes need review             |
| Commit + push + PR            | `/cpr`                  | Ready to ship to remote                     |
| Start local dev server        | `/run-local`            | Need to run project locally                 |
| Parallel feature branches     | `/parallel-dev`         | Multiple independent features               |
| Clean unused files            | `/codebase-cleanup`     | Project has cruft                           |
| Design website/landing page   | `/website-design`       | Any web UI design task                      |
| Full project lifecycle        | `/project-orchestrator` | New project from zero to production         |
| End-of-session reflection     | `/meditate`             | After /ship, /cto, /parallel-dev, long work |
| Commit + push (no PR)         | `/cp`                   | Ready to push, no PR needed                 |
| Full product from idea        | `/cpo`                  | Product lifecycle: discovery → spec → build |
| Git worktree management       | `/maketree`             | Create/manage isolated worktrees            |
| Refactor for clarity          | `/simplify` (built-in)  | Clean up code after long session or PR      |
| Parallel codebase migration   | `/batch` (built-in)     | Repetitive changes across many files        |
| Revert a feature/track        | `/revert-track`         | Undo a feature, phase, or commit range      |

### QA & Testing

| Task                        | Skill                   | When                                                                |
| --------------------------- | ----------------------- | ------------------------------------------------------------------- |
| Full QA cycle (any project) | `/qa-cycle`             | Master orchestrator — auto-detects project                          |
| Contably QA specifically    | `/qa-conta`             | Contably-specific testing                                           |
| SourceRank QA specifically  | `/qa-sourcerank`        | SourceRank-specific testing                                         |
| Fix issues from QA DB       | `/qa-fix`               | Open QA issues need fixing                                          |
| Verify fixed issues         | `/qa-verify`            | Issues in TESTING status                                            |
| Full-spectrum site testing  | `/fulltest-skill`       | Sub-skill called by qa-cycle; or direct for standalone site testing |
| Persona-based user testing  | `/virtual-user-testing` | Simulate real user journeys                                         |
| Check Contably on OCI       | `/oci-health`           | Is Contably up?                                                     |

### Research & Analysis

| Task                         | Skill            | When                                          |
| ---------------------------- | ---------------- | --------------------------------------------- |
| Deep multi-track research    | `/deep-research` | Any research question                         |
| Analyze URL/image/tool       | `/research`      | Evaluate a specific resource                  |
| Web scraping                 | `/firecrawl`     | Extract data from websites                    |
| Anti-bot / Cloudflare scrape | `/scrapling`     | Stealth scraping, TLS impersonation, anti-bot |
| Headless browser automation  | `/browserless`   | PDFs, screenshots, Lighthouse                 |

### Communication & Utilities

| Task                           | Skill                     |
| ------------------------------ | ------------------------- |
| Send/manage email              | `/agentmail`              |
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

Long-running skills like `/parallel-dev`, `/cto` (swarm), `/qa-cycle`, and `/fulltest-skill` can be monitored from any browser or mobile device using Claude Code Remote Control (Pro/Max, research preview).

- **From within a session:** type `/remote-control` or `/rc`
- **From CLI:** `claude remote-control` (supports `--verbose`, `--sandbox`, `--no-sandbox`)
- Uses outbound HTTPS polling only — no inbound ports needed
- Sessions reconnect automatically after network drops

Useful for fire-and-forget workflows: launch the skill locally, then monitor/approve from phone.

## Composing Skills

Many tasks benefit from chaining skills:

- Feature work: `/deep-plan` → `/ship` → `/verify` → `/cpr`
- QA cycle: `/qa-cycle` → `/qa-fix` → `/qa-verify`
- Release: `/review-changes` → `/verify` → `/cpr`
