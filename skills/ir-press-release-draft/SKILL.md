---
name: ir-press-release-draft
description: "Draft press releases for NVNI Group Limited (NASDAQ: NVNI) including quarterly earnings releases, material event announcements, and acquisition announcements. Includes GAAP-to-non-GAAP reconciliation tables sourced from the FP&A Blueprint. All drafts include SEC safe harbor language, forward-looking statements disclaimer, and boilerplate. All outputs are RED confidence — mandatory legal and IR review before publication or filing. Triggers on: press release, comunicado, earnings press release, material event, GAAP reconciliation, non-GAAP."
argument-hint: "[type earnings|material-event|acquisition|other] [period YYYY-QN] [--draft | --reconciliation-table | --review]"
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

# ir-press-release-draft — Press Release Drafter

**Agent:** Bella
**Entity:** NVNI Group Limited (NASDAQ: NVNI)
**Purpose:** Draft press releases for material corporate events and earnings. Pulls financial data from the FP&A Blueprint, constructs GAAP and non-GAAP reconciliation tables, and formats output to meet SEC press release standards for foreign private issuers. Every output is RED confidence — no press release may be published, filed on Form 6-K, or distributed over a wire service without CFO, legal counsel, and IR team sign-off.

## CRITICAL COMPLIANCE RULES

1. **RED Confidence — Mandatory:** ALL press release drafts are RED confidence. No exceptions. No distribution without full legal and management review.
2. **Safe Harbor:** Every press release must include the SEC Safe Harbor Statement for forward-looking statements.
3. **SEC Form 6-K:** Material event press releases for NVNI (as a foreign private issuer) are furnished on Form 6-K. The draft must include a note indicating the applicable 6-K filing obligation.
4. **Regulation FD:** Simultaneous public disclosure is required. Any press release distributed via PR wire (e.g., GlobeNewswire, PR Newswire) must be filed on 6-K on the same day.
5. **Non-GAAP Measures:** All non-GAAP measures (Adjusted EBITDA, Adjusted Net Income, etc.) must be presented alongside the most directly comparable GAAP measure. The reconciliation table is mandatory.
6. **No Material Non-Public Information:** Do not draft press releases referencing information not yet cleared for public disclosure by management.

---

## Usage

```
/ir press-release-draft earnings Q4-2025 --draft
/ir press-release-draft earnings Q4-2025 --reconciliation-table
/ir press-release-draft material-event Q1-2026 --draft
/ir press-release-draft acquisition --draft
/ir press-release-draft Q4-2025 --review
```

## Sub-commands

| Command                  | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `--draft`                | Full press release draft including all sections, tables, and boilerplate      |
| `--reconciliation-table` | Generate only the GAAP-to-non-GAAP reconciliation table from FP&A Blueprint   |
| `--review`               | Produce a compliance checklist against the existing draft for legal/IR review |

---

## Process

### Phase 1: Determine Press Release Type

**earnings:** Quarterly or annual financial results. Requires full financial tables (income statement highlights, EBITDA reconciliation, balance sheet highlights, cash flow summary).

**material-event:** Any event requiring 6-K disclosure (significant contract, change in executive leadership, capital raise, NASDAQ notice, material litigation). Financial tables may not be required.

**acquisition:** Announce a completed or signed acquisition. Includes transaction overview, rationale, consideration, and financing. No target-specific financials unless already public.

**other:** Custom press release type. Bella drafts based on provided topic and prompts for required sections.

### Phase 2: Retrieve Financial Data (earnings type)

Source: FP&A Blueprint (Google Sheets or Docs). Search via `sheets_find` with query: `"FP&A Blueprint"` or `"Consolidation"`.

Extract the following for the stated quarter and the prior-year comparable period:

**Income Statement Highlights:**

- Net Revenue (consolidated and by segment / subsidiary)
- Cost of Revenue / Gross Profit / Gross Margin
- Operating Expenses (Sales, G&A, R&D)
- Operating Income (Loss)
- Net Income (Loss) attributable to NVNI shareholders
- EBITDA (computed: Operating Income + D&A)
- Adjusted EBITDA (EBITDA + non-cash items + one-time adjustments as defined)

**Balance Sheet Highlights (period end):**

- Cash and cash equivalents
- Total current assets
- Total assets
- Total current liabilities
- Total debt (short-term + long-term)
- Total equity

**Cash Flow:**

- Net cash from operating activities
- Net cash used in investing activities
- Net cash from financing activities
- Net change in cash

**Per Share:**

- Weighted average shares outstanding (basic and diluted)
- EPS basic and diluted (GAAP)
- Adjusted EPS (non-GAAP, if applicable)

**Portfolio subsidiary revenue (from NOR dashboard):**

- Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions

### Phase 3: Build GAAP-to-Non-GAAP Reconciliation Table

Required reconciliation: **Net Income (Loss) to Adjusted EBITDA**

```
RECONCILIATION OF NET INCOME (LOSS) TO ADJUSTED EBITDA
(Unaudited, in thousands of USD)

                                        Three Months Ended          Year Ended
                                        {QN YYYY}   {QN YYYY}      {FY YYYY}   {FY YYYY}
                                        ---------   ---------      ---------   ---------
Net income (loss)                       $( X,XXX)   $( X,XXX)      $( X,XXX)   $( X,XXX)
  Add: Income tax expense (benefit)      X,XXX       X,XXX          X,XXX       X,XXX
  Add: Interest expense, net             X,XXX       X,XXX          X,XXX       X,XXX
  Add: Depreciation and amortization     X,XXX       X,XXX          X,XXX       X,XXX
                                        ---------   ---------      ---------   ---------
EBITDA                                  $  X,XXX    $  X,XXX       $  X,XXX    $  X,XXX
  Add: Stock-based compensation          X,XXX       X,XXX          X,XXX       X,XXX
  Add: Transaction costs                 X,XXX       X,XXX          X,XXX       X,XXX
  Add: Other non-recurring items         X,XXX       X,XXX          X,XXX       X,XXX
                                        ---------   ---------      ---------   ---------
Adjusted EBITDA                         $  X,XXX    $  X,XXX       $  X,XXX    $  X,XXX
                                        =========   =========      =========   =========
Adjusted EBITDA Margin                   XX.X%       XX.X%          XX.X%       XX.X%
```

Note: Non-GAAP Adjusted EBITDA is a supplemental measure of performance. It is not a substitute for, and should be read in conjunction with, NVNI's financial statements prepared in accordance with IFRS as adopted by the IASB (or US GAAP as applicable). See "Non-GAAP Financial Measures" section for definitions.

### Phase 4: Draft Full Press Release Structure

```
FOR IMMEDIATE RELEASE

NVNI GROUP LIMITED REPORTS [FOURTH QUARTER / FULL YEAR] {YYYY} FINANCIAL RESULTS

[CITY, COUNTRY] — [DATE] — NVNI Group Limited (NASDAQ: NVNI) ("NVNI" or the "Company"),
a holding company of B2B SaaS businesses serving the Brazilian market, today reported
financial results for the [period ended DATE].

[OPTIONAL MANAGEMENT QUOTE — placeholder for CEO/CFO quote]

FINANCIAL HIGHLIGHTS

For the [period]:
  - Net Revenue: $X.XM, [up/down] X% year-over-year
  - Adjusted EBITDA: $X.XM ([X.X%] margin)
  - Cash position: $X.XM as of [date]
  - [Key operational metric]

PORTFOLIO PERFORMANCE

The Company operates [N] B2B SaaS businesses serving the Brazilian market:
[Subsidiary revenue table]

FINANCIAL TABLES

[Income Statement Highlights Table]
[Balance Sheet Highlights Table]
[Cash Flow Summary Table]
[GAAP to Non-GAAP Reconciliation — see Phase 3]

NON-GAAP FINANCIAL MEASURES

[Definition paragraph for Adjusted EBITDA and any other non-GAAP measures used]

ABOUT NVNI GROUP LIMITED

NVNI Group Limited (NASDAQ: NVNI) is a holding company that acquires, operates, and
grows B2B SaaS businesses in Brazil. The Company's portfolio includes Effecti,
Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, and MK Solutions.
For more information, please visit [IR website].

FORWARD-LOOKING STATEMENTS

This press release contains forward-looking statements within the meaning of
Section 27A of the Securities Act of 1933, as amended, and Section 21E of the
Securities Exchange Act of 1934, as amended. These statements include, but are not
limited to, statements regarding the Company's future operating results, financial
position, strategy, and growth plans. Forward-looking statements involve known and
unknown risks, uncertainties, and other factors that may cause the Company's actual
results, performance, or achievements to differ materially from those expressed or
implied by the forward-looking statements. Factors that could cause actual results
to differ materially include, but are not limited to: changes in general economic
conditions in Brazil, changes in the competitive landscape for SaaS products,
regulatory changes, currency fluctuations, and other risks detailed in NVNI's
filings with the U.S. Securities and Exchange Commission, including its Annual Report
on Form 20-F. NVNI undertakes no obligation to update or revise any forward-looking
statements.

NOTE REGARDING FORM 6-K FILING

This press release is being furnished as an exhibit to a Report on Form 6-K filed
with the Securities and Exchange Commission. This press release shall not be deemed
"filed" for purposes of Section 18 of the Securities Exchange Act of 1934.

INVESTOR CONTACT:
ir@nuvini.com.br

MEDIA CONTACT:
[Media contact placeholder]
```

### Phase 5: Save and Route for Review

1. Create Google Doc via `docs_create` titled `[DRAFT] NVNI Press Release — {type} — {period} — {date}` in the `IR/Press Releases/Drafts/` Drive folder.
2. Add review metadata block at top of document: draft version, date created, data sources, open items list.
3. Send notification via `gmail_send` to: `ceo@nuvini.com.br`, `cfo@nuvini.com.br`, `legal@nuvini.com.br`, `ir@nuvini.com.br` with draft link and review deadline.
4. Log draft in memory: `memory__add_observations` on entity `ir-press-release-draft` with type, period, and review status.

---

## Data Sources

| Source                         | Tool                              | Data Retrieved                                  |
| ------------------------------ | --------------------------------- | ----------------------------------------------- |
| FP&A Blueprint (Sheets)        | `sheets_find` + `sheets_getRange` | GAAP financials: revenue, EBITDA, cash flow     |
| NOR Dashboard (Sheets)         | `sheets_find` + `sheets_getRange` | Per-subsidiary revenue for portfolio table      |
| NVNI Capital Register (Sheets) | `sheets_find` + `sheets_getRange` | Share count for EPS, debt for balance sheet     |
| M&A / Deal Documents (Docs)    | `drive_search` + `docs_getText`   | Acquisition details (public announcements only) |
| Memory                         | `memory__search_nodes`            | Prior press releases, boilerplate text          |
| SEC EDGAR                      | `WebSearch`                       | Prior 6-K filings for format consistency        |

Drive search queries:

- FP&A Blueprint: `name contains 'FP&A Blueprint' and mimeType = 'application/vnd.google-apps.spreadsheet'`
- Prior press releases: `name contains 'Press Release' and mimeType = 'application/vnd.google-apps.document'`
- IR Drafts folder: `name = 'Press Releases' and mimeType = 'application/vnd.google-apps.folder'`

---

## Output Format

```
[DRAFT — RED CONFIDENCE — LEGAL REVIEW MANDATORY]
================================================
NVNI PRESS RELEASE DRAFT
Type: {earnings | material-event | acquisition | other}
Period: {YYYY-QN}
Draft Date: {date}
Data Sources: {list}
Open Items: {list any missing data requiring manual input}

---

[FULL PRESS RELEASE TEXT — see structure in Phase 4]

---

[GAAP TO NON-GAAP RECONCILIATION TABLE — see Phase 3]

---

REVIEW CHECKLIST:
  [ ] Financial figures verified against audited/reviewed financials
  [ ] Non-GAAP definitions consistent with prior releases
  [ ] Safe harbor language included
  [ ] 6-K filing note included
  [ ] Management quote reviewed and approved
  [ ] Legal counsel sign-off obtained
  [ ] CFO sign-off obtained
  [ ] IR director sign-off obtained
  [ ] Wire service filing date confirmed
  [ ] Form 6-K filing submitted to SEC same day as wire release

Document saved: {Google Doc URL}
```

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                         |
| ------ | --------- | ---------------------------------------------------------------- |
| Green  | > 95%     | Not applicable — press releases are never auto-approved          |
| Yellow | 80–95%    | Not applicable for external press releases                       |
| Red    | ALL       | Mandatory — every press release draft requires full legal review |

**ALL press release outputs are permanently RED confidence.** This is non-negotiable. Press releases are public disclosures under SEC jurisdiction. No draft may be distributed, transmitted to a wire service, or filed on Form 6-K without:

- CFO written sign-off on all financial figures.
- Legal counsel written sign-off on forward-looking statements and safe harbor language.
- IR director approval of overall messaging and tone.

---

## Integration

| Agent / Skill       | Role                                                            |
| ------------------- | --------------------------------------------------------------- |
| Julia               | FP&A Blueprint data: GAAP financials and EBITDA bridge          |
| Zuck                | NOR dashboard: per-subsidiary revenue for portfolio table       |
| Cris                | Acquisition details (public transactions only)                  |
| Marco               | Legal review: FLS, safe harbor, 6-K filing obligations          |
| Scheduler           | Earnings release date, SEC filing calendar, blackout periods    |
| ir-capital-register | Share count, diluted shares, debt for balance sheet             |
| ir-earnings-release | For earnings type, defer to ir-earnings-release for full tables |

---

## Examples

```
/ir press-release-draft earnings Q4-2025 --draft
→ Full earnings press release draft with all financial tables and reconciliation

/ir press-release-draft earnings Q4-2025 --reconciliation-table
→ GAAP-to-non-GAAP reconciliation table only, sourced from FP&A Blueprint

/ir press-release-draft material-event Q1-2026 --draft
→ Material event press release template with placeholders for event details

/ir press-release-draft acquisition --draft
→ Acquisition announcement draft with transaction overview template

/ir press-release-draft Q4-2025 --review
→ Compliance checklist against an existing draft
```
