# Agent Skills

This directory contains custom Agent Skills for Claude Code. Skills are specialized capabilities that Claude loads automatically when relevant to your task.

## Available Skills

### 1. **Committee Presenter**

**Location:** `./committee-presenter/`

Creates professional PowerPoint presentations for M&A board approval in Nuvini brand style.

**Capabilities:**

- Executive dashboards with key metrics
- Financial highlights and transaction structure
- Risk assessment matrices with mitigation strategies
- 100-day integration plans
- Exit strategy scenarios

**Formats:**

- **5-slide Summary** - Quick board decisions
- **20+ slide Full Analysis** - Comprehensive review

**Required Inputs:**

- Company name
- IRR (Internal Rate of Return)
- MOIC (Multiple on Invested Capital)
- Total investment amount
- Current EBITDA

**Brand Standards:**

- Primary Blue: #1B4F8C
- Accent Teal: #00A19C
- Highlight Orange: #FF8C42
- Fonts: Montserrat (headers), Open Sans (body)
- Quality: McKinsey/BCG professional standard

**Usage Example:**

```
Create a board summary for TechBrasil:
- IRR: 35%
- MOIC: 4.2x
- Investment: R$90M
- Current EBITDA: R$15M
```

---

### 2. **M&A Proposal Generator**

**Location:** `./mna-proposal-generator/`

Generates comprehensive M&A financial proposals with dual-perspective analysis (acquirer + target).

**Capabilities:**

- IRR and MOIC calculations
- Payment schedules with earnout structures
- Debt financing models (PIK, amortizing)
- Dual-perspective analysis (buyer and seller view)
- Excel model generation with formulas
- Sensitivity analysis
- Exit scenario modeling

**Required Inputs:**

- Company name
- EBITDA by year (historical and projected)

**Optional Inputs:**

- Revenue by year
- Purchase multiple (default: 6.0x)
- Cash at closing % (default: 60%)
- Deferred payment % (default: 40%)
- Earnout multiple (default: 3.0x)
- Debt terms (duration, rate, type)
- Exit assumptions

**Hurdle Rates:**

- Minimum IRR: 20%
- Minimum MOIC: 2.5x
- Maximum Leverage: 4.0x EBITDA
- Minimum DSCR: 1.5x

**Outputs:**

- Excel financial model
- Acquirer perspective (IRR, MOIC, payback period)
- Target perspective (payment schedule, total consideration)
- Debt amortization schedule
- 7-year cash flow projections

**Usage Example:**

```
Generate a proposal for TechBrasil:
- 2024: R$50M revenue, R$15M EBITDA
- 2025: R$60M revenue, R$18M EBITDA
- 2026: R$72M revenue, R$22M EBITDA
```

---

### 3. **Triage Analyzer**

**Location:** `./triage-analyzer/`

Analyzes M&A opportunities and scores them 0-10 against Nuvini's investment criteria.

**Evaluation Criteria:**

#### Financial Health (35 points)

- EBITDA Margin: ≥40% (15 pts), ≥30% (10 pts), ≥20% (5 pts)
- Revenue Growth: ≥30% (10 pts), ≥20% (7 pts), ≥10% (3 pts)
- Cash Conversion: ≥80% (10 pts), ≥60% (7 pts)

#### Business Model (25 points)

- Recurring Revenue: ≥95% (10 pts), ≥80% (7 pts)
- Churn Rate: <5% (10 pts), ≤8% (7 pts)
- Customer Base: >500 (5 pts), >100 (3 pts)

#### Market Position (20 points)

- Vertical focus identification (8 pts)
- Market leadership indicators (7 pts)
- Customer base size (5 pts)

#### Strategic Fit (20 points)

- Portfolio synergies (10 pts)
- Integration complexity (5 pts)
- Scale potential (5 pts)

**Red Flags (Auto-Disqualifiers):**

- Not SaaS/Software business
- Not Brazil-focused
- EBITDA < R$5M or > R$100M
- Churn rate > 15%
- Cash conversion < 60%

**Outputs:**

- Overall score (0-10)
- Recommendation: PROCEED / REVIEW / REJECT
- Scoring breakdown by category
- Identified strengths and weaknesses
- Red flags
- Strategic fit assessment
- Recommended next steps

**Usage Example:**

```
Triage this opportunity:
- Company: TechBrasil
- Revenue: R$50M
- EBITDA: R$15M (30% margin)
- Growth: 25% YoY
- Model: SaaS, tax tech vertical
- Churn: 6%
- Recurring revenue: 95%
```

---

### 4. **Portfolio Reporter**

**Location:** `./portfolio-reporter/`

Generates comprehensive Nuvini portfolio financial reports and presentations from individual company Excel files.

**Capabilities:**

- Consolidates financial data from 6 portfolio companies (Mercos, Effecti, Ipê Digital, Datahub, OnClick, Leadlovers)
- Monthly and quarterly report generation
- Executive-ready PowerPoint presentations (16 slides)
- AI-generated visuals using Gemini (optional)
- Organized output folders by period

**Triggers:**

- "portfolio report", "portfolio update", "portfolio presentation"
- "consolidate financials", "monthly portfolio", "quarterly portfolio"
- `/portfolio-report`

**Slide Structure:**

1. Title
2. Executive Summary
3. Consolidated Financial Overview
4. Month vs Previous Month Comparison
5. Portfolio Performance Dashboard (Rule of 40)
6. Revenue Analysis
7. Profitability Analysis
8. Cash Flow and Liquidity
   9-14. Company Deep Dives (one per company)
9. Portfolio Summary Table
10. Strategic Outlook

**Outputs:**

- `Consolidated_Summary_{Period}_{Year}.xlsx` - Full financial consolidation
- `Portfolio_Update_{Period}_{Year}.pptx` - Executive presentation

**Usage Example:**

```bash
# Interactive mode
python portfolio_reporter.py

# CLI mode
python portfolio_reporter.py --type monthly --period "July 2025" --directory /path/to/files

# With AI visuals
GEMINI_API_KEY=xxx python portfolio_reporter.py --visuals
```

---

### 5. **Financial Data Extractor** (Legacy)

**Location:** `./financial-data-extractor.skill`

Extracts financial data from various formats (PDF, Excel, text).

**Note:** This is a legacy skill. Consider migrating to the newer SKILL.md format.

---

## M&A Workflow

The skills work together in a sequential workflow:

```
1. TRIAGE → Score opportunity (triage-analyzer)
   ↓ (If score ≥ 7)
2. PROPOSAL → Generate financial model (mna-proposal-generator)
   ↓ (If IRR ≥ 20%)
3. PRESENTATION → Create board deck (committee-presenter)
   ↓
4. BOARD APPROVAL
```

## Installation

### Global Installation

Skills in this directory can be installed globally:

```bash
# Copy to global skills directory
cp -r ./committee-presenter ~/.claude/skills/
cp -r ./mna-proposal-generator ~/.claude/skills/
cp -r ./triage-analyzer ~/.claude/skills/
```

### Project-Specific Installation

For project-specific skills:

```bash
# Copy to project .claude directory
cp -r ./committee-presenter /path/to/project/.claude/skills/
```

## Creating Custom Skills

### Skill Structure

```
skill-name/
├── SKILL.md          # Main skill definition (required)
├── scripts/          # Helper scripts (optional)
└── templates/        # Templates or reference files (optional)
```

### SKILL.md Format

```markdown
# Skill Name

## Name

Short skill name

## Description

Brief description of what this skill does and when to use it

## When to Use This Skill

- Bullet points of use cases

## Required Inputs

- List of required parameters

## Optional Inputs

- List of optional parameters with defaults

## Output

Description of what the skill produces

## Implementation

How the skill works (MCP tools, Python modules, etc.)

## Examples

Real-world usage examples
```

### Frontmatter (Optional)

Add YAML frontmatter for metadata:

```yaml
---
name: skill-name
description: Brief description
version: 1.0.0
allowed-tools:
  - Read
  - Write
  - Bash
---
```

## Usage in Claude Code

Skills activate automatically when Claude detects relevance to your request:

```
# Triage a deal (activates triage-analyzer)
"Analyze this M&A opportunity: TechCo, R$50M revenue, R$15M EBITDA, 25% growth"

# Generate proposal (activates mna-proposal-generator)
"Create a financial proposal for the TechCo acquisition"

# Create board deck (activates committee-presenter)
"Generate a board presentation for the TechCo deal"
```

You can also explicitly invoke skills:

```
"Use the triage-analyzer skill to evaluate this deal"
```

## Best Practices

### Skill Design

1. **Single Responsibility** - Each skill should do one thing well
2. **Clear Triggers** - Make description specific so Claude knows when to use it
3. **Progressive Disclosure** - Start with metadata, load details as needed
4. **Reusable** - Design for multiple contexts, not single use cases

### Skill Naming

- Use kebab-case for directory names
- Make names descriptive: `mna-proposal-generator` not `proposal`
- Avoid generic names that might conflict

### Documentation

- Clear description of when to use the skill
- Document all inputs (required and optional)
- Provide real-world examples
- Include expected outputs

### Integration

- Skills can call MCP tools
- Skills can reference Python scripts
- Skills can include templates or reference files
- Keep heavy computation in scripts, not SKILL.md

## MCP Integration

These skills integrate with the `nuvini-mna` MCP server:

**Triage Analyzer** → `mcp__nuvini-mna__triage_deal`
**Proposal Generator** → `mcp__nuvini-mna__generate_proposal`
**Committee Presenter** → `mcp__nuvini-mna__create_presentation`

See `../mcp-servers/nuvini-mna/README.md` for MCP server documentation.

## Testing Skills

### List Available Skills

In Claude Code:

```
"What skills are available?"
```

### Test Skill Activation

```
"Use the [skill-name] to [task description]"
```

### Check Skill Content

```bash
# View skill definition
cat ~/.claude/skills/skill-name/SKILL.md
```

### Debug Skills

- Check `~/.claude/debug/` for logs
- Verify skill SKILL.md is well-formed
- Ensure description is specific enough for Claude to match

## Resources

- [Agent Skills Documentation](https://docs.claude.com/en/docs/agents-and-tools/agent-skills)
- [Skills Engineering Blog](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Official Skills Repository](https://github.com/anthropics/skills)
- [Skills Explained Guide](https://www.claude.com/blog/skills-explained)
