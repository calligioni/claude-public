---
name: legal-20f-assistant
description: |
  SEC annual report (Form 20-F) drafting support for NVNI Group Limited as a foreign private issuer.
  Parses the prior year 20-F filing into sections and flags content requiring updates: financial figures,
  officer names, risk factors, legal proceedings, and corporate structure changes. Pulls updated data
  from Julia (financials), Scheduler (compliance events), and Cris (M&A activity). Generates draft
  updated text with tracked changes, section-by-section update tracker, and a review checklist for
  Latham & Watkins.
  CRITICAL: Form 20-F is a legal SEC filing. AI generates DRAFTS ONLY. All content requires review
  and sign-off by legal counsel (Latham & Watkins) before EDGAR submission. Never auto-distribute.
  Triggers on: 20-F, annual report SEC, Form 20-F, EDGAR annual, SEC annual filing, 20F draft
argument-hint: "[fiscal-year YYYY] [--section N or 'all'] [--changes-only | --full-draft | --checklist | --cross-reference]"
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

Supports Marco (Legal Agent) in drafting the annual Form 20-F for NVNI Group Limited filed with the SEC as a foreign private issuer. The skill parses the prior year EDGAR filing into its canonical sections, performs a diff against current-year data (financial statements, corporate updates, material events), and produces a draft update packet for legal counsel review.

NVNI Group Limited is the Cayman Islands holding company listed on Nasdaq. The filing covers consolidated operations across NVNI Group (Cayman), Nuvini Holdings (Cayman), Nuvini S.A. (Brazil), and the Delaware Holding LLC, and eight Brazilian portfolio companies: Effecti, Leadlovers, Ipe Digital, DataHub, Mercos, Onclick, Dataminer, and MK Solutions.

**CRITICAL RULE**: This skill produces draft working materials only. Form 20-F is an SEC legal filing carrying personal liability for signing officers. No draft section may be treated as final, distributed externally, or uploaded to EDGAR without sign-off from Latham & Watkins and the responsible officers.

## Usage

```bash
# Check what sections need updating for fiscal year 2025
/legal-20f-assistant 2025 --changes-only

# Generate full draft update of all 20-F sections
/legal-20f-assistant 2025 all --full-draft

# Generate only a specific section (e.g., Item 4 — Business Overview)
/legal-20f-assistant 2025 --section 4 --full-draft

# Generate counsel review checklist for Latham & Watkins
/legal-20f-assistant 2025 --checklist

# Generate cross-reference index to supporting documents
/legal-20f-assistant 2025 --cross-reference
```

## Sub-commands

| Flag                | Description                                                                              |
| ------------------- | ---------------------------------------------------------------------------------------- |
| `--changes-only`    | Scan prior 20-F and flag sections with stale content; output change summary only         |
| `--full-draft`      | Generate complete updated draft for specified section(s) as Google Doc with tracked text |
| `--checklist`       | Produce itemized review checklist for management and Latham & Watkins counsel            |
| `--cross-reference` | Build index mapping each 20-F section to supporting source documents in Drive/EDGAR      |
| `--section N`       | Scope any flag to a single Item number (1–19B); default is `all`                         |

## 20-F Section Map

The skill processes all standard 20-F Items. Sections most likely to require annual updates are marked HIGH:

| Item | Title                                               | Update Priority |
| ---- | --------------------------------------------------- | --------------- |
| 1    | Identity and Officers of Directors                  | HIGH            |
| 2    | Offer Statistics and Expected Timetable             | Medium          |
| 3    | Key Information (risk factors, dividends, cap)      | HIGH            |
| 4    | Information on the Company                          | HIGH            |
| 4A   | Unresolved Staff Comments                           | Medium          |
| 5    | Operating and Financial Review (MD&A)               | HIGH            |
| 6    | Directors, Senior Management, Employees             | HIGH            |
| 7    | Major Shareholders and Related-Party Transactions   | HIGH            |
| 8    | Financial Information (consolidated statements)     | HIGH            |
| 9    | Listing Details                                     | Medium          |
| 10   | Additional Information (charter, exchange controls) | Medium          |
| 11   | Quantitative Disclosures About Market Risk          | HIGH            |
| 12   | ADR Descriptions                                    | Low             |
| 13   | Defaults, Dividends, Arrears                        | Medium          |
| 14   | Material Modifications to Rights of Securities      | Medium          |
| 15   | Controls and Procedures (CEO/CFO Certifications)    | HIGH            |
| 16A  | Audit Committee Financial Expert                    | Medium          |
| 16B  | Code of Ethics                                      | Low             |
| 16C  | Principal Accountant Fees                           | HIGH            |
| 16D  | Exemptions from Listing Standards                   | Low             |
| 16E  | Purchases of Equity Securities                      | Medium          |
| 16F  | Change in Registrant's Certifying Accountant        | Medium          |
| 16G  | Corporate Governance                                | Medium          |
| 16H  | Mine Safety Disclosure                              | Low             |
| 16I  | Disclosure Regarding Foreign Jurisdictions          | Medium          |
| 17   | Financial Statements                                | HIGH            |
| 18   | Financial Statements (IFRS cross-reference)         | HIGH            |
| 19   | Exhibits Index                                      | HIGH            |
| 19B  | Cybersecurity                                       | HIGH            |

## Data Sources

| Input                             | Source Agent / Location                                                          |
| --------------------------------- | -------------------------------------------------------------------------------- |
| Prior year 20-F filing text       | EDGAR (WebFetch) or Drive search `name contains '20-F' AND name contains 'NVNI'` |
| Audited financial statements      | Julia (Finance) — Drive search `name contains 'Audited' OR name contains 'IFRS'` |
| MD&A narrative (Item 5)           | Julia — finance-management-report, finance-variance-commentary outputs           |
| Officer/director roster updates   | Drive search `name contains 'Board Resolution' OR name contains 'Officer'`       |
| Risk factor changes               | Marco (Legal) — material events log, Cris M&A pipeline closings                  |
| Material events and M&A activity  | Cris (M&A) — mna-pipeline, mna-integration outputs                               |
| Compliance events and proceedings | Scheduler — compliance-calendar, legal-compliance-calendar outputs               |
| Related-party transactions        | Marco + Julia — Mutuo register, finance-mutuo-calculator outputs                 |
| Cybersecurity disclosures (19B)   | Scheduler — incident log, security policy register                               |
| Corporate structure chart         | legal-entity-registry — entity map for all 4 parent entities + 8 portfolio cos   |
| Principal accountant fees         | Julia — accounts payable / audit engagement letter                               |
| SEC staff comments (Item 4A)      | EDGAR correspondence search for NVNI Group ticker                                |

## Process Flow

When invoked, the skill executes this sequence:

1. **Retrieve prior 20-F** — fetch from EDGAR or Drive; parse into Item-level sections.
2. **Load current-year data** — pull from each data source listed above; flag any sources not found.
3. **Diff each section** — compare prior-year text against current data; identify stale figures, outdated names, superseded risk factors, new material events.
4. **Generate change flags** — for each stale element, produce a structured change note: what changed, why, source document, confidence level.
5. **Draft updated text** — rewrite flagged passages with updated data; preserve prior-year language where unchanged; mark all AI-generated text `[AI DRAFT — COUNSEL REVIEW REQUIRED]`.
6. **Build counsel checklist** — extract all flagged items into a numbered checklist categorized by: (a) factual update, (b) legal judgment required, (c) management sign-off required, (d) auditor confirmation required.
7. **Create Google Doc** — output full draft with change markers; link to source documents inline.

## Output Format

```
FORM 20-F DRAFT ASSISTANT — NVNI GROUP LIMITED
================================================
Fiscal Year    : 2025
Ticker         : NVNI (Nasdaq)
Filer Type     : Foreign Private Issuer
Prior Filing   : FY2024 20-F (filed EDGAR 2025-04-25)
Run Date       : 2026-02-19
Mode           : --changes-only

SECTION CHANGE FLAGS
--------------------
Item 1  — Identity / Officers          : 2 officer changes detected
Item 3  — Risk Factors                 : 4 risk factors require review (M&A activity, LGPD)
Item 4  — Business Overview            : 2 new portfolio companies (DataHub, Mercos post-acquisition)
Item 5  — MD&A                         : ALL financial figures require update (FY2025 actuals)
Item 6  — Directors / Management       : Board composition changed — 1 new independent director
Item 7  — Related-Party Transactions   : 3 new Mutuo agreements since last filing
Item 8  — Financial Information        : Audited IFRS statements not yet received — BLOCKING
Item 11 — Market Risk                  : FX exposure changed — BRL/USD rate disclosure needs update
Item 15 — Controls / Certifications    : CEO/CFO cert language — review for accuracy
Item 16C — Accountant Fees             : Pending — request from Julia
Item 17/18 — Financial Statements      : BLOCKING — awaiting audited statements
Item 19  — Exhibits                    : New exhibits required for 3 material agreements
Item 19B — Cybersecurity               : Policy updated 2026-01 — disclosure requires refresh

BLOCKING ITEMS (3)
------------------
[1] Audited IFRS financial statements not found — request from auditors via Julia
[2] CEO/CFO Sarbanes-Oxley certifications — management must prepare (cannot be AI-drafted)
[3] Latham & Watkins legal opinion letters — not in scope for AI generation

Draft Google Doc : [link] (Items 1, 3, 4, 6, 7, 9, 10 populated)
Counsel Checklist: [link]
Cross-Reference  : [link]

CONFIDENCE: RED — Legal filing. No section is final. Latham & Watkins review required.
```

## Confidence Scoring

- **Red (mandatory and permanent)** — Form 20-F is an SEC legal filing. Inaccurate disclosure creates legal liability for signing officers and the company. This skill ALWAYS outputs Red confidence regardless of data completeness. No section auto-finalizes. No draft is distributed without legal counsel review.
- **Yellow** — Not applicable. Red is the floor for all 20-F work product.
- **Green** — Not applicable for this skill.
- **Escalation**: If financial statements are missing within 60 days of the EDGAR filing deadline, immediately alert Marco, Scheduler, and Julia via Gmail.

## Integration

- **Marco (Legal)**: Primary owner — runs this skill, reviews all output, coordinates with Latham & Watkins
- **Julia (Finance)**: Provides audited IFRS financial statements, MD&A data, related-party transaction values, accountant fee data
- **Scheduler (Compliance)**: Provides compliance calendar events referenced in Items 3 and 15; tracks EDGAR filing deadline
- **Cris (M&A)**: Provides material acquisition events, integration status, deal terms for risk factor and business description updates
- **Bella (IR)**: Coordinates on Items 9, 14, 16E (equity securities); cross-checks against IR deck and capital register
- **legal-entity-registry**: Corporate structure source for Item 4 (corporate structure chart) and Item 7 (related-party entities)
- **finance-mutuo-calculator**: Source for Item 7 related-party lending disclosures
- **compliance-regulatory-monitor**: Feeds Item 3 risk factors with new regulatory developments from CVM, ANPD, Bacen, SEC, CIMA
- **mna-pipeline / mna-integration**: Material acquisition events feed Item 4 (business description) and Item 3 (risk factors)
