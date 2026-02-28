---
name: portfolio-reporter
description: Generate comprehensive portfolio financial reports and presentations from individual company Excel files. Consolidates financial data from multiple Nuvini portfolio companies and creates executive-ready presentations with monthly and quarterly support.
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
tool-annotations:
  Bash: { readOnlyHint: false, idempotentHint: false }
memory: user
---

# Portfolio Financial Reporter

Generate comprehensive portfolio financial reports and presentations from individual company Excel files. This skill consolidates financial data from multiple Nuvini portfolio companies and creates executive-ready presentations.

**Version 2.0** - Now supports:

- Interactive mode (run without arguments)
- Monthly AND quarterly reports
- Organized output folders by period
- AI-generated visuals using Gemini (Nano Banana)

## When to Use This Skill

Use this skill when:

- The user wants to generate a monthly or quarterly portfolio update presentation
- The user needs to consolidate financial data from multiple company Excel files
- The user asks for a "portfolio report", "portfolio update", or "monthly financials"
- The user provides company financial Excel files and wants them consolidated

Trigger phrases:

- "Generate portfolio report"
- "Create portfolio presentation"
- "Consolidate financials"
- "Monthly portfolio update"
- "Quarterly portfolio update"
- "/portfolio-report"

## Quick Start

### Interactive Mode (Recommended)

Simply run without arguments:

```bash
python portfolio_reporter.py
```

This will interactively ask for:

1. Report type (Monthly or Quarterly)
2. Year and period (month/quarter)
3. Company file locations
4. Output directory
5. Visual generation options

### CLI Mode

Monthly report:

```bash
python portfolio_reporter.py \
  --type monthly \
  --period "December 2025" \
  --directory /path/to/company/files
```

Quarterly report:

```bash
python portfolio_reporter.py \
  --type quarterly \
  --quarter 4 \
  --period "2025" \
  --directory /path/to/company/files
```

With AI visuals (requires GEMINI_API_KEY):

```bash
GEMINI_API_KEY=xxx python portfolio_reporter.py --visuals
```

## Output Structure

Reports are organized by period:

```
output/
├── December/                      # Monthly: /{Month}/
│   ├── Consolidated_Summary_Dec_2025.xlsx
│   └── Portfolio_Update_Dec_2025.pptx
├── Q4_2025/                       # Quarterly: /Q{N}_{Year}/
│   ├── Consolidated_Summary_Q4_2025.xlsx
│   └── Portfolio_Update_Q4_2025.pptx
```

## Portfolio Companies (6 Fixed)

1. Mercos
2. Effecti
3. Ipê Digital
4. Datahub
5. OnClick
6. Leadlovers

## Workflow

### Phase 1: File Collection

Ask the user to provide the financial files. Accept either:

1. **File uploads** - Direct Excel file uploads
2. **Google Drive links** - Links to Excel files on Google Drive
3. **Local file paths** - Paths to Excel files on the local system

Prompt the user:

```
I'll generate your Portfolio Financial Report. Please provide the company financial files in one of these ways:

1. **Upload files** - Drag and drop Excel files here
2. **Google Drive links** - Paste shareable links to Excel files
3. **Local paths** - Provide file paths to Excel files on your system

Which companies should I include? (Default: Mercos, Effecti, Ipê Digital, Datahub, OnClick, Leadlovers)

What reporting period? (e.g., "January-July 2025" or "Jul 2025")
```

### Phase 2: Data Extraction

For each company file, extract data from these sheets:

#### From Monthly Analysis Sheets (`Análise_Resultado_MMYY`)

- Receita Bruta (Gross Revenue)
- Receita Líquida (Net Revenue)
- Deduções (Deductions)
- Lucro Bruto (Gross Profit)
- EBITDA
- Lucro Líquido (Net Profit)
- Depreciation & Amortization

#### From `KPI_Real` Sheet

- Total Clientes (Active Clients)
- % Churn
- MRR
- ARPU
- LTV
- CAC
- LTV/CAC
- NDR (Net Dollar Retention)
- Rule of 40

#### Key Financial Line Item Mappings (Portuguese → English)

| Portuguese          | English         |
| ------------------- | --------------- |
| Receita Bruta       | Gross Revenue   |
| Receita Líquida     | Net Revenue     |
| Deduções            | Deductions      |
| Lucro Bruto         | Gross Profit    |
| Custos Operacionais | Operating Costs |
| Despesas            | Expenses        |
| EBITDA              | EBITDA          |
| Lucro Líquido       | Net Profit      |
| Margem Bruta        | Gross Margin    |
| Margem EBITDA       | EBITDA Margin   |
| Free Cash Flow      | Free Cash Flow  |

### Phase 3: Consolidation

Create a consolidated summary that:

1. Sums all company revenues, costs, and profits
2. Calculates portfolio-level margins
3. Computes weighted averages for ratios
4. Tracks month-over-month and year-over-year changes

Output: `consolidated_summary.xlsx` with structure matching the template:

- DRE (Income Statement) section
- Balanço (Balance Sheet) section
- Fluxo de Caixa (Cash Flow) section
- KPI section

### Phase 4: Presentation Generation

Generate a PowerPoint presentation with exactly this structure:

#### Slide 1: Title

- "NUVINI Portfolio Financial Performance"
- "[Month] [Year] Results & Strategic Outlook"
- "Portfolio Update [Month] [Year]"
- "Year-to-Date Performance Review"

#### Slide 2: Executive Summary

**Header KPIs (5 boxes):**

- Gross Revenue (Jan-[Month])
- Net Revenue (Jan-[Month])
- EBITDA (Jan-[Month])
- EBITDA Margin
- Free Cash Flow

**Two columns:**

- Left: Key Performance Insights (5 bullet points)
- Right: Strategic Outlook Q[X] [Year] (5 bullet points)

#### Slide 3: Consolidated Financial Overview

**Header KPIs (4 boxes):**

- Gross Revenue with subtitle
- Net Revenue with conversion rate
- EBITDA with margin
- Free Cash Flow with FCF conversion

**Content:**

- Financial Waterfall Chart (Gross Revenue → Deductions → Net Revenue → COGS → Gross Profit → OpEx → EBITDA → D&A + Tax → FCF)
- Key Financial Insights (5 bullet points)

#### Slide 4: Month vs Previous Month Comparison

**Header KPIs (4 boxes):**

- Gross Revenue (Month) with MoM %
- Net Revenue (Month) with MoM %
- EBITDA (Month) with MoM %
- Companies with Positive Growth (X/6)

**Content:**

- Monthly Performance Trend line chart (Jan-Month)
- Company Performance (MoM) cards for each company

#### Slide 5: Portfolio Performance Dashboard

**Header KPIs (4 boxes):**

- Portfolio Rule of 40
- Avg EBITDA Margin
- Avg YoY Growth
- Companies Above 40 (X/6)

**Content:**

- Rule of 40 Scatter Plot (X: YoY Growth, Y: EBITDA Margin)
- Company Rankings list with Rule of 40 scores

#### Slide 6: Revenue Analysis

**Header KPIs (4 boxes):**

- Total Net Revenue (Jan-Month)
- Total Gross Revenue (Jan-Month)
- Average Monthly Revenue
- Portfolio Companies count

**Content:**

- Horizontal bar chart: Net Revenue by Company

#### Slide 7: Profitability Analysis

**Header KPIs (4 boxes):**

- Portfolio Gross Margin
- Portfolio EBITDA Margin
- Companies >35% EBITDA (X/6)
- Companies >65% Gross (X/6)

**Content:**

- Table with Company, Gross Margin (bar), EBITDA Margin (bar)
- 3 insight bullet points

#### Slide 8: Cash Flow and Liquidity

**Header KPIs (4 boxes):**

- Jan-Month Free Cash Flow
- FCF Conversion Rate
- Q[X] FCF
- Positive FCF Companies (X/6)

**Content:**

- Quarterly FCF bar chart
- FCF table by quarter with YoY change
- 4 insight bullet points

#### Slides 9-14: Company Deep Dives (one per company)

**Header KPIs (8 boxes):**

- Net Revenue (Jan-Month)
- EBITDA (Jan-Month)
- [Month] EBITDA
- [Month] Revenue
- EBITDA Margin
- YoY Growth OR Gross Margin
- Active Clients OR July Revenue
- FCF (Jan-Month) OR Churn Rate

**Content:**

- Monthly Performance line chart (Net Revenue + EBITDA)
- Key Performance Insights OR Strengths/Focus Areas

#### Slide 15: Portfolio Summary Table

Full table with columns:

- Company
- Net Revenue (Jan-Month)
- EBITDA (Jan-Month)
- EBITDA Margin
- YoY Growth
- Gross Margin
- FCF (Jan-Month)
- Rule of 40
- Status (Strong/Growth/Turnaround/Recovery)

3 footer insights

#### Slide 16: Strategic Outlook

6 company cards (2 rows x 3 columns) each with:

- Company name + icon
- 3 strategic initiatives

Portfolio-Wide Initiatives section (3 bullet points)

### Phase 5: Output

Deliver:

1. `consolidated_summary.xlsx` - Full financial consolidation
2. `Portfolio_Update_[Month]_[Year].pptx` - Executive presentation

## Design Specifications

### Colors (Nuvini Brand)

- Primary Blue: #1E3A8A (headers, titles)
- Light Blue: #DBEAFE (KPI boxes background)
- Green: #10B981 (positive values, growth)
- Red: #EF4444 (negative values, decline)
- Orange: #F59E0B (caution/turnaround)
- Text: #1F2937 (dark gray)

### Typography

- Titles: Bold, 28-36pt
- KPI Values: Bold, 24-32pt
- Body: Regular, 12-14pt
- Footer: Light, 10pt

### Chart Colors by Company

- Mercos: #3B82F6 (Blue)
- Effecti: #10B981 (Green)
- Ipê Digital: #F59E0B (Orange)
- Datahub: #6366F1 (Indigo)
- OnClick: #EF4444 (Red)
- Leadlovers: #6B7280 (Gray)

### Number Formatting

- Currency: R$XX.XM (millions) or R$XX.XK (thousands)
- Percentages: XX.X%
- Growth: +XX.X% (green) or -XX.X% (red)
- Whole numbers: X,XXX

## PDF Handling

For PDFs over 10 pages, use the `pages` parameter when reading: `Read(file_path="doc.pdf", pages="1-5")`. Maximum 20 pages per request.

## Error Handling

If data is missing:

- Use "N/A" for unavailable metrics
- Note which companies have incomplete data
- Proceed with available data and flag gaps

If file format is unexpected:

- Attempt to locate key sheets by name patterns
- Search for key row labels to find data
- Ask user to verify correct file was provided

## Example Usage

```
User: Generate portfolio report for August 2025
```
