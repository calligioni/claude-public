---
name: mna-ic-brief
description: "Compile weekly Investment Committee briefing packages for Nuvini Group M&A deals. Aggregates triage scores, financials, DD status, and pipeline context into a one-page deal summary per deal. Use when the user needs to prepare IC materials, schedule an IC meeting, or archive prior IC packages. Triggers on phrases like 'IC brief', 'IC package', 'investment committee brief', 'prepare IC materials', 'IC meeting', 'weekly IC', or 'committee briefing'."
argument-hint: "[generate|schedule|archive]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_getRange
  - mcp__google-workspace__sheets_find
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
tool-annotations:
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__docs_getText:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__sheets_getText:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__sheets_getRange:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__sheets_find:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__google-workspace__gmail_createDraft: { idempotentHint: false }
  mcp__google-workspace__time_getCurrentDate:
    { readOnlyHint: true, idempotentHint: true }
  mcp__memory__search_nodes: { readOnlyHint: true, idempotentHint: true }
  mcp__memory__open_nodes: { readOnlyHint: true, idempotentHint: true }
  mcp__memory__create_entities: { idempotentHint: false }
  mcp__memory__add_observations: { idempotentHint: false }
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
memory: user
---

# Investment Committee Brief Generator

Compiles the weekly IC briefing package for Nuvini's M&A Investment Committee. Aggregates data from across the Nuvini OS agent ecosystem — triage scores, financial extractions, DD status, pipeline context — into a professional one-page-per-deal briefing document.

## Commands

| Command                  | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `/mna ic-brief`          | Default: generate this week's IC package                  |
| `/mna ic-brief generate` | Generate IC package for all deals scheduled for IC review |
| `/mna ic-brief schedule` | Show upcoming IC agenda with deals per meeting            |
| `/mna ic-brief archive`  | Search Drive for prior IC packages, list with dates       |

## IC Cadence

IC typically meets weekly on Monday or Tuesday. Generate by Friday of the prior week. Package is distributed to IC members via Gmail draft.

## Workflow

### Phase 1: Identify Deals for IC Review

1. Get current date: `mcp__google-workspace__time_getCurrentDate`.
2. Read pipeline sheet to identify deals in stages 4 (IC Approval) or 7 (Final Approval):
   - Sheet ID: `1rtZOaIEd_ywCbbZb-FoKz8csRWjehrq0X0ICqzYPDH0`
3. Search memory for deals flagged for this week's IC: `mcp__memory__search_nodes` query "IC brief".
4. If no deals found in IC stages, report an empty pipeline and suggest checking pipeline tracker.

### Phase 2: Aggregate Data per Deal

For each deal, pull from multiple sources in parallel:

**From Memory / mna-toolkit outputs:**

- Triage score (0–10) and key scoring breakdown
- Financial extraction: revenue, EBITDA, growth rate, Rule of 40
- Proposal IRR and MOIC
- Investment thesis highlights from any prior analysis

**From Pipeline Sheet:**

- Current pipeline stage
- Days in current stage
- Days since first contact (total deal age)
- Assigned M&A team member

**From DD Tracker (if deal is in DD or beyond):**

- Overall DD completion %
- Critical outstanding items
- Red flags found in DD

**From Docs (search Drive for company name + "analysis" or "proposal"):**

- `mcp__google-workspace__drive_search` to find prior investment analysis docs
- `mcp__google-workspace__docs_getText` to extract key sections if found

### Phase 3: Build the IC Package

Create a Google Doc: `"IC Brief — Week of [Date] — Nuvini M&A"`

#### Cover Page

- Week of: [Date]
- Deals under review: [Count]
- Prepared by: Cris (M&A Agent)
- Date prepared: [Today]

#### Per-Deal One-Pager

For each deal, produce a structured one-pager:

---

**[COMPANY NAME] — [STAGE] — [RECOMMENDATION: PROCEED / CONDITIONAL / DEFER]**

**Company Overview**

- Sector: [B2B SaaS / vertical]
- Geography: [State, Brazil]
- Founded: [Year]
- Employees: [Count]
- Business description: [2–3 sentences]

**Key Metrics Table**

| Metric              | Value  |
| ------------------- | ------ |
| LTM Revenue         | R$[X]M |
| LTM EBITDA          | R$[X]M |
| EBITDA Margin       | [X]%   |
| YoY Revenue Growth  | [X]%   |
| Rule of 40          | [X]    |
| Recurring Revenue % | [X]%   |
| Triage Score        | [X]/10 |

**Proposed Transaction**

| Parameter      | Value              |
| -------------- | ------------------ |
| Purchase Price | R$[X]M (6x EBITDA) |
| Cash at Close  | R$[X]M (60%)       |
| Deferred       | R$[X]M (40%)       |
| Earn-out       | [Structure]        |
| Projected IRR  | [X]%               |
| Projected MOIC | [X]x               |

**Portfolio Fit & Synergies**

How this deal fits the existing Nuvini portfolio:

- Synergies with: [Effecti / Leadlovers / Ipê Digital / DataHub / Mercos / Onclick / Dataminer / MK Solutions]
- Cross-sell opportunities: [Description]
- Platform play: [How this strengthens Nuvini's vertical coverage]

**DD Status** (if applicable)

- DD Start: [Date]
- Overall Completion: [X]%
- Critical Open Items: [List top 3]
- Red Flags: [None / List]

**Open Questions for IC**

1. [Key unresolved question]
2. [Key unresolved question]
3. [Key unresolved question]

**M&A Team Recommendation**

PROCEED / CONDITIONAL PROCEED (conditions listed) / DEFER

Rationale: [2–3 sentences]

---

#### IC Agenda Summary (Last Page)

| Deal        | Stage          | Triage | IRR | DD % | Recommendation |
| ----------- | -------------- | ------ | --- | ---- | -------------- |
| [Company A] | IC Approval    | 8.2    | 35% | —    | PROCEED        |
| [Company B] | Final Approval | 7.8    | 28% | 85%  | CONDITIONAL    |

### Phase 4: Distribute

1. Save the IC package Google Doc and log its ID in memory.
2. Draft a distribution email to IC members via `mcp__google-workspace__gmail_createDraft`.
   - Subject: `IC Briefing — Week of [Date] — [N] Deals`
   - Body: List deals under review, link to Google Doc, attach agenda summary

### Phase 5: Archive (`archive` subcommand)

Search Drive for prior IC packages: `mcp__google-workspace__drive_search` query "IC Brief Nuvini M&A".
List all found packages with date, number of deals, and document link.

## Current Nuvini Portfolio (for synergy analysis)

| Company      | Vertical             |
| ------------ | -------------------- |
| Effecti      | HR / Payroll         |
| Leadlovers   | Marketing Automation |
| Ipê Digital  | Digital Marketing    |
| DataHub      | Data Analytics       |
| Mercos       | B2B Commerce         |
| Onclick      | Digital Advertising  |
| Dataminer    | Data Intelligence    |
| MK Solutions | Customer Service     |

## Data Sources

| Source                                                        | Purpose                                 |
| ------------------------------------------------------------- | --------------------------------------- |
| Pipeline Sheet `1rtZOaIEd_ywCbbZb-FoKz8csRWjehrq0X0ICqzYPDH0` | Stage, days in stage, deal context      |
| Memory graph                                                  | Triage scores, IRR/MOIC, prior IC notes |
| Google Drive / Docs                                           | Investment analyses, proposals          |
| mna-dd-tracker outputs                                        | DD completion, red flags                |
| Gmail (drafts)                                                | IC package distribution                 |
| Current date tool                                             | Week identification, deadline awareness |

## Error Handling

| Error                                             | Action                                                                   |
| ------------------------------------------------- | ------------------------------------------------------------------------ |
| No deals in IC stages                             | Report empty IC pipeline, suggest checking pipeline tracker              |
| Triage or financial data missing for a deal       | Flag as "data incomplete", include what is available, mark fields as TBD |
| Drive search finds no prior analysis for a deal   | Generate IC one-pager from pipeline data only, note data gaps            |
| Google Doc creation fails                         | Output IC package as markdown in chat                                    |
| Synergy analysis not possible (no portfolio data) | Use built-in portfolio list above                                        |

## Confidence Scoring

- **Green (>95%):** Document structure, deal listing, pipeline stage data. Auto-proceed.
- **Yellow (80–95%):** All financial metrics, IRR/MOIC, triage scores, recommendations. Default Yellow — IC members must verify figures before voting.
- **Red (<80%):** Deals with incomplete triage or no financial extraction — flag clearly as "INCOMPLETE DATA" and do not include a recommendation.

All IC package content is deal-sensitive and defaults to Yellow. IC members must confirm all financial figures before voting.

## Examples

```bash
# Generate this week's IC package
/mna ic-brief

# Explicitly generate
/mna ic-brief generate

# Show upcoming IC agenda
/mna ic-brief schedule

# List historical IC packages
/mna ic-brief archive
```
