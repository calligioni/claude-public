---
name: mna-integration
description: "Generate post-closing integration playbooks for Nuvini acquisitions. Covers a phased 90-day timeline with cross-agent coordination (Julia, Marco, Zuck, Scheduler). Use after a deal closes to generate the integration checklist, check progress on an ongoing integration, or create a weekly status template. Triggers on phrases like 'integration playbook', 'post-closing integration', 'onboard acquired company', 'integration checklist for [company]', 'Day 1 integration', '90-day integration', or 'integration status'."
argument-hint: "[generate|status|checklist] [company]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_find
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
tool-annotations:
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__sheets_getText:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__sheets_find:
    { readOnlyHint: true, idempotentHint: true }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
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

# M&A Post-Closing Integration Playbook

Generates phased 90-day integration playbooks for newly acquired Nuvini companies. Draws on experience from 8 prior acquisitions and coordinates cross-agent tasks with Julia (Mútuo), Marco (legal filings), Zuck (KPIs), and Scheduler (compliance calendar).

## Commands

| Command                                | Description                                                                |
| -------------------------------------- | -------------------------------------------------------------------------- |
| `/mna integration`                     | Default: interactive mode — collect company details then generate playbook |
| `/mna integration generate [company]`  | Generate integration playbook for named company                            |
| `/mna integration status [company]`    | Check progress on an ongoing integration                                   |
| `/mna integration checklist [company]` | Output the integration checklist only (no full playbook)                   |

## Workflow

### Phase 1: Gather Company Context

If not provided, prompt for:

| Input            | Description                        | Default        |
| ---------------- | ---------------------------------- | -------------- |
| Company name     | Full legal name of acquired entity | —              |
| Acquisition type | Asset purchase or share purchase   | Share purchase |
| Closing date     | Date of closing                    | Today          |
| Existing ERP     | Current ERP system                 | Unknown        |
| Banking          | Current bank(s)                    | Unknown        |
| HR system        | Payroll/HR platform                | Unknown        |
| Headcount        | Number of employees                | —              |
| Key personnel    | CEO, CFO, CTO to retain            | —              |
| Accounting firm  | Current external auditor           | —              |

Search memory for any deal data on this company: `mcp__memory__search_nodes` with company name.

### Phase 2: Generate the Integration Playbook

Create a Google Doc: `"Integration Playbook — [Company] — Closing [Date]"`

#### Structure

**Cover:**

- Acquired company: [Name]
- Closing date: [Date]
- Integration lead: Cris (M&A) + [functional owners]
- Target completion: 90 days from closing

---

#### DAY 1–30: Foundation & Control

**Banking & Finance**

- [ ] Add authorized signatories (Nuvini signers) to all bank accounts (Owner: Julia)
- [ ] Update signing authority documentation with all banks
- [ ] Cancel or transfer legacy signing authorities of former owners
- [ ] Notify banks of change of control
- [ ] Review existing credit facilities and guarantees
- [ ] Set up reporting to Nuvini treasury (weekly cash position)

**Legal & Corporate**

- [ ] File change of control notifications with Junta Comercial (Owner: Marco)
- [ ] Update company registration (CNPJ) if entity name changes
- [ ] Transfer shares in the company's equity register (if share purchase)
- [ ] Notify key commercial counterparties of change of control (per SPA requirements)
- [ ] Validate that all CPs in the SPA are confirmed complete

**Insurance**

- [ ] Transfer or renew all insurance policies under Nuvini coverage
- [ ] Cancel duplicate policies
- [ ] Confirm D&O coverage is in place for new management

**IT & Access**

- [ ] Provision Nuvini email domain (if applicable)
- [ ] Revoke former owner IT access (same day as closing)
- [ ] Audit all admin credentials and transfer to Nuvini IT
- [ ] Verify data backup status and DR plan

**Communications**

- [ ] Send Day 1 welcome communication to all employees (from Nuvini CEO)
- [ ] Update company website and LinkedIn with Nuvini ownership
- [ ] Notify key customers of acquisition (per communication plan)

---

#### DAY 31–60: Systems & Compliance

**Finance / Accounting**

- [ ] Onboard accounting firm: Grant Thornton (Owner: Julia)
- [ ] Set up Oracle / Questor ERP (Owner: Julia) — migrate from legacy ERP
- [ ] Establish monthly financial reporting cadence (delivery to Julia by 15th)
- [ ] Set up intercompany loan (Mútuo) if needed for working capital (Owner: Julia)
- [ ] IOF calculation and registration for Mútuo (Owner: Julia)

**Brand & Identity**

- [ ] Align brand with Nuvini portfolio standards (logo, colors)
- [ ] Update email signatures, proposal templates, and contracts

**HR & Culture**

- [ ] Distribute Nuvini Code of Conduct to all employees (Owner: Integration Lead)
- [ ] Review employment contracts and flag non-standard clauses
- [ ] Assess compensation alignment with Nuvini portfolio benchmarks
- [ ] Identify key talent retention risk — escalate to CEO if needed

**Regulatory**

- [ ] Confirm LGPD compliance posture and gap analysis
- [ ] Verify all operating licenses are transferred/renewed

---

#### DAY 61–90: Integration & Performance

**Payroll & HR Systems**

- [ ] Migrate payroll to Nuvini standard (if applicable)
- [ ] Complete FGTS and e-Social alignment
- [ ] HR system integration or data export for reporting

**KPI & Reporting**

- [ ] Onboard company into Zuck KPI dashboard (Owner: Zuck)
- [ ] Define monthly KPIs: ARR, NRR, MRR, EBITDA, headcount
- [ ] Complete first Nuvini-format financial report (using Questor data)

**Compliance Calendar**

- [ ] Add company to Nuvini compliance calendar (Owner: Scheduler)
- [ ] Key dates: CND renewals, FGTS, Junta Comercial annual filing, tax deadlines
- [ ] Confirm statutory audit plan with Grant Thornton

**Earn-out Setup** (if applicable)

- [ ] Establish earn-out measurement framework (per SPA terms)
- [ ] Set up earn-out reporting with CFO and former owner

**90-Day Review**

- [ ] Integration status review with IC
- [ ] Outstanding items log
- [ ] Declare integration complete or extend timeline

---

### Phase 3: Cross-Agent Task Assignments

When generating the playbook, emit task alerts for other agents:

| Agent     | Trigger | Task                                         |
| --------- | ------- | -------------------------------------------- |
| Julia     | Day 1   | Add signatories to all bank accounts         |
| Julia     | Day 31  | Set up Questor ERP, onboard Grant Thornton   |
| Julia     | Day 31  | Set up Mútuo if needed (IOF, registration)   |
| Marco     | Day 1   | File Junta Comercial change of control       |
| Marco     | Day 1   | Confirm all SPA CPs are closed out           |
| Zuck      | Day 61  | Onboard company into KPI dashboard           |
| Scheduler | Day 61  | Add company deadlines to compliance calendar |

Output a cross-agent coordination section in the playbook with specific task descriptions and deadlines.

### Phase 4: Status Tracking (`status` subcommand)

1. Search memory for integration playbook data on this company.
2. If a Google Doc was created, read it: `mcp__google-workspace__sheets_find` or retrieve from memory.
3. Present a progress summary: completed tasks / total tasks by phase.
4. Flag overdue items (tasks past their day target based on closing date).
5. List next 5 actions due in the next 7 days.

### Phase 5: Memory Logging

Store integration parameters in memory:

- `mcp__memory__create_entities` with entity type `design-decision:nuvini-integration`
- Record: company name, closing date, Google Doc ID, key milestones

## Data Sources

| Source               | Purpose                                                 |
| -------------------- | ------------------------------------------------------- |
| Memory graph         | Deal data, pipeline context, prior integration patterns |
| Pipeline Sheet       | Deal stage confirmation (must be Closing stage)         |
| Google Docs (create) | Output integration playbook                             |
| Gmail                | Cross-agent notifications and welcome communications    |
| Current date tool    | Milestone date calculations from closing date           |

## 8 Prior Acquisitions Reference

Nuvini has closed 8 acquisitions. Key integration patterns learned:

- Banking authorization typically takes 5–7 business days.
- Junta Comercial filing: allow 15–30 days for processing.
- Questor ERP onboarding: typically 30–45 days.
- Grant Thornton onboarding: immediate but first full audit takes 60 days.
- Employee communication on Day 1 is critical — silence creates uncertainty.

## Error Handling

| Error                                       | Action                                                                      |
| ------------------------------------------- | --------------------------------------------------------------------------- |
| Closing date not provided                   | Default to today, flag to user                                              |
| No deal data found in memory                | Generate generic playbook, flag that deal-specific customization is missing |
| Cross-agent task notifications fail         | Log tasks in playbook doc only, remind user to notify agents manually       |
| Google Doc creation fails                   | Output playbook as markdown in chat                                         |
| Company already has an integration playbook | Alert user and ask if they want to create a new one or view existing        |

## Confidence Scoring

- **Green (>95%):** Task list structure, 90-day timeline, owner assignments. Auto-proceed.
- **Yellow (80–95%):** Specific milestone dates, Mútuo setup parameters, earn-out measurement. Human review required.
- **Red (<80%):** Non-standard acquisition types (e.g., asset-only deal with complex IP transfer, financial-regulated entity). Full review by legal and finance team required.

## Examples

```bash
# Interactive mode
/mna integration

# Generate for a specific company
/mna integration generate TechBrasil

# Check progress on an ongoing integration
/mna integration status TechBrasil

# Output checklist only
/mna integration checklist TechBrasil
```
