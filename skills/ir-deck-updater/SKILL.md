---
name: ir-deck-updater
description: "Auto-update the master NVNI investor presentation with latest portfolio data, financial highlights, M&A pipeline, and capital structure. Replaces data placeholders in the master Google Slides template with live figures sourced from Zuck (portfolio), Julia (financials), Cris (M&A), and Bella's own capital register. Exports PDF and creates a version-tagged copy in the IR Drive folder. Triggers on: deck update, investor deck, update presentation, IR deck, investor presentation, atualizar deck."
argument-hint: "[quarter YYYY-QN] [--update | --preview | --export-pdf | --version-tag]"
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
  - mcp__google-workspace__slides_getText
  - mcp__google-workspace__slides_find
  - mcp__google-workspace__slides_getMetadata
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_getRange
  - mcp__google-workspace__sheets_find
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
tool-annotations:
  mcp__google-workspace__slides_getText: { readOnlyHint: true }
  mcp__google-workspace__slides_find: { readOnlyHint: true }
  mcp__google-workspace__slides_getMetadata: { readOnlyHint: true }
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__memory__search_nodes: { readOnlyHint: true }
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

# ir-deck-updater — Master Investor Presentation Updater

**Agent:** Bella
**Entity:** NVNI Group Limited (NASDAQ: NVNI)
**Purpose:** Maintain the master investor presentation as a living document. Pull latest data from all relevant agents and data sources, update placeholders in the Google Slides master template, produce a versioned output, and export PDF for distribution. All outputs are YELLOW confidence minimum and require IR team review before external distribution.

## Usage

```
/ir deck-updater YYYY-QN --update
/ir deck-updater YYYY-QN --preview
/ir deck-updater YYYY-QN --export-pdf
/ir deck-updater YYYY-QN --version-tag
```

## Sub-commands

| Command         | Description                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------ |
| `--update`      | Pull all data sources, update placeholders in master slides, save updated version to Drive       |
| `--preview`     | Pull data and produce a text-based preview of updated slide content without modifying the master |
| `--export-pdf`  | Trigger PDF export of the current master and save to IR/Exports Drive folder                     |
| `--version-tag` | Create a version-tagged snapshot copy (e.g., `NVNI Investor Deck Q1-2026 v1.0`) in IR Archive    |

---

## Process

### Phase 1: Retrieve Current Quarter Data

Call `mcp__google-workspace__time_getCurrentDate` to determine current date and derive the target quarter if not specified.

Collect data from the following sources in parallel:

**Portfolio Revenue & EBITDA (from Zuck / portfolio dashboard):**

- `sheets_find` for the NOR dashboard or Portfolio Summary sheet.
- Extract: revenue per subsidiary (Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions), consolidated revenue, EBITDA, EBITDA margin, YoY growth rates.

**Financial Highlights (from Julia / FP&A):**

- `sheets_find` for Management Report or Consolidation sheet.
- Extract: consolidated net revenue, adjusted EBITDA, cash position, net debt, IFRS vs management accounts bridge.

**M&A Pipeline (from Cris):**

- `sheets_find` or `docs_getText` for M&A pipeline summary.
- Extract: active pipeline count, deals in LOI / due diligence / signed, total potential acquisition value.

**Capital Structure (from ir-capital-register):**

- Invoke `ir-capital-register summary` or extract from Capital Register sheet directly.
- Extract: total debt outstanding, diluted share count, nearest maturity, warrant status (NVNIW).

**Market Data:**

- `mcp__memory__search_nodes` for latest NVNI stock price and market cap.
- `WebSearch` for current NVNI share price from NASDAQ if memory is stale (>1 trading day).

### Phase 2: Map Data to Slide Placeholders

The master investor deck uses named placeholders in the following pattern: `{{KEY}}`. Map fetched data to placeholder keys:

| Placeholder                | Source          | Description                             |
| -------------------------- | --------------- | --------------------------------------- |
| `{{QUARTER}}`              | Derived         | e.g., Q4 2025                           |
| `{{CONSOLIDATED_REVENUE}}` | Julia / Sheets  | Consolidated net revenue (USD)          |
| `{{REVENUE_GROWTH_YOY}}`   | Julia / Sheets  | YoY revenue growth (%)                  |
| `{{ADJUSTED_EBITDA}}`      | Julia / Sheets  | Adjusted EBITDA (USD)                   |
| `{{EBITDA_MARGIN}}`        | Julia / Sheets  | EBITDA margin (%)                       |
| `{{CASH_POSITION}}`        | Julia / Sheets  | Cash and equivalents (USD)              |
| `{{PORTFOLIO_COUNT}}`      | Static (8)      | Number of portfolio companies           |
| `{{EFFECTI_REVENUE}}`      | Zuck / NOR      | Effecti net revenue                     |
| `{{LEADLOVERS_REVENUE}}`   | Zuck / NOR      | Leadlovers net revenue                  |
| `{{IPE_REVENUE}}`          | Zuck / NOR      | Ipê Digital net revenue                 |
| `{{DATAHUB_REVENUE}}`      | Zuck / NOR      | DataHub net revenue                     |
| `{{MERCOS_REVENUE}}`       | Zuck / NOR      | Mercos net revenue                      |
| `{{ONCLICK_REVENUE}}`      | Zuck / NOR      | Onclick net revenue                     |
| `{{DATAMINER_REVENUE}}`    | Zuck / NOR      | Dataminer net revenue                   |
| `{{MK_REVENUE}}`           | Zuck / NOR      | MK Solutions net revenue                |
| `{{MA_PIPELINE_COUNT}}`    | Cris            | Active M&A targets in pipeline          |
| `{{MA_LOI_COUNT}}`         | Cris            | Deals at LOI stage                      |
| `{{TOTAL_DEBT}}`           | Bella / Capital | Total debt outstanding (USD equivalent) |
| `{{DILUTED_SHARES}}`       | Bella / Capital | Fully diluted share count               |
| `{{NVNI_PRICE}}`           | Memory / Web    | Current NVNI share price                |
| `{{MARKET_CAP}}`           | Derived         | Price x diluted shares                  |
| `{{NVNIW_OUTSTANDING}}`    | Bella / Capital | Warrants outstanding                    |

### Phase 3: Apply Updates

For each placeholder found in the master slides (via `slides_getText`):

1. Log what current value is vs. what new value will replace it.
2. In `--preview` mode: output the diff table only, do not write.
3. In `--update` mode: apply all replacements. Since direct slide editing via API may not be available, create an updated data mapping document in Google Docs (`docs_create`) labeled `IR Deck Data Map — {QUARTER} — {date}` in the IR Drive folder documenting all placeholder values for the design team to apply manually or via automation.

### Phase 4: Version and Export

**`--version-tag`:**

- Search for existing versions via `drive_search` with query `"NVNI Investor Deck {QUARTER}"`.
- Determine next version number (v1.0, v1.1, etc.).
- Log version in memory: `mcp__memory__add_observations` on entity `ir-deck-updater`.

**`--export-pdf`:**

- Note the Google Slides file ID from `slides_find`.
- Document the export request in a Google Doc in `IR/Exports/` folder with file reference and timestamp.
- Notify `ir@nuvini.com.br` via `gmail_send` that PDF export is ready for download.

---

## Data Sources

| Source                             | Tool                              | Data Retrieved                              |
| ---------------------------------- | --------------------------------- | ------------------------------------------- |
| NOR / Portfolio Dashboard (Sheets) | `sheets_find` + `sheets_getRange` | Per-subsidiary revenue, growth rates        |
| Management Report / Consolidation  | `sheets_find` + `sheets_getRange` | Consolidated financials, EBITDA, cash       |
| M&A Pipeline (Docs or Sheets)      | `docs_getText` / `sheets_getText` | Pipeline count, deal stage                  |
| NVNI Capital Register              | `sheets_find` + `sheets_getRange` | Debt outstanding, diluted shares, warrants  |
| Master Investor Deck (Slides)      | `slides_find` + `slides_getText`  | Current placeholder values, slide structure |
| Memory                             | `memory__search_nodes`            | Cached NVNI price, prior version history    |
| Web                                | `WebSearch`                       | Live NVNI stock price if memory stale       |

Drive search query for master deck: `name contains 'NVNI Investor' and mimeType = 'application/vnd.google-apps.presentation'`

---

## Output Format

### Preview Mode (`--preview`)

```
IR DECK UPDATE PREVIEW — NVNI — {QUARTER}
==========================================
Generated: {date}

PLACEHOLDER CHANGES:
  Placeholder                  Current Value         New Value
  ---------------------------  --------------------  --------------------
  {{CONSOLIDATED_REVENUE}}     $XX.XM                $YY.YM
  {{REVENUE_GROWTH_YOY}}       XX%                   YY%
  {{ADJUSTED_EBITDA}}          $XX.XM                $YY.YM
  ...

SLIDES AFFECTED: {N} slides contain data placeholders
DATA GAPS: {list any placeholders where source data was unavailable}

CONFIDENCE: YELLOW — IR team review required before applying update
```

### Update Mode (`--update`)

```
IR DECK UPDATE COMPLETE — NVNI — {QUARTER}
===========================================
Generated: {date}

DATA MAP DOCUMENT: {Google Doc URL}
  - {N} placeholders mapped
  - {N} data gaps flagged (manual input required)

NEXT STEPS:
  1. Design team applies data map to master Slides
  2. IR team reviews updated deck
  3. Run --version-tag once approved
  4. Run --export-pdf for distribution copy

CONFIDENCE: YELLOW — Requires IR review before external use
```

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                     |
| ------ | --------- | ------------------------------------------------------------ |
| Green  | > 95%     | Auto-proceed with display                                    |
| Yellow | 80–95%    | Human review required before distribution — ALL deck outputs |
| Red    | < 80%     | Full manual verification required                            |

**All investor deck outputs are YELLOW confidence minimum.** The IR team must review the updated deck before any version is distributed to investors, analysts, or uploaded to EDGAR or the NVNI investor relations website. Downgrade to RED if any financial figure cannot be traced to a confirmed source document.

Confidence is reduced when:

- Any portfolio company revenue figure is unconfirmed or flagged as preliminary.
- M&A pipeline data is older than 14 days.
- Stock price used for market cap is from memory older than 1 trading day.
- Placeholder gaps remain unfilled.

---

## Integration

| Agent / Skill       | Role                                              |
| ------------------- | ------------------------------------------------- |
| Zuck                | Portfolio dashboard — per-subsidiary NOR and KPIs |
| Julia               | Consolidated financials, EBITDA, cash position    |
| Cris                | M&A pipeline count and deal stage summary         |
| ir-capital-register | Capital structure, debt, diluted shares, warrants |
| Marco               | Legal review of any forward-looking statements    |
| Scheduler           | Trigger automated quarterly deck refresh          |

---

## Examples

```
/ir deck-updater Q4-2025 --preview
→ Shows what values would change in the master deck; no writes

/ir deck-updater Q4-2025 --update
→ Pulls all data, produces data map doc, notifies IR team

/ir deck-updater Q4-2025 --version-tag
→ Creates version-tagged snapshot: "NVNI Investor Deck Q4-2025 v1.0"

/ir deck-updater Q4-2025 --export-pdf
→ Logs export request and notifies ir@nuvini.com.br
```
