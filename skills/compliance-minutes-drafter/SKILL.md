---
name: compliance-minutes-drafter
description: |
  Converts meeting notes into formal board minutes and corporate resolutions for Nuvini OS entities.
  Supports US-format minutes and Brazilian Ata format (Junta Comercial compliant). Generates
  resolution register updates, distributes action items, and produces Junta filing checklist for
  Brazilian entities. Covers NVNI Group (Cayman), Nuvini Holdings (Cayman), Nuvini S.A. (Brazil),
  Holding LLC (Delaware), and portfolio company boards.
  Triggers on: board minutes, minutes, ata, draft minutes, meeting minutes, resolutions, ata de reunião
argument-hint: "[meeting-date YYYY-MM-DD] [entity] [--from-notes 'text or file'] [--ata-format | --us-format] [--resolutions-only]"
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
  - mcp__google-workspace__calendar_listEvents
  - mcp__google-workspace__calendar_getEvent
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

Transforms free-form or structured meeting notes into formally drafted board minutes and corporate resolutions. Automatically selects the correct format based on the entity: US-format minutes for NVNI Group (Cayman), Nuvini Holdings (Cayman), and Holding LLC (Delaware); Brazilian Ata format compliant with Junta Comercial requirements for Nuvini S.A. and Brazilian portfolio subsidiaries. Outputs a formatted Google Doc, updates the resolution register, distributes action items to owners, and generates the Junta filing checklist when applicable.

## Usage

```bash
# Draft Ata for Nuvini S.A. board meeting from free-form notes
/compliance-minutes-drafter 2026-02-15 "Nuvini S.A." \
  --from-notes "Meeting held at Av. Paulista 1000. Present: Pedro (CEO), Ana (CFO), Joao (Board). \
   Discussed Q4 results. Approved BRL 500k intercompany loan to Effecti. Approved new compliance policy." \
  --ata-format

# Draft US-format minutes for Nuvini Holdings Ltd
/compliance-minutes-drafter 2026-02-15 "Nuvini Holdings Ltd" \
  --from-notes /path/to/meeting-notes.txt \
  --us-format

# Generate resolutions only (no full minutes)
/compliance-minutes-drafter 2026-02-15 "Nuvini S.A." \
  --from-notes "Approved: BRL 1.2M loan to Leadlovers at 1.5% p.a. Vote: 3-0." \
  --resolutions-only --ata-format

# Draft minutes with calendar event as source
/compliance-minutes-drafter 2026-02-15 "Holding LLC (Delaware)" \
  --from-notes "Annual Board Meeting — see calendar invite notes" \
  --us-format

# Check resolution register for an entity
/compliance-minutes-drafter --resolutions-only "Nuvini S.A." --status
```

## Sub-commands

| Flag                          | Description                                                                  |
| ----------------------------- | ---------------------------------------------------------------------------- |
| `--from-notes 'text or file'` | Free-form notes as inline text or file path to process                       |
| `--ata-format`                | Generate Brazilian Ata de Reunião (Junta Comercial compliant)                |
| `--us-format`                 | Generate US-style board minutes (Cayman / Delaware entities)                 |
| `--resolutions-only`          | Extract and format only the resolutions passed, skip narrative minutes       |
| `--status`                    | Show resolution register for entity, last meeting date, pending action items |

## Entities and Formats

| Entity                       | Format     | Filing Requirement       |
| ---------------------------- | ---------- | ------------------------ |
| NVNI Group Ltd (Cayman)      | US format  | Cayman board records     |
| Nuvini Holdings Ltd (Cayman) | US format  | Cayman board records     |
| Holding LLC (Delaware)       | US format  | Delaware LLC records     |
| Nuvini S.A. (Brazil)         | Ata format | Junta Comercial (JUCESP) |
| Effecti Tecnologia Ltda      | Ata format | Junta Comercial (state)  |
| Leadlovers Tecnologia Ltda   | Ata format | Junta Comercial (state)  |
| Ipê Digital                  | Ata format | Junta Comercial (state)  |
| DataHub                      | Ata format | Junta Comercial (state)  |
| Mercos Software Ltda         | Ata format | Junta Comercial (state)  |
| Onclick                      | Ata format | Junta Comercial (state)  |
| Dataminer                    | Ata format | Junta Comercial (state)  |
| MK Solutions                 | Ata format | Junta Comercial (state)  |

## US-Format Minutes Structure

1. Entity name, type of meeting (regular/special), date, time, location/virtual
2. Attendees: directors present, officers present, quorum confirmation
3. Call to order and confirmation of notice
4. Agenda items (narrative format)
5. Resolutions passed (each numbered: RESOLVED THAT...)
6. Dissenting votes (if any)
7. Action items: owner, description, deadline
8. Next meeting date
9. Adjournment
10. Secretary signature block

## Brazilian Ata Format Structure

Per Junta Comercial requirements (Lei 6.404/76, Instrução Normativa DREI):

1. Cabeçalho: razão social, CNPJ, sede, data, hora e local da reunião
2. Presença e quórum: verificação de quórum estatutário
3. Mesa diretora: presidente e secretário da mesa
4. Ordem do dia: itens pautados
5. Deliberações: para cada item — discussão resumida, votação (votos a favor, contra, abstenções), deliberação aprovada
6. Encerramento: próxima reunião, assinatura dos presentes

### Junta Comercial Filing Checklist (Nuvini S.A.)

Generated automatically when entity is Nuvini S.A. or other Brazilian entities:

- [ ] Ata original assinada por todos os presentes
- [ ] Procurações (if attorneys-in-fact present)
- [ ] Requerimento de arquivamento (DREI model)
- [ ] Comprovante de pagamento de taxas
- [ ] DOESP/Monitor Mercantil publication (if required by statute)
- [ ] Prazo de arquivamento: 30 dias da data da reunião
- [ ] Filing deadline: [computed from meeting date]

## Resolution Register

Each resolution is logged in the Nuvini Resolution Register (Google Sheets, Drive search `name contains 'Resolution Register'`):

| Field           | Description                                                  |
| --------------- | ------------------------------------------------------------ |
| Resolution No.  | Sequential per entity: `NVNI-2026-001`, `NSA-2026-005`, etc. |
| Entity          | Legal entity name                                            |
| Meeting Date    | ISO date                                                     |
| Resolution Text | Full text of resolution                                      |
| Vote            | For/Against/Abstain counts                                   |
| Status          | Passed / Rejected / Deferred                                 |
| Action Owner    | Person responsible for execution                             |
| Action Deadline | Date                                                         |
| Filed           | Junta filing date (Brazilian entities)                       |

## Action Item Distribution

After minutes are drafted, action items are automatically extracted and:

- Summarized in an email to each action item owner
- Added as calendar reminders (if calendar access available)
- Logged in the resolution register with deadlines

## Data Sources

- **Meeting notes**: Provided inline or as file path
- **Calendar events**: `mcp__google-workspace__calendar_listEvents` for meeting details
- **Resolution register**: Drive search `name contains 'Resolution Register' AND name contains 'Nuvini'`
- **Attendee list**: Parsed from notes or Board member register in Drive
- **Previous minutes**: Drive search `name contains 'Minutes' AND name contains '[entity]'` for formatting reference

## Output Format

```
MINUTES DRAFT — NUVINI S.A.
============================
Entity         : Nuvini S.A.
Format         : Ata de Reunião (Junta Comercial)
Meeting Date   : 2026-02-15
Draft Created  : 2026-02-19
Status         : DRAFT — Pending Compliance Officer review

Google Doc     : [link to generated Ata]

RESOLUTIONS PASSED
------------------
NSA-2026-005  Aprovação de mútuo BRL 500.000 — Effecti Tecnologia Ltda
              Vote: 3 favor, 0 contra, 0 abstenção — APROVADA

NSA-2026-006  Aprovação da Política de Compliance v2.0
              Vote: 3 favor, 0 contra, 0 abstenção — APROVADA

ACTION ITEMS
------------
[1] CEO — Execute Mútuo agreement with Effecti — Due: 2026-03-01
[2] Compliance Officer — Publish new Compliance Policy — Due: 2026-03-15

JUNTA FILING CHECKLIST
-----------------------
[ ] Ata original assinada
[ ] Requerimento de arquivamento
[ ] Pagamento de taxas JUCESP
[ ] DOESP publication (verify if required)
Filing deadline: 2026-03-17 (30 days from meeting)
```

## Confidence Scoring

- **Yellow (default)** — All minutes drafts require review and approval by the responsible director or Compliance Officer before being signed, distributed, or filed.
- **Green threshold not applicable** — Minutes are never auto-distributed. Marco (Legal) or Scheduler must confirm before any filing action.
- **Red** — If quorum cannot be confirmed from notes, or if a resolution appears to lack required authorization (e.g., intercompany loan exceeding approval threshold), flag immediately and halt. Do not draft a resolution that appears ultra vires.

## Integration

- **Scheduler (Compliance)**: Primary owner — triggers minutes drafting after each board/committee meeting
- **Marco (Legal)**: Reviews all resolutions for legal validity; provides Junta filing guidance
- **compliance-annual-report**: Board resolutions and meeting records feed into RCVM 21 annual report (Section 4)
- **legal-contract-generator**: Board resolutions authorizing contracts reference document numbers from the contract generator; the two systems cross-reference by document number
- **legal-compliance-calendar**: Meeting dates and filing deadlines tracked in compliance calendar
- **Julia (Finance)**: Financial resolutions (capex, loans, dividends) cross-referenced with approved budgets
