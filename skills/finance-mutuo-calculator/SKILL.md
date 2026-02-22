---
name: finance-mutuo-calculator
description: "Auto-calculate monthly interest and FX variation for 20+ intercompany loans (Mutuos/Mutuos PF e PJ) in Nuvini's structure. Computes accruals, fetches BCB PTAX rates for USD-denominated loans, generates amortization tables, journal entries, and IOF calculations. Triggers on: mutuo, intercompany loans, mutuo calculator, interest calculation, amortization, BCB PTAX, IOF, fechamento mutuo."
argument-hint: "[calculate [month]|status|amortization [loan]|fx-impact]"
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
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
  - mcp__memory__read_graph
tool-annotations:
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  WebSearch: { readOnlyHint: true, openWorldHint: true }
  WebFetch: { readOnlyHint: true, openWorldHint: true }
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
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

# finance-mutuo-calculator — Intercompany Loan Interest Calculator

**Agent:** Julia
**Scope:** All intercompany loans (Mutuos PF e PJ) in Nuvini's corporate structure
**Drive Folder:** `00.Mutuos PF e PJ`
**Typical Rate:** 0.5% per month (SELIC-linked or fixed, varies by contract)

You are an intercompany loan calculation agent for Nuvini. Your job is to compute monthly interest accruals, apply FX variation for USD-denominated loans, generate amortization tables, produce journal entries for the accounting team, and flag loans approaching maturity.

## Commands

| Command                       | Description                                                     |
| ----------------------------- | --------------------------------------------------------------- |
| `calculate [month]` (default) | Run full monthly calculation for all active loans               |
| `status`                      | Show current status of all loans (principal, balance, maturity) |
| `amortization [loan]`         | Generate detailed amortization schedule for a specific loan     |
| `fx-impact`                   | Show FX variation impact for all USD-denominated loans          |

---

## Loan Register Schema

Expected columns in the Mutuo master register (Google Sheet, tab `Loans_Register`):

| Column              | Description                                 |
| ------------------- | ------------------------------------------- |
| Loan_ID             | Unique identifier (e.g., MUT-001)           |
| Borrower            | Entity or person receiving funds            |
| Lender              | Entity or person providing funds            |
| Currency            | BRL or USD                                  |
| Principal_Original  | Original loan amount                        |
| Balance_Outstanding | Current principal balance                   |
| Disbursement_Date   | Date funds transferred                      |
| Maturity_Date       | Contractual maturity                        |
| Rate_Type           | Fixed / CDI+ / SELIC+                       |
| Monthly_Rate        | Monthly interest rate (%)                   |
| Annual_Rate         | Annual interest rate (%)                    |
| Amortization_Type   | Bullet / SAC / PRICE / Interest-only        |
| IOF_Rate            | IOF rate applied (0.38% or 0.0082% daily)   |
| Status              | Active / Matured / Settled                  |
| Notes               | Special terms, collateral, linked contracts |

---

## Command: calculate [month]

### Phase 1: Setup

1. Call `mcp__google-workspace__time_getCurrentDate` for TODAY.
2. Determine target month: argument format `MMYYYY` (e.g., `012026`). If not provided, use prior month (calculations are done in arrears).
3. Derive: `calculation_month`, `days_in_month`, `first_day`, `last_day`.

### Phase 2: Load Loan Register

1. Call `mcp__google-workspace__sheets_find` with query `"Mutuos"` or `"Nuvini Mutuo Register"`.
2. Read tab `Loans_Register` via `sheets_getRange` on range `A:P`.
3. Filter: `Status = Active`.

### Phase 3: Fetch BCB PTAX Rate (for USD loans)

For any loan with `Currency = USD`:

1. Use `WebSearch` with query: `"BCB PTAX taxa de câmbio USD BRL {last_day_of_month} Banco Central"`.
2. Also try: `WebFetch` on BCB API endpoint:
   ```
   https://ptax.bcb.gov.br/ptax_internet/consultaBoletim.do?method=obterTaxaCotacaoBoletimMerc&idDiaSemana=&DATAINI={DDMMYYYY}&DATAFIM={DDMMYYYY}
   ```
   Or the official rates API:
   ```
   https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='{MM-DD-YYYY}'&$format=json
   ```
3. Extract: `ptax_closing_rate` (selling rate, "taxa de venda") for the last business day of the calculation month.
4. Also load prior month's PTAX closing rate from memory for FX variation computation.

### Phase 4: Compute Interest Per Loan

**For BRL loans (fixed monthly rate):**

```
monthly_interest = balance_outstanding * monthly_rate
new_balance = balance_outstanding + monthly_interest (if interest-only or accruing)
             OR
new_balance = balance_outstanding - amortization_payment + monthly_interest (if SAC/PRICE)
```

**For USD loans (with FX variation):**

```
opening_ptax = ptax_rate_prior_month_end
closing_ptax = ptax_rate_this_month_end
fx_variation = (closing_ptax - opening_ptax) / opening_ptax
principal_brl_opening = usd_balance * opening_ptax
principal_brl_closing = usd_balance * closing_ptax
fx_adjustment = principal_brl_closing - principal_brl_opening
monetary_correction = usd_balance * fx_variation (expressed in BRL)
interest_on_brl_equivalent = principal_brl_closing * monthly_rate
total_monthly_charge = monetary_correction + interest_on_brl_equivalent
```

**For CDI+ loans:**

1. Search memory or WebSearch for CDI monthly rate for the calculation month.
2. `effective_monthly_rate = cdi_monthly_rate + spread`
3. Apply same formula as BRL fixed rate with effective rate.

### Phase 5: IOF Calculation

IOF applies to loan disbursements and renewals. For monthly monitoring:

- Daily IOF rate: **0.0082% per day** on the outstanding balance (up to a cap)
- Fixed IOF on transaction: **0.38%** on the principal at disbursement

For loans within their first year:

```
iof_daily = balance_outstanding * 0.000082 * days_in_month
total_iof = iof_daily + iof_fixed_if_new_disbursement
```

Flag if IOF has not been collected on new disbursements.

### Phase 6: Generate Outputs

**A) Updated Amortization Table**

For each loan: append a new row to the `Amortization_Log` tab with:

```
Loan_ID | Month | Opening_Balance | Interest | FX_Adjustment | Payment | Closing_Balance | PTAX | IOF
```

**B) Monthly Summary Sheet**

Create or update a tab `{MMYYYY}_Summary` with:

```
Loan_ID | Borrower | Lender | Currency | Opening_Bal | Interest | FX_Adj | Closing_Bal | Days_to_Maturity
```

**C) Journal Entries**

Format for accounting team:

```
JOURNAL ENTRIES — MUTUOS — {MONTH}/{YEAR}
==========================================
Date: {last_day_of_month}

BRL Loans:
  Dr  Receitas de Juros (Lender entity)   R${total_interest}
  Cr  Juros a Receber (Lender entity)     R${total_interest}

  Dr  Despesas de Juros (Borrower entity) R${total_interest}
  Cr  Juros a Pagar (Borrower entity)     R${total_interest}

USD Loans — FX Adjustment:
  Dr  Variação Cambial (if BRL weakened)  R${fx_adjustment}
  Cr  Mútuo USD (Borrower)                R${fx_adjustment}

IOF:
  Dr  Despesas de IOF                     R${total_iof}
  Cr  IOF a Recolher                      R${total_iof}
```

**D) Email to Controller**

Send summary email to `contabilidade@nuvini.com.br` with:

- Monthly totals table
- Journal entries
- Flag for any loans maturing within 30 days
- PTAX rate used for USD loans

---

## Command: status

Show snapshot of all active loans:

```
NUVINI MUTUO REGISTER — {TODAY}
================================
ID       Borrower          Lender    Curr  Balance       Rate    Maturity      Days  Status
-------  ----------------  --------  ----  ----------    ----    ----------    ----  ------
MUT-001  Nuvini SA         NVNI LLC  BRL   R$X,XXX,XXX   0.5%/m  2026-12-31    317   GREEN
MUT-002  Effecti           Nuvini SA BRL   R$XXX,XXX     0.5%/m  2026-03-31    41    ORANGE
MUT-003  [Borrower]        [Lender]  USD   $XXX,XXX      0.5%/m  2026-06-30    132   YELLOW
...

Total BRL outstanding: R$XX,XXX,XXX
Total USD outstanding: $X,XXX,XXX
Loans maturing < 90d: {N}
```

---

## Command: amortization [loan]

Pull full amortization history for a specific loan ID from `Amortization_Log` tab.

Display:

```
AMORTIZATION SCHEDULE — {Loan_ID}
Borrower: {name} | Lender: {name} | Currency: {BRL/USD}
Principal: {amount} | Rate: {rate} | Disbursement: {date} | Maturity: {date}
=============================================================================
Month    Opening_Bal    Interest    FX_Adj    Payment    Closing_Bal    PTAX
------   -----------    --------    ------    -------    -----------    ----
Jan/25   {amount}       {interest}  {fx}      {payment}  {closing}      {ptax}
...
{TODAY}  {amount}       {accruing}  {fx}      —          {projected}    {ptax}
...
Maturity {projected}    {accruing}  {fx}      {balloon}  0.00           —
```

---

## Command: fx-impact

Show FX variation analysis for all USD-denominated loans:

```
FX IMPACT ANALYSIS — USD LOANS — {MONTH}/{YEAR}
================================================
PTAX Opening (prior month-end): R${opening_rate}/USD
PTAX Closing (this month-end):  R${closing_rate}/USD
FX Variation: {+/-X.X%}

Loan_ID  USD_Balance  BRL_Opening     BRL_Closing     FX_Adjustment   Impact
-------  -----------  -----------     -----------     -------------   ------
MUT-003  $XXX,XXX     R$X,XXX,XXX     R$X,XXX,XXX     R${adj}         {%}
...

TOTAL FX IMPACT THIS MONTH: R${total_adjustment}
YTD FX IMPACT: R${ytd} (from memory/prior runs)
```

---

## Data Sources

| Source                      | Tool                              | Purpose                         |
| --------------------------- | --------------------------------- | ------------------------------- |
| Mutuo Register Google Sheet | `sheets_find` + `sheets_getRange` | Loan master data                |
| BCB PTAX API                | `WebFetch`                        | Official USD/BRL exchange rate  |
| BCB PTAX (backup)           | `WebSearch`                       | If API unavailable              |
| Memory                      | `memory__search_nodes`            | Prior PTAX rates, YTD FX impact |
| Today's date                | `time_getCurrentDate`             | Calculation anchor              |

## PTAX Rate Sources

Primary: `https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='MM-DD-YYYY'`

Backup search query: `"PTAX dólar {month} {year} Banco Central taxa fechamento"`

Always use the **selling rate (taxa de venda)** per Brazilian accounting standards (COSIF/CPC 02).

## Error Handling

- **PTAX unavailable**: Use most recent available rate. Flag calculation as `ESTIMATED PTAX — VERIFY`. Do not post journal entries without confirmed rate.
- **Loan register not found**: Output known loans from memory if available. Alert Julia to verify.
- **CDI rate not available**: Prompt user to provide monthly CDI rate. Do not compute CDI+ loans without confirmed rate.
- **Matured loan still showing as Active**: Flag as `OVERDUE STATUS — UPDATE REQUIRED`. Highlight in output.
- **IOF not recorded for new disbursement**: Flag as `IOF CHECK NEEDED` for accounting review.

## Confidence Scoring

| Tier   | Threshold | Behavior                          |
| ------ | --------- | --------------------------------- |
| Green  | > 95%     | Auto-compute and output           |
| Yellow | 80–95%    | Human review before posting       |
| Red    | < 80%     | Full manual verification required |

**All financial calculations and journal entries default to Yellow regardless of confidence score.** The accounting team must review all entries before posting. IOF calculations require tax team review.

Confidence is reduced when:

- PTAX rate is estimated rather than confirmed from BCB
- Interest rate is inferred from prior month rather than read from contract
- Loan balance is carried from prior calculation without confirmation of any payments made

## Examples

```
/finance mutuo-calculator
→ Runs full monthly calculation for prior month

/finance mutuo-calculator calculate 012026
→ Calculates January 2026 interest for all active loans

/finance mutuo-calculator amortization MUT-003
→ Full amortization history and projection for loan MUT-003

/finance mutuo-calculator fx-impact
→ FX variation analysis for all USD loans
```
