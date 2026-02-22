---
name: ir-capital-register
description: "Live register of all outstanding capital instruments for NVNI including convertible notes, bridge loans, PIPE subscriptions, debentures, trust notes, and warrants. Computes days to maturity, conversion triggers, and generates executive capital structure summaries. Triggers on: capital register, convertible notes, capital instruments, warrants, PIPE, debentures, maturity alert, capital structure."
argument-hint: "[status|update|maturity-alert|summary]"
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
  - mcp__google-workspace__docs_getText
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
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
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

# ir-capital-register — Capital Instruments Live Register

**Agent:** Bella
**Entity:** NVNI Group Limited (NASDAQ: NVNI)
**Purpose:** Track all outstanding debt and equity-linked instruments, compute maturities and conversion triggers, alert on approaching deadlines, generate capital structure summaries for board and IR.

## Commands

| Command            | Description                                                               |
| ------------------ | ------------------------------------------------------------------------- |
| `status` (default) | Read Capital Register sheet, compute days to maturity for all instruments |
| `update`           | Pull latest data from source documents, update register                   |
| `maturity-alert`   | Highlight instruments maturing within 90 days, send email alert           |
| `summary`          | Generate executive capital structure summary for board/IR                 |

---

## Instrument Registry

### Convertible Notes

| Field              | Description                                 |
| ------------------ | ------------------------------------------- |
| Holder             | Note holder name                            |
| Principal          | Original face value (USD)                   |
| Outstanding        | Current outstanding balance                 |
| Interest Rate      | Annual rate (%)                             |
| Accrued Interest   | Computed from issuance date                 |
| Maturity Date      | Contractual maturity                        |
| Conversion Price   | Per-share conversion price (USD)            |
| Conversion Trigger | Automatic or optional conversion conditions |
| Governing Law      | Delaware / Cayman                           |
| Status             | Active / Matured / Converted / Cancelled    |

Known holders: **Ayrton**, **Pierre**

### Bridge Loans

| Field              | Description           |
| ------------------ | --------------------- |
| Lender             | Counterparty          |
| Principal          | Loan amount           |
| Interest Rate      | Annual / monthly rate |
| Disbursement Date  | Funding date          |
| Maturity Date      | Repayment due date    |
| Repayment Schedule | Lump sum / amortizing |
| Collateral         | If any                |
| Status             | Active / Repaid       |

### PIPE Subscriptions

| Field                    | Description                 |
| ------------------------ | --------------------------- |
| Subscriber               | Investor name               |
| Subscription Amount      | USD                         |
| Share Price              | Per share                   |
| Shares Issued / Reserved | Count                       |
| Lock-up Period           | If applicable               |
| Registration Rights      | S-1 / S-3 filing obligation |
| Status                   | Closed / Pending            |

Known subscribers: **Buck**, **Coppi**, **Dave**

### Debentures

| Field                 | Description                 |
| --------------------- | --------------------------- |
| Issuance              | Series / tranche identifier |
| Principal             | BRL or USD amount           |
| Interest Rate         | CDI+ or fixed rate          |
| Issuance Date         | Date                        |
| Maturity Date         | Date                        |
| Covenants             | Key financial covenants     |
| Trustee               | Name                        |
| CETIP/B3 Registration | Identifier                  |
| Status                | Active / Matured / Redeemed |

Source folder: `Treasury/03. Debenture/` on Google Drive.

### Bullfrog Bay Trust Note

| Field               | Description                    |
| ------------------- | ------------------------------ |
| Counterparty        | Bullfrog Bay Trust             |
| Principal           | USD amount                     |
| Outstanding Balance | Current balance after payments |
| Interest Rate       | Annual rate                    |
| Maturity            | Date or on-demand              |
| Payment History     | Dates and amounts              |
| Status              | Active / Satisfied             |

### Warrants (NVNIW)

| Field             | Description                    |
| ----------------- | ------------------------------ |
| Series            | NVNIW (NASDAQ listed)          |
| Strike Price      | Exercise price per share (USD) |
| Expiry Date       | Warrant expiration date        |
| Outstanding Count | Current warrants outstanding   |
| Exercised to Date | Count exercised                |
| Cashless Exercise | Available Y/N                  |
| Governing Terms   | Warrant agreement date         |

---

## Command: status

### Phase 1: Load Capital Register

1. Call `mcp__google-workspace__time_getCurrentDate` for TODAY.
2. Call `mcp__google-workspace__sheets_find` with query `"NVNI Capital Register"` or `"Capital Instruments"`.
3. Load each instrument tab: `Convertible_Notes`, `Bridge_Loans`, `PIPE`, `Debentures`, `Trust_Notes`, `Warrants` via `sheets_getRange`.

### Phase 2: Compute Metrics

For each active instrument:

```
days_to_maturity = Maturity_Date - TODAY
```

Classify maturity urgency:

| Days to Maturity | Flag              |
| ---------------- | ----------------- |
| > 365 days       | GREEN             |
| 181–365 days     | YELLOW            |
| 91–180 days      | ORANGE            |
| 31–90 days       | RED               |
| 1–30 days        | CRITICAL          |
| <= 0 days        | MATURED / OVERDUE |

For convertible notes, also compute:

- `current_stock_price` — search memory for latest NVNI price or prompt user
- `conversion_value = (outstanding_principal / conversion_price) * current_stock_price`
- `in_the_money = conversion_value > outstanding_principal` → flag as `ITM` or `OTM`

For debentures, compute:

- `accrued_interest = principal * (rate / 12) * months_outstanding`
- `total_outstanding = principal + accrued_interest`

### Phase 3: Output Status Table

```
NVNI CAPITAL REGISTER STATUS — {TODAY}
=======================================

CONVERTIBLE NOTES
  Holder    Principal   Rate   Maturity      Days   Conv Price  Status
  -------   ---------   ----   ----------    ----   ----------  ------
  Ayrton    $X,XXX,XXX  X%     YYYY-MM-DD    NNN    $X.XX       RED/OTM
  Pierre    $X,XXX,XXX  X%     YYYY-MM-DD    NNN    $X.XX       YELLOW/ITM

BRIDGE LOANS
  Lender    Principal   Rate   Maturity      Days   Status
  -------   ---------   ----   ----------    ----   ------
  ...

PIPE SUBSCRIPTIONS
  Subscriber  Amount      Shares   Lock-up     Status
  ----------  ----------  ------   ----------  ------
  Buck        $X,XXX,XXX  X,XXX    YYYY-MM-DD  Closed
  Coppi       $X,XXX,XXX  X,XXX    YYYY-MM-DD  Closed
  Dave        $X,XXX,XXX  X,XXX    YYYY-MM-DD  Closed

DEBENTURES
  Series   Principal    Rate    Maturity    Days   Status
  ------   ---------    ----    --------    ----   ------
  ...

WARRANTS (NVNIW)
  Strike   Expiry        Outstanding   Exercised   Status
  ------   ----------    -----------   ---------   ------
  $X.XX    YYYY-MM-DD    X,XXX,XXX     X,XXX       ORANGE

TOTAL DEBT OUTSTANDING: $XX,XXX,XXX
TOTAL DILUTED EQUITY (if all convert/exercise): XX,XXX,XXX shares
```

---

## Command: maturity-alert

Run status analysis, then for all instruments with `days_to_maturity <= 90`:

Send email alert to: `cfo@nuvini.com.br`, `legal@nuvini.com.br`, `ir@nuvini.com.br`

**Email template:**

```
Subject: [CAPITAL ALERT] Instrument Maturing in {N} Days — {Holder/Series}

Nuvini Capital Register Alert — {TODAY}

The following instrument is approaching maturity:

Instrument Type: {type}
Counterparty: {holder}
Principal Outstanding: {amount}
Maturity Date: {date}
Days Remaining: {N}
Interest Rate: {rate}

Conversion / Repayment Options:
  [List applicable options from instrument terms]

Recommended Actions:
  - Contact counterparty to discuss renewal, conversion, or repayment
  - Prepare necessary board resolutions
  - Review cash position for repayment capacity
  - Assess accounting treatment (reclassify to current liabilities if <12 months)

— Bella (Nuvini IR Agent)
```

Dedup: Do not re-send maturity alerts for the same instrument within 14 days.

---

## Command: update

Pull latest instrument data from source documents:

1. For debentures: Search Drive folder `Treasury/03. Debenture/` via `drive_search`-like text extraction. Use `mcp__google-workspace__docs_getText` if documents are Google Docs, or note PDF locations for manual review.
2. For convertible notes: Read from the instrument agreement summaries stored in the Capital Register sheet.
3. For warrants: Check EDGAR for any Form 4 filings reporting NVNIW warrant exercises.
4. Update outstanding balances based on any payments or conversions recorded since last update.
5. Log update timestamp in memory.

---

## Command: summary

Generate an executive capital structure summary suitable for board presentation or IR communications.

**Summary format:**

```
NVNI CAPITAL STRUCTURE SUMMARY — {TODAY}
=========================================

DEBT INSTRUMENTS
  Convertible Notes:   $XX.XM total outstanding
    - Weighted avg rate: X.X%
    - Nearest maturity: {date} ({N} days)
    - Instruments in-the-money: {count}

  Bridge Loans:        $XX.XM total outstanding
    - Nearest maturity: {date} ({N} days)

  Debentures:          R$XX.XM total outstanding (BRL)
    - Nearest maturity: {date} ({N} days)

  Bullfrog Bay Note:   $XX.XM outstanding

EQUITY-LINKED
  PIPE Subscriptions:  $XX.XM raised (closed)
    - Shares issued: XX.XM

  Warrants (NVNIW):    XX.XM outstanding
    - Strike: $X.XX | Expiry: {date}
    - In-the-money at current price: [YES/NO]

TOTAL DEBT:            $XX.XM USD equivalent
DILUTED SHARES (fully diluted): XXX.XM

KEY MATURITY EVENTS (next 12 months):
  {date}: {instrument} — ${amount}M
  {date}: {instrument} — ${amount}M
```

Email to: `cfo@nuvini.com.br` (if running as automated report)

---

## Data Sources

| Source                               | Tool                              | Purpose                         |
| ------------------------------------ | --------------------------------- | ------------------------------- |
| NVNI Capital Register Google Sheet   | `sheets_find` + `sheets_getRange` | Primary instrument register     |
| Treasury/03. Debenture/ Drive folder | `docs_getText`                    | Debenture terms                 |
| Memory                               | `memory__search_nodes`            | NVNI stock price, alert history |
| Today's date                         | `time_getCurrentDate`             | Maturity calculations           |

## Error Handling

- **Missing maturity date**: Flag as `DATE MISSING — MANUAL REVIEW`. Include in alert output.
- **Outstanding balance not updated**: Use original principal with note `balance may be stale`.
- **Conversion price below current stock price (ITM)**: Flag prominently in output. Include in any board summary.
- **Matured instrument not yet repaid**: Flag as `OVERDUE — CREDIT EVENT RISK`. Escalate immediately.
- **Sheet not found**: Output known instruments from Instrument Registry above with `DATA: MANUAL` tag.

## Confidence Scoring

| Tier   | Threshold | Behavior                          |
| ------ | --------- | --------------------------------- |
| Green  | > 95%     | Auto-proceed with display         |
| Yellow | 80–95%    | Human review before distribution  |
| Red    | < 80%     | Full manual verification required |

**All capital instrument data and financial outputs default to Yellow regardless of confidence.** CFO and legal must verify before any external communications reference specific instrument terms or balances.

Confidence is reduced when:

- Outstanding balance is inferred rather than confirmed from a payment record
- Maturity date is computed from stated tenor rather than read from a signed agreement
- Conversion price or exercise price is not confirmed against the governing document

## Examples

```
/ir capital-register
→ Full capital register status with maturity flags

/ir capital-register maturity-alert
→ Sends email alerts for instruments maturing within 90 days

/ir capital-register summary
→ Generates executive capital structure summary

/ir capital-register update
→ Refreshes data from source documents
```
