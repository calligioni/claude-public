---
name: ir-qna-draft
description: "Generate formal investor Q&A draft responses from the Nuvini knowledge base. Accepts a free-text investor question or a common topic (revenue growth, M&A strategy, capital structure, regulatory status). Searches across all agent knowledge domains (Julia for financials, Cris for M&A, Marco for legal, Zuck for portfolio, Scheduler for compliance), drafts a response in formal IR language with specific data citations, assigns a confidence score, and flags any answer touching forward-looking statements or MNPI for mandatory human review. Triggers on: investor question, Q&A, investor query, IR response, draft answer, investor FAQ."
argument-hint: "'<question text>' [--topic revenue|ma|capital|regulatory|portfolio] [--formal | --brief]"
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
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__search_nodes
  - mcp__memory__open_nodes
  - mcp__memory__add_observations
  - mcp__memory__read_graph
tool-annotations:
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__memory__search_nodes: { readOnlyHint: true }
  mcp__memory__open_nodes: { readOnlyHint: true }
  mcp__memory__read_graph: { readOnlyHint: true }
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

# ir-qna-draft — Investor Q&A Response Drafter

**Agent:** Bella
**Entity:** NVNI Group Limited (NASDAQ: NVNI)
**Purpose:** Draft formal investor Q&A responses using Nuvini's full knowledge base. Pulls financial, operational, legal, and M&A data from relevant agents and source documents. Produces a structured draft response in SEC-compliant IR language with data citations, confidence score, and mandatory flags for forward-looking statements (FLS) and Material Non-Public Information (MNPI). All outputs require human review before transmission to any investor or analyst.

## CRITICAL COMPLIANCE RULES

1. **Forward-Looking Statements (FLS):** Any response containing projections, guidance, targets, or future-oriented language MUST include the SEC safe harbor disclaimer and be flagged RED.
2. **MNPI:** If the question or any sourced data point touches undisclosed material information (unannounced M&A, undisclosed financials, regulatory decisions not yet public), HALT draft and flag immediately. Do NOT include MNPI in any draft output. Escalate to `ir@nuvini.com.br` and `legal@nuvini.com.br`.
3. **Regulation FD:** Responses must not selectively disclose material information to individual investors. Flag any answer that would constitute selective disclosure if distributed to a single analyst without simultaneous public release.
4. **Foreign Private Issuer:** NVNI files on Form 20-F and is exempt from certain Reg FD provisions, but applies FD principles as best practice. All material information must be publicly disclosed before inclusion in investor communications.

---

## Usage

```
/ir qna-draft 'What was NVNI revenue growth in the last quarter?'
/ir qna-draft 'What is the M&A strategy going forward?' --topic ma --formal
/ir qna-draft 'How is the capital structure positioned?' --topic capital --brief
/ir qna-draft --topic regulatory
```

## Sub-commands

| Flag       | Description                                                                                   |
| ---------- | --------------------------------------------------------------------------------------------- |
| `--topic`  | Pre-load the relevant knowledge domain: `revenue`, `ma`, `capital`, `regulatory`, `portfolio` |
| `--formal` | Use full formal IR language, longer response, all citations listed                            |
| `--brief`  | Concise 3-5 sentence response suitable for verbal/informal Q&A                                |

---

## Process

### Phase 1: Question Classification

Parse the question and determine:

1. **Primary topic domain:** revenue / growth, M&A strategy, capital structure, regulatory / compliance, portfolio operations, market / trading, guidance / outlook.
2. **FLS risk:** Does the question ask about future performance, targets, or strategy? → Pre-flag as potential FLS.
3. **MNPI risk:** Does the question reference unannounced transactions, undisclosed events, or internal forecasts not yet published? → Escalate immediately if yes.
4. **Data sources required:** Map topic to agents and documents.

Topic-to-source mapping:

| Topic             | Primary Sources                              | Secondary Sources             |
| ----------------- | -------------------------------------------- | ----------------------------- |
| Revenue / Growth  | Julia (FP&A), Zuck (NOR), Sheets             | Last 20-F / earnings release  |
| M&A Strategy      | Cris (pipeline), Docs (LOI summaries)        | Press releases, 6-K filings   |
| Capital Structure | Bella (ir-capital-register), Sheets          | 20-F notes, warrants register |
| Regulatory        | Marco (legal), Scheduler (compliance cal)    | NASDAQ notices, SEC EDGAR     |
| Portfolio Ops     | Zuck (portfolio dashboard), NOR Sheets       | Portfolio company data rooms  |
| Market / Trading  | Memory (NVNI price), WebSearch (NASDAQ)      | EDGAR, Bloomberg              |
| Guidance          | Julia (FP&A), management approved statements | ALWAYS flag as FLS            |

### Phase 2: Data Retrieval

Based on topic classification, retrieve data from relevant sources:

- **Financial data:** `sheets_find` for Management Report, FP&A consolidation, or NOR dashboard. Extract specific figures with period labels.
- **M&A data:** `drive_search` for pipeline documents, `docs_getText` for LOI or deal summaries. Do not include MNPI — only reference publicly disclosed transactions.
- **Capital data:** `sheets_find` for Capital Register. Use ir-capital-register output if available in memory.
- **Regulatory:** `memory__search_nodes` for compliance calendar entries. `WebSearch` for public NASDAQ or SEC notices re: NVNI.
- **Portfolio:** Extract per-company KPIs from NOR dashboard for the 8 portfolio companies: Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions.

### Phase 3: Draft Response

Structure the response as follows:

**Header block (internal use only):**

```
QUESTION: {verbatim question}
TOPIC: {classified topic}
DATE: {today}
FLS FLAG: YES / NO
MNPI FLAG: YES / NO — {reason if YES}
CONFIDENCE: GREEN / YELLOW / RED
REVIEW REQUIRED: YES (always)
```

**Draft response body (investor-facing):**

Use formal IR language. Always write in third person referring to "the Company" or "NVNI." Cite specific figures with period labels. Example:

> For the [period], NVNI reported consolidated net revenue of $[X]M, representing [Y]% growth year-over-year. This performance was driven by [key factors].

If the question cannot be answered with available public data, state: "The Company does not provide guidance on [topic]. Investors should refer to the Company's most recent Annual Report on Form 20-F and 6-K filings for historical data."

**Citation block:**

```
DATA SOURCES:
  - [Document name] — [Sheet/tab] — [Date of data]
  - [Document name] — [Sheet/tab] — [Date of data]
```

**FLS disclaimer (append if FLS flagged):**

```
FORWARD-LOOKING STATEMENTS DISCLAIMER:
This response contains forward-looking statements within the meaning of Section 27A of the Securities Act of 1933 and Section 21E of the Securities Exchange Act of 1934. These statements involve known and unknown risks and uncertainties that may cause actual results to differ materially from those expressed or implied. NVNI Group Limited undertakes no obligation to update forward-looking statements.
```

### Phase 4: Save and Route

1. Create a Google Doc via `docs_create` titled `IR Q&A Draft — {topic} — {date}` in the IR/QA Drive folder.
2. Log Q&A draft in memory (`memory__add_observations`) on entity `ir-qna-draft` with question summary and confidence score.
3. Notify `ir@nuvini.com.br` via `gmail_send` with the draft and review request if confidence is YELLOW or RED.

---

## Data Sources

| Source                            | Tool                              | Data Retrieved                              |
| --------------------------------- | --------------------------------- | ------------------------------------------- |
| FP&A / Management Report (Sheets) | `sheets_find` + `sheets_getRange` | Revenue, EBITDA, cash, growth rates         |
| NOR Dashboard (Sheets)            | `sheets_find` + `sheets_getRange` | Per-subsidiary NOR and KPIs                 |
| M&A Pipeline (Docs / Sheets)      | `drive_search` + `docs_getText`   | Public deal activity only                   |
| NVNI Capital Register (Sheets)    | `sheets_find` + `sheets_getRange` | Debt, diluted shares, warrants              |
| Compliance Calendar               | `memory__search_nodes`            | Upcoming disclosure deadlines               |
| Memory                            | `memory__search_nodes`            | NVNI price, prior Q&A drafts, company facts |
| SEC EDGAR / NASDAQ                | `WebSearch`                       | Public filings, notices, press releases     |

Drive search queries:

- IR Q&A folder: `name contains 'IR Q&A' and mimeType = 'application/vnd.google-apps.folder'`
- Last earnings release: `name contains 'Earnings Release' and mimeType = 'application/vnd.google-apps.document'`

---

## Output Format

```
IR Q&A DRAFT — NVNI — {date}
==============================

QUESTION: {question}
TOPIC: {topic}
FLS FLAG: {YES/NO}
MNPI FLAG: {NO — verified against public record}
CONFIDENCE: {YELLOW / RED}

---

DRAFT RESPONSE (for IR review):

{Formal response text}

---

DATA SOURCES:
  - {source 1}
  - {source 2}

{FLS DISCLAIMER if applicable}

---

REVIEW REQUIRED: This draft must be reviewed by the IR team and legal counsel before transmission.
Document saved: {Google Doc URL}
```

---

## Common Topic Templates

### Revenue Growth

Pull from Julia / FP&A: consolidated revenue for current and prior period. Compute YoY growth. Reference last Form 20-F fiscal year as baseline. Never project future revenue without management-approved language.

### M&A Strategy

Reference publicly disclosed strategy from last 20-F or press releases only. For pipeline, state only: "The Company continues to evaluate acquisition opportunities in the Brazilian SaaS market. The Company does not comment on specific targets or timelines." Do not reference any undisclosed LOIs or targets.

### Capital Structure

Pull from ir-capital-register: total debt, maturity profile, NVNIW warrants outstanding. Reference share count from last SEC filing as base. State diluted share count with warrant and convertible note assumptions.

### Regulatory / Listing Status

Reference NVNI's NASDAQ listing status (NVNI common shares, NVNIW warrants). Check memory and WebSearch for any active NASDAQ notices. If compliance notices are active, flag RED and route to legal before drafting.

### Portfolio Operations

Reference aggregate metrics across 8 portfolio companies. Do not disclose individual company figures unless already public in a Form 20-F or 6-K filing.

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                    |
| ------ | --------- | ----------------------------------------------------------- |
| Green  | > 95%     | Auto-proceed — NOT applicable for any investor-facing draft |
| Yellow | 80–95%    | Human review required before any investor communication     |
| Red    | < 80%     | Full legal + IR review required; do not distribute          |

**ALL investor Q&A outputs are YELLOW confidence minimum.** Outputs are automatically downgraded to RED when:

- The question involves forward-looking statements or guidance.
- Any cited data point is preliminary, unaudited, or from a source that has not been publicly filed.
- The question touches on MNPI (output is halted; only escalation notice is produced).
- Regulatory or listing status topics are present.
- Any M&A target is named.

---

## Integration

| Agent / Skill       | Role                                                  |
| ------------------- | ----------------------------------------------------- |
| Julia               | Financial data: revenue, EBITDA, cash, growth rates   |
| Cris                | M&A public deal data; pipeline is MNPI — not included |
| Marco               | Legal review for regulatory questions, FLS sign-off   |
| Zuck                | Portfolio operational KPIs from NOR dashboard         |
| Scheduler           | Compliance calendar — disclosure blackout periods     |
| ir-capital-register | Capital structure data for capital-topic Q&A          |

---

## Examples

```
/ir qna-draft 'What drove revenue growth in Q3?'
→ Pulls Julia financials + NOR data, drafts formal response, YELLOW confidence

/ir qna-draft 'What is the M&A pipeline?' --topic ma --formal
→ Drafts public-only response, flags MNPI risk, routes to legal

/ir qna-draft 'What is the capital structure?' --topic capital --brief
→ Concise 3-5 sentence response from capital register data

/ir qna-draft 'What is your revenue guidance for next year?'
→ YELLOW+FLS flag, appends safe harbor disclaimer, routes to IR + legal
```
