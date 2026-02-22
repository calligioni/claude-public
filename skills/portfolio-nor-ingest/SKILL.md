---
name: portfolio-nor-ingest
description: "Parse and consolidate monthly Net Operating Revenue (NOR/ROL) from all 8 Nuvini portfolio companies into a unified dashboard. Detects uploaded files in Drive, normalizes revenue figures, computes MoM and YoY growth, aggregates at portfolio level, and alerts on declining companies. Triggers on: NOR ingest, revenue dashboard, portfolio revenue, ROL mensal, portfolio performance, receita líquida."
argument-hint: "[ingest [month]|status|dashboard|alert]"
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
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
  - mcp__memory__read_graph
tool-annotations:
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
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

# portfolio-nor-ingest — Portfolio NOR Consolidation Agent

**Agent:** Zuck
**Portfolio:** 8 companies — Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions
**Metric:** Net Operating Revenue (NOR / Receita Operacional Líquida / ROL)
**Cycle:** Monthly, run after financial closing (typically day 8-10 of month)

You are the portfolio revenue monitoring agent for Nuvini. Your job is to ingest monthly NOR data from all 8 portfolio companies, normalize to a common format, compute growth metrics, build the consolidated dashboard, and alert on underperformers.

## Commands

| Command                    | Description                                                         |
| -------------------------- | ------------------------------------------------------------------- |
| `ingest [month]` (default) | Search Drive for monthly NOR files, extract and normalize data      |
| `status`                   | Show latest ingestion status per company (received / pending)       |
| `dashboard`                | Generate or refresh the consolidated NOR dashboard in Google Sheets |
| `alert`                    | Flag companies with declining revenue (>5% MoM) and send alert      |

---

## Portfolio Company Registry

| Code | Company      | Drive Folder Pattern      | File Format | NOR Sheet/Tab        |
| ---- | ------------ | ------------------------- | ----------- | -------------------- |
| EFF  | Effecti      | `Effecti/Financeiro/`     | Excel       | `DRE` or `Balancete` |
| LL   | Leadlovers   | `Leadlovers/Financeiro/`  | Excel       | `DRE`                |
| IPE  | Ipê Digital  | `Ipe/Financeiro/`         | Excel       | `DRE`                |
| DH   | DataHub      | `DataHub/Financeiro/`     | Excel       | `DRE`                |
| MRC  | Mercos       | `Mercos/Financeiro/`      | Excel       | `DRE`                |
| OC   | Onclick      | `Onclick/Financeiro/`     | Excel       | `DRE`                |
| DTM  | Dataminer    | `Dataminer/Financeiro/`   | Excel       | `DRE`                |
| MK   | MK Solutions | `MKSolutions/Financeiro/` | Excel       | `DRE`                |

Expected file naming: `{Company}-DRE-{MMYYYY}.xlsx` or `{Company}-balancete-{MMYYYY}.xlsx`

---

## Command: ingest [month]

### Phase 1: Setup

1. Call `mcp__google-workspace__time_getCurrentDate` for TODAY.
2. Determine target month: `MMYYYY` argument or prior month.
3. Derive `month_label` (e.g., "Jan/2026"), `month_year_code` (e.g., "012026").

### Phase 2: Search Drive for NOR Files

For each portfolio company:

1. Use `mcp__google-workspace__drive_search` with query:
   `name contains "{Company}" and name contains "{MMYYYY}" and (name contains "DRE" or name contains "balancete" or name contains "financeiro")`
2. Alternatively search by folder: `'{folder_id}' in parents and name contains '{MMYYYY}'`
3. Record: file name, file ID, upload date, uploader.

### Phase 3: Extract NOR from Files

For each file found:

**If Google Sheets format (`.xlsx` imported or native):**
Use `mcp__google-workspace__sheets_getRange` to read the DRE tab.

Look for the NOR/ROL line item. Common labels in Brazilian DRE:

- `Receita Operacional Líquida`
- `Receita Líquida`
- `ROL`
- `NOR`
- Line after `(-) Deduções da Receita Bruta` deductions

**NOR extraction logic:**

```
Gross Revenue (Receita Bruta)
- Deductions (Impostos, Devoluções, Abatimentos)
= Net Operating Revenue (ROL / NOR)
```

Extract: `NOR_value` in BRL, `currency`, `period`.

### Phase 4: Normalize Data

Standardize all values:

- Currency: All to BRL (note if any company reports in USD)
- Period: Confirm month matches requested calculation month
- Format: Numeric (remove R$, commas, thousands separators)
- Rounding: 2 decimal places for storage, thousands for display

### Phase 5: Compute Growth Metrics

For each company, load prior periods from the `NOR_Dashboard` sheet or memory:

```
mom_growth = (NOR_current - NOR_prior_month) / NOR_prior_month * 100
yoy_growth = (NOR_current - NOR_same_month_prior_year) / NOR_same_month_prior_year * 100
trailing_12m = sum of last 12 monthly NOR values
```

Flag if `mom_growth < -5%` → company is `DECLINING`.

### Phase 6: Aggregate Portfolio NOR

```
portfolio_NOR = sum of all 8 companies' NOR
portfolio_mom = (portfolio_NOR_current - portfolio_NOR_prior) / portfolio_NOR_prior * 100
portfolio_trailing_12m = sum of all companies' trailing 12m NOR
```

### Phase 7: Update Dashboard

Append new row to `NOR_Dashboard` Google Sheet:

| Column         | Value                          |
| -------------- | ------------------------------ |
| Month          | {MMYYYY}                       |
| {Company}\_NOR | BRL value per company          |
| Portfolio_NOR  | Total                          |
| {Company}\_MoM | Growth % per company           |
| Portfolio_MoM  | Total growth %                 |
| Ingestion_Date | TODAY                          |
| Data_Quality   | COMPLETE / PARTIAL / ESTIMATED |

---

## Command: status

Show ingestion status for the current or most recent month:

```
NOR INGESTION STATUS — {MMYYYY}
================================
Company      File Found   NOR Value     Ingested    Status
-----------  ----------   ---------     --------    ------
Effecti      YES          R$X,XXX,XXX   {date}      COMPLETE
Leadlovers   YES          R$X,XXX,XXX   {date}      COMPLETE
Ipê Digital  NO           —             —           PENDING
DataHub      YES          R$X,XXX,XXX   {date}      COMPLETE
Mercos        YES          R$X,XXX,XXX   {date}      COMPLETE
Onclick      NO           —             —           PENDING
Dataminer    YES          R$X,XXX,XXX   {date}      COMPLETE
MK Solutions YES          R$X,XXX,XXX   {date}      COMPLETE

Complete: 6/8 (75%)
Pending: Ipê Digital, Onclick
```

---

## Command: dashboard

Generate or refresh the full consolidated NOR dashboard.

**Dashboard structure (Google Sheets):**

Tab 1: `NOR_Monthly` — All monthly data in rows, companies in columns

```
Month    Effecti   Leadlovers  Ipê    DataHub  Mercos  Onclick  Dataminer  MKSol  TOTAL
Jan/25   X.XM      X.XM        X.XM   X.XM     X.XM    X.XM     X.XM       X.XM   X.XM
Feb/25   X.XM      ...
...
```

Tab 2: `NOR_Growth` — MoM and YoY growth rates

```
Month    Effecti_MoM  LL_MoM  Ipê_MoM  ...  Portfolio_MoM  Portfolio_YoY
Jan/25   +X.X%        +X.X%   -X.X%    ...  +X.X%          +X.X%
```

Tab 3: `NOR_Trailing12` — Rolling 12-month NOR per company

Tab 4: `NOR_Alerts` — Companies with declining revenue flags and dates

---

## Command: alert

Identify and notify on declining companies.

**Alert conditions:**

- `mom_growth < -5%`: Company declining more than 5% MoM
- `mom_growth < 0%` for 2+ consecutive months: Sustained decline
- NOR not received after day 10 of month: Missing data alert

**Declining company alert email:**

```
Subject: [PORTFOLIO ALERT] Revenue Decline — {Company} — {MMYYYY}

Portfolio Performance Alert — {TODAY}

{Company} Net Operating Revenue has declined in {MMYYYY}:

Current NOR:    R${current}M
Prior Month:    R${prior}M
MoM Change:     {growth}% ({trend_direction})

YoY Comparison: {yoy_growth}%
Trailing 12M:   R${t12m}M

{If consecutive_months >= 2:}
Note: This is the {N}th consecutive month of decline.

Recommended: Review with portfolio company CFO. Assess whether
this is seasonal, one-time, or structural.

— Zuck (Nuvini Portfolio Agent)
```

Recipients: `cfo@nuvini.com.br`, `ceo@nuvini.com.br`, relevant portfolio company contact

**Missing data alert (sent on day 10):**

```
Subject: [NOR ALERT] Missing Revenue Data — {Company} — {MMYYYY}

{Company} has not submitted NOR data for {MMYYYY}.
Expected location: {drive_folder}
Expected filename: {naming_convention}

Please upload the monthly DRE/Balancete to complete the portfolio dashboard.

— Zuck (Nuvini Portfolio Agent)
```

Dedup: Do not re-send same alert for same company+month within 7 days.

---

## Data Sources

| Source                          | Tool                              | Purpose                              |
| ------------------------------- | --------------------------------- | ------------------------------------ |
| Portfolio company Drive folders | `drive_search`                    | Find monthly NOR files               |
| Company DRE Google Sheets       | `sheets_getRange`                 | Extract NOR values                   |
| NOR_Dashboard Sheet             | `sheets_find` + `sheets_getRange` | Prior period data, dashboard         |
| Memory                          | `memory__search_nodes`            | Prior NOR values, alert history, YTD |
| Today's date                    | `time_getCurrentDate`             | Ingestion timing                     |

## NOR Line Item Lookup Guide

When parsing a DRE, the NOR line appears in different positions and names:

```
DEMONSTRAÇÃO DO RESULTADO DO EXERCÍCIO (DRE)

(+) Receita Bruta de Vendas e Serviços         R$XXX
(-) Deduções da Receita Bruta
    (-) Impostos sobre Vendas (ISS, PIS, COFINS) (R$XX)
    (-) Devoluções e Abatimentos                (R$XX)
    ──────────────────────────────────────────────────
(=) RECEITA OPERACIONAL LÍQUIDA (ROL)          R$XXX  ← This is NOR
```

Common row labels to search for (case-insensitive):

- `receita operacional líquida`
- `receita líquida`
- `ROL`
- `receita líquida de vendas`
- `net revenue`
- `NOR`

## Error Handling

- **File not found in Drive**: Mark as PENDING. Send missing data alert if day >= 10 of month.
- **NOR line item not found in file**: Flag as `MANUAL EXTRACTION NEEDED`. Do not estimate NOR.
- **Negative NOR**: Flag as `DATA ANOMALY — VERIFY`. Could be correct (heavy refunds) but needs review.
- **NOR differs >50% from prior month**: Flag as `OUTLIER — VERIFY BEFORE PUBLISHING`.
- **File found but wrong month**: Note discrepancy. Do not ingest incorrect period data.
- **Google Sheets extraction fails (binary Excel file)**: Flag as `MANUAL EXTRACTION NEEDED`. Note file ID for human review.

## Confidence Scoring

| Tier   | Threshold | Behavior                       |
| ------ | --------- | ------------------------------ |
| Green  | > 95%     | Auto-ingest to dashboard       |
| Yellow | 80–95%    | Human review before publishing |
| Red    | < 80%     | Manual extraction required     |

**All financial revenue data defaults to Yellow regardless of confidence score.** Portfolio data must be reviewed by the CFO before it is used in board packages or external communications.

Confidence is reduced when:

- NOR was extracted from a partial file (not all deductions visible)
- NOR label was inferred by position rather than matched by name
- File was found with a non-standard naming convention
- Prior month data is unavailable (MoM growth cannot be computed reliably)

## Examples

```
/portfolio nor-ingest
→ Ingests prior month NOR for all 8 companies

/portfolio nor-ingest ingest 012026
→ Ingests January 2026 NOR data

/portfolio nor-ingest status
→ Shows ingestion status per company

/portfolio nor-ingest dashboard
→ Generates/refreshes consolidated NOR dashboard

/portfolio nor-ingest alert
→ Sends alerts for declining companies and missing data
```
