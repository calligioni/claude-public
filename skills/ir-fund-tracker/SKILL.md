---
name: ir-fund-tracker
description: "Fund deal pipeline and LP fundraising tracker for NVNI Group Limited (NASDAQ: NVNI). Tracks the full fund lifecycle: LP commitments received, capital calls issued, capital deployed, distributions returned, and remaining dry powder. Monitors fund-level deal pipeline separately from corporate M&A. Generates LP reporting materials including capital account statements and quarterly performance letters. All outputs comply with SEC regulations for foreign private issuers. Triggers on: fund tracker, LP tracker, capital calls, fund performance, LP reporting, fund dashboard, committed capital."
argument-hint: "[fund-name or 'all'] [--dashboard | --capital-calls | --lp-statements | --performance | --pipeline]"
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
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_appendText
  - mcp__google-workspace__docs_replaceText
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__search_nodes
  - mcp__memory__open_nodes
  - mcp__memory__add_observations
  - mcp__memory__create_entities
  - mcp__memory__create_relations
tool-annotations:
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__docs_appendText: { idempotentHint: false }
  mcp__google-workspace__docs_replaceText: { idempotentHint: false }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__google-workspace__gmail_createDraft: { idempotentHint: false }
  mcp__memory__search_nodes: { readOnlyHint: true }
  mcp__memory__open_nodes: { readOnlyHint: true }
  mcp__memory__add_observations: { idempotentHint: false }
  mcp__memory__create_entities: { idempotentHint: false }
  mcp__memory__create_relations: { idempotentHint: false }
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

# ir-fund-tracker — Fund Lifecycle and LP Fundraising Tracker

**Agent:** Bella
**Entity:** NVNI Group Limited (NASDAQ: NVNI)
**Purpose:** Track the complete lifecycle of any NVNI-managed or NVNI-affiliated fund: LP commitments, capital calls, deployment into deals, distributions, and fund-level deal pipeline. Produce LP reporting materials (capital account statements, quarterly performance letters) that are suitable for distribution to limited partners after IR team review. All outputs comply with SEC regulations for foreign private issuers and applicable private fund reporting standards.

## Usage

```
/ir-fund-tracker all --dashboard
/ir-fund-tracker "Fund Name" --capital-calls
/ir-fund-tracker "Fund Name" --lp-statements
/ir-fund-tracker all --performance
/ir-fund-tracker "Fund Name" --pipeline
```

## Sub-commands

| Command           | Description                                                                                           |
| ----------------- | ----------------------------------------------------------------------------------------------------- |
| `--dashboard`     | Fund-level overview: committed vs. called vs. deployed vs. distributed, dry powder remaining          |
| `--capital-calls` | Upcoming and historical capital call schedule with amounts, dates, and LP allocation                  |
| `--lp-statements` | Generate capital account statements for each LP (contributions, distributions, NAV, MOIC, IRR)        |
| `--performance`   | Quarterly fund performance report with portfolio-level TVPI, DPI, RVPI, IRR, and benchmark comparison |
| `--pipeline`      | Fund-level deal pipeline: targets under review, LOI, DD, and signed at the fund vehicle level         |

---

## Process

### Phase 1: Load Fund Registry

Call `mcp__google-workspace__time_getCurrentDate` to anchor date calculations and determine the current reporting quarter.

Locate the Fund Registry sheet via `sheets_find` using query: `name contains 'Fund Registry' or name contains 'Fund Tracker'`. Fall back to `drive_search` with `name contains 'Fund' and mimeType = 'application/vnd.google-apps.spreadsheet'`.

The Fund Registry tracks the following per fund:

| Field               | Type    | Description                                        |
| ------------------- | ------- | -------------------------------------------------- |
| `fund_id`           | string  | Unique fund identifier (e.g., NVNI-F1)             |
| `fund_name`         | string  | Legal fund name                                    |
| `vehicle`           | enum    | Cayman LP, Delaware LLC, BVI Fund, FIDC, FIP       |
| `vintage_year`      | integer | Fund formation year                                |
| `target_size_usd`   | number  | Target fund size in USD                            |
| `committed_usd`     | number  | Total LP commitments received to date              |
| `called_usd`        | number  | Total capital called from LPs                      |
| `deployed_usd`      | number  | Capital invested in portfolio companies            |
| `distributed_usd`   | number  | Capital returned to LPs (proceeds + dividends)     |
| `nav_usd`           | number  | Net asset value (remaining portfolio fair value)   |
| `dry_powder_usd`    | number  | Committed but uncalled capital available to deploy |
| `investment_period` | date    | End date of investment period                      |
| `fund_term`         | date    | Legal maturity / wind-down date                    |
| `status`            | enum    | Fundraising, Active, Harvest, Closed               |

### Phase 2: Load LP Register

The LP Register (separate sheet tab) tracks each limited partner per fund:

| Field                | Type   | Description                                          |
| -------------------- | ------ | ---------------------------------------------------- |
| `lp_id`              | string | Unique LP identifier per fund (e.g., NVNI-F1-LP-001) |
| `lp_name`            | string | LP legal name                                        |
| `lp_entity`          | string | Firm / fund of funds name                            |
| `commitment_usd`     | number | Total LP commitment                                  |
| `called_to_date_usd` | number | Capital called from this LP to date                  |
| `distributions_usd`  | number | Distributions received by this LP                    |
| `nav_allocated_usd`  | number | LP's pro-rata share of current portfolio NAV         |
| `moic`               | number | Multiple on invested capital (called + NAV basis)    |
| `irr`                | number | Net IRR since inception (annualized)                 |
| `last_call_date`     | date   | Date of most recent capital call                     |
| `next_call_estimate` | date   | Estimated next capital call date                     |
| `status`             | enum   | Active, Fully Called, Defaulted, Transferred         |

### Phase 3: Mode Execution

#### `--dashboard`

1. Load Fund Registry and LP Register for all funds (or named fund).
2. Compute aggregate waterfall metrics:
   - Committed capital (target vs. actual by close date)
   - Called capital (% of committed)
   - Deployed capital (% of called)
   - Distributed capital (DPI)
   - Remaining NAV (RVPI)
   - Total Value (TVPI = DPI + RVPI)
   - Dry powder remaining
3. Flag funds approaching investment period end (<180 days).
4. Flag upcoming capital calls (<60 days).
5. Render fund dashboard (see Output Format).

#### `--capital-calls`

1. Load all capital call records from the Capital Calls sheet tab.
2. For each fund: show historical call schedule (date, amount, % of commitment, purpose).
3. Identify next estimated call: pull from `next_call_estimate` fields.
4. Generate upcoming capital call schedule for the next 12 months.
5. For user-direct mode: offer to draft capital call notices as Gmail drafts (`gmail_createDraft`) addressed to LP contact emails.

Capital call notice fields:

- Fund name, call number (e.g., Call #3)
- Call amount per LP (based on pro-rata commitment percentage)
- Due date (standard: 10 business days from notice)
- Purpose (acquisition, follow-on, fees, expenses)
- Wire instructions reference

#### `--lp-statements`

Generate a capital account statement for each LP in the named fund. Each statement contains:

1. LP identification header (LP name, entity, commitment amount, fund name, statement date)
2. Capital account activity table:

   | Date       | Transaction          | Amount      | Running Balance |
   | ---------- | -------------------- | ----------- | --------------- |
   | YYYY-MM-DD | Capital Contribution | +$X,XXX,XXX | $X,XXX,XXX      |
   | YYYY-MM-DD | Capital Contribution | +$X,XXX,XXX | $X,XXX,XXX      |
   | YYYY-MM-DD | Distribution         | -$X,XXX,XXX | $X,XXX,XXX      |
   | ...        | ...                  | ...         | ...             |

3. Performance summary: MOIC, net IRR since inception, DPI, RVPI, TVPI.
4. NAV allocation: LP's current pro-rata share of fund NAV.
5. Upcoming obligation: next estimated call amount and date.

Output: Create a Google Doc per LP via `docs_create` in `IR/Fund Statements/{Fund Name}/{Quarter}/` folder. Title format: `{LP Name} — Capital Account Statement — {Fund Name} — {Quarter}`.

All statements are YELLOW confidence and require IR team review before distribution.

#### `--performance`

Produce a quarterly fund performance report covering:

1. Fund-level performance metrics:
   - Gross IRR, Net IRR (after fees and carry)
   - TVPI, DPI, RVPI
   - PME (Public Market Equivalent) vs. NASDAQ Composite benchmark
   - Capital deployment pace vs. investment period remaining

2. Portfolio company performance within the fund:
   - Per investment: entry date, cost basis, current fair value, MOIC
   - Aggregate portfolio: total cost, total fair value, unrealized gain/loss

3. Benchmark comparison:
   - Use `WebSearch` to retrieve current NASDAQ Composite and S&P 500 levels.
   - Compute PME using modified PME or KS-PME methodology.

4. Write performance report to Google Doc: `docs_create` titled `{Fund Name} — Quarterly Performance Report — {Quarter}`.

#### `--pipeline`

Load the fund-level deal pipeline (distinct from the corporate M&A pipeline tracked by Arnold/mna-pipeline). This covers deals sourced and evaluated for the fund vehicle specifically.

Fields per fund pipeline entry:

- Company name, vertical, geography
- Stage: Sourced | First Meeting | IOI | LOI | Due Diligence | IC Approved | Signed | Passed
- Estimated investment size, ownership target
- Lead contact, last activity date
- Fund vehicle allocation (which fund will invest)

Display pipeline kanban-style summary grouped by stage.

### Phase 4: Data Validation

Before generating LP statements or performance reports:

1. Verify total called capital = sum of all LP contributions logged. Flag discrepancy if >$1 diff.
2. Verify distributions: confirm wire confirmations or bank records exist (search Drive for confirmation docs).
3. Verify NAV: confirm most recent independent valuation date is <90 days old. If stale, flag as RED.
4. Cross-check MOIC/IRR calculations against a second pass using raw transaction data.

---

## Data Sources

| Source                     | Tool                              | Data Retrieved                                     |
| -------------------------- | --------------------------------- | -------------------------------------------------- |
| Fund Registry Sheet        | `sheets_find` + `sheets_getRange` | Fund-level committed, called, deployed, NAV        |
| LP Register Sheet          | `sheets_find` + `sheets_getRange` | LP commitments, contributions, distributions, MOIC |
| Capital Call History Sheet | `sheets_getText`                  | Historical call schedule, amounts, dates           |
| Fund Pipeline Sheet        | `sheets_find` + `sheets_getRange` | Fund-level deal pipeline by stage                  |
| ir:capital-register        | `sheets_find` + `sheets_getRange` | Cross-reference with corporate capital instruments |
| Market Data                | `WebSearch`                       | NASDAQ / S&P 500 levels for PME benchmark          |
| Memory Graph               | `memory__search_nodes`            | Cached fund entities, LP entities, prior reports   |

Drive search for Fund Tracker: `name contains 'Fund Tracker' and mimeType = 'application/vnd.google-apps.spreadsheet'`
Drive search for statements: `name contains 'Capital Account Statement' and mimeType = 'application/vnd.google-apps.document'`

---

## Output Format

### Dashboard (`--dashboard`)

```
FUND DASHBOARD — NVNI — {date}
================================

FUND: {Fund Name} | Vintage: {YYYY} | Status: {Active/Harvest} | Vehicle: {Cayman LP}
  Target Size:      $XX.XM
  Committed:        $XX.XM  (XX% of target)
  Called:           $XX.XM  (XX% of committed)
  Deployed:         $XX.XM  (XX% of called)
  Distributed:      $XX.XM  DPI: X.Xx
  NAV (RVPI):       $XX.XM  RVPI: X.Xx
  TVPI:             X.Xx
  Dry Powder:       $XX.XM  (available to deploy)
  Investment Period End: {date}  [{N} days remaining — FLAG if <180]
  Next Capital Call: ~{date}  Estimated: $X.XM

LP COUNT: N LPs  |  Fully Called: N  |  Active: N  |  Defaults: N

UPCOMING CAPITAL CALLS (next 60 days):
  {Fund Name} Call #{N} — {date} — ${amount}

CONFIDENCE: YELLOW — Internal use only. Requires IR review before LP distribution.
```

### LP Capital Account Statement (`--lp-statements`)

```
CAPITAL ACCOUNT STATEMENT
{Fund Name} | {LP Legal Name}
As of: {Quarter end date}  |  Generated: {date}

COMMITMENT: ${X,XXX,XXX}  |  % of Fund: XX%

CAPITAL ACCOUNT ACTIVITY:
  Date        Transaction             Amount           Balance
  ----------  ----------------------  ---------------  ---------------
  YYYY-MM-DD  Capital Contribution    +$X,XXX,XXX      $X,XXX,XXX
  YYYY-MM-DD  Distribution            -$X,XXX,XXX      $X,XXX,XXX

CUMULATIVE SUMMARY:
  Total Contributions:   $X,XXX,XXX
  Total Distributions:   $X,XXX,XXX
  Current NAV (est.):    $X,XXX,XXX
  MOIC (Gross):          X.Xx
  Net IRR (since incep): XX.X%
  DPI:                   X.Xx
  RVPI:                  X.Xx
  TVPI:                  X.Xx

NEXT ESTIMATED CALL:    ~{date}  /  Est. Amount: $X,XXX,XXX

CONFIDENCE: YELLOW — Requires IR review and legal sign-off before delivery to LP.
```

### Performance Report (`--performance`)

```
QUARTERLY FUND PERFORMANCE REPORT
{Fund Name} | {Quarter} | Generated: {date}

FUND-LEVEL METRICS:
  Gross IRR:         XX.X%
  Net IRR:           XX.X%
  TVPI:              X.Xx  |  DPI: X.Xx  |  RVPI: X.Xx
  PME vs NASDAQ:     {Outperform/Underperform} by XX%

PORTFOLIO SUMMARY ({N} investments):
  Company          Entry     Cost Basis   Fair Value    MOIC    Status
  ---------------  --------  -----------  ------------  ------  --------
  {Company}        {date}    $X.XM        $X.XM         X.Xx    Active
  ...

DEPLOYMENT:
  Total Cost Basis:   $XX.XM  ({XX}% of called)
  Unrealized Gain:    +$XX.XM
  Investment Period:  {N} days remaining

CONFIDENCE: YELLOW — Requires independent valuation confirmation and IR review.
```

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                            |
| ------ | --------- | ------------------------------------------------------------------- |
| Green  | > 95%     | Auto-proceed (internal dashboard reads only)                        |
| Yellow | 80–95%    | Human review required before any LP distribution — ALL fund reports |
| Red    | < 80%     | Full manual verification required — block LP distribution           |

**All LP-facing outputs are YELLOW confidence minimum.** Downgrade to RED if:

- NAV figures are based on a valuation more than 90 days old.
- Called capital totals do not reconcile with LP contribution log.
- IRR calculation cannot be independently verified against raw transaction data.
- Fund performance report includes forward-looking projections without legal review.
- Any output is intended for SEC filing or public release (escalate to Marco).

---

## Integration

| Agent / Skill       | Role                                                                |
| ------------------- | ------------------------------------------------------------------- |
| ir:capital-register | Cross-reference corporate capital instruments vs. fund instruments  |
| ir-investor-tracker | LP contact details, communication log, engagement scores            |
| ir-deck-updater     | Pull fund-level highlights for investor presentation                |
| Julia               | Fund-level financial statements, audited NAV, fee calculations      |
| Marco               | Legal review of LP agreements, capital call notices, SEC compliance |
| Cris                | Fund-level M&A pipeline distinct from corporate pipeline            |
| Scheduler           | Trigger quarterly LP reporting cycle and capital call reminders     |

---

## Examples

```
/ir-fund-tracker all --dashboard
→ Overview of all active funds: commitment waterfall, dry powder, upcoming calls

/ir-fund-tracker "NVNI Growth Fund I" --capital-calls
→ Historical and upcoming capital call schedule with draft LP notices

/ir-fund-tracker "NVNI Growth Fund I" --lp-statements
→ Generate capital account statement docs for all LPs in fund (YELLOW confidence)

/ir-fund-tracker all --performance
→ Quarterly performance report: IRR, TVPI, DPI, RVPI, PME vs benchmark

/ir-fund-tracker "NVNI Growth Fund I" --pipeline
→ Fund-level deal pipeline grouped by stage (Sourced → Signed)
```
