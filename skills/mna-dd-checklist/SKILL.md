---
name: mna-dd-checklist
description: "Auto-generate Due Diligence demand lists per deal from Nuvini's master DD template. Create data room folder structures in Google Drive. Use when a deal enters the Due Diligence stage and needs a DD demand list, a data room setup, or a DD kickoff email. Triggers on phrases like 'generate DD checklist', 'create due diligence list', 'DD demand list for [company]', 'set up data room', 'DD kickoff', or 'due diligence template'."
argument-hint: "[generate|template|data-room] [target]"
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
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
tool-annotations:
  mcp__google-workspace__sheets_getText:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__sheets_getRange:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__sheets_find:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__drive_search:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__google-workspace__gmail_createDraft: { idempotentHint: false }
  mcp__google-workspace__time_getCurrentDate:
    { readOnlyHint: true, idempotentHint: true }
  mcp__memory__search_nodes: { readOnlyHint: true, idempotentHint: true }
  mcp__memory__open_nodes: { readOnlyHint: true, idempotentHint: true }
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

# M&A Due Diligence Checklist Generator

Generates deal-specific Due Diligence demand lists from Nuvini's master DD template and creates data room folder structures in Google Drive. Covers all 10 standard workstreams with 10–30 document requests each.

## Master DD Template

**Sheet ID:** `19zEVq-d1Gor7HCjAHRdhec6WTmNTaTHftsxUAOb9mnE` (Base - Demandas Diligências)

## Commands

| Command                                | Description                                                    |
| -------------------------------------- | -------------------------------------------------------------- |
| `/mna dd-checklist`                    | Default: interactive mode — collect deal details then generate |
| `/mna dd-checklist generate [target]`  | Generate DD checklist for named target                         |
| `/mna dd-checklist template`           | Display the master DD template structure by workstream         |
| `/mna dd-checklist data-room [target]` | Create data room folder structure for named target             |

## The 10 DD Workstreams

| Workstream | Area                             | Typical Items |
| ---------- | -------------------------------- | ------------- |
| A          | Corporate / Organizational       | 15–20 items   |
| B          | Debt / Financial obligations     | 10–15 items   |
| C          | Regulatory & Compliance          | 15–20 items   |
| D          | Legal disputes                   | 10–15 items   |
| E          | Property (real + personal)       | 10–15 items   |
| F          | Tax                              | 20–30 items   |
| G          | Labor / Employment               | 15–20 items   |
| H          | IP & Technology                  | 15–20 items   |
| I          | Insurance                        | 10–15 items   |
| J          | Privacy / Data Protection (LGPD) | 10–15 items   |

## Workflow

### Phase 1: Gather Deal Context

If not provided, prompt for:

- Target company name
- DD start date (default: today)
- Document deadline (default: 30 days from DD start)
- Deal contact at target company (name, email, title)
- Special focus areas (e.g., "heavy tax risk", "IP-intensive business")

### Phase 2: Load Master Template

1. Read the master DD template sheet:
   - `mcp__google-workspace__sheets_getText` with sheet ID `19zEVq-d1Gor7HCjAHRdhec6WTmNTaTHftsxUAOb9mnE`
2. Parse all 10 workstreams and their document requests.
3. Note any items marked as "critical" or "minimum viable DD" in the template.

### Phase 3: Generate Deal-Specific Checklist

Create a Google Doc with the following structure:

**Title:** `DD Checklist — [Target] — [DD Start Date]`

**Header block:**

- Target: [Company name]
- DD Start Date: [Date]
- Document Deadline: [Date, default 30 days out]
- Nuvini Contact: Cris (M&A)
- Target Contact: [Name, title, email]

**Per workstream section:**

```
WORKSTREAM A — CORPORATE / ORGANIZATIONAL
Deadline: [Date]

A.1  Articles of Incorporation and all amendments
A.2  Current bylaws (estatuto social)
A.3  Minutes of shareholders' meetings (last 3 years)
A.4  Minutes of board/directors meetings (last 3 years)
A.5  Shareholder register and cap table
A.6  Organizational chart
...
Status column: [ ] Pending | [R] Received | [N/A] Not Applicable
```

Each item includes:

- Item number (e.g., A.1)
- Document description (in Portuguese for Brazilian targets)
- Priority flag: CRITICAL, HIGH, STANDARD
- Status tracking column (initially all Pending)
- Deadline date

### Phase 4: Create the Data Room (if `generate` or `data-room` subcommand)

Since Google Drive folder creation is not directly available via MCP tools, provide the user with the exact folder structure to create manually or via a Drive link:

```
Data Room — [Target] — [Year]
├── A. Corporate-Organizacional/
├── B. Dividas-Obrigacoes-Financeiras/
├── C. Regulatorio-Compliance/
├── D. Disputas-Legais/
├── E. Propriedades/
├── F. Tributario/
├── G. Trabalhista-RH/
├── H. PI-Tecnologia/
├── I. Seguros/
└── J. Privacidade-LGPD/
```

Search Drive for any existing [Target] folder: `mcp__google-workspace__drive_search` with target name.

### Phase 5: DD Kickoff Email Draft

Generate a kickoff email draft to the target company contact:

- `mcp__google-workspace__gmail_createDraft`
- Subject: `Início da Diligência — [Target] — Lista de Documentos`
- Body: Introduce DD process, attach checklist link, state deadline, provide Nuvini contact

### Phase 6: Log in Memory

Store the deal's DD parameters:

- `mcp__memory__create_entities` with entity type `design-decision:nuvini-mna`
- Record: target name, DD start date, deadline, Google Doc ID

## Data Sources

| Source                                                         | Purpose                               |
| -------------------------------------------------------------- | ------------------------------------- |
| Master DD Sheet `19zEVq-d1Gor7HCjAHRdhec6WTmNTaTHftsxUAOb9mnE` | Master document request template      |
| Google Drive search                                            | Check for existing deal folders       |
| Google Docs (create)                                           | Output DD checklist document          |
| Gmail (drafts)                                                 | DD kickoff email to target            |
| Current date tool                                              | Deadline calculations                 |
| Memory                                                         | Existing deal context, pipeline stage |

## DD Timeline Reference

| Deal Complexity                         | DD Duration |
| --------------------------------------- | ----------- |
| Simple (small deal, clean records)      | 30 days     |
| Standard                                | 45 days     |
| Complex (multiple entities, tax issues) | 60 days     |

## Error Handling

| Error                                | Action                                                               |
| ------------------------------------ | -------------------------------------------------------------------- |
| Master template sheet not accessible | Fall back to hardcoded 10-workstream structure with standard items   |
| Target not found in pipeline         | Generate checklist anyway, note that pipeline context is unavailable |
| Missing deadline or start date       | Default to today + 30 days, flag to user                             |
| Document creation fails              | Output checklist as markdown in chat                                 |
| Drive folder already exists          | Note existing folder, do not duplicate                               |

## Confidence Scoring

- **Green (>95%):** Document structure, workstream organization, item list completeness. Auto-proceed.
- **Yellow (80–95%):** Deal-specific customizations, deadline assignments, critical item flagging. Human review recommended.
- **Red (<80%):** Non-standard business types (e.g., financial institution, regulated entity) that require workstream modifications. Full review required before sending to target.

## Examples

```bash
# Interactive mode
/mna dd-checklist

# Generate for a specific target
/mna dd-checklist generate TechBrasil

# Show master template structure
/mna dd-checklist template

# Create data room structure only
/mna dd-checklist data-room TechBrasil
```
