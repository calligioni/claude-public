---
name: ir-earnings-release
description: "Produce quarterly earnings releases for NVNI Group Limited (NASDAQ: NVNI) with full financial tables: revenue breakdown by subsidiary, EBITDA reconciliation, balance sheet highlights, cash flow summary, per-share metrics, and optional guidance language. Sourced from the FP&A Blueprint. All outputs are RED confidence — mandatory CFO and legal review before release. Triggers on: earnings release, quarterly earnings, resultados trimestrais, earnings report, quarterly results."
argument-hint: "[quarter YYYY-QN] [--tables | --narrative | --full | --compare-prior]"
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
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
tool-annotations:
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__memory__search_nodes: { readOnlyHint: true }
  mcp__memory__open_nodes: { readOnlyHint: true }
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

# ir-earnings-release — Quarterly Earnings Release Builder

**Agent:** Bella
**Entity:** NVNI Group Limited (NASDAQ: NVNI)
**Purpose:** Build full quarterly earnings releases with GAAP financial tables, EBITDA reconciliation, per-share metrics, and management narrative. Sourced entirely from the FP&A Blueprint and NOR dashboard. Outputs a draft Google Doc structured for Form 6-K filing and press wire distribution. All outputs are permanently RED confidence — no draft may be published or filed without written sign-off from the CFO and legal counsel.

## CRITICAL COMPLIANCE RULES

1. **RED Confidence — Non-negotiable:** Every earnings release draft is RED. No exceptions. Do not distribute to any party outside the internal review team without CFO + legal written approval.
2. **Unaudited label required:** Unless the period has been audited by the external auditor, all financial figures must be labeled "(unaudited)" throughout the document.
3. **Forward-looking statements:** Any guidance section or outlook language must include the full SEC Safe Harbor Statement. Do not draft speculative language — use only management-approved wording.
4. **FPI compliance:** NVNI files on Form 6-K as a foreign private issuer. The earnings release is furnished, not filed. The draft must note this distinction.
5. **Currency disclosure:** All USD figures must state the exchange rate used for BRL-to-USD conversion. Source: use the rate from the FP&A Blueprint or note as "Management estimate."
6. **No MNPI:** Do not include any unannounced M&A transactions, undisclosed financing, or pending material events.

## Usage

```
/bella ir-earnings-release Q4-2025
/bella ir-earnings-release Q4-2025 --full
/bella ir-earnings-release Q4-2025 --tables
/bella ir-earnings-release Q4-2025 --narrative
/bella ir-earnings-release Q4-2025 --compare-prior
```

## Sub-commands

| Command           | Description                                                                                                           |
| ----------------- | --------------------------------------------------------------------------------------------------------------------- |
| `--full`          | Complete earnings release: header, highlights, narrative, all financial tables, reconciliation, boilerplate (default) |
| `--tables`        | Financial tables only: income statement highlights, EBITDA reconciliation, balance sheet, cash flow, EPS              |
| `--narrative`     | Management narrative sections only: overview, segment discussion, outlook                                             |
| `--compare-prior` | Include prior-year and prior-quarter comparison columns in all tables                                                 |

---

## Process

### Phase 1: Load Financial Data from FP&A Blueprint

Call `mcp__google-workspace__time_getCurrentDate` for TODAY. Derive the target quarter if not explicitly provided.

Search for the FP&A Blueprint via `mcp__google-workspace__sheets_find` with query: `"FP&A Blueprint"` or `"Financial Statements Consolidation"`.

Extract the following data for the **reporting period** and the **prior-year comparable period** (and prior quarter if `--compare-prior`):

#### Income Statement Highlights

| Line Item                         | Notes                                                                               |
| --------------------------------- | ----------------------------------------------------------------------------------- |
| Net Revenue (consolidated)        | Total from all 8 portfolio companies                                                |
| Revenue by subsidiary             | Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions |
| Cost of Revenue                   | Direct costs                                                                        |
| Gross Profit                      | Net Revenue minus Cost of Revenue                                                   |
| Gross Margin (%)                  | Gross Profit / Net Revenue                                                          |
| Sales & Marketing Expenses        |                                                                                     |
| General & Administrative Expenses |                                                                                     |
| Research & Development Expenses   |                                                                                     |
| Total Operating Expenses          |                                                                                     |
| Operating Income (Loss)           |                                                                                     |
| Financial Income (Expense), net   | Interest, FX gains/losses                                                           |
| Income Before Taxes               |                                                                                     |
| Income Tax Expense (Benefit)      |                                                                                     |
| Net Income (Loss)                 |                                                                                     |
| Net Income (Loss) attr. to NVNI   | After non-controlling interest                                                      |
| Non-controlling Interest          |                                                                                     |

#### EBITDA Bridge (Adjusted EBITDA Reconciliation)

| Line Item                       | Notes                                        |
| ------------------------------- | -------------------------------------------- |
| Net Income (Loss)               | GAAP starting point                          |
| (+) Income Tax Expense          |                                              |
| (+) Financial Expense, net      |                                              |
| (+) Depreciation & Amortization | Include amortization of acquired intangibles |
| = EBITDA                        | Computed subtotal                            |
| (+) Share-based compensation    | Non-cash                                     |
| (+) M&A transaction costs       | Non-recurring, if any                        |
| (+) Restructuring charges       | Non-recurring, if any                        |
| (+) Other non-recurring items   | List individually with description           |
| = Adjusted EBITDA               | Management non-GAAP metric                   |
| Adjusted EBITDA Margin (%)      | Adjusted EBITDA / Net Revenue                |

#### Balance Sheet Highlights (Period End)

| Line Item                         | Notes                                 |
| --------------------------------- | ------------------------------------- |
| Cash and cash equivalents         |                                       |
| Accounts receivable, net          |                                       |
| Total current assets              |                                       |
| Goodwill and intangible assets    |                                       |
| Total assets                      |                                       |
| Accounts payable                  |                                       |
| Short-term debt                   | Includes current portion of long-term |
| Total current liabilities         |                                       |
| Long-term debt                    |                                       |
| Total liabilities                 |                                       |
| Total equity attributable to NVNI |                                       |
| Non-controlling interest          |                                       |
| Total equity                      |                                       |

#### Cash Flow Summary

| Line Item                          | Notes                      |
| ---------------------------------- | -------------------------- |
| Net cash from operating activities |                            |
| Capital expenditures               |                            |
| Free Cash Flow                     | CFO minus capex (non-GAAP) |
| Cash used in investing activities  | M&A, capex, investments    |
| Cash from financing activities     | Debt proceeds, repayments  |
| Net change in cash                 |                            |
| Cash at beginning of period        |                            |
| Cash at end of period              |                            |

#### Per-Share Metrics

| Metric                        | Notes                                          |
| ----------------------------- | ---------------------------------------------- |
| Weighted avg shares — basic   |                                                |
| Weighted avg shares — diluted | Include warrants (NVNIW) and convertible notes |
| EPS — basic (GAAP)            |                                                |
| EPS — diluted (GAAP)          |                                                |
| Adjusted EPS (non-GAAP)       | Using Adjusted Net Income if defined           |

### Phase 2: Load Per-Subsidiary Revenue from NOR Dashboard

Call `mcp__google-workspace__sheets_find` with query `"Portfolio NOR"` or `"NOR Dashboard"`. Extract monthly and quarterly revenue for all 8 portfolio companies:

- **Effecti** — marketing tech
- **Leadlovers** — marketing automation
- **Ipê Digital** — digital transformation services
- **DataHub** — data analytics
- **Mercos** — B2B commerce platform
- **Onclick** — digital performance
- **Dataminer** — data intelligence
- **MK Solutions** — customer service software

Aggregate to quarterly total. Compute YoY growth rate per subsidiary. Flag any subsidiary where revenue data is preliminary or estimated.

### Phase 3: Load Capital / Share Data

Call `mcp__google-workspace__sheets_find` with query `"NVNI Capital Register"` or invoke ir-capital-register to obtain:

- Shares outstanding (basic)
- Fully diluted share count (warrants + convertible note conversions)
- Total debt outstanding (for balance sheet cross-check)
- NVNIW warrants outstanding

### Phase 4: Draft the Earnings Release

Structure the Google Doc as follows:

---

**[DRAFT — UNAUDITED — CONFIDENTIAL — NOT FOR DISTRIBUTION]**

**FOR IMMEDIATE RELEASE** _(remove DRAFT tag before publication)_

**NVNI Group Limited Reports [Quarter] [Year] Financial Results**

_[City, Date]_ — NVNI Group Limited (NASDAQ: NVNI) ("NVNI" or the "Company"), a holding company of leading B2B SaaS companies in Brazil, today reported financial results for the [quarter] ended [date].

---

**Financial Highlights**

```
                              [Quarter]          [Prior Year Quarter]    Change
                              ---------          --------------------    ------
Net Revenue (USD)             $XX.XM             $XX.XM                  +XX%
Adjusted EBITDA (USD)         $XX.XM             $XX.XM                  +XX%
Adjusted EBITDA Margin        XX.X%              XX.X%                   +X.Xpp
Cash and Equivalents          $XX.XM             $XX.XM
```

---

**Management Commentary** _(narrative section — populate with management-approved language only)_

"[CEO quote — insert verbatim from management. Do not draft speculative language.]"

"[CFO quote — insert verbatim from management.]"

---

**Revenue by Subsidiary**

```
Company             [Quarter] Revenue    [PY Quarter] Revenue    YoY Growth
-----------         -----------------    --------------------    ----------
Effecti             $X.XM                $X.XM                   +XX%
Leadlovers          $X.XM                $X.XM                   +XX%
Ipê Digital         $X.XM                $X.XM                   +XX%
DataHub             $X.XM                $X.XM                   +XX%
Mercos              $X.XM                $X.XM                   +XX%
Onclick             $X.XM                $X.XM                   +XX%
Dataminer           $X.XM                $X.XM                   +XX%
MK Solutions        $X.XM                $X.XM                   +XX%
                    ------               ------
Consolidated        $XX.XM               $XX.XM                  +XX%
```

_All BRL figures converted to USD at [rate] BRL/USD, the average exchange rate for the period._

---

**GAAP to Non-GAAP Reconciliation — Net Income to Adjusted EBITDA**

```
                                          [Quarter]       [PY Quarter]
                                          ---------       ------------
Net Income (Loss) — GAAP                  $X.XM           $X.XM
  Add: Income tax expense                 $X.XM           $X.XM
  Add: Net financial expense              $X.XM           $X.XM
  Add: Depreciation & amortization        $X.XM           $X.XM
                                          ------          ------
EBITDA                                    $X.XM           $X.XM
  Add: Share-based compensation           $X.XM           $X.XM
  Add: M&A transaction costs              $X.XM           $X.XM
  Add: Other non-recurring items          $X.XM           $X.XM
                                          ------          ------
Adjusted EBITDA                           $X.XM           $X.XM
Adjusted EBITDA Margin                    XX.X%           XX.X%
```

---

**Condensed Consolidated Balance Sheet (Unaudited)**

```
                                          [Period End]    [Prior Year End]
                                          -----------     ----------------
Cash and cash equivalents                 $XX.XM          $XX.XM
Total current assets                      $XX.XM          $XX.XM
Total assets                              $XX.XM          $XX.XM

Total current liabilities                 $XX.XM          $XX.XM
Total long-term debt                      $XX.XM          $XX.XM
Total equity                              $XX.XM          $XX.XM
```

---

**Condensed Consolidated Cash Flow (Unaudited)**

```
                                          [Quarter]       [PY Quarter]
                                          ---------       ------------
Net cash from operating activities        $X.XM           $X.XM
Capital expenditures                      ($X.XM)         ($X.XM)
Free Cash Flow (non-GAAP)                 $X.XM           $X.XM
Net cash used in investing activities     ($X.XM)         ($X.XM)
Net cash from financing activities        $X.XM           $X.XM
Net change in cash                        $X.XM           $X.XM
```

---

**Per Share Data (Unaudited)**

```
                                          [Quarter]       [PY Quarter]
                                          ---------       ------------
Weighted avg shares — basic               XXX.XM          XXX.XM
Weighted avg shares — diluted             XXX.XM          XXX.XM
EPS — basic (GAAP)                        $X.XX           $X.XX
EPS — diluted (GAAP)                      $X.XX           $X.XX
```

---

**Guidance** _(include only if management-approved language is provided — mark section as PLACEHOLDER if not)_

[Guidance section — insert management-approved language only. All guidance text is a forward-looking statement and must include the Safe Harbor Statement below.]

---

**About NVNI Group Limited**

NVNI Group Limited (NASDAQ: NVNI) is a holding company of leading Brazilian B2B SaaS businesses. The Company's portfolio includes eight companies spanning marketing technology, data analytics, B2B commerce, customer service software, and digital transformation services: Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, and MK Solutions. NVNI's mission is to consolidate and scale the leading vertical SaaS businesses serving Brazilian SMBs.

---

**Safe Harbor Statement — Forward-Looking Statements**

This press release contains forward-looking statements within the meaning of the U.S. Private Securities Litigation Reform Act of 1995, Section 27A of the Securities Act of 1933, and Section 21E of the Securities Exchange Act of 1934. All statements other than statements of historical facts contained in this press release, including statements regarding the Company's future results of operations, financial position, business strategy, plans, and objectives of management for future operations, are forward-looking statements. These statements involve known and unknown risks, uncertainties, and other factors that may cause actual results, performance, or achievements to be materially different from any future results, performance, or achievements expressed or implied by the forward-looking statements. Such risks and uncertainties include, but are not limited to, competitive pressures in the Brazilian SaaS market, macroeconomic and currency risks, integration of acquired businesses, regulatory changes, and other risks described in NVNI's most recent Annual Report on Form 20-F filed with the U.S. Securities and Exchange Commission. NVNI Group Limited undertakes no obligation to publicly update or revise any forward-looking statements, whether as a result of new information, future events, or otherwise.

**Use of Non-GAAP Financial Measures**

This press release includes Adjusted EBITDA and Free Cash Flow, which are non-GAAP financial measures. The Company presents these measures as supplemental information and they should not be considered in isolation from, or as a substitute for, financial information presented in accordance with IFRS as adopted by the IASB. A reconciliation to the most comparable GAAP measure is provided in the tables above.

_This press release is being furnished as an exhibit to a Report on Form 6-K and is not deemed "filed" for purposes of Section 18 of the Securities Exchange Act of 1934._

---

**Investor Relations Contact**

ir@nuvini.com.br
NVNI Group Limited

---

### Phase 5: Save and Route for Review

1. Create draft via `mcp__google-workspace__docs_create` with title: `NVNI Earnings Release — {QUARTER} — DRAFT — {TODAY}` in the IR/Earnings Drive folder.
2. Add `[DRAFT — NOT FOR DISTRIBUTION]` as the first line of the document.
3. Produce a data source audit block at the end of the document listing every figure with its source tab and extraction date.
4. Send review notification via `mcp__google-workspace__gmail_send` to:
   - `ceo@nuvini.com.br`
   - `cfo@nuvini.com.br`
   - `legal@nuvini.com.br`
   - `ir@nuvini.com.br`
     Subject: `[ACTION REQUIRED] NVNI Earnings Release Draft — {QUARTER} — CFO + Legal Review Needed`
5. Log draft in memory: `mcp__memory__add_observations` on entity `ir-earnings-release` with quarter, draft URL, and open items list.

---

## Data Sources

| Source                         | Tool                              | Data Retrieved                                     |
| ------------------------------ | --------------------------------- | -------------------------------------------------- |
| FP&A Blueprint (Sheets)        | `sheets_find` + `sheets_getRange` | Consolidated P&L, EBITDA, balance sheet, cash flow |
| NOR Dashboard (Sheets)         | `sheets_find` + `sheets_getRange` | Per-subsidiary revenue, YoY growth rates           |
| NVNI Capital Register (Sheets) | `sheets_find` + `sheets_getRange` | Share count, diluted shares, NVNIW warrants        |
| Memory                         | `memory__search_nodes`            | FX rate, prior earnings release drafts             |
| SEC EDGAR                      | `WebSearch`                       | Prior 6-K filings for format consistency           |

Drive search queries:

- FP&A Blueprint: `name contains 'FP&A Blueprint' and mimeType = 'application/vnd.google-apps.spreadsheet'`
- NOR Dashboard: `name contains 'NOR' and mimeType = 'application/vnd.google-apps.spreadsheet'`
- IR Earnings folder: `name = 'Earnings Releases' and mimeType = 'application/vnd.google-apps.folder'`
- Prior 6-K: search SEC EDGAR via `WebSearch` for `site:sec.gov NVNI 6-K`

---

## Output Format

```
EARNINGS RELEASE BUILD REPORT — {QUARTER} — {TODAY}
====================================================

DRAFT STATUS: CREATED
DRAFT URL: {Google Doc URL}

DATA LOADED:
  Consolidated Revenue:         $XX.XM  [Source: FP&A Blueprint / Consolidation tab — {date}]
  Revenue YoY Growth:           +XX%    [Derived]
  Adjusted EBITDA:              $XX.XM  [Source: FP&A Blueprint / EBITDA tab — {date}]
  EBITDA Margin:                XX.X%   [Derived]
  Cash Position:                $XX.XM  [Source: FP&A Blueprint / Balance Sheet tab — {date}]
  Diluted Share Count:          XXX.XM  [Source: Capital Register — {date}]
  EPS (basic, GAAP):            $X.XX   [Derived]

SUBSIDIARY REVENUE LOADED: 8 / 8
  [list subsidiaries with data source status]

OPEN ITEMS (require management input before filing):
  - CEO quote: PLACEHOLDER — insert approved text
  - CFO quote: PLACEHOLDER — insert approved text
  - Guidance section: PLACEHOLDER — confirm if guidance is being provided
  - Exchange rate used: {rate} — confirm with CFO
  - Audit status: UNAUDITED — confirm with external auditor

PENDING FLAGS:
  - [Any figure marked preliminary or estimated]

REVIEW NOTIFICATIONS SENT TO: ceo, cfo, legal, ir

CONFIDENCE: RED — CFO + Legal review mandatory before any distribution.
```

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                               |
| ------ | --------- | ---------------------------------------------------------------------- |
| Green  | > 95%     | Not applicable — earnings releases require mandatory review regardless |
| Yellow | 80–95%    | Not applicable for earnings releases                                   |
| Red    | ALL       | Mandatory — every earnings release draft is RED with no exceptions     |

**ALL earnings release outputs are permanently RED confidence.** The earnings release is a public disclosure furnished on Form 6-K to the SEC. Every financial figure must be:

- Verified by the CFO against the audited or reviewed financial statements.
- Cleared by legal counsel for forward-looking statements, Safe Harbor adequacy, and MNPI.
- Approved by the IR director for messaging alignment.

Unaudited figures must be labeled "(unaudited)" throughout. No figures from preliminary management accounts may be used as final without CFO confirmation.

Confidence is not upgradeable for this skill. Even if all data sources are confirmed, the Red designation remains until written CFO + legal sign-off is received.

---

## Integration

| Agent / Skill          | Role                                                                      |
| ---------------------- | ------------------------------------------------------------------------- |
| Julia                  | FP&A Blueprint: consolidated GAAP financials, EBITDA bridge, cash flow    |
| Zuck                   | NOR Dashboard: per-subsidiary revenue for portfolio breakdown table       |
| Marco                  | Legal: FLS review, Safe Harbor adequacy, 6-K furnishing confirmation      |
| Scheduler              | Earnings calendar: release date, SEC filing window, blackout period dates |
| ir-capital-register    | Share count, diluted shares (NVNIW + convertible notes) for EPS           |
| ir-press-release-draft | For material event announcements embedded in or alongside earnings        |
| Cris                   | M&A activity disclosure (public transactions only, no MNPI)               |

---

## Examples

```
/bella ir-earnings-release Q4-2025
-> Full earnings release draft with all sections, tables, and boilerplate

/bella ir-earnings-release Q4-2025 --tables
-> Financial tables only: income statement, EBITDA reconciliation, balance sheet, cash flow, EPS

/bella ir-earnings-release Q4-2025 --narrative
-> Management narrative sections only (requires management-approved quotes and outlook)

/bella ir-earnings-release Q4-2025 --compare-prior
-> Full release with prior-year and prior-quarter comparison columns in all tables

/bella ir-earnings-release Q3-2025 --tables --compare-prior
-> Tables with both current quarter, prior quarter, and prior year columns
```
