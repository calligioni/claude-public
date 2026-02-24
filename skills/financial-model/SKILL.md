---
description: Create M&A financial proposal with IRR/MOIC analysis
argument-hint: [company-name]
allowed-tools: Read, Write, Bash, TaskCreate, TaskUpdate, TaskList
---

## Argument Syntax
- `$0` - First argument
- `$1` - Second argument
- `$ARGUMENTS` - Full argument string
- `$ARGUMENTS[0]` - Indexed access

# Generate Financial Model

Create comprehensive M&A financial proposal with IRR/MOIC analysis.

## Process
1. Gather historical and projected financials
2. Configure deal terms (or use defaults)
3. Call generate_proposal MCP tool
4. Export Excel model
5. Present key metrics and validation results

## Usage
```
/financial-model
```

## Required Information
- Company name
- EBITDA by year (historical + projected)

## Optional Information
- Revenue by year
- Purchase multiple (default: 6.0x)
- Cash at closing % (default: 60%)
- Earnout multiple (default: 3.0x)
- Custom output path

## Output
- IRR and MOIC calculations
- Payment schedule
- Debt structure analysis
- Returns validation (vs 20% IRR, 2.5x MOIC hurdles)
- Excel model with formulas
- Text report

## Deal Structure (Default)
- 60% cash at closing
- 40% deferred (Year 1)
- 3.0x earnout on EBITDA growth
- 6-year debt at 9% PIK
