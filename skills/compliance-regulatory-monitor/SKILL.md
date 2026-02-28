---
name: compliance-regulatory-monitor
description: |
  Monitors regulatory bodies for new rules and publications affecting Nuvini's corporate profile.
  Covers CVM (Brazilian Securities Commission), ANPD (data protection / LGPD), Bacen (Central Bank —
  FX and intercompany lending rules), SEC (foreign private issuer rule changes), and CIMA (Cayman Islands
  Monetary Authority — Economic Substance Requirements). Filters publications for relevance to Nuvini's
  profile: Nasdaq-listed public company, Brazilian B2B SaaS holding structure, intercompany Mutuo lending,
  data processing. Outputs monthly regulatory bulletin, material alerts, and action items per agent.
  Triggers on: regulatory monitor, new regulations, regulatory bulletin, CVM update, SEC update,
  LGPD update, regulatory changes
argument-hint: "[regulator cvm|anpd|bacen|sec|cima|all] [--scan | --bulletin | --alerts | --action-items]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
  - Edit
  - WebSearch
  - WebFetch
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_find
  - mcp__google-workspace__docs_replaceText
  - mcp__google-workspace__docs_appendText
  - mcp__google-workspace__docs_move
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__drive_downloadFile
  - mcp__google-workspace__drive_findFolder
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_getRange
  - mcp__google-workspace__sheets_find
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_search
tool-annotations:
  readOnlyHint: false
  idempotentHint: false
  openWorldHint: true
invocation-contexts:
  user-direct:
    output: verbose
    confirm-destructive: true
    format: markdown
  agent-spawned:
    output: minimal
    confirm-destructive: false
    format: structured
memory: user
---

## Overview

Owned by Scheduler (Compliance Agent). Performs periodic web searches across five regulatory bodies to detect new rules, guidance, consultations, and enforcement actions relevant to Nuvini's multi-jurisdictional corporate profile. Filters raw regulatory output against a relevance profile, summarizes impact, and assigns action items to the responsible agent. Produces a monthly regulatory bulletin as a Google Doc and sends material alerts in real time.

Nuvini's regulatory exposure profile:

- **Public company obligations**: Nasdaq listing rules, SEC foreign private issuer requirements (20-F, 6-K, Regulation FD, SOX)
- **Brazilian public company**: CVM rules (RCVM 21 compliance program, periodic disclosures, related-party transactions, insider trading)
- **Data processing**: ANPD / LGPD obligations for 8 portfolio SaaS companies and Nuvini S.A. as data controller
- **Intercompany lending**: Bacen rules on cross-border Mutuo contracts, IOF, BACEN RDE-IED registration, FX settlement
- **Cayman holding structure**: CIMA Economic Substance Requirements (ESR) for NVNI Group (Cayman) and Nuvini Holdings (Cayman)

## Usage

```bash
# Full scan across all 5 regulators — find anything new since last run
/compliance-regulatory-monitor all --scan

# Scan a single regulator only
/compliance-regulatory-monitor cvm --scan
/compliance-regulatory-monitor anpd --scan
/compliance-regulatory-monitor bacen --scan
/compliance-regulatory-monitor sec --scan
/compliance-regulatory-monitor cima --scan

# Generate monthly regulatory bulletin (Google Doc)
/compliance-regulatory-monitor all --bulletin

# Show only material alerts requiring immediate action
/compliance-regulatory-monitor all --alerts

# Generate action items assigned to relevant agents
/compliance-regulatory-monitor all --action-items
```

## Sub-commands

| Flag             | Description                                                                                    |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| `--scan`         | Web search each regulator for new publications; filter for Nuvini relevance; output change log |
| `--bulletin`     | Generate monthly regulatory bulletin as Google Doc with full summaries of all new items        |
| `--alerts`       | Output only high-priority items requiring immediate agent or management attention              |
| `--action-items` | Produce structured action item list with assigned agent, deadline, and required response       |

## Regulators Monitored

### CVM — Comissao de Valores Mobiliarios (Brazilian Securities Commission)

- **URL**: `https://www.gov.br/cvm/pt-br`
- **Search targets**: RCVM resolutions, CVM circulares, instrucoes normativas, enforcement actions (PAS)
- **Nuvini relevance filters**: foreign private issuer exemptions, compliance program requirements (RCVM 21), related-party transaction rules, periodic disclosure obligations, insider trading regulations
- **Filing that could be impacted**: compliance-annual-report, legal-20f-assistant (Item 3 risk factors), legal-compliance-calendar

### ANPD — Autoridade Nacional de Protecao de Dados (National Data Protection Authority)

- **URL**: `https://www.gov.br/anpd/pt-br`
- **Search targets**: LGPD regulations, resolucoes, orientacoes, sanction guidelines, data transfer rules, DPA registration requirements
- **Nuvini relevance filters**: data controller obligations for SaaS companies, data processing agreements, cross-border data transfers, DPIA requirements, incident notification rules, DPO obligations
- **Filing that could be impacted**: portfolio company compliance calendars, legal-contract-generator (DPA addenda), legal-compliance-calendar

### Bacen — Banco Central do Brasil (Central Bank of Brazil)

- **URL**: `https://www.bcb.gov.br`
- **Search targets**: Resolucoes CMN, Circulares BCB, normativas, RDE-IED updates, IOF rate changes, FX settlement rules, cross-border lending regulations
- **Nuvini relevance filters**: intercompany Mutuo loan obligations (20+ active contracts), IOF rate changes affecting loan costs, RDE-IED registration requirements for FX exposure, rules on Adiantamento sobre Contrato de Cambio
- **Filing that could be impacted**: finance-mutuo-calculator (IOF rate inputs), legal-contract-generator (Mutuo terms), legal-compliance-calendar (Bacen registration deadlines)

### SEC — U.S. Securities and Exchange Commission

- **URL**: `https://www.sec.gov`
- **Search targets**: Final rules, proposed rules, no-action letters, staff guidance affecting foreign private issuers, Nasdaq rule filings with SEC
- **Nuvini relevance filters**: foreign private issuer (FPI) eligibility rules, Form 20-F and 6-K requirements, Regulation FD applicability, SOX certifications, Regulation S-X financial statement requirements, cybersecurity disclosure rules (Rule 10b-5), insider trading / Rule 10b5-1
- **Filing that could be impacted**: legal-20f-assistant, compliance-sec-filing-tracker, legal-compliance-calendar, legal-entity-registry (FPI status maintenance)

### CIMA — Cayman Islands Monetary Authority

- **URL**: `https://www.cima.ky`
- **Search targets**: Economic Substance Requirements (ESR) updates, Cayman regulatory guidance, beneficial ownership register requirements, AML/CFT rules for holding companies
- **Nuvini relevance filters**: ESR for NVNI Group (Cayman) and Nuvini Holdings (Cayman) — holding company classification, substance test requirements, annual ESR reporting deadlines, Cayman beneficial ownership register (CIMA/TIA portal)
- **Filing that could be impacted**: legal-entity-registry (Cayman entities), legal-compliance-calendar (ESR deadlines), compliance-board-package

## Relevance Scoring

Each publication found is scored on two axes before inclusion in the bulletin:

**Relevance dimensions** (score 1-3 each):

- **Profile match**: Does this rule apply to Nuvini's entity types (public company / holding / SaaS / lending)?
- **Action required**: Does this create a new obligation, deadline, or filing requirement?
- **Urgency**: Is there a compliance deadline within 90 days?

**Inclusion threshold**:

- Score 7-9: **HIGH** — include in alerts, action items, and bulletin
- Score 4-6: **MEDIUM** — include in bulletin only
- Score 1-3: **LOW** — log for awareness; exclude from bulletin unless requested

## Process Flow

When `--scan` is invoked:

1. **Web search per regulator** — search for publications from the current month and the prior 30 days.
2. **Parse results** — extract publication title, date, regulator, document type, and URL.
3. **Deduplicate** — compare against prior scan log (Drive search for last bulletin doc); skip already-reported items.
4. **Score relevance** — apply the relevance scoring model above.
5. **Generate summaries** — for each HIGH and MEDIUM item, write: (a) what changed, (b) why it matters to Nuvini, (c) required action, (d) assigned agent.
6. **Assign action items** — route to Marco (legal analysis), Julia (financial regulation), or Scheduler (calendar entries).

When `--bulletin` is invoked:

- Compile all HIGH and MEDIUM items from `--scan` output.
- Create Google Doc titled `Regulatory Bulletin — [Month YYYY]` in the Compliance folder.
- Structure: Executive Summary, then one section per regulator.

When `--alerts` is invoked:

- Output only HIGH items and items with a deadline within 30 days.
- Send Gmail notification to Marco, Scheduler, and the relevant portfolio company contact if applicable.

## Output Format

```
REGULATORY MONITOR — SCAN RESULTS
====================================
Run Date     : 2026-02-19
Scope        : ALL REGULATORS
Period Scanned: 2026-01-20 to 2026-02-19

SUMMARY
-------
CVM    : 3 new publications — 1 HIGH, 1 MEDIUM, 1 LOW
ANPD   : 1 new publication  — 1 HIGH
Bacen  : 2 new publications — 1 MEDIUM, 1 LOW
SEC    : 4 new publications — 1 HIGH, 2 MEDIUM, 1 LOW
CIMA   : 0 new publications

ALERTS (HIGH PRIORITY — 3)
--------------------------
[1] CVM — RCVM 50 (hypothetical): New related-party transaction disclosure threshold lowered
    Impact: Nuvini S.A. must now disclose all RPTs above R$500k (prev. R$1M)
    Action: Marco to review all active Mutuo agreements for new disclosure thresholds
    Deadline: Next CVM periodic report
    Assigned: Marco

[2] ANPD — Resolucao CP 5/2026: DPIA mandatory for SaaS data processors above 50k records/month
    Impact: Likely affects Leadlovers, Effecti, DataHub, Mercos — review required
    Action: Marco to conduct DPIA assessment per affected portfolio company
    Deadline: 180 days from publication
    Assigned: Marco + Scheduler (calendar entry)

[3] SEC — Final Rule: Cybersecurity disclosure amendments for FPIs effective Q2 2026
    Impact: 20-F Item 19B disclosure requirements expanded; material incident reporting tightened
    Action: Marco to update 20-F cybersecurity section template; Scheduler to update incident log
    Deadline: Effective for fiscal years ending after 2026-06-30
    Assigned: Marco + Scheduler

MEDIUM ITEMS (4)
----------------
[4] CVM — Circular CVM 2026-01: Updated guidance on quarterly ITR filing format
...

Monthly Bulletin: [Google Doc link — created]
Action Items: [Google Doc link — created]

CONFIDENCE: YELLOW — Regulatory analysis requires human verification before action.
```

## Confidence Scoring

- **Yellow (mandatory)** — Regulatory monitoring involves interpretation of legal texts. The skill identifies and summarizes new publications but cannot substitute for legal analysis. All HIGH-priority items must be reviewed by Marco (Legal) before action is taken.
- **Green** — Not applicable. Legal and regulatory analysis is always Yellow minimum.
- **Red escalation** — If a publication imposes a deadline within 14 days, or if an enforcement action is found naming Nuvini or any portfolio company, immediately escalate to Marco and Scheduler via Gmail and mark the item RED.

## Integration

- **Scheduler (Compliance)**: Primary owner — runs monthly scan, manages bulletin distribution, adds compliance calendar entries for new deadlines
- **Marco (Legal)**: Receives all HIGH-priority alerts; performs legal analysis and drafts response memos; primary owner of CVM, ANPD, and CIMA items
- **Julia (Finance)**: Receives Bacen and SEC items that affect financial reporting or Mutuo contract economics
- **Bella (IR)**: Notified of SEC rule changes affecting investor communications, press releases, or IR deck disclosures
- **compliance-annual-report**: Feeds CVM regulatory updates into the annual compliance report (new requirements section)
- **legal-20f-assistant**: Feeds SEC and CVM updates into Item 3 (risk factors) and Item 10 (regulatory environment section)
- **legal-compliance-calendar**: New deadlines identified by this skill are added as calendar entries
- **finance-mutuo-calculator**: Bacen IOF rate changes detected by this skill trigger recalculation runs
- **legal-contract-generator**: ANPD rule changes may trigger DPA addendum generation for portfolio company contracts
