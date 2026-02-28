---
name: compliance-annual-report
description: |
  Generates a draft Annual Compliance Report per RCVM 21 requirements for Nuvini S.A. and affiliated
  Brazilian entities. Aggregates compliance calendar status, policy review dates, incident reports,
  training records, whistleblower channel status, and related-party transactions. Outputs a structured
  draft Google Doc formatted per CVM standards, ready for Compliance Officer review.
  CRITICAL: First-year report — no prior baseline exists. Human-in-the-loop mandatory. Deadline: April 30.
  Triggers on: annual compliance report, RCVM 21, relatório anual de compliance, CVM compliance report, annual report draft
argument-hint: "[fiscal-year YYYY] [--draft | --status | --checklist | --related-party-review]"
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
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_find
  - mcp__google-workspace__docs_replaceText
  - mcp__google-workspace__docs_appendText
  - mcp__google-workspace__docs_move
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__drive_downloadFile
  - mcp__google-workspace__drive_findFolder
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_getRange
  - mcp__google-workspace__sheets_find
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_search
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
memory: user
---

## Overview

Generates the annual compliance report required under RCVM 21 (CVM Resolution 21/2021) for Nuvini S.A. as a registered entity with the Brazilian Securities Commission. Aggregates data from the compliance calendar, policy tracker, incident log, training records, whistleblower channel, and related-party transaction register to produce a draft report following the CVM-mandated structure. This is a new requirement with no prior baseline — the first report establishes the compliance program baseline. Human-in-the-loop review by the Compliance Officer is mandatory before submission.

## Usage

```bash
# Check current draft status and data completeness for fiscal year 2025
/compliance-annual-report 2025 --status

# Generate full RCVM 21 compliance checklist for fiscal year 2025
/compliance-annual-report 2025 --checklist

# Run related-party transaction review section only
/compliance-annual-report 2025 --related-party-review

# Generate full draft Annual Compliance Report (Google Doc output)
/compliance-annual-report 2025 --draft

# Check how many days until the April 30 deadline
/compliance-annual-report 2025 --status
# (status output always includes days-to-deadline)
```

## Sub-commands

| Flag                     | Description                                                                      |
| ------------------------ | -------------------------------------------------------------------------------- |
| `--draft`                | Generate full RCVM 21 draft report as Google Doc                                 |
| `--status`               | Show data completeness, missing inputs, and days until April 30 deadline         |
| `--checklist`            | Output RCVM 21 compliance checklist with completion status per item              |
| `--related-party-review` | Generate related-party transactions section only, sourcing data from Marco/Julia |

## RCVM 21 Report Structure

The generated draft follows this mandatory structure:

1. **Identificação do Diretor Responsável** — Compliance Officer details, appointment date
2. **Estrutura Organizacional** — Compliance function org chart, independence statement, reporting lines
3. **Programa de Compliance** — Compliance program overview: policies in force, code of conduct, training program
4. **Atividades Realizadas no Período** — Activities during the fiscal year:
   - Policy reviews completed (dates, owners)
   - Training sessions conducted (dates, attendance rates, topics)
   - Audits and monitoring activities
   - Whistleblower channel: number of reports, categories, resolution status (anonymized)
5. **Incidentes e Remediação** — Compliance incidents, root cause analysis, remediation actions taken
6. **Operações com Partes Relacionadas** — Related-party transactions: counterparties, values, arm's-length assessment, board approvals
7. **Recomendações** — Compliance Officer recommendations for the following year
8. **Declaração de Conformidade** — Compliance Officer attestation and signature block

## Data Sources

All inputs are gathered automatically where possible; gaps trigger `--status` warnings:

| Input                        | Source                                                                     |
| ---------------------------- | -------------------------------------------------------------------------- |
| Compliance calendar status   | `compliance-calendar` skill / Google Sheets                                |
| Policy review dates          | Drive search `name contains 'Policy Register' AND name contains 'Nuvini'`  |
| Incident reports             | Drive search `name contains 'Compliance Incident'`                         |
| Training records             | Drive search `name contains 'Training Log' OR name contains 'Treinamento'` |
| Whistleblower channel status | Marco (Legal) input — manual entry required                                |
| Related-party transactions   | Marco (Legal) + Julia (Finance) — Mútuo register + financial statements    |
| Compliance Officer details   | Drive search for appointment resolution                                    |

## First-Year Baseline Notes

CRITICAL — this is a new requirement. The first report (FY 2025) must:

- Establish the compliance program inception date
- Document that policies were adopted (even if mid-year)
- Acknowledge that baseline metrics are being established for future comparison
- Not overstate program maturity — regulators expect candor in Year 1 reports
- Include a "Year 2 Roadmap" in the Recommendations section

## Deadline Management

- **Statutory deadline**: April 30 annually (RCVM 21, Art. 22)
- **Internal draft deadline**: March 31 (30-day buffer for Compliance Officer review)
- **Escalation**: If `--status` shows less than 30 days remaining and draft is not complete, send alert to Scheduler and Marco via Gmail

## Output Format

```
ANNUAL COMPLIANCE REPORT — DRAFT STATUS
========================================
Entity         : Nuvini S.A.
Fiscal Year    : 2025
Report Type    : RCVM 21 Annual Report
Deadline       : 2026-04-30 (70 days remaining)
Draft Status   : IN PROGRESS

DATA COMPLETENESS
-----------------
Section 1 — Diretor Responsável   : COMPLETE
Section 2 — Estrutura Org.        : COMPLETE
Section 3 — Programa de Compliance: PARTIAL (2 policies missing review dates)
Section 4 — Atividades            : PARTIAL (training attendance data missing for Q3)
Section 5 — Incidentes            : COMPLETE (0 incidents recorded)
Section 6 — Partes Relacionadas   : INCOMPLETE (awaiting Julia/Marco input)
Section 7 — Recomendações         : NOT STARTED
Section 8 — Declaração            : NOT STARTED

BLOCKING ITEMS
--------------
[1] Related-party transaction data not provided — request from Julia/Marco
[2] Q3 training attendance records not found in Drive

Draft Google Doc: [link] (created, sections 1-2-3 populated)
```

## Confidence Scoring

- **Yellow (mandatory)** — Regulatory filing. Human Compliance Officer must review every section before submission. No section auto-finalizes.
- **Green threshold not applicable** — RCVM 21 filings are never auto-submitted. Draft only.
- **Red** — If related-party transaction data is inconsistent with financial statements, or if an incident exists with no documented remediation, halt draft generation and escalate to Marco and Scheduler immediately.

## Integration

- **Scheduler (Compliance)**: Primary owner of this skill — tracks deadline, triggers annual run
- **Marco (Legal)**: Reviews related-party transactions section; provides whistleblower channel data
- **Julia (Finance)**: Provides Balancete data and related-party transaction values
- **compliance-annual-report** feeds from **compliance-minutes-drafter**: Board resolutions recorded in minutes are referenced in Sections 4 and 6
- **legal-contract-generator**: Mútuo document register feeds Section 6 (related-party transactions)
- **legal-compliance-calendar**: Section 4 activities sourced from compliance calendar completion records
