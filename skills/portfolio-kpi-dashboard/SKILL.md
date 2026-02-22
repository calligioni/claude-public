---
name: portfolio-kpi-dashboard
description: |
  Track and visualize portfolio KPIs month-over-month for all 8 Nuvini OS portfolio companies.
  Computes SaaS metrics (MRR/ARR, NRR, Rule of 40, EBITDA margin), ranks companies by performance,
  flags underperformers, and generates portfolio-level aggregates. Inputs sourced from NOR ingest
  and subsidiary Balancetes. Outputs a monthly dashboard in Google Sheets or Slides with alerts.
  Triggers on: KPI dashboard, portfolio KPIs, company metrics, portfolio performance, underperformers, SaaS metrics, Rule of 40
argument-hint: "[month YYYY-MM] [company or 'all'] [--ranking | --underperformers | --rule-of-40 | --trends | --full]"
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
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_getRange
  - mcp__google-workspace__sheets_find
  - mcp__google-workspace__sheets_getMetadata
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__drive_findFolder
  - mcp__google-workspace__drive_downloadFile
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_find
  - mcp__google-workspace__slides_getText
  - mcp__google-workspace__slides_find
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_search
  - mcp__google-workspace__time_getCurrentDate
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

Aggregates monthly financial and operational data for all 8 Nuvini portfolio companies and computes a standard SaaS metrics suite: MRR/ARR growth, net revenue retention (NRR), Rule of 40 score, and EBITDA margin. Companies are ranked by composite performance score; underperformers (greater than 5% MoM revenue decline or negative EBITDA) trigger automated alerts. Outputs a monthly portfolio dashboard in Google Sheets and a summary Slides deck, with portfolio-level aggregates across the full holding structure.

## Usage

```bash
# Full dashboard for February 2026, all companies
/portfolio-kpi-dashboard 2026-02 all --full

# Ranking table only
/portfolio-kpi-dashboard 2026-02 all --ranking

# Underperformer alert check
/portfolio-kpi-dashboard 2026-02 all --underperformers

# Rule of 40 scores for all companies
/portfolio-kpi-dashboard 2026-02 all --rule-of-40

# Trend analysis for a single company (last 6 months)
/portfolio-kpi-dashboard 2026-02 Effecti --trends

# Trend analysis for all companies
/portfolio-kpi-dashboard 2026-02 all --trends
```

## Sub-commands

| Flag                | Description                                                                              |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `--full`            | Generate complete monthly dashboard: all metrics, ranking, trends, underperformer alerts |
| `--ranking`         | Output company ranking table by composite performance score                              |
| `--underperformers` | List companies breaching thresholds; trigger alert emails to Zuck and portfolio teams    |
| `--rule-of-40`      | Compute and display Rule of 40 score for each company (ARR growth % + EBITDA margin %)   |
| `--trends`          | Show MoM and 6-month trend lines per metric for specified company or all                 |

## Portfolio Companies

| Company      | Type              | Primary Currency |
| ------------ | ----------------- | ---------------- |
| Effecti      | SaaS / HCM        | BRL              |
| Leadlovers   | SaaS / MarTech    | BRL              |
| Ipê Digital  | SaaS / Agri       | BRL              |
| DataHub      | SaaS / Data       | BRL              |
| Mercos       | SaaS / B2B Sales  | BRL              |
| Onclick      | SaaS / Telecom    | BRL              |
| Dataminer    | SaaS / Analytics  | BRL              |
| MK Solutions | SaaS / Telecom IT | BRL              |

Parent holding entities (aggregated at portfolio level):

- NVNI Group Ltd. (Cayman) — ultimate parent
- Nuvini Holdings Ltd. (Cayman) — intermediary
- Nuvini S.A. (Brazil) — operating holding
- Holding LLC (Delaware) — US holding vehicle

## Metrics Computed

### Per-Company SaaS Metrics

| Metric                | Formula                                          | Source                 |
| --------------------- | ------------------------------------------------ | ---------------------- |
| MRR                   | Monthly Recurring Revenue                        | NOR ingest / Balancete |
| ARR                   | MRR x 12                                         | Derived                |
| MRR Growth (MoM)      | (MRR_t - MRR_t-1) / MRR_t-1                      | Derived                |
| ARR Growth (YoY)      | (ARR_t - ARR_t-12) / ARR_t-12                    | Derived                |
| Net Revenue Retention | (MRR end - churned + expansion) / MRR start      | NOR ingest             |
| EBITDA                | Revenue - COGS - OpEx (excl. D&A, interest, tax) | Balancete              |
| EBITDA Margin         | EBITDA / Net Revenue                             | Derived                |
| Rule of 40            | ARR Growth (%) + EBITDA Margin (%)               | Derived                |
| Churn Rate            | MRR churned / MRR start of period                | NOR ingest             |
| NPS                   | Net Promoter Score                               | Operational input      |
| Headcount             | Total FTE count                                  | HR / operational input |
| Number of Clients     | Active paying clients                            | NOR ingest             |

### Portfolio-Level Aggregates

- Total ARR across all 8 companies
- Weighted average NRR
- Portfolio Rule of 40 (revenue-weighted)
- Total headcount
- Aggregate EBITDA and margin
- MoM ARR change (BRL and %)

## Underperformer Thresholds

A company is flagged as an underperformer when any of the following are true:

- MoM net revenue decline exceeds 5%
- EBITDA is negative for 2 consecutive months
- NRR falls below 90%
- Churn rate exceeds 3% in a single month
- Rule of 40 score falls below 0

When thresholds are breached, the skill:

1. Generates an underperformer alert summary
2. Sends an email via Gmail to Zuck (Portfolio) and the relevant portfolio company contact
3. Tags the company row in the dashboard with RED status
4. Logs the alert in the portfolio tracker sheet

## Data Sources

| Input                            | Source                                                                 |
| -------------------------------- | ---------------------------------------------------------------------- |
| NOR (Net Operating Revenue) data | `portfolio:nor-ingest` skill output / Google Sheets                    |
| Monthly Balancetes (financials)  | Drive search `name contains 'Balancete' AND name contains '[company]'` |
| Revenue and EBITDA               | Subsidiary financial statements (Sheets)                               |
| Churn and NPS                    | Operational metrics sheet per company                                  |
| Headcount                        | HR tracker (Drive search `name contains 'Headcount'`)                  |
| ARR and client count             | NOR ingest or company CRM export                                       |
| Prior month dashboard            | Drive search `name contains 'Portfolio KPI Dashboard'`                 |

All data gaps (missing Balancete, absent NOR data) are flagged in `--status` output. The skill does not impute or estimate missing values — it halts and requests the missing input.

## Output Format

### Ranking Table (--ranking)

```
PORTFOLIO KPI DASHBOARD — February 2026
========================================
Rank | Company      | ARR (BRL M) | MoM Growth | NRR   | Rule of 40 | EBITDA %  | Status
-----|--------------|-------------|------------|-------|------------|-----------|--------
  1  | Mercos       | 48.2M       | +3.1%      | 112%  | 58         | +22%      | GREEN
  2  | Leadlovers   | 35.7M       | +2.4%      | 108%  | 47         | +18%      | GREEN
  3  | Effecti      | 29.1M       | +1.8%      | 104%  | 38         | +14%      | GREEN
  4  | DataHub      | 18.4M       | +0.9%      | 99%   | 22         |  +8%      | GREEN
  5  | Ipê Digital  | 12.3M       | +0.2%      | 95%   | 11         |  +3%      | YELLOW
  6  | Onclick      | 22.6M       | -1.1%      | 94%   |  9         |  +2%      | YELLOW
  7  | MK Solutions | 16.8M       | -2.3%      | 91%   |  4         |  +1%      | YELLOW
  8  | Dataminer    | 9.4M        | -6.2%      | 87%   | -8         |  -4%      | RED

PORTFOLIO TOTALS
-----------------
Total ARR       : BRL 192.5M
Wtd Avg NRR     : 103%
Portfolio R40   : 27
Total Headcount : 1,847
Aggregate EBITDA: +BRL 18.3M (9.5% margin)

ALERTS
------
[CRITICAL] Dataminer — MoM revenue -6.2% (threshold: -5%), EBITDA negative.
           Alert sent to Zuck and Dataminer team. 2026-02-19 10:42 UTC
```

### Google Sheets Dashboard

Generated in Drive folder `Portfolio / KPI Dashboards / 2026-02/`:

- Tab 1: Summary ranking table (above)
- Tab 2: Per-company detail (all metrics, MoM delta, 6-month trend)
- Tab 3: Portfolio aggregates and trend charts
- Tab 4: Underperformer log and alert history

## Confidence Scoring

| Level  | Threshold | Action                                                                                                                                          |
| ------ | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Green  | >95%      | All data sources present, metrics computed cleanly — auto-publish dashboard to Drive                                                            |
| Yellow | 80-95%    | One or more companies missing data (e.g., Balancete not yet available) — publish partial dashboard with gaps clearly marked; notify Zuck        |
| Red    | <80%      | Critical data missing (more than 3 companies without Balancete, NOR data corrupted) — halt and request data refresh before generating dashboard |

Underperformer alerts always send regardless of confidence level — a data gap for a declining company is itself an alert.

## Integration

| Agent / Skill               | Interaction                                                                                          |
| --------------------------- | ---------------------------------------------------------------------------------------------------- |
| `portfolio:nor-ingest`      | Primary revenue data source; must run before this skill each month                                   |
| Zuck (Portfolio)            | Primary owner — receives dashboard, underperformer alerts, and ranking updates                       |
| Julia (Finance)             | Provides Balancete data; cross-checks EBITDA figures                                                 |
| Cris (M&A)                  | Uses ranking and Rule of 40 data to prioritize portfolio support and acquisition targeting           |
| `compliance-annual-report`  | EBITDA and revenue figures cross-referenced for related-party transaction disclosures                |
| `legal-compliance-calendar` | Dashboard generation scheduled monthly; calendar tracks due date (typically 15th of following month) |
