---
name: mna-pipeline
description: "Full M&A pipeline management for Nuvini Group. Track 75+ targets across a 9-stage acquisition funnel using Google Sheets and optional HubSpot CRM. Use when asked to check deal status, flag stuck deals, analyze pipeline velocity, update a deal's stage, or visualize the acquisition funnel. Triggers on phrases like 'pipeline status', 'stuck deals', 'deal velocity', 'update deal stage', 'funnel report', 'M&A pipeline', or 'pipeline snapshot'."
argument-hint: "[status|stuck|velocity|update|funnel] [target] [stage]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - WebSearch
  - WebFetch
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
  - mcp__browserbase__*
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

# M&A Pipeline Manager

Full pipeline management for Nuvini Group's acquisition funnel. Tracks 75+ targets (52 primary + 23 secondary) across a 9-stage process using the pipeline Google Sheet as the single source of truth.

## Pipeline Sheet

**Sheet ID:** `1rtZOaIEd_ywCbbZb-FoKz8csRWjehrq0X0ICqzYPDH0`

## Commands

| Command                                 | Description                                                                       |
| --------------------------------------- | --------------------------------------------------------------------------------- |
| `/mna pipeline`                         | Default: runs `status`                                                            |
| `/mna pipeline status`                  | Snapshot of all deals by stage with counts and total deal value                   |
| `/mna pipeline stuck`                   | Flag deals with no stage movement in 30+ days, generate follow-up recommendations |
| `/mna pipeline velocity`                | Average days per stage, conversion rates, vs. historical benchmarks               |
| `/mna pipeline update [target] [stage]` | Move a deal to a new stage, log timestamp, notify relevant agents                 |
| `/mna pipeline funnel`                  | ASCII funnel chart of deal flow across all 9 stages                               |

## The 9-Stage Funnel

```
Stage 1: Sourcing
Stage 2: NDA
Stage 3: Pre-Due Diligence
Stage 4: IC Approval
Stage 5: Term Sheet
Stage 6: Due Diligence
Stage 7: Final Approval
Stage 8: SPA
Stage 9: Closing
```

## Workflow

### Phase 1: Load Pipeline Data

1. Get the current date via `mcp__google-workspace__time_getCurrentDate`.
2. Read the pipeline sheet: `mcp__google-workspace__sheets_getText` with sheet ID `1rtZOaIEd_ywCbbZb-FoKz8csRWjehrq0X0ICqzYPDH0`.
3. Parse deals into: target name, current stage, last stage-change date, deal value (estimated), deal type (primary/secondary).
4. Search memory for any recent pipeline snapshots or velocity benchmarks: `mcp__memory__search_nodes` with query "mna pipeline velocity".

### Phase 2: Execute Subcommand

#### `status`

- Group all deals by stage.
- For each stage: count of deals, list of company names, sum of estimated deal values (in BRL).
- Highlight any stage with 0 deals (potential pipeline gap).
- Display as a markdown table. Financial outputs are always **Yellow** confidence.

#### `stuck`

- For each deal, calculate days since last stage change using today's date.
- Flag any deal where `days_since_move >= 30`.
- For each stuck deal: last move date, current stage, recommended next action (e.g., "Follow up on NDA signature", "Request missing DD documents").
- Generate email drafts for the top 3 most-stuck deals via `mcp__google-workspace__gmail_createDraft`.

#### `velocity`

- Calculate average days per stage across all deals that have moved through each stage.
- Compute stage-to-stage conversion rate (% of deals that advance vs. drop off).
- Compare against historical benchmarks: 404 companies analyzed, 8 closed acquisitions.
  - Historical median days per stage (use memory if available, otherwise estimate from dataset context).
- Flag any stage where current average > 1.5x historical median.
- Output as table with current vs. benchmark columns.

#### `update [target] [stage]`

1. Confirm the target name matches a deal in the sheet (fuzzy match acceptable, ask for confirmation if ambiguous).
2. Confirm the new stage is a valid stage name or number (1–9).
3. In user-direct context: confirm before making the update.
4. Log the update with timestamp in memory: `mcp__memory__add_observations`.
5. Cross-agent notifications:
   - Moving to **Due Diligence (Stage 6)**: notify Marco agent (NDA check required).
   - Moving to **IC Approval (Stage 4)**: alert IC brief generation may be needed.
   - Moving to **Closing (Stage 9)**: trigger integration playbook reminder.
6. Draft a notification email if warranted via `mcp__google-workspace__gmail_createDraft`.

#### `funnel`

- Build ASCII funnel showing deal counts at each stage.
- Wider bars = more deals. Visualize drop-off between stages.

```
STAGE 1 — SOURCING         ████████████████████ 28 deals
STAGE 2 — NDA              ████████████████     22 deals
STAGE 3 — PRE-DUE DIL.     ████████████         16 deals
STAGE 4 — IC APPROVAL      ████████              8 deals
STAGE 5 — TERM SHEET        ████████              8 deals
STAGE 6 — DUE DILIGENCE     ████                  4 deals
STAGE 7 — FINAL APPROVAL    ██                    2 deals
STAGE 8 — SPA               ██                    1 deal
STAGE 9 — CLOSING           █                     1 deal
```

### Phase 3: Memory Update

After completing any subcommand, store key findings in memory if novel:

- New velocity benchmarks discovered.
- Stage conversion rates that deviate from prior runs.
- Specific stuck deal patterns.

## Data Sources

| Source                                                        | Purpose                                         |
| ------------------------------------------------------------- | ----------------------------------------------- |
| Pipeline Sheet `1rtZOaIEd_ywCbbZb-FoKz8csRWjehrq0X0ICqzYPDH0` | Primary pipeline data                           |
| Memory graph                                                  | Historical velocity benchmarks, prior snapshots |
| Current date tool                                             | Age calculations for stuck deals                |
| Gmail (drafts)                                                | Follow-up and notification emails               |

## Deal Parameters (Nuvini Standard)

- **Multiple:** 6x EBITDA
- **Split:** 60% cash at close / 40% deferred
- **Geography:** Brazil, B2B SaaS
- **Revenue range:** R$5M–R$100M
- **Historical dataset:** 404 companies analyzed, 8 closed acquisitions

## Error Handling

| Error                             | Action                                                                    |
| --------------------------------- | ------------------------------------------------------------------------- |
| Sheet not accessible              | Report error with sheet ID, suggest checking Google Workspace permissions |
| Target name not found in `update` | Fuzzy match and ask user to confirm the correct deal                      |
| Invalid stage name                | List valid stages 1–9 and ask user to clarify                             |
| No stage-change date available    | Estimate from creation date, flag as estimated                            |
| Memory write fails                | Continue without memory update, log warning                               |

## Confidence Scoring

- **Green (>95%):** Deal counts per stage, list of stuck deals, funnel shape. Auto-proceed.
- **Yellow (80–95%):** Velocity benchmarks, deal values, conversion rates. Human review recommended. All financial outputs default to Yellow regardless of computed confidence.
- **Red (<80%):** Ambiguous company matches, missing stage-change dates on >30% of deals. Full human review required before acting.

## Examples

```bash
# Default status snapshot
/mna pipeline

# See stuck deals with follow-up drafts
/mna pipeline stuck

# Analyze pipeline velocity vs. historical benchmarks
/mna pipeline velocity

# Move TechBrasil to Due Diligence stage
/mna pipeline update TechBrasil "Due Diligence"

# Display ASCII funnel chart
/mna pipeline funnel
```
