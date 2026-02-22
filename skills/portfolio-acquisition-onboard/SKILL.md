---
name: portfolio-acquisition-onboard
description: |
  Auto-extends all 7 Nuvini OS Master Agents when a new company is acquired — the self-replication
  mechanism of the operating system. Configures data ingestion, KPI tracking, compliance calendar
  entries, financial reporting, and governance across Julia (Finance), Marco (Legal), Scheduler
  (Compliance), Zuck (Portfolio), Bella (IR), Cris (M&A), and Claudia (Chief of Staff). Source
  process defined in the FP&A Blueprint. Generates per-agent onboarding checklist, status dashboard,
  and completion report. Human oversight required at each agent's configuration step.
  Triggers on: acquisition onboard, new company, onboard acquisition, add portfolio company,
  self-replicate, extend agents
argument-hint: "[company-name] [--plan | --execute | --status | --checklist]"
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
---

## Overview

Owned by Zuck (Portfolio Agent). This is the Nuvini OS self-replication skill — the mechanism by which the operating system extends itself to cover a newly acquired company across all 7 Master Agents. When Nuvini closes an acquisition, a single invocation of this skill generates and coordinates the full onboarding sequence: financial model integration, legal entity setup, compliance calendar configuration, KPI dashboard registration, IR capital register update, M&A pipeline transition, and system-wide announcement.

The design principle is the FP&A Blueprint: every entity in the portfolio must be treated identically from day one. This skill enforces that discipline by ensuring no agent is forgotten and no integration step is skipped.

**Current portfolio (8 companies)**: Effecti, Leadlovers, Ipe Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions.

**Parent entities**: NVNI Group Limited (Cayman), Nuvini Holdings Limited (Cayman), Nuvini S.A. (Brazil), Holding LLC (Delaware).

## Usage

```bash
# Generate an onboarding plan for a new acquisition (review before executing)
/portfolio-acquisition-onboard "Empresa XYZ" --plan

# Execute the full onboarding sequence across all 7 agents
/portfolio-acquisition-onboard "Empresa XYZ" --execute

# Check status of an in-progress onboarding
/portfolio-acquisition-onboard "Empresa XYZ" --status

# Generate or refresh the per-agent checklist only (no execution)
/portfolio-acquisition-onboard "Empresa XYZ" --checklist
```

## Sub-commands

| Flag          | Description                                                                                          |
| ------------- | ---------------------------------------------------------------------------------------------------- |
| `--plan`      | Generate full onboarding plan per agent with required inputs listed; no changes made                 |
| `--execute`   | Run the onboarding sequence; requires all inputs to be confirmed; human oversight at each agent step |
| `--status`    | Show completion status per agent and per checklist item for an in-progress onboarding                |
| `--checklist` | Output the master checklist only; useful for manual tracking or partial execution                    |

## Required Inputs

Before `--execute` can proceed, the following inputs must be collected (gathered interactively if not supplied as arguments):

| Input                   | Description                                                              | Example                       |
| ----------------------- | ------------------------------------------------------------------------ | ----------------------------- |
| Company name            | Legal name of the acquired entity                                        | "Empresa XYZ Ltda."           |
| Short name              | Internal identifier used in dashboards and file names                    | "xyz"                         |
| Jurisdiction            | Country and state/city of incorporation                                  | "Brazil — Sao Paulo/SP"       |
| Acquisition type        | Asset deal, share purchase, merger, partial acquisition                  | "Share Purchase Agreement"    |
| ERP / accounting system | Current accounting platform                                              | "Omie", "Totvs", "Conta Azul" |
| Closing date            | Legal closing date (SPA execution date)                                  | "2026-02-19"                  |
| Headcount               | Total employees at closing                                               | 47                            |
| Annual revenue (LTM)    | Last twelve months net revenue at closing (BRL)                          | R$8.2M                        |
| Primary business        | One-line business description                                            | "B2B SaaS — restaurant ERP"   |
| Key contacts            | CEO, CFO, legal counsel for the acquired entity                          | Name, email, phone            |
| SPA location            | Google Drive link or folder path for the executed SPA                    | Drive link                    |
| Earn-out terms          | Yes/No; if yes, formula, targets, and measurement period                 | "3 years, EBITDA-based"       |
| New capital instruments | Any new shares, options, warrants, or notes issued as deal consideration | "500k new NVNI shares"        |
| Intercompany loans      | Will any Mutuo agreements be established at closing?                     | "Yes — R$2M operational loan" |

## Agent Onboarding Sequence

Onboarding is executed in this order. Each step requires confirmation before proceeding to the next.

---

### Step 1 — Julia (Finance Agent)

**Objective**: Make the new entity visible in all financial models.

Checklist items:

- [ ] Add entity to `finance-closing-orchestrator` — create monthly closing checklist entry
- [ ] Add to `finance-consolidation` — map chart of accounts from entity ERP to Nuvini unified CoA
- [ ] Add to `finance-mutuo-calculator` — if Mutuo loan at closing, enter loan terms, IOF rate, principal
- [ ] Add to `finance-budget-builder` — create entity budget tab for current fiscal year (pro-rata from closing date)
- [ ] Add to `finance-rolling-forecast` — initialize forecast from closing month forward
- [ ] Add to `finance-earnout-tracker` — if earn-out clause in SPA, extract formula and enter tracker
- [ ] Request first Balancete and Razao from entity CFO (Drive upload instructions)
- [ ] Set up Drive folder structure: `Portfolio / [Entity Name] / Financials / [YYYY] / [MM]`

Data collected: ERP system name, chart of accounts mapping, Mutuo loan terms (if applicable), earn-out terms (if applicable).

---

### Step 2 — Marco (Legal Agent)

**Objective**: Register the entity legally and configure compliance obligations.

Checklist items:

- [ ] Add entity to `legal-entity-registry` — jurisdiction, CNPJ/registration number, ownership %, registered agent, key dates
- [ ] Generate corporate formation documentation summary (existing entity — confirm formation docs received)
- [ ] Add to `legal-compliance-calendar`:
  - Brazilian entities: SPED ECF, SPED ECD, DEFIS, DAS, annual Junta Comercial, LGPD obligations
  - Cayman entities: ESR reporting, beneficial ownership register, annual return
  - Delaware entities: franchise tax, annual report
- [ ] Check for existing contracts requiring assignment or novation (customer contracts, vendor agreements, leases)
- [ ] Register in ANPD if entity processes personal data above threshold
- [ ] Add Mutuo contract to `legal-contract-generator` register if intercompany loan at closing
- [ ] File SPA in Drive under `Legal / M&A / Closed / [Entity Name]`

Data collected: CNPJ, entity registration documents, compliance jurisdiction profile, data processing profile.

---

### Step 3 — Scheduler (Compliance Agent)

**Objective**: Configure board governance and regulatory filing calendar.

Checklist items:

- [ ] Add entity to board governance calendar — required board meeting frequency per jurisdiction
- [ ] Schedule first integration review board meeting (T+30 days from closing)
- [ ] Add regulatory filing deadlines to master compliance calendar (sources from Marco Step 2)
- [ ] Confirm entity is covered by group D&O insurance policy — escalate to Marco if not
- [ ] Set up `compliance-regulatory-monitor` profile for entity-specific regulatory exposures
- [ ] Add entity to annual `compliance-annual-report` scope (if Brazilian entity subject to RCVM 21)
- [ ] Schedule 90-day integration review checkpoint in Claudia's board package cycle

Data collected: Board structure at acquisition, regulatory filing dates, insurance confirmation.

---

### Step 4 — Zuck (Portfolio Agent)

**Objective**: Make the entity visible in all portfolio tracking tools.

Checklist items:

- [ ] Add entity to `portfolio-nor-ingest` — register entity name, short code, Drive folder path for NOR files
- [ ] Add entity to `portfolio-kpi-dashboard` — configure KPI template (SaaS: MRR, churn, NRR; non-SaaS: revenue, EBITDA, headcount)
- [ ] Add entity to `portfolio-reporter` — include in next monthly portfolio report
- [ ] Add entity to `finance-variance-commentary` entity list
- [ ] Set MRR/ARR baseline from LTM data provided at closing
- [ ] Configure Rule of 40 calculation parameters (growth rate source, EBITDA margin source)
- [ ] Add to consolidated portfolio performance dashboard tab

Data collected: LTM revenue, MRR (if SaaS), EBITDA margin, headcount, growth rate.

---

### Step 5 — Bella (IR Agent)

**Objective**: Update capital register and investor communications templates.

Checklist items:

- [ ] Update `ir-capital-register` — if new NVNI shares, options, warrants, or convertible notes issued as deal consideration, enter instrument details, quantity, vesting/conversion terms
- [ ] Update `ir-deck-updater` master template — add entity to portfolio company slides
- [ ] Update `ir-earnings-release` template — add entity to revenue breakdown table
- [ ] Draft 6-K material event announcement (acquisition press release) via `ir-press-release-draft`
- [ ] Update investor Q&A database (`ir-qna-draft`) with standard acquisition rationale responses
- [ ] Confirm SEC 6-K filing obligation with Marco — material acquisitions require 6-K within 4 business days

Data collected: Capital instruments issued at closing, deal value for press release, integration narrative.

---

### Step 6 — Cris (M&A Agent)

**Objective**: Close the deal in the pipeline and trigger integration playbook.

Checklist items:

- [ ] Move deal from active pipeline to "Closed" status in `mna-pipeline` — record closing date, deal value, structure
- [ ] Archive DD data room link in closed deal record
- [ ] Trigger `mna-integration` — generate 90-day post-closing integration playbook for the entity
- [ ] Mark all earn-out terms in `finance-earnout-tracker` (linked from Julia Step 1)
- [ ] Log SPA key terms: reps & warranties, indemnification caps, survival periods — calendar in Marco Step 2
- [ ] Close NDA in `mna-nda-gen` register — mark as superseded by SPA

Data collected: Final deal terms, pipeline stage history, DD findings summary.

---

### Step 7 — Claudia (Chief of Staff Agent)

**Objective**: Announce acquisition and update system-wide agent memory.

Checklist items:

- [ ] Draft acquisition announcement message (Portuguese and English) for all channels
- [ ] Send announcement to configured channels: Discord ops server, Slack (Nuvini workspace), Telegram
- [ ] Update agent memory — add new entity to portfolio entity list in all agent contexts
- [ ] Send onboarding completion summary to management via Gmail
- [ ] Log onboarding completion in system memory with date, entity name, all checklist items confirmed
- [ ] Schedule 30-day and 90-day onboarding review reminders in Scheduler's calendar

Data collected: Announcement approved by management before distribution.

---

## Output Format

```
ACQUISITION ONBOARDING — STATUS DASHBOARD
==========================================
Company        : Empresa XYZ Ltda.
Short Name     : xyz
Jurisdiction   : Brazil — Sao Paulo/SP
Closing Date   : 2026-02-19
Acquisition Type: Share Purchase Agreement
Run Date       : 2026-02-19
Mode           : --status

OVERALL PROGRESS: 3 of 7 agents complete

AGENT STATUS
------------
Step 1 — Julia (Finance)       : COMPLETE  (2026-02-19 — 8 items done)
Step 2 — Marco (Legal)         : COMPLETE  (2026-02-19 — 7 items done)
Step 3 — Scheduler (Compliance): COMPLETE  (2026-02-19 — 7 items done)
Step 4 — Zuck (Portfolio)      : IN PROGRESS (4/7 items done)
  PENDING: KPI dashboard configuration — awaiting MRR baseline from Julia
  PENDING: Rule of 40 parameters — awaiting EBITDA margin input
  PENDING: Portfolio reporter inclusion — next run scheduled 2026-03-01
Step 5 — Bella (IR)            : PENDING (0/6 items) — waiting on Step 4
Step 6 — Cris (M&A)            : PENDING (0/6 items) — waiting on Step 5
Step 7 — Claudia (Chief of Staff): PENDING (0/6 items) — waiting on all steps

BLOCKING ITEMS (2)
------------------
[1] MRR baseline not confirmed — request from entity CFO (Empresa XYZ CFO: [contact])
[2] Capital instruments at closing not confirmed — Bella waiting for confirmation from Marco

Drive Onboarding Folder : [link]
Master Checklist Doc    : [link]
Integration Playbook    : [link] (Cris — mna-integration output)

CONFIDENCE: YELLOW — Onboarding requires human oversight at each agent configuration step.
```

## Confidence Scoring

- **Yellow (mandatory)** — Acquisition onboarding configures live financial models, legal registrations, compliance calendars, and investor communications. Each step must be confirmed by the responsible human principal (CFO for finance steps, General Counsel for legal steps, IR officer for Bella steps) before execution. No step auto-commits to production systems without confirmation.
- **Green** — Not applicable. Cross-agent configuration changes are always Yellow minimum.
- **Red escalation** — If SPA documents cannot be located in Drive, or if the entity's CNPJ cannot be verified, halt execution at Step 2 and escalate to Marco. If new capital instruments at closing cannot be confirmed, halt at Step 5 and escalate to Bella and Marco.

## Data Flow Between Agents

The onboarding sequence has explicit data dependencies:

```
Julia (Step 1) ──── LTM revenue, EBITDA ────────────► Zuck (Step 4)
Julia (Step 1) ──── Mutuo loan terms ───────────────► Marco (Step 2)
Marco (Step 2) ──── compliance deadlines ───────────► Scheduler (Step 3)
Marco (Step 2) ──── capital instruments confirmed ──► Bella (Step 5)
Marco (Step 2) ──── SPA key terms ──────────────────► Cris (Step 6)
Zuck  (Step 4) ──── KPI baseline ───────────────────► Bella (Step 5)
Bella (Step 5) ──── press release approved ─────────► Claudia (Step 7)
All agents ────────── completion confirmed ──────────► Claudia (Step 7)
```

## Integration

- **Zuck (Portfolio)**: Primary owner — drives the onboarding sequence, tracks status dashboard
- **Julia (Finance)**: Executes Step 1 — financial model integration
- **Marco (Legal)**: Executes Step 2 — legal entity registration and compliance calendar
- **Scheduler (Compliance)**: Executes Step 3 — board governance and regulatory filings
- **Bella (IR)**: Executes Step 5 — capital register and investor communications
- **Cris (M&A)**: Executes Step 6 — pipeline transition and integration playbook
- **Claudia (Chief of Staff)**: Executes Step 7 — announcement and memory update
- **mna-integration**: Called by Cris in Step 6 to generate the 90-day integration playbook
- **legal-entity-registry**: Updated in Step 2 — permanent record of all Nuvini entities
- **legal-compliance-calendar**: Updated in Steps 2 and 3 — compliance deadlines for new entity
- **ir-capital-register**: Updated in Step 5 — any new instruments issued at closing
- **portfolio-kpi-dashboard**: Updated in Step 4 — new entity KPI tracking initialized
- **finance-closing-orchestrator**: Updated in Step 1 — new entity added to monthly closing cycle
