---
name: legal-contract-generator
description: |
  Template-based generation of standard legal documents for Nuvini OS entities. Supports Mútuo
  (intercompany loan), First Addendum to Mútuo, NDA (Nuvini standard format), and Term Sheet.
  Computes IOF where applicable, generates sequential document numbers, and prepares documents
  for Clicksign e-signature workflow. Auto-files to correct Drive folder and logs in document register.
  Triggers on: generate contract, contrato, mútuo template, generate NDA, contract generator, legal template, gerar documento
argument-hint: "[type mutuo|addendum|nda|termsheet] [--parties '...'] [--amount N] [--preview | --generate | --list-templates]"
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

Generates standard legal documents from Nuvini-approved templates stored in Google Drive. Covers the four most common document types across NVNI Group entities: intercompany Mútuo agreements, addenda to existing Mútuo contracts, NDAs, and Term Sheets. All generated documents are sequentially numbered, auto-filed in the correct Drive folder, and queued for Clicksign e-signature. Human legal approval is required before execution of any generated contract.

## Usage

```bash
# List all available templates
/legal-contract-generator --list-templates

# Preview a Mútuo (intercompany loan) without generating
/legal-contract-generator mutuo --parties "Nuvini S.A. (lender), Effecti Tecnologia Ltda (borrower)" --amount 500000 --preview

# Generate a Mútuo
/legal-contract-generator mutuo \
  --parties "Nuvini S.A. (lender), Leadlovers Tecnologia Ltda (borrower)" \
  --amount 1200000 \
  --rate 1.5 \
  --term "12 months" \
  --currency BRL \
  --iof true \
  --generate

# Generate an NDA
/legal-contract-generator nda \
  --parties "NVNI Group Ltd, Potential Acquiree Inc" \
  --jurisdiction "Cayman Islands" \
  --period "24 months" \
  --generate

# Generate a Term Sheet using deal parameters
/legal-contract-generator termsheet \
  --parties "Nuvini Holdings Ltd, Target Co" \
  --amount 8000000 \
  --generate

# Generate First Addendum to an existing Mútuo
/legal-contract-generator addendum \
  --original-doc "DOC-MUTUO-2024-0012" \
  --parties "Nuvini S.A., Mercos Software Ltda" \
  --generate
```

## Sub-commands

| Flag                       | Description                                                              |
| -------------------------- | ------------------------------------------------------------------------ |
| `--list-templates`         | Display all supported templates with Drive IDs and required fields       |
| `--preview`                | Populate template and display filled content without saving              |
| `--generate`               | Populate template, save DOCX + PDF, log in register, queue for Clicksign |
| `--parties '...'`          | Comma-separated party names with roles (lender/borrower, etc.)           |
| `--amount N`               | Principal or deal amount (numeric, no currency symbol)                   |
| `--rate N`                 | Annual interest rate as percentage (Mútuo only)                          |
| `--term 'X months'`        | Loan or agreement term (Mútuo only)                                      |
| `--currency BRL\|USD\|USD` | Transaction currency (default: BRL)                                      |
| `--iof true\|false`        | Whether IOF tax applies (Mútuo only — auto-computes if true)             |
| `--jurisdiction '...'`     | Governing law jurisdiction (NDA, Term Sheet)                             |
| `--period 'X months'`      | Confidentiality period (NDA only)                                        |
| `--original-doc ID`        | Reference to original Mútuo document number (Addendum only)              |

## Templates

| Template                  | Drive Template ID                      | Required Fields                                                               |
| ------------------------- | -------------------------------------- | ----------------------------------------------------------------------------- |
| Mútuo (intercompany loan) | `1SUyRGBZbE2vVUQwmT5ueJUVXeau--ei8`    | lender, borrower, principal, interest rate, term, currency, IOF applicability |
| First Addendum to Mútuo   | `1waOvQojb7S8rDPYc3Bsph6CmvwqteJKV`    | original doc ID, parties, amendment terms, effective date                     |
| NDA                       | Nuvini standard (Drive search by name) | parties, jurisdiction, confidentiality period, effective date                 |
| Term Sheet                | Historical examples (Drive search)     | deal parameters from Cris, target company, valuation, structure               |

## IOF Computation

When `--iof true` is set for Mútuo documents:

- IOF rate: 0.0041% per day for loans up to 365 days (IOF diário)
- Additional 0.38% fixed IOF (IOF adicional)
- Compute total IOF on principal and include in document body
- Log IOF amount in document register for tax reporting

## Document Numbering

Sequential format: `DOC-{TYPE}-{YEAR}-{NNNN}`

Examples: `DOC-MUTUO-2026-0023`, `DOC-NDA-2026-0007`, `DOC-TS-2026-0004`

The document register is maintained in Google Sheets (search Drive for "Nuvini Document Register").

## Data Sources

- **Mútuo template**: Drive ID `1SUyRGBZbE2vVUQwmT5ueJUVXeau--ei8`
- **Addendum template**: Drive ID `1waOvQojb7S8rDPYc3Bsph6CmvwqteJKV`
- **NDA templates**: Drive search `name contains 'NDA' and name contains 'Nuvini standard'`
- **Term Sheet examples**: Drive search `name contains 'Term Sheet' and name contains 'Nuvini'`
- **Document register**: Drive search `name contains 'Nuvini Document Register'`
- **Output folder**: Drive search `name contains 'Contracts Executed'` or `name contains 'Contratos'`

## Output Format

```
CONTRACT GENERATION SUMMARY
============================
Document Type : Mútuo
Document No.  : DOC-MUTUO-2026-0023
Lender        : Nuvini S.A.
Borrower      : Effecti Tecnologia Ltda
Principal     : BRL 500,000.00
Interest Rate : 1.5% p.a.
Term          : 12 months
IOF           : BRL 2,169.50 (computed)
Generated     : 2026-02-19
Drive Link    : [Google Doc link]
Status        : DRAFT — Pending legal review
Clicksign     : Queued (not yet sent)

NEXT STEPS
----------
1. Marco reviews generated document
2. Legal approval obtained
3. Clicksign envelope triggered
4. Signed copy auto-filed in executed contracts folder
```

## Confidence Scoring

- **Yellow (default)** — All generated contracts require human legal review before execution. Marco (Legal) must approve every document regardless of template fidelity.
- **Green threshold not applicable** — Legal documents never auto-execute. The skill generates drafts only.
- **Red** — If template fields cannot be mapped or IOF computation fails, halt and alert Marco immediately.

## Integration

- **Marco (Legal)**: Primary owner — reviews and approves all generated contracts
- **Cris (M&A)**: Supplies deal parameters for Term Sheets
- **Julia (Finance)**: Supplies intercompany loan details and IOF reporting data
- **Scheduler (Compliance)**: `compliance-annual-report` ingests document register for related-party transaction review
- **legal-contract-reviewer**: Optionally run reviewer on generated doc before sending to Clicksign
- **compliance-minutes-drafter**: Board resolutions authorizing contracts reference document numbers from this skill
