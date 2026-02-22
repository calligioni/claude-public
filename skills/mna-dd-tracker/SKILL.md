---
name: mna-dd-tracker
description: "Monitor Due Diligence completion across all active Nuvini deals. Chase outstanding DD items, summarize findings as they arrive, and flag critical risks by workstream. Use when checking DD progress, generating chase emails, reviewing what's missing, or summarizing DD findings. Triggers on phrases like 'DD status', 'DD progress', 'chase outstanding', 'what's missing from DD', 'DD summary', 'DD risk report', 'due diligence tracker', or 'follow up on documents'."
argument-hint: "[status|chase|summary|risk] [target]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
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
---

# M&A Due Diligence Tracker

Monitors DD completion status across all active deals, generates chase emails for overdue items, summarizes findings as documents arrive, and flags critical risks by workstream for IC review.

## Commands

| Command                            | Description                                         |
| ---------------------------------- | --------------------------------------------------- |
| `/mna dd-tracker`                  | Default: runs `status` across all active DD deals   |
| `/mna dd-tracker status`           | Completion % per workstream per active deal         |
| `/mna dd-tracker chase [target]`   | Identify overdue items (>7 days), draft chase email |
| `/mna dd-tracker summary [target]` | Summarize DD findings received so far, flag risks   |
| `/mna dd-tracker risk [target]`    | Critical risk analysis by workstream                |

## Workflow

### Phase 1: Discover Active DD Deals

1. Get current date: `mcp__google-workspace__time_getCurrentDate`.
2. Search memory for deals currently in DD stage: `mcp__memory__search_nodes` query "DD checklist".
3. Search Google Drive for DD checklist documents: `mcp__google-workspace__sheets_find` or `mcp__google-workspace__drive_search` with query "DD Checklist".
4. Load each active DD checklist to retrieve item status.

If a specific `[target]` is provided, narrow to that deal only.

### Phase 2: Execute Subcommand

#### `status`

For each active DD deal:

- Read the DD checklist (Google Sheet or Doc created by mna-dd-checklist).
- Count items by status: Pending / Received / N/A per workstream.
- Calculate % complete per workstream and overall.
- Identify deadline: days remaining until target submission deadline.
- Display as a table:

```
Deal: TechBrasil  |  DD Start: 2026-02-01  |  Deadline: 2026-03-03  |  12 days remaining

Workstream              | Received | Pending | N/A | % Complete
A. Corporate            |    12    |    3    |  1  |   80%
B. Debt/Financial       |     8    |    4    |  0  |   67%
F. Tax                  |     6    |   14    |  0  |   30%   ← LAGGING
G. Labor                |    10    |    5    |  0  |   67%
...
TOTAL                   |   65     |   40    |  5  |   62%
```

Flag workstreams below 50% with 7 or fewer days remaining.

#### `chase [target]`

1. Identify all items with status = Pending AND requested > 7 days ago.
2. Group by workstream.
3. Generate a specific chase list (item numbers + descriptions).
4. Draft a polite but firm chase email in Portuguese:
   - Subject: `[Urgente] Documentação Pendente — Diligência [Target]`
   - List specific outstanding items by workstream
   - Reference original deadline
   - Request updated submission date for each outstanding item
   - `mcp__google-workspace__gmail_createDraft`

#### `summary [target]`

Summarize all documents received so far, organized by workstream:

- Key findings per workstream (what was found, any concerns flagged).
- Red flags: items where received documents reveal issues (e.g., outstanding lawsuits, unpaid taxes, IP disputes).
- Green flags: workstreams that are clean and complete.
- Open questions: items still outstanding that are critical to the investment thesis.
- Overall DD health assessment: Green / Yellow / Red.

Note: This is an analytical summary of documents received, not legal advice.

#### `risk [target]`

Flag critical missing items by workstream risk level:

| Workstream        | Critical Missing Items                  | Risk Level |
| ----------------- | --------------------------------------- | ---------- |
| F. Tax            | No tax returns for last 3 years         | CRITICAL   |
| D. Legal disputes | No litigation certificate               | HIGH       |
| B. Debt           | No debt schedule or banking agreements  | HIGH       |
| G. Labor          | No payroll register or union agreements | MEDIUM     |

Risk levels:

- **CRITICAL:** Missing item could be a deal-breaker or result in undisclosed liability >5% of purchase price.
- **HIGH:** Missing item materially affects deal valuation or representations.
- **MEDIUM:** Missing item is required but unlikely to materially affect deal terms.

For each critical/high risk item, suggest next action: escalate to seller's counsel, request direct from regulator, or waive with indemnification.

### Phase 3: Weekly IC Summary

When invoked without arguments (default `status`), check if today is Sunday or Monday. If so, append a "Weekly DD Summary for IC" block:

- All active DD deals with overall % complete.
- Deals at risk of missing their deadline.
- Critical open items requiring IC awareness.
- Recommendation: proceed / pause / conditional approval.

### Phase 4: Memory Update

Log DD status snapshots in memory:

- `mcp__memory__add_observations` with workstream completion %, date, and any critical risks flagged.
- Use this for trend analysis: is DD accelerating or stalling?

## Critical Risk Flags by Workstream

| Workstream    | Auto-Flag Trigger                                          |
| ------------- | ---------------------------------------------------------- |
| A. Corporate  | Missing Articles of Incorporation or shareholder register  |
| B. Debt       | No bank debt schedule — assume undisclosed liabilities     |
| C. Compliance | Missing operating licenses or regulatory certificates      |
| D. Legal      | No litigation search certificate (certidão negativa)       |
| F. Tax        | Missing PGFN/Receita Federal clearance certificate         |
| G. Labor      | Missing FGTS clearance certificate (CRF)                   |
| H. IP         | No IP registration certificates or software ownership docs |
| J. LGPD       | No privacy policy or DPA record                            |

## Data Sources

| Source                                      | Purpose                               |
| ------------------------------------------- | ------------------------------------- |
| DD Checklists (created by mna-dd-checklist) | Item-level completion status          |
| Google Drive search                         | Locate DD documents and folders       |
| Memory graph                                | Deal context, historical DD durations |
| Gmail (drafts)                              | Chase emails to target companies      |
| Current date tool                           | Age calculations, deadline tracking   |

## Error Handling

| Error                                          | Action                                                              |
| ---------------------------------------------- | ------------------------------------------------------------------- |
| DD checklist not found for target              | Prompt user to confirm checklist location or generate new checklist |
| No items have dates (cannot calculate overdue) | Use DD start date from memory or ask user                           |
| Multiple deals in DD simultaneously            | Process all, display in separate sections                           |
| Drive search returns no results                | Ask user for checklist document link directly                       |
| Checklist in wrong format                      | Parse best-effort, flag parsing issues per workstream               |

## Confidence Scoring

- **Green (>95%):** Item counts per status, % complete calculations, overdue flags. Auto-proceed.
- **Yellow (80–95%):** Risk assessments, finding summaries, chase email drafts. Human review before sending.
- **Red (<80%):** DD finding interpretations, materiality judgments, deal-breaker assessments. Requires legal and M&A team review before acting.

All DD risk assessments and finding summaries default to Yellow — they require human judgment before being shared with IC.

## Examples

```bash
# Status of all active DD deals
/mna dd-tracker

# Specific deal status
/mna dd-tracker status TechBrasil

# Generate chase email for overdue items
/mna dd-tracker chase TechBrasil

# Summarize findings received so far
/mna dd-tracker summary TechBrasil

# Critical risk analysis by workstream
/mna dd-tracker risk TechBrasil
```
