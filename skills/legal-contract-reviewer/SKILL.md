---
name: legal-contract-reviewer
description: |
  AI-assisted contract review for Nuvini OS. Analyzes inbound and outbound contracts against the
  Nuvini playbook — flagging deviations from standard terms, missing protective clauses, risk
  thresholds, and prohibited language. Produces a risk-scored review report with redline suggestions.
  Supported types: SaaS subscription, vendor/service agreements, employment contracts, lease agreements.
  LIMITATION: AI review only — all contracts require human legal approval before execution.
  Triggers on: review contract, contract review, analyze contract, revisar contrato, contract risk, redline
argument-hint: "[file-path or Drive ID] [type saas|vendor|employment|lease|other] [--risk-score | --redline | --full-review]"
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
---

## Overview

Reviews contracts submitted to or by Nuvini OS entities against the Nuvini standard playbook. Analyzes clause-by-clause for deviations, missing protections, prohibited language, and risk exposure. Produces a structured review report with an overall risk score (low/medium/high), flagged clauses, and redline suggestions ready for Marco's review. Covers SaaS subscription agreements, vendor/service agreements (bilingual), employment contracts, and lease agreements. All reviews are preliminary — human legal approval is mandatory before any contract is executed.

## Usage

```bash
# Full review of a SaaS agreement by Drive file ID
/legal-contract-reviewer 1AbCdEfGhIjKlMnOpQrStUvWx type saas --full-review

# Risk score only (quick pass)
/legal-contract-reviewer 1AbCdEfGhIjKlMnOpQrStUvWx type vendor --risk-score

# Generate redlines on an employment contract
/legal-contract-reviewer /path/to/contract.pdf type employment --redline

# Review a lease agreement and output to Google Doc
/legal-contract-reviewer 1AbCdEfGhIjKlMnOpQrStUvWx type lease --full-review

# Review against bilingual vendor template
/legal-contract-reviewer 1AbCdEfGhIjKlMnOpQrStUvWx type vendor --full-review
# (automatically references bilingual template ID 13oq5PHenm7QoFTKVPF4N6HCwjZCTwsmY)

# Review unknown contract type
/legal-contract-reviewer 1AbCdEfGhIjKlMnOpQrStUvWx type other --full-review
```

## Sub-commands

| Flag            | Description                                                                         |
| --------------- | ----------------------------------------------------------------------------------- |
| `--risk-score`  | Return overall risk score (low/medium/high) and top 3 issues only                   |
| `--redline`     | Generate tracked-changes redline suggestions document                               |
| `--full-review` | Full clause-by-clause analysis, risk score, redlines, comparison to Nuvini standard |

## Contract Types and Playbook Rules

### SaaS Subscription Agreements (inbound)

- Flag: auto-renewal clauses with insufficient notice periods (<60 days)
- Flag: data processing terms that do not meet LGPD/GDPR requirements
- Flag: liability caps below 12 months of fees paid
- Flag: missing SLA definitions or remedies
- Require: right to audit, data portability, termination for convenience

### Vendor / Service Agreements

- Reference template: Drive ID `13oq5PHenm7QoFTKVPF4N6HCwjZCTwsmY` (bilingual PT/EN)
- Flag: payment terms exceeding net-30 without board approval
- Flag: exclusivity clauses
- Flag: IP ownership not clearly assigned to Nuvini entity
- Flag: missing confidentiality obligations on vendor side
- Require: LGPD data processing addendum for vendors handling personal data

### Employment Contracts

- Flag: non-compete clauses exceeding 12 months (Brazilian law limits enforceability)
- Flag: missing IP assignment / invention assignment clause
- Flag: stock option / equity terms inconsistent with NVNI Group equity plan
- Require: confidentiality clause, LGPD consent for employee data processing
- Note: CLT compliance required for Brazilian entities (Nuvini S.A.)

### Lease Agreements

- Flag: term exceeding 3 years without board resolution
- Flag: personal guarantee requirements (escalate to Marco)
- Flag: missing force majeure / pandemic clauses
- Flag: insufficient notice for landlord entry
- Require: break clause or early termination option

## Prohibited Clauses (All Types)

- Waiver of right to seek injunctive relief
- Unlimited indemnification without cap
- Unilateral amendment rights by counterparty
- Governing law outside Nuvini approved jurisdictions (Brazil, Cayman, Delaware, BVI, England)
- Automatic assignment of contract without Nuvini consent

## Data Sources

- **Vendor template (bilingual)**: Drive ID `13oq5PHenm7QoFTKVPF4N6HCwjZCTwsmY`
- **Nuvini playbook**: Drive search `name contains 'Nuvini Legal Playbook'`
- **Standard SaaS terms**: Drive search `name contains 'Standard SaaS Agreement Nuvini'`
- **Prior review reports**: Drive search `name contains 'Contract Review'` folder
- **Input contract**: Provided as Drive ID or local file path

## Output Format

```
CONTRACT REVIEW REPORT
======================
Document       : [Contract name / Drive ID]
Type           : Vendor/Service Agreement
Reviewed by    : Marco (AI-assisted, legal-contract-reviewer)
Date           : 2026-02-19
Overall Risk   : MEDIUM

RISK SUMMARY
------------
Critical Issues : 1
High Issues     : 2
Medium Issues   : 3
Low Issues      : 4

CRITICAL ISSUES (must resolve before signing)
----------------------------------------------
[1] Unlimited indemnification — Clause 8.3 contains no liability cap.
    Suggested redline: "...in no event shall either party's aggregate
    liability exceed [12x monthly fees paid]..."

HIGH ISSUES
-----------
[2] Auto-renewal with 30-day notice — Clause 4.1 requires only 30 days
    notice. Nuvini standard requires 60 days.
[3] No LGPD data processing addendum referenced.

MEDIUM ISSUES
-------------
[4-6] ...

COMPARISON TO NUVINI STANDARD
------------------------------
Clause          | Contract      | Nuvini Standard | Delta
----------------|---------------|-----------------|-------
Liability cap   | Unlimited     | 12x fees        | FAIL
Auto-renewal    | 30-day notice | 60-day notice   | FAIL
IP assignment   | Present       | Present         | PASS
...

REDLINE DOCUMENT
----------------
Drive link: [link to generated redline doc]

DISCLAIMER
----------
This review is AI-generated and preliminary. All contracts must receive
human legal approval from Marco (Legal) before execution.
```

## Confidence Scoring

- **Yellow (default for all contract types)** — AI review is a first pass only. Marco must review all flagged items and sign off before any contract proceeds.
- **Green threshold not applicable** — Contract review never auto-approves. All outputs are advisory.
- **Red** — If contract cannot be parsed, is in an unsupported language, or contains clauses that match prohibited-clause patterns, halt and escalate to Marco immediately with raw text.

## Integration

- **Marco (Legal)**: Primary consumer — receives all review reports and makes final legal determination
- **legal-contract-generator**: Optionally invoked after review to regenerate cleaner version using Nuvini templates
- **compliance-annual-report**: Vendor agreement review summaries may feed into annual compliance report
- **Cris (M&A)**: Term sheets and acquisition-related contracts flagged to Cris when deal-related
- **Julia (Finance)**: Financial terms (payment, indemnification caps) cross-checked against approved budget thresholds
- **Scheduler (Compliance)**: Contract review completion dates tracked in compliance calendar
