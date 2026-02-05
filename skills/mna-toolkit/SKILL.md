---
name: mna-toolkit
description: |
  Unified M&A toolkit for Nuvini Group acquisitions. Consolidates all M&A skills into one interface:
  - /mna triage - Score deals 0-10 against investment criteria
  - /mna extract - Extract financial data from PDFs/Excel
  - /mna proposal - Generate IRR/MOIC financial models
  - /mna analysis - Create 18-page investment analysis PDFs
  - /mna deck - Create board approval PowerPoint presentations
  - /mna aimpact - AI cost reduction analysis for targets
  Use for end-to-end M&A deal processing from initial screening to board approval.
argument-hint: "[triage|extract|proposal|analysis|deck|aimpact] [target]"
user-invocable: true
context: fork
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - WebFetch
  - WebSearch
  - TaskCreate
  - TaskUpdate
  - TaskList
---

# M&A Toolkit

Unified interface for all Nuvini M&A operations. This skill consolidates 6 specialized M&A capabilities into a single, streamlined workflow.

## Quick Reference

| Command         | Purpose                     | Output                       |
| --------------- | --------------------------- | ---------------------------- |
| `/mna triage`   | Score deal against criteria | JSON report with 0-10 score  |
| `/mna extract`  | Extract data from CIM/Excel | Structured JSON/CSV          |
| `/mna proposal` | Generate financial model    | Excel with IRR/MOIC          |
| `/mna analysis` | Create investment report    | 18-page PDF                  |
| `/mna deck`     | Create board presentation   | PowerPoint (5 or 20+ slides) |
| `/mna aimpact`  | AI cost reduction analysis  | Excel model + Word report    |

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    M&A DEAL PIPELINE                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. SCREENING          2. ANALYSIS           3. APPROVAL        │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │ /mna triage  │ ──► │ /mna extract │ ──► │ /mna proposal│    │
│  │ Score: 0-10  │     │ CIM data     │     │ IRR/MOIC     │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│        │                    │                    │              │
│        │ Score ≥ 7         │                    │ IRR ≥ 20%    │
│        ▼                    ▼                    ▼              │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │ /mna aimpact │     │ /mna analysis│     │ /mna deck    │    │
│  │ AI savings   │     │ 18-page PDF  │     │ Board PPT    │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. Triage Analysis (`/mna triage`)

Score M&A opportunities 0-10 against Nuvini investment criteria.

### Required Inputs

- Company name
- Revenue (annual, millions BRL)
- EBITDA (millions BRL)

### Optional Inputs

- Revenue growth rate (%)
- EBITDA margin (%)
- Recurring revenue %
- Churn rate (%)
- Customer count
- Business model (SaaS, Software, B2B)
- Market vertical

### Scoring Framework

| Category         | Max Points | Criteria                                       |
| ---------------- | ---------- | ---------------------------------------------- |
| Financial Health | 35         | EBITDA margin, revenue growth, cash conversion |
| Business Model   | 25         | Recurring revenue, churn rate, customer base   |
| Market Position  | 20         | Vertical focus, leadership indicators          |
| Strategic Fit    | 20         | Portfolio synergies, integration complexity    |

### Red Flags (Auto-Reject)

- Not SaaS/Software business
- Not Brazil-focused
- EBITDA <R$5M or >R$100M
- Churn >15%
- Cash conversion <60%

### Example

```
User: /mna triage
Company: TechBrasil
Revenue: R$50M, EBITDA: R$15M
Growth: 25%, SaaS, tax tech vertical

Output: Score 8.2/10 - PROCEED
- Strengths: Strong margins, vertical focus
- Risks: Customer concentration
- Next: Generate proposal
```

---

## 2. Financial Data Extraction (`/mna extract`)

Extract structured data from CIMs, financial statements, and Excel models.

### Supported Formats

- **PDF**: CIMs, financial statements, pitch decks, reports
- **Excel**: Financial models, data exports, projections

### PDF Page Ranges (Claude Code 2.1.30+)

For large CIMs (>10 pages), specify page ranges to avoid token limits and improve extraction accuracy:

```bash
# Read specific pages from large CIM
Read CIM.pdf with pages="10-20"

# Common page ranges for CIMs:
# - Executive Summary: pages 1-5
# - Financial Highlights: pages 10-15 (typical location)
# - Management/Team: pages 25-30
# - Appendix/Details: pages 40-50
```

**Why use page ranges?**

- Large PDFs (>10 pages) return a lightweight reference when @-mentioned
- Targeted extraction is faster and more accurate
- Reduces token usage for focused analysis

### Extraction Modes

- `figures` - Key financial metrics (revenue, EBITDA, etc.)
- `tables` - All tables with page numbers
- `all` - Complete extraction

### Model Selection

- **Sonnet 4.5**: Standard extraction (95% of tasks)
- **Opus 4.1**: High-stakes validation (>$25M deals, ambiguous docs)

### Example

```
User: /mna extract ProjectAlpha_CIM.pdf

Output:
{
  "company": "Project Alpha",
  "revenue_2024": 42000000,
  "ebitda_2024": 12600000,
  "ebitda_margin": 0.30,
  "recurring_revenue_pct": 0.92,
  "employees": 85,
  "customers": 450
}
```

---

## 3. Proposal Generation (`/mna proposal`)

Generate comprehensive financial models with IRR/MOIC calculations.

### Required Inputs

- Company name
- EBITDA by year (historical + projected)

### Default Deal Structure

- **Purchase**: 6.0x EBITDA
- **Cash at close**: 60%
- **Deferred**: 40% in Year 1
- **Earnout**: 3.0x on EBITDA growth
- **Debt**: 6-year bullet at 9% PIK

### Outputs

- IRR and MOIC calculations
- Payment schedule (target perspective)
- Sources & uses (acquirer perspective)
- Debt schedule
- Sensitivity analysis
- Excel model with formulas

### Hurdle Rates

- Minimum IRR: 20%
- Minimum MOIC: 2.5x
- Maximum leverage: 4.0x EBITDA

### Example

```
User: /mna proposal TechBrasil
EBITDA: 2024: R$15M, 2025: R$18M, 2026: R$22M

Output:
- IRR: 35.2%
- MOIC: 4.2x
- Purchase: R$90M (6.0x)
- Excel: TechBrasil_proposal.xlsx
```

---

## 4. Investment Analysis (`/mna analysis`)

Generate professional 18-page investment analysis PDF.

### Page Structure

| Page | Section                     |
| ---- | --------------------------- |
| 1    | Cover Page                  |
| 2    | Executive Summary           |
| 3    | Company Snapshot            |
| 4    | Product Portfolio           |
| 5    | Financial Performance       |
| 6    | Revenue Quality             |
| 7    | Client Portfolio            |
| 8    | Competitive Positioning     |
| 9    | Competitive Landscape       |
| 10   | SWOT Analysis               |
| 11   | Technology & Infrastructure |
| 12   | AI Development Roadmap      |
| 13   | Growth Strategy             |
| 14   | Management & Ownership      |
| 15   | Transaction Summary         |
| 16   | Risk Assessment             |
| 17   | Conclusion                  |
| 18   | Appendix                    |

### Data Sources

- Triage analysis results
- CIM extraction data
- AI-synthesized insights

### Example

```
User: /mna analysis TechBrasil (triage_id: abc123)

Output:
- File: investment_analysis_techbrasil_20250110.pdf
- Pages: 18
- Extraction quality: high
```

---

## 5. Board Presentation (`/mna deck`)

Create PowerPoint presentations for investment committee.

### Formats

**Summary (5 slides)**

1. Executive Dashboard
2. Financial Highlights
3. Risk Assessment
4. Recommendations
5. Next Steps

**Full Analysis (20+ slides)**
All summary slides plus:

- Deal structure details
- Financial deep-dive
- Sensitivity analysis
- Integration framework
- Exit strategy
- Implementation roadmap

### Brand Standards

- Primary Blue: #1B4F8C
- Accent Teal: #00A19C
- Highlight Orange: #FF8C42
- Font: Montserrat (headers), Open Sans (body)
- Quality: McKinsey/BCG standard

### Example

```
User: /mna deck TechBrasil
IRR: 35%, MOIC: 4.2x, Investment: R$90M

Output:
- File: TechBrasil_board_deck.pptx
- Slides: 5 (summary format)
- Recommendation: STRONGLY APPROVE
```

---

## 6. AI Impact Analysis (`/mna aimpact`)

Analyze AI cost reduction opportunities for acquisition targets.

### Purpose

Model potential cost savings from AI implementation post-acquisition.

### Analysis Categories

| Category         | AI Opportunity          | Typical Reduction |
| ---------------- | ----------------------- | ----------------- |
| Customer Support | Chatbots, automation    | 15-45%            |
| Sales            | Lead scoring, co-pilots | 8-25%             |
| Marketing        | Content, optimization   | 12-35%            |
| Finance/Admin    | Invoice processing      | 18-45%            |
| Infrastructure   | Auto-scaling            | 10-28%            |

### Three Scenarios

- **Conservative**: 8-18% reduction, <12mo payback
- **Moderate**: 15-30% reduction, <8mo payback
- **Aggressive**: 25-45% reduction, <6mo payback

### Outputs

- Excel model with NPV calculations
- Word document with recommendations
- Implementation roadmap (12 months)

### Example

```
User: /mna aimpact TechBrasil financials.xlsx

Output:
- Excel: TechBrasil_ai_cost_reduction.xlsx
- Word: TechBrasil_ai_recommendations.docx
- Conservative savings: R$2.1M/year
- Moderate savings: R$3.8M/year
- Aggressive savings: R$5.5M/year
```

---

## Atomic Tools vs Outcomes

### Agent-Native Design Principle

This skill follows the **Agent-native principle**: "Tools should be atomic primitives. Features are outcomes achieved by an agent operating in a loop."

### Atomic Tools Used

The mna-toolkit uses these atomic primitives:

- **Read** - Read CIMs, Excel files, previous analyses
- **Write** - Generate reports, proposals, presentations
- **Edit** - Modify financial models, update documents
- **Glob/Grep** - Find deal files, search for financial data
- **Bash** - Execute Python scripts, generate PDFs, run calculations
- **WebFetch/WebSearch** - Research companies, gather market data
- **TaskCreate/TaskUpdate/TaskList** - Track multi-step deal workflows

**Key insight**: The six sub-commands (`/mna triage`, `/mna extract`, etc.) are **entry points that describe desired outcomes**, not hardcoded workflow functions.

### Outcomes Achieved via Prompts

Each sub-command is an outcome:

1. **`/mna triage`** - Outcome: "Score this deal 0-10 against Nuvini criteria and identify red flags"
   - Agent uses Read to get deal data, applies scoring criteria via prompts, uses Write to create JSON report
   - Scoring criteria are in prompts, not hardcoded logic

2. **`/mna extract`** - Outcome: "Extract structured financial data from this document"
   - Agent uses Read to analyze PDF/Excel, follows extraction prompts, uses Write to create JSON/CSV
   - Extraction patterns are prompt-based, allowing flexibility for different document formats

3. **`/mna proposal`** - Outcome: "Generate IRR/MOIC financial model with Nuvini deal structure"
   - Agent calculates via Bash (Python scripts), follows Excel template prompts, uses Write for output
   - Deal structure parameters are in prompts, easily modified without code changes

4. **`/mna analysis`** - Outcome: "Create professional 18-page investment analysis PDF"
   - Agent synthesizes data from multiple sources, follows page-by-page prompts, uses Bash to generate PDF
   - Page structure is prompt-defined, not template-locked

5. **`/mna deck`** - Outcome: "Create board-quality PowerPoint with key metrics"
   - Agent selects relevant data, follows slide design prompts, uses Bash (python-pptx) to generate
   - Slide content adapts based on deal specifics, guided by prompts

6. **`/mna aimpact`** - Outcome: "Model AI cost reduction scenarios for this target"
   - Agent analyzes cost structure, applies AI opportunity prompts, calculates NPV via Bash
   - Scenario assumptions are prompt-defined, easily adjusted for different industries

### How to Modify Behavior via Prompts

**Want to change triage scoring criteria?**

Edit the scoring framework prompts (lines 92-98). Change the weights or add new categories:

```markdown
### Scoring Framework (Modified for SaaS Focus)

| Category         | Max Points | Criteria                                       |
| ---------------- | ---------- | ---------------------------------------------- |
| Financial Health | 30         | EBITDA margin, revenue growth, cash conversion |
| Business Model   | 30         | Recurring revenue, churn rate, NRR             |
| Market Position  | 25         | Vertical focus, market share, leadership       |
| Tech Stack       | 15         | Modern architecture, API-first, AI-ready       |
```

The agent will adapt scoring based on these updated prompts.

**Want different proposal assumptions?**

Modify the default deal structure prompts (lines 172-177):

```markdown
### Default Deal Structure (Modified)

- **Purchase**: 7.0x EBITDA (up from 6.0x for premium assets)
- **Cash at close**: 50% (more seller financing)
- **Deferred**: 30% in Year 1, 20% in Year 2
- **Earnout**: 2.5x on revenue growth (not EBITDA)
- **Debt**: 5-year amortizing at 8% (not PIK)
```

The agent's proposal calculations will reflect these new parameters.

**Want to add new analysis pages?**

Extend the page structure prompts (lines 216-235) with additional pages:

```markdown
| 19 | AI Integration Opportunities |
| 20 | Synergies with Portfolio |
| 21 | Go-to-Market Strategy |
```

The agent will generate content for these new pages following the pattern.

**Want different deck formats?**

Create new slide structure prompts beyond "Summary (5 slides)" and "Full (20+ slides)":

```markdown
### Formats

**Quick Pitch (3 slides)**

1. One-slide summary with key metrics
2. Investment thesis and deal structure
3. Risk/mitigation matrix

**Due Diligence Deep-Dive (40+ slides)**

- All full analysis slides
- Financial model walkthrough
- Customer concentration analysis
- Legal/regulatory review
- Integration planning timeline
```

**Want industry-specific triage criteria?**

Add conditional scoring based on vertical:

```markdown
### Industry-Specific Red Flags

**Tax/Accounting Software**

- Regulatory changes risk
- Professional certification dependencies

**HR Tech**

- Data privacy (LGPD) compliance critical
- Customer contract length <2 years

**FinTech**

- Banking partnerships required
- Regulatory approval timelines
```

### Contrast: Workflow-Shaped Anti-Pattern

**What this skill does NOT do:**

```python
# Anti-pattern: Hardcoded workflow tool
def mna_complete_analysis(company_name, cim_file):
    # Hardcoded steps
    triage = run_triage_logic(company_name)
    if triage.score < 7:
        return "REJECTED"

    data = extract_with_predefined_fields(cim_file)
    proposal = calculate_with_fixed_multiples(data)
    analysis = generate_from_locked_template(data, proposal)
    deck = create_slides_from_template(analysis)

    return {triage, data, proposal, analysis, deck}
```

**What this skill DOES:**

Each sub-command is an outcome-oriented prompt:

- "Evaluate this deal against Nuvini investment criteria and provide a scored recommendation"
- "Extract relevant financial metrics from this document, adapting to its structure"
- "Model the financial returns for this deal using Nuvini's typical structure"

The agent uses atomic tools (Read, Bash, Write) to achieve these outcomes. The workflow emerges from the agent's decision-making based on the document structure, financial data, and desired outcome.

### Example: Evolving Triage Criteria

**Scenario**: Nuvini wants to prioritize AI-ready companies starting Q2 2026.

**Without code changes**, update the triage prompt:

```markdown
### Scoring Framework (Updated Q2 2026 - AI Focus)

| Category         | Max Points | Criteria                                       |
| ---------------- | ---------- | ---------------------------------------------- |
| Financial Health | 30         | EBITDA margin, revenue growth, cash conversion |
| Business Model   | 25         | Recurring revenue, churn rate, customer base   |
| AI Readiness     | 25         | Data quality, API infra, AI use cases          |
| Strategic Fit    | 20         | Portfolio synergies, integration complexity    |

### AI Readiness Evaluation

Score 0-25 based on:

- Data infrastructure: APIs, clean datasets, real-time pipelines (10 pts)
- Current AI usage: ML models in production, AI features launched (8 pts)
- AI potential: Clear use cases, customer demand for AI features (7 pts)
```

The agent immediately adapts its triage scoring to include AI readiness assessment, asking relevant questions and evaluating companies differently, all without touching code.

### Session Tracking

Use `${CLAUDE_SESSION_ID}` to track analysis across sessions for comprehensive due diligence workflows.

### Directory Structure

Organize multiple document extractions per deal with session-specific directories:

```bash
# Create session-specific output directories
DEAL_DIR="deals/${COMPANY_NAME}/sessions/${CLAUDE_SESSION_ID}"
mkdir -p "$DEAL_DIR"

# All outputs tagged with session ID
TRIAGE_FILE="$DEAL_DIR/triage_${CLAUDE_SESSION_ID}.json"
EXTRACTION_FILE="$DEAL_DIR/extraction_${CLAUDE_SESSION_ID}.json"
PROPOSAL_FILE="$DEAL_DIR/proposal_${CLAUDE_SESSION_ID}.xlsx"
ANALYSIS_FILE="$DEAL_DIR/analysis_${CLAUDE_SESSION_ID}.pdf"
DECK_FILE="$DEAL_DIR/deck_${CLAUDE_SESSION_ID}.pptx"
```

### Cross-Referencing Sessions

Link extraction sessions with triage and proposal analyses:

```bash
# Create session manifest for cross-referencing
SESSION_MANIFEST="deals/${COMPANY_NAME}/session_manifest.json"

# Append session record
cat >> "$SESSION_MANIFEST" << EOF
{
  "session_id": "${CLAUDE_SESSION_ID}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workflow_type": "full_analysis",
  "related_sessions": ["<previous_triage_session>", "<cim_extraction_session>"],
  "outputs": ["triage.json", "extraction.json", "proposal.xlsx", "analysis.pdf"]
}
EOF
```

### Audit Trail for Due Diligence

Maintain complete audit trails for investment committee review:

```bash
# Create audit log with all session activities
AUDIT_LOG="deals/${COMPANY_NAME}/audit_trail.log"

# Log each action with session context
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SESSION=${CLAUDE_SESSION_ID} ACTION=triage SCORE=8.2 RECOMMENDATION=PROCEED" >> "$AUDIT_LOG"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SESSION=${CLAUDE_SESSION_ID} ACTION=extract SOURCE=CIM.pdf PAGES=45" >> "$AUDIT_LOG"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SESSION=${CLAUDE_SESSION_ID} ACTION=proposal IRR=35.2 MOIC=4.2" >> "$AUDIT_LOG"
```

### Benefits

- **Complete audit trail**: Every analysis tracked per session for compliance
- **Multi-session workflows**: Continue analysis across multiple Claude sessions
- **Team handoff**: Share session IDs for seamless collaboration
- **Parallel evaluation**: Run multiple deal analyses simultaneously
- **Historical reference**: Trace back any decision to its source session

## Complete Deal Workflow

### Phase 1: Initial Screening

```bash
# 1. Set up deal tracking
DEAL_DIR="deals/CompanyName_${CLAUDE_SESSION_ID}"
mkdir -p "$DEAL_DIR"

# 2. Triage the deal
/mna triage CompanyName revenue=50 ebitda=15 growth=25 > "$DEAL_DIR/triage.json"

# If score >= 7, proceed
```

### Phase 2: Deep Analysis

```bash
# 2. Extract CIM data
/mna extract CompanyName_CIM.pdf

# 3. Optional: AI cost analysis
/mna aimpact CompanyName_financials.xlsx
```

### Phase 3: Financial Modeling

```bash
# 4. Generate proposal (need IRR >= 20%)
/mna proposal CompanyName

# 5. Create investment analysis PDF
/mna analysis CompanyName
```

### Phase 4: Board Approval

```bash
# 6. Generate board deck
/mna deck CompanyName --format full
```

---

## Implementation Notes

### MCP Tools (if available)

- `mcp__nuvini-mna__triage_deal`
- `mcp__nuvini-mna__generate_proposal`
- `mcp__nuvini-mna__create_presentation`

### Script Locations

- Triage: `/Volumes/AI/Code/MNA/nuvini-ma-system-complete/triage-analyzer/`
- Proposal: `/Volumes/AI/Code/MNA/nuvini-ma-system-complete/mna-proposal-generator/`
- Presenter: `/Volumes/AI/Code/MNA/nuvini-ma-system-complete/committee-approval-presenter/`
- Extractor: `skills/mna-toolkit/scripts/`

### API Endpoints (if running)

- `POST /api/triages` - Create triage
- `POST /api/triages/{id}/generate-investment-analysis` - Generate PDF
- `GET /download/investment-reports/{filename}` - Download report

---

## Related Skills

This toolkit consolidates:

- `triage-analyzer` → `/mna triage`
- `financial-data-extractor` → `/mna extract`
- `mna-proposal-generator` → `/mna proposal`
- `investment-analysis-generator` → `/mna analysis`
- `committee-presenter` → `/mna deck`
- `aimpact` → `/mna aimpact`

The individual skills remain available for backward compatibility.
