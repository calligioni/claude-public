---
name: mna-termsheet
description: "Auto-generate Term Sheets for Nuvini M&A deals from negotiated parameters using historical deal templates. Use when a deal reaches the Term Sheet stage and the user needs to draft a term sheet, review historical templates, or browse previous deals. Triggers on phrases like 'generate term sheet', 'create term sheet', 'term sheet for [company]', 'show term sheet template', 'term sheet history', or 'draft acquisition terms'."
argument-hint: "[generate|template|history] [target]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
tool-annotations:
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__docs_getText:
    { readOnlyHint: true, idempotentHint: true }
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

# M&A Term Sheet Generator

Auto-generates Nuvini-standard Term Sheets from negotiated deal parameters. Pulls from historical templates (Munddi, Lecom, Nerus) and produces a Google Doc ready for review and e-signature.

## Commands

| Command                            | Description                                                  |
| ---------------------------------- | ------------------------------------------------------------ |
| `/mna termsheet`                   | Default: interactive mode — collect parameters then generate |
| `/mna termsheet generate [target]` | Generate term sheet for a named target                       |
| `/mna termsheet template`          | Show the standard Nuvini term sheet template structure       |
| `/mna termsheet history`           | List previously generated term sheets with deal summaries    |

## Workflow

### Phase 1: Gather Parameters

#### Interactive Mode

If parameters are not provided, prompt for each field below. For fields marked **[default]**, offer the Nuvini standard and allow override.

| Parameter                 | Description                            | Default            |
| ------------------------- | -------------------------------------- | ------------------ |
| Target company name       | Full legal name                        | —                  |
| Purchase price            | Total enterprise value (BRL)           | —                  |
| Cash at close %           | % paid on closing date                 | 60%                |
| Deferred payment %        | % paid post-close                      | 40%                |
| Deferred payment schedule | e.g., "40% in 12 months"               | 40% at Month 12    |
| Earn-out metric           | Revenue, EBITDA, or other KPI          | EBITDA             |
| Earn-out period           | Measurement period (months)            | 12 months          |
| Earn-out multiplier       | e.g., 3x on EBITDA growth above target | 3x                 |
| Earn-out cap              | Maximum earn-out payout (BRL)          | —                  |
| Exclusivity period        | Days of exclusivity                    | 90 days            |
| Conditions precedent      | Key closing conditions                 | Standard           |
| Governing law             | Jurisdiction                           | Brazil (São Paulo) |
| Effective date            | Date of term sheet                     | Today              |
| Counterparty contact      | Name, title, email                     | —                  |
| Jurisdiction type         | Brazilian or international             | Brazil             |

#### From Pipeline Context

If invoked as `generate [target]`, first search memory and Drive for any existing triage or proposal data for this target to pre-fill financial parameters.

### Phase 2: Load Historical Templates

1. Search Google Drive for historical term sheet documents:
   - `mcp__google-workspace__drive_search` with queries: "Munddi term sheet", "Lecom term sheet", "Nerus term sheet"
2. Read each found document via `mcp__google-workspace__docs_getText` to extract standard clause language.
3. Search memory for any term sheet patterns: `mcp__memory__search_nodes` with "term sheet template".
4. Use the most recent completed deal's language as the base template.

### Phase 3: Draft the Term Sheet

Compose a complete term sheet Google Doc with the following sections:

#### Document Structure

**1. PARTIES**

- Acquirer: NVNI Group Limited (or Nuvini S.A. for domestic deals)
- Target: [Full legal name, CNPJ if Brazilian]
- Date: [Effective date]

**2. TRANSACTION STRUCTURE**

- Transaction type: Share purchase / Asset purchase
- Description of the business being acquired

**3. PURCHASE PRICE**

- Total enterprise value
- Basis (e.g., "6x LTM EBITDA of R$[X]M = R$[Y]M")
- Subject to working capital adjustment (state mechanism)

**4. PAYMENT TERMS**

- Cash at close: [%] = R$[amount]
- Deferred payment: [%] = R$[amount], payable [schedule]
- Escrow: [if applicable]

**5. EARN-OUT**

- Metric: [EBITDA / Revenue]
- Measurement period: [12/24 months post-close]
- Earn-out payment: [Multiplier]x on [metric] above [base target]
- Cap: R$[amount]
- Payment timing: [date]

**6. REPRESENTATIONS & WARRANTIES**

- Standard R&W package (list key categories)
- R&W survival period: 18 months post-close
- R&W cap: [% of purchase price]

**7. CONDITIONS PRECEDENT**

- Regulatory approvals (CADE if applicable)
- Completion of due diligence to Nuvini's satisfaction
- No material adverse change
- Key employee retention agreements
- [Deal-specific conditions]

**8. EXCLUSIVITY**

- Period: [90 days from signing]
- Scope: No-shop, no-talk obligations
- Break fee: R$[amount] if target breaches

**9. GOVERNING LAW**

- Law: [Brazilian law / applicable law]
- Venue: [São Paulo / applicable court]
- Language: [PT / EN]

**10. CONFIDENTIALITY**

- Reference to existing NDA (if in place)
- Additional confidentiality obligations for term sheet itself

**11. NON-BINDING NATURE**

- Standard non-binding disclaimer (except exclusivity, confidentiality, governing law)

**12. SIGNATURES**

- Nuvini representative signature block
- Target representative signature block

#### Language

- If Brazilian counterparty: generate bilingual PT/EN dual-column format.
- If international counterparty: English only.
- Use formal legal register consistent with historical templates.

### Phase 4: Create Google Doc

1. Create the document: `mcp__google-workspace__docs_create` with title `"Term Sheet — [Target] — [Date]"`.
2. Store the document ID in memory: `mcp__memory__add_observations`.
3. Draft a cover email to the counterparty with the term sheet attached for review: `mcp__google-workspace__gmail_createDraft`.
4. Note that the document should be shared via Clicksign (Brazilian) or DocuSign (international) for e-signature when ready.

### Phase 5: Validation (if running `history`)

For `history` subcommand:

1. Search Drive for all term sheets: `mcp__google-workspace__drive_search` query "term sheet Nuvini".
2. For each, extract: deal name, date, purchase price, outcome (if known).
3. Display as a summary table.

For validation mode (internal): generate a term sheet for a historical completed deal (e.g., Munddi) and compare key fields against the signed document.

## Nuvini Standard Terms Reference

| Parameter          | Standard                  |
| ------------------ | ------------------------- |
| EBITDA multiple    | 6x                        |
| Cash at close      | 60%                       |
| Deferred payment   | 40%                       |
| Earn-out period    | 12 months                 |
| Earn-out metric    | EBITDA                    |
| Exclusivity period | 90 days                   |
| R&W survival       | 18 months                 |
| Governing law      | Brazil (São Paulo courts) |

## Data Sources

| Source                     | Purpose                                           |
| -------------------------- | ------------------------------------------------- |
| Google Drive (M&A folders) | Historical templates (Munddi, Lecom, Nerus)       |
| Memory graph               | Previously generated term sheets, deal parameters |
| Current date tool          | Effective date, deadline calculations             |
| Google Docs (create)       | Output document                                   |
| Gmail (drafts)             | Cover email to counterparty                       |

## Error Handling

| Error                                          | Action                                                               |
| ---------------------------------------------- | -------------------------------------------------------------------- |
| Historical template not found                  | Use built-in standard template structure, note absence               |
| Missing required parameter in interactive mode | Ask specifically for the missing field before proceeding             |
| Purchase price inconsistent with 6x EBITDA     | Flag discrepancy, ask user to confirm the override                   |
| Google Docs creation fails                     | Write the term sheet content to the chat in markdown for manual copy |
| Bilingual formatting issues                    | Generate PT version and EN version as separate sections              |

## Confidence Scoring

- **Green (>95%):** Document structure, standard clause language, formatting. Auto-proceed.
- **Yellow (80–95%):** All financial figures (purchase price, earn-out amounts, payment schedule). Always Yellow — require human review before sending to counterparty.
- **Red (<80%):** Non-standard earn-out structures, complex earn-out metrics, international jurisdiction terms. Full legal review required.

Note: All term sheet content is deal-sensitive and defaults to Yellow confidence. Never send directly to counterparty without human review.

## Examples

```bash
# Interactive mode — prompts for all parameters
/mna termsheet

# Generate for a specific target using stored deal data
/mna termsheet generate TechBrasil

# Show the standard template structure
/mna termsheet template

# List all previously generated term sheets
/mna termsheet history
```
