# Skill-First Rule

## Mandatory Pre-Flight Check

**BEFORE starting ANY task, scan the available skills list in the system reminder and check if a skill covers it.** Never do ad-hoc what a skill already handles. Skills use optimized pipelines, swarms, and established patterns — they are faster and more thorough than improvising.

When you identify a matching skill, tell the user which skill you're invoking and why, then call it via the Skill tool.

## Routing Table

### Development Workflow

| Task                          | Skill                   | When                                     |
| ----------------------------- | ----------------------- | ---------------------------------------- |
| Build a feature end-to-end    | `/ship`                 | Feature requires spec → implement → test |
| Plan complex implementation   | `/deep-plan`            | Need research → plan → implement phases  |
| Quick architecture advice     | `/cto`                  | Technical decision, swarm analysis       |
| Break down hard problem       | `/first-principles`     | Ambiguous or complex problem             |
| Run project tests + typecheck | `/verify`               | After making changes, before committing  |
| Fix failing tests             | `/test-and-fix`         | Tests are broken, need auto-fix loop     |
| Review code before commit     | `/review-changes`       | Uncommitted changes need review          |
| Commit + push + PR            | `/cpr`                  | Ready to ship to remote                  |
| Start local dev server        | `/run-local`            | Need to run project locally              |
| Parallel feature branches     | `/parallel-dev`         | Multiple independent features            |
| Clean unused files            | `/codebase-cleanup`     | Project has cruft                        |
| Design website/landing page   | `/website-design`       | Any web UI design task                   |
| Full project lifecycle        | `/project-orchestrator` | New project from zero to production      |

### QA & Testing

| Task                        | Skill                   | When                                       |
| --------------------------- | ----------------------- | ------------------------------------------ |
| Full QA cycle (any project) | `/qa-cycle`             | Master orchestrator — auto-detects project |
| Contably QA specifically    | `/qa-conta`             | Contably-specific testing                  |
| SourceRank QA specifically  | `/qa-sourcerank`        | SourceRank-specific testing                |
| Fix issues from QA DB       | `/qa-fix`               | Open QA issues need fixing                 |
| Verify fixed issues         | `/qa-verify`            | Issues in TESTING status                   |
| Full-spectrum site testing  | `/fulltest-skill`       | Comprehensive swarm testing                |
| Persona-based user testing  | `/virtual-user-testing` | Simulate real user journeys                |
| Check Contably on OCI       | `/oci-health`           | Is Contably up?                            |

### Research & Analysis

| Task                        | Skill            | When                          |
| --------------------------- | ---------------- | ----------------------------- |
| Deep multi-track research   | `/deep-research` | Any research question         |
| Analyze URL/image/tool      | `/research`      | Evaluate a specific resource  |
| Web scraping                | `/firecrawl`     | Extract data from websites    |
| Headless browser automation | `/browserless`   | PDFs, screenshots, Lighthouse |

### M&A (Nuvini)

| Task                     | Skill                                  | When                            |
| ------------------------ | -------------------------------------- | ------------------------------- |
| Any M&A operation        | `/mna-toolkit`                         | Unified entry point for all M&A |
| Full deal analysis       | `/analyze-deal`                        | End-to-end company analysis     |
| Quick deal scoring       | `/triage`                              | Score target 0-10               |
| Pipeline management      | `/mna-pipeline`                        | Check/update deal funnel        |
| Due diligence            | `/mna-dd-checklist`, `/mna-dd-tracker` | DD phase                        |
| Term sheet               | `/mna-termsheet`                       | Deal at term sheet stage        |
| NDA generation           | `/mna-nda-gen`                         | New target needs NDA            |
| IC briefing              | `/mna-ic-brief`                        | Weekly IC package               |
| Integration playbook     | `/mna-integration`                     | Post-closing                    |
| Market scanning          | `/mna-market-scan`                     | Proactive deal sourcing         |
| Financial model/proposal | `/financial-model`                     | IRR/MOIC analysis               |
| Board presentation       | `/generate-deck`                       | M&A board deck                  |

### Finance (Nuvini)

| Task                | Prefix                          | Skills                        |
| ------------------- | ------------------------------- | ----------------------------- |
| Monthly close       | `/finance-closing-orchestrator` | Checklist + document tracking |
| Consolidation       | `/finance-consolidation`        | Multi-entity trial balance    |
| Bank reconciliation | `/finance-bank-recon`           | Statement parsing + matching  |
| Cash flow forecast  | `/finance-cash-flow-forecast`   | 13-week and 12-month          |
| Budget              | `/finance-budget-builder`       | Annual per entity             |
| Rolling forecast    | `/finance-rolling-forecast`     | 12-month updated monthly      |
| Scenarios           | `/finance-scenario-modeler`     | Monte Carlo + sensitivity     |
| Variance analysis   | `/finance-variance-commentary`  | Auto-generate explanations    |
| DRE (Brazilian P&L) | `/finance-dre-generator`        | Per subsidiary                |
| Management report   | `/finance-management-report`    | Executive summary package     |
| Intercompany loans  | `/finance-mutuo-calculator`     | Interest + FX accruals        |
| Earn-out tracking   | `/finance-earnout-tracker`      | SPA obligation calc           |

### Legal & Compliance (Nuvini)

| Task                     | Skill                            |
| ------------------------ | -------------------------------- |
| Contract generation      | `/legal-contract-generator`      |
| Contract review          | `/legal-contract-reviewer`       |
| Entity registry          | `/legal-entity-registry`         |
| Compliance calendar      | `/legal-compliance-calendar`     |
| SEC 20-F drafting        | `/legal-20f-assistant`           |
| NDA review               | `/nda-reviewer`                  |
| SEC filing tracking      | `/compliance-sec-filing-tracker` |
| NASDAQ monitoring        | `/compliance-nasdaq-monitor`     |
| Regulatory monitoring    | `/compliance-regulatory-monitor` |
| Board minutes            | `/compliance-minutes-drafter`    |
| Board packages           | `/compliance-board-package`      |
| Annual compliance report | `/compliance-annual-report`      |

### IR (Nuvini)

| Task              | Skill                     |
| ----------------- | ------------------------- |
| Investor tracking | `/ir-investor-tracker`    |
| Fund/LP tracking  | `/ir-fund-tracker`        |
| Capital register  | `/ir-capital-register`    |
| Earnings release  | `/ir-earnings-release`    |
| Press release     | `/ir-press-release-draft` |
| Investor Q&A      | `/ir-qna-draft`           |
| Deck updates      | `/ir-deck-updater`        |

### Portfolio (Nuvini)

| Task                    | Skill                            |
| ----------------------- | -------------------------------- |
| KPI dashboard           | `/portfolio-kpi-dashboard`       |
| NOR ingestion           | `/portfolio-nor-ingest`          |
| Portfolio reports       | `/portfolio-reporter`            |
| New acquisition onboard | `/portfolio-acquisition-onboard` |

### Communication & Utilities

| Task                  | Skill                     |
| --------------------- | ------------------------- |
| Send/manage email     | `/agentmail`              |
| Fetch tweet           | `/tweet`                  |
| Memory maintenance    | `/memory-consolidation`   |
| Optimize claude setup | `/claude-setup-optimizer` |
| Sync setup repo       | `/cs`                     |
| Build user manual     | `/manual`                 |

## When to Go Ad-Hoc

Only skip skills when:

1. The task is a **single small edit** (fix a typo, change a value)
2. The user explicitly asks for a specific manual approach
3. No skill covers the task at all
4. The task is pure conversation/explanation (no implementation)

## Composing Skills

Many tasks benefit from chaining skills:

- Feature work: `/deep-plan` → `/ship` → `/verify` → `/cpr`
- QA cycle: `/qa-cycle` → `/qa-fix` → `/qa-verify`
- Release: `/review-changes` → `/verify` → `/cpr`
- M&A deal: `/triage` → `/analyze-deal` → `/mna-dd-checklist` → `/mna-termsheet`
