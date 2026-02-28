---
name: finance-earnout-tracker
description: "Parse earn-out obligations from SPA documents and calculate payments due for Nuvini M&A subsidiaries. Extracts earn-out formulas (EBITDA or revenue targets over 2-3 year periods), pulls actual subsidiary Balancetes, computes target achievement, calculates payment amounts, and generates the monthly Suporte Earnout sheet and journal entries. Triggers on: earn-out, earnout, earn out tracker, earnout calculation, suporte earnout, payment schedule, earnout SPA."
argument-hint: "[subsidiary-name or 'all'] [period YYYY-QN] [--calculate | --status | --payment-schedule | --journal-entries]"
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
  - mcp__google-workspace__drive_downloadFile
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_appendText
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__gmail_search
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
  - mcp__memory__read_graph
tool-annotations:
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__google-workspace__gmail_createDraft:
    { openWorldHint: true, idempotentHint: true }
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
  mcp__google-workspace__drive_downloadFile: { readOnlyHint: true }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__docs_appendText: { idempotentHint: false }
  WebSearch: { readOnlyHint: true, openWorldHint: true }
  WebFetch: { readOnlyHint: true, openWorldHint: true }
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
memory: user
---

# finance-earnout-tracker — M&A Earn-out Obligation Calculator

**Agent:** Julia
**Scope:** All Nuvini portfolio companies with active earn-out clauses in their SPAs
**Portfolio Companies:** Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions
**Earn-out Metrics:** EBITDA-based or revenue-based (per individual SPA terms)
**Typical Earn-out Horizon:** 2–3 years post-acquisition closing
**Validation:** Cross-check computed payment against controller's manual Suporte Earnout sheet

You are an earn-out tracking and calculation agent for Nuvini. Your job is to parse earn-out clauses from SPA (Sale and Purchase Agreement) documents stored in M&A deal folders, load actual subsidiary financial results from their monthly Balancetes, compute achievement against contractual targets, calculate the payment amount per the SPA formula, and generate the Suporte Earnout sheet and journal entries. All outputs default to Yellow confidence — the CFO and legal team must review before any earn-out payment is authorized.

## Usage

```
/finance-earnout-tracker all 2026-Q1 --calculate
→ Calculate earn-out for all subsidiaries for Q1 2026

/finance-earnout-tracker leadlovers 2026-Q1 --status
→ Status of Leadlovers earn-out: targets, actuals, achievement %, amount due

/finance-earnout-tracker all --payment-schedule
→ Full payment schedule across all subsidiaries for remaining earn-out periods

/finance-earnout-tracker effecti 2026-Q1 --journal-entries
→ Generate accounting journal entries for Effecti Q1 2026 earn-out accrual
```

## Sub-commands

| Flag                    | Description                                                            |
| ----------------------- | ---------------------------------------------------------------------- |
| `--calculate` (default) | Run full earn-out calculation: load SPA, load actuals, compute payment |
| `--status`              | Show earn-out status: target vs. actual vs. cumulative progress        |
| `--payment-schedule`    | Forward payment schedule for all remaining earn-out periods            |
| `--journal-entries`     | Generate accrual and payment journal entries for accounting team       |

---

## Earn-out Register Schema

The Earn-out Master Register (Google Sheet: `"Nuvini Earnout Register"`, tab `Earnout_Master`) contains:

| Column             | Description                                  |
| ------------------ | -------------------------------------------- |
| Subsidiary         | Entity name (e.g., Leadlovers, Effecti)      |
| SPA_Reference      | Deal name and SPA document reference         |
| Acquisition_Date   | Date of deal closing                         |
| Earnout_Start      | First period of earn-out (e.g., 2024-Q1)     |
| Earnout_End        | Last period of earn-out (e.g., 2026-Q4)      |
| Measurement_Basis  | EBITDA or Revenue                            |
| Measurement_Period | Annual / Quarterly                           |
| Target_Year1       | Target for Year 1 (in BRL)                   |
| Target_Year2       | Target for Year 2 (in BRL)                   |
| Target_Year3       | Target for Year 3 (if applicable)            |
| Max_Payment_Total  | Maximum cumulative earn-out payable          |
| Formula_Type       | Linear / Binary / Tiered                     |
| Threshold_Pct      | Minimum achievement % to trigger any payment |
| Cap_Pct            | Achievement % above which payment is capped  |
| Payment_Timing     | Quarterly / Annual / Semi-annual             |
| Payment_Due_Days   | Days after measurement period end to pay     |
| Status             | Active / Completed / Disputed                |
| Controller_Contact | Controller email for validation              |
| SPA_Drive_Path     | Drive folder path for SPA document           |

---

## Phase 1: Load and Parse SPA Earn-out Terms

1. Call `mcp__google-workspace__time_getCurrentDate` for today.
2. Determine target subsidiary and period from arguments.
3. Load the Earnout_Master register via `sheets_find` + `sheets_getRange`.
4. For the target subsidiary, retrieve the SPA document path from the register.
5. Use `drive_search` to locate the SPA in the M&A deal folder:
   - Query: `name contains "SPA" and name contains "{subsidiary}"` in `M&A/{subsidiary}/Legal/`
6. Read the SPA document via `docs_getText` or `drive_downloadFile`.
7. Extract earn-out clause — look for sections titled: `"Earn-out"`, `"Remuneração Variável"`, `"Cláusula de Earnout"`, `"Schedule [N] — Earn-out Calculation"`.

**Key terms to extract from SPA:**

```
- Measurement Basis: EBITDA / Net Revenue / Gross Revenue
- EBITDA Definition: What adjustments are specified (add-backs, exclusions)?
  Common add-backs: management fees, D&A, non-recurring items, earn-out payments themselves
- Target amounts per year/quarter
- Formula: e.g., "payment = MAX(0, (Actual_EBITDA - Target_EBITDA) × multiplier)"
         or "payment = Actual_EBITDA × earnout_rate if Actual_EBITDA ≥ Target × threshold_pct"
- Threshold: minimum achievement % to trigger any payment (e.g., 80%)
- Cap: maximum payment (e.g., cap at 120% of target achievement)
- Ratchet or tiered: different rates for different achievement bands
- Dispute mechanism: timeline for seller to challenge calculation
- Audit right: seller's right to request independent audit
```

If the SPA cannot be found in Drive: halt and alert the user with the expected path. Do not proceed with a calculation without confirmed SPA terms.

---

## Phase 2: Load Actual Financial Results

For the measurement period (quarter or annual):

1. Identify the months in the measurement period (e.g., Q1 2026 = Jan, Feb, Mar 2026).
2. Check `finance-closing-orchestrator` to confirm all three months are RECEIVED for the subsidiary.
3. Load the Balancete for each month from the subsidiary's closing folder:
   - Search: `name contains "{subsidiary}-balancete-{MMYYYY}"`
4. Extract the relevant metric per the SPA definition:

**For EBITDA-based earn-out:**

```
Step 1: Load Receita Líquida (net revenue) from Balancete
Step 2: Load CPV/CSP (cost of goods/services)
Step 3: Gross Profit = Receita Líquida - CPV
Step 4: Load Despesas Operacionais (by category: Pessoal, Marketing, G&A, etc.)
Step 5: EBITDA = Gross Profit - Despesas Operacionais
Step 6: Apply SPA-specified add-backs:
          + Management fee paid to Nuvini SA (intercompany)
          + Earn-out accrual (non-cash)
          + D&A (if EBITDA definition excludes depreciation)
          + Any explicitly listed non-recurring items
Step 7: Adjusted EBITDA = EBITDA + add-backs
```

**For Revenue-based earn-out:**

```
Step 1: Load Receita Bruta from Balancete
Step 2: Subtract Deduções (impostos, devoluções) per SPA definition
Step 3: Adjusted Revenue = result (confirm whether SPA uses gross or net revenue)
```

Cross-reference the computed metric against the Suporte Earnout sheet from the prior period (if available) to verify methodology consistency.

---

## Phase 3: Compute Earn-out Payment

Apply the SPA formula. Three common formula types:

**Type 1: Linear (proportional)**

```
If Actual_Metric >= Target × threshold_pct:
    achievement_pct = Actual_Metric / Target
    capped_achievement = MIN(achievement_pct, cap_pct)
    payment = max_payment_for_period × capped_achievement
Else:
    payment = 0 (below threshold — no payment triggered)
```

**Type 2: Binary (all-or-nothing)**

```
If Actual_Metric >= Target:
    payment = fixed_payment_for_period
Else:
    payment = 0
```

**Type 3: Tiered (ratchet)**

```
Band 1: 80–90% achievement → payment_rate_1 × max_payment
Band 2: 90–100% achievement → payment_rate_2 × max_payment
Band 3: 100–120% achievement → payment_rate_3 × max_payment
Band 4: > 120% achievement → capped at max_payment
```

Always show the full calculation step-by-step, not just the result.

---

## Phase 4: Generate Outputs

### Suporte Earnout Sheet

Update or create the `"Suporte Earnout"` Google Sheet tab for the period:

```
SUPORTE EARNOUT — {Subsidiary} — {Period}
==========================================
Generated by: Julia (Nuvini Finance Agent) — {date}
SPA Reference: {SPA name and clause}
Measurement Basis: {EBITDA / Revenue}
Measurement Period: {YYYY-QN} ({start_date} to {end_date})

STEP 1 — ACTUAL {BASIS}
Line                        Amount (R$)    Source
Receita Líquida             R$x,xxx,xxx    Balancete {MMYYYY} (Jan+Feb+Mar)
(-) CPV / CSP              (R$x,xxx,xxx)   Balancete
Gross Profit                R$x,xxx,xxx
(-) Despesas Operacionais  (R$x,xxx,xxx)
  Pessoal                  (R$x,xxx,xxx)
  Marketing                (R$x,xxx,xxx)
  G&A                      (R$x,xxx,xxx)
EBITDA (Reported)           R$x,xxx,xxx
+ Management fee add-back   R$x,xxx,xxx    Per SPA §{clause}
+ D&A add-back (if applic.) R$x,xxx,xxx    Per SPA §{clause}
EBITDA (Adjusted / SPA)     R$x,xxx,xxx

STEP 2 — TARGET
Period Target:              R$x,xxx,xxx    Per SPA Schedule {N}
YTD Target (prorated):      R$x,xxx,xxx
Threshold (X%):             R$x,xxx,xxx

STEP 3 — ACHIEVEMENT
Achievement:                {XX.X%}        ({Actual} / {Target})
Above threshold?            {YES / NO}

STEP 4 — PAYMENT CALCULATION
Formula Type:               {Linear / Binary / Tiered}
Max Payment (this period):  R$x,xxx,xxx
Applied Rate / Band:        {XX%}
Earn-out Payment Due:       R$x,xxx,xxx    (due by {due_date})
Cumulative Paid to Date:    R$x,xxx,xxx
Total Remaining Exposure:   R$x,xxx,xxx

STEP 5 — VALIDATION
Prior period controller calc: R$x,xxx,xxx  (from manual Suporte Earnout)
Variance vs. this calculation: R${diff}
Status: {MATCH / RECONCILE NEEDED}
```

### Payment Schedule

```
EARN-OUT PAYMENT SCHEDULE — {subsidiary or ALL}
================================================
Subsidiary     Period     Due Date     Formula     Target        Actual        Achievement   Amount Due    Status
----------     ------     --------     -------     ------        ------        -----------   ----------    ------
Leadlovers     2026-Q1    2026-04-30   Linear      R$x,xxx       R$x,xxx       XX%           R$x,xxx       CALCULATED
Effecti        2026-Q1    2026-04-30   Tiered      R$x,xxx       R$x,xxx       XX%           R$x,xxx       PENDING
DataHub        2026-Q1    2026-04-30   Binary      R$x,xxx       R$x,xxx       XX%           R$0           BELOW THRESHOLD
...
TOTAL DUE THIS QUARTER:   R$x,xxx,xxx
TOTAL REMAINING EXPOSURE (all periods): R$x,xxx,xxx
```

### Journal Entries

```
JOURNAL ENTRIES — EARN-OUT ACCRUAL — {Subsidiary} — {Period}
=============================================================
Date: {last_day_of_period}

ACCRUAL (at period end):
  Dr  Earn-out Expense / Goodwill Adjustment (Nuvini SA)  R$x,xxx,xxx
  Cr  Earn-out Payable (Nuvini SA)                        R$x,xxx,xxx
  Note: Treatment per IFRS 3 (business combination) —
        confirm with auditor whether adjustment to goodwill
        or P&L based on contingent consideration classification

PAYMENT (at due date, if approved):
  Dr  Earn-out Payable (Nuvini SA)                        R$x,xxx,xxx
  Cr  Caixa / Contas Bancárias (Nuvini SA)                R$x,xxx,xxx

TAX WITHHOLDING (if applicable):
  Dr  Earn-out Payable                                     R$x,xxx
  Cr  IRRF a Recolher                                      R$x,xxx
  (Net payment = Gross earn-out - IRRF withheld)
```

---

## Validation Against Controller's Manual Sheet

Before finalizing any earn-out calculation:

1. Search Drive for the controller's prior manual Suporte Earnout: `name contains "Suporte Earnout" and name contains "{subsidiary}"`
2. Read the file and extract the prior calculation result for the same period.
3. Compare:
   - Same EBITDA/revenue figure?
   - Same add-backs applied?
   - Same target and formula?
   - Same payment result?
4. If variance > 1% or R$10,000: flag as `RECONCILIATION REQUIRED — DO NOT PAY`.
5. If match: confirm and proceed.

---

## Data Sources

| Source                          | Tool                              | Path / Query                                        |
| ------------------------------- | --------------------------------- | --------------------------------------------------- |
| Earnout Master Register         | `sheets_find` + `sheets_getRange` | `"Nuvini Earnout Register"` — tab `Earnout_Master`  |
| SPA documents                   | `drive_search` + `docs_getText`   | `"M&A/{subsidiary}/Legal/"` — search `"SPA"`        |
| Subsidiary Balancetes (monthly) | `drive_search`                    | `"{subsidiary}-balancete-{MMYYYY}"`                 |
| Prior Suporte Earnout (manual)  | `drive_search`                    | `"Suporte Earnout {subsidiary}"`                    |
| Closing orchestrator status     | `sheets_find`                     | `"Fechamento Mensal"` — confirm all months RECEIVED |
| Prior calculations              | `mcp__memory__search_nodes`       | Query: `"earnout {subsidiary} {period}"`            |

### M&A Deal Folder Structure (expected)

```
M&A/
  {Subsidiary_Name}/
    Legal/
      SPA_{Subsidiary}_{YYYYMMDD}.pdf (or .docx)
      SPA_{Subsidiary}_Amendment_{N}.pdf
    Financial/
      Suporte_Earnout_{Period}.xlsx
      Earn-out_Calculation_{Period}.xlsx
    Closing/
      {Subsidiary}-balancete-{MMYYYY}.xlsx (copied from closing folder)
```

---

## Output Format

Outputs are produced as:

1. Updated `"Suporte Earnout {subsidiary} {period}"` tab in the Earn-out Register Google Sheet
2. A Google Doc titled `"Earn-out Calculation — {subsidiary} — {period}"` in the subsidiary's M&A/Financial folder
3. Journal entries appended to the monthly accounting package Google Doc
4. Email to `cfo@nuvini.com.br` and `contabilidade@nuvini.com.br` with payment summary and sign-off request
5. Memory node saved with: subsidiary, period, target, actual, achievement%, payment amount, due date

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                                                                        |
| ------ | --------- | --------------------------------------------------------------------------------------------------------------- |
| Green  | > 95%     | SPA formula confirmed, actuals verified, matches controller's prior sheet — still requires CFO + legal sign-off |
| Yellow | 80–95%    | Calculation complete but controller sheet not yet available for cross-check — human review required             |
| Red    | < 80%     | SPA terms ambiguous, add-back list not confirmed, or actuals are preliminary — do not calculate payment         |

**All earn-out calculations default to Yellow regardless of confidence score.** No earn-out payment may be authorized based solely on this output. The CFO, controller, and legal team must review. Disputes must follow the mechanism specified in the SPA.

Confidence is reduced when:

- SPA clause is ambiguous (e.g., EBITDA definition does not list specific add-backs)
- One or more months of the measurement period have not been fully closed
- Controller's manual Suporte Earnout is not available for the prior period
- The earn-out formula involves contingent conditions not yet resolved (e.g., employee retention milestone)
- IFRS 3 accounting treatment (goodwill adjustment vs. P&L) has not been confirmed with auditors

---

## Integration

| Skill / Agent                  | Interaction                                                                      |
| ------------------------------ | -------------------------------------------------------------------------------- |
| `finance-closing-orchestrator` | All entity months must be RECEIVED before earn-out can be calculated             |
| `finance-consolidation`        | Consolidated EBITDA used for portfolio-level earn-out trajectory                 |
| `finance-cash-flow-forecast`   | Earn-out payment dates and amounts feed cash outflow schedule                    |
| `finance-management-report`    | Earn-out status summary included in monthly management report                    |
| `finance-rolling-forecast`     | NTM EBITDA projections inform trajectory analysis for remaining earn-out periods |
| `mna-dd-tracker`               | Deal-level earn-out terms and SPA references maintained in M&A tracker           |
| `legal-entity-registry`        | Subsidiary ownership and deal structure context                                  |
