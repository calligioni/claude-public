---
name: mna-nda-gen
description: "Generate mutual NDAs for Nuvini M&A targets with pre-filled company fields. Supports bilingual PT/EN output for Brazilian counterparties. Use when a new target enters the pipeline and needs an NDA drafted, or when reviewing available NDA templates. Triggers on phrases like 'generate NDA', 'draft NDA for [company]', 'create confidentiality agreement', 'NDA template', 'send NDA to [company]', or 'mutual NDA'. Works alongside the nda-reviewer skill — this generates outgoing NDAs, that reviews incoming NDAs."
argument-hint: "[generate|template|status]"
user-invocable: true
context: fork
model: haiku
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

# M&A NDA Generator

Generates mutual NDAs for new M&A targets with Nuvini party details pre-filled. Supports bilingual PT/EN for Brazilian counterparties. Produces a Google Doc ready for Clicksign (Brazil) or DocuSign (international) e-signature.

This skill generates outgoing NDAs. To review incoming NDAs from counterparties, use the `nda-reviewer` skill instead.

## Commands

| Command                 | Description                                                            |
| ----------------------- | ---------------------------------------------------------------------- |
| `/mna nda-gen`          | Default: interactive mode — collect counterparty details then generate |
| `/mna nda-gen generate` | Generate NDA with prompted fields                                      |
| `/mna nda-gen template` | Display the standard NDA template structure                            |
| `/mna nda-gen status`   | List recently generated NDAs from memory                               |

## Workflow

### Phase 1: Gather Parameters

If not provided, prompt for:

| Field                     | Description                                                    | Default                 |
| ------------------------- | -------------------------------------------------------------- | ----------------------- |
| Target company name       | Full legal name                                                | —                       |
| CNPJ                      | Brazilian tax ID (if applicable)                               | —                       |
| Counterparty contact name | Full name                                                      | —                       |
| Counterparty title        | Job title                                                      | —                       |
| Counterparty email        | Email for NDA delivery                                         | —                       |
| Jurisdiction              | Brazil or International                                        | Brazil                  |
| Confidentiality period    | Duration of obligations                                        | 2 years                 |
| Effective date            | Start date of NDA                                              | Today                   |
| Purpose                   | Scope of the NDA (e.g., "evaluation of potential acquisition") | Standard M&A evaluation |

Get today's date: `mcp__google-workspace__time_getCurrentDate`.

### Phase 2: Determine Nuvini Party

Based on jurisdiction:

- **Brazil:** Nuvini S.A. — CNPJ [to be confirmed], Avenida [address], São Paulo, SP
- **International:** NVNI Group Limited — [Cayman Islands registered entity], [registered address]

Search Drive for any existing NDA templates: `mcp__google-workspace__drive_search` with query "NDA template Nuvini mutual".

### Phase 3: Draft the NDA

Compose the full NDA with these sections:

---

**ACORDO DE CONFIDENCIALIDADE MÚTUO / MUTUAL NON-DISCLOSURE AGREEMENT**

_(If Brazilian counterparty: dual-column PT | EN format. If international: English only.)_

**1. PARTES / PARTIES**

- Party 1: [Nuvini entity], a [corporation] organized under the laws of [Brazil/Cayman Islands], with [CNPJ/registration number], represented by [authorized signatory]
- Party 2: [Target company full legal name], a [corporation] organized under the laws of [jurisdiction], with CNPJ [number if Brazilian], represented by [counterparty contact, title]
- Collectively referred to as "Parties"

**2. DEFINIÇÕES / DEFINITIONS**

"Confidential Information" means any information disclosed by either Party to the other Party, directly or indirectly, in writing, orally, or by inspection of tangible objects, that is designated as confidential or that reasonably should be understood to be confidential given the nature of the information and circumstances of disclosure.

Specifically includes: business plans, financial data, customer lists, technology, trade secrets, and terms of any potential transaction between the Parties.

**3. ESCOPO / SCOPE OF CONFIDENTIAL INFORMATION**

The Parties are considering a potential [acquisition/partnership/investment] transaction (the "Purpose"). All information exchanged in connection with the Purpose is subject to this Agreement.

**4. OBRIGAÇÕES / OBLIGATIONS**

Each Party agrees to:

- Hold all Confidential Information in strict confidence
- Not disclose to third parties without prior written consent of the disclosing Party
- Use only for the Purpose defined above
- Protect with at least the same degree of care as its own confidential information (minimum: reasonable care)
- Limit disclosure to employees, advisors, and representatives with need-to-know, who are bound by equivalent confidentiality obligations

**5. DIVULGAÇÕES PERMITIDAS / PERMITTED DISCLOSURES**

Confidential Information does not include information that:

- (a) Is or becomes publicly available through no breach of this Agreement
- (b) Was known to the receiving Party prior to disclosure
- (c) Is independently developed by the receiving Party without use of Confidential Information
- (d) Is rightfully received from a third party without restriction
- (e) Must be disclosed pursuant to applicable law or court order (with prompt prior notice to the disclosing Party)

Financial advisors, legal counsel, and accountants engaged by either Party in connection with the Purpose are considered permitted representatives.

**6. PRAZO E RESCISÃO / TERM AND TERMINATION**

- Effective Date: [Date]
- Term: [2 years] from the Effective Date, or until the Purpose is abandoned by either Party, whichever is earlier
- Survival: Confidentiality obligations survive termination for [2 years]

**7. DEVOLUÇÃO DE MATERIAIS / RETURN OF MATERIALS**

Upon request or termination, each Party shall promptly return or certifiably destroy all Confidential Information (and any copies) of the other Party. Confirmation of destruction to be provided in writing within 10 business days.

**8. REMÉDIOS / REMEDIES**

The Parties acknowledge that breach of this Agreement may cause irreparable harm for which monetary damages would be inadequate. The non-breaching Party shall be entitled to seek injunctive relief and specific performance in addition to any other remedies available at law or equity.

**9. LEI APLICÁVEL / GOVERNING LAW**

- Brazil: This Agreement shall be governed by the laws of the Federative Republic of Brazil. The Parties elect the courts of the city of São Paulo, State of São Paulo, as the exclusive forum for dispute resolution.
- International: This Agreement shall be governed by the laws of [applicable jurisdiction]. Disputes shall be resolved by [arbitration/courts] in [location].

**10. CONFIDENCIALIDADE DESTE ACORDO / CONFIDENTIALITY OF THIS AGREEMENT**

The existence and terms of this Agreement are themselves confidential and shall not be disclosed to any third party without the prior written consent of both Parties.

**11. DISPOSIÇÕES GERAIS / GENERAL PROVISIONS**

- This Agreement constitutes the entire agreement between the Parties regarding the subject matter hereof.
- This Agreement may be executed in counterparts, each of which shall be deemed an original.
- Amendments must be in writing and signed by both Parties.
- Neither Party's failure to enforce any provision shall constitute a waiver.

**12. ASSINATURAS / SIGNATURES**

For [Nuvini entity]:
Name: ******\_\_\_\_******
Title: ******\_\_\_\_******
Date: ******\_\_\_\_******

For [Target company]:
Name: [Counterparty contact name]
Title: [Title]
Date: ******\_\_\_\_******

---

### Phase 4: Create Google Doc and Prepare for E-Signature

1. Create the NDA as a Google Doc: `mcp__google-workspace__docs_create`
   - Title: `"NDA Mútuo — [Target] — [Date]"`
2. Log in memory: `mcp__memory__add_observations`
   - Target name, effective date, Google Doc ID, counterparty email, jurisdiction
3. Draft the transmission email via `mcp__google-workspace__gmail_createDraft`:
   - Subject: `Acordo de Confidencialidade Mútuo — [Nuvini entity] e [Target]`
   - Body: Introduce the NDA, provide link to Google Doc, instructions for signing
   - Note: For Brazil, send to Clicksign; for international, send via DocuSign
4. Note the signing platform in the email draft:
   - **Brazil:** Clicksign — upload the Doc and set up signing flow
   - **International:** DocuSign — export as PDF and upload

### Phase 5: Template Display (`template` subcommand)

Display the 12 sections of the standard template with brief descriptions. Do not generate a full NDA — just show the structure for reference.

### Phase 6: Status (`status` subcommand)

Search memory: `mcp__memory__search_nodes` query "NDA mútuo generated".
List all NDAs generated, with: target name, date, effective date, jurisdiction, signing status (if known).

## Nuvini Party Details

| Jurisdiction  | Entity             | Details                                                |
| ------------- | ------------------ | ------------------------------------------------------ |
| Brazil        | Nuvini S.A.        | Brazilian entity — fill CNPJ from legal registry       |
| International | NVNI Group Limited | Cayman Islands — fill registration from legal registry |

When in doubt about the correct entity or signatory, flag to user before generating the NDA.

## Language Rules

- If counterparty is **Brazilian** (has CNPJ or is in Brazil): Generate **bilingual PT/EN** — dual column format (PT left, EN right) for each article.
- If counterparty is **international**: Generate **English only**.
- All financial figures and legal terms must be consistent in both language columns.

## E-Signature Platforms

| Jurisdiction  | Platform  | Action                                                        |
| ------------- | --------- | ------------------------------------------------------------- |
| Brazil        | Clicksign | Upload signed PDF or Google Doc link; set up signing sequence |
| International | DocuSign  | Export as PDF, upload, configure routing                      |

## Data Sources

| Source               | Purpose                                |
| -------------------- | -------------------------------------- |
| Google Drive search  | Find existing NDA templates            |
| Google Docs (create) | Output NDA document                    |
| Gmail (drafts)       | NDA transmission email to counterparty |
| Memory               | Prior NDAs generated, deal context     |
| Current date tool    | Effective date                         |

## Error Handling

| Error                                        | Action                                                               |
| -------------------------------------------- | -------------------------------------------------------------------- |
| CNPJ not provided for Brazilian counterparty | Note as TBD in document, remind user to fill before sending          |
| Nuvini signatory unknown                     | Leave signature block blank, add note: "Insert authorized signatory" |
| Google Doc creation fails                    | Output NDA as markdown in chat for manual copy                       |
| Jurisdiction unclear                         | Default to Brazil jurisdiction, flag to user                         |
| Counterparty email missing                   | Generate NDA document but skip email draft, remind user              |

## Confidence Scoring

- **Green (>95%):** NDA structure, standard clause language, bilingual formatting. Auto-proceed for document generation.
- **Yellow (80–95%):** All party details, CNPJ numbers, signatory names, governing law specifics. Require human review before sending to counterparty.
- **Red (<80%):** Non-standard confidentiality scope, unusual jurisdiction, complex multi-party NDA. Full legal review required.

All NDA content defaults to Yellow — require human review before sending to any counterparty. This tool generates legal documents; always confirm with legal counsel before execution.

## Examples

```bash
# Interactive mode — prompts for all fields
/mna nda-gen

# Generate with explicit trigger
/mna nda-gen generate

# Show template structure only
/mna nda-gen template

# List recently generated NDAs
/mna nda-gen status
```
