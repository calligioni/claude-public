---
description: Create professional M&A board presentation deck
argument-hint: [company-name]
allowed-tools: Read, Write, Bash, TaskCreate, TaskUpdate, TaskList
---

## Argument Syntax
- `$0` - First argument
- `$1` - Second argument
- `$ARGUMENTS` - Full argument string
- `$ARGUMENTS[0]` - Indexed access

# Generate Board Presentation

Create professional M&A board presentation deck.

## Process
1. Collect deal metrics (from proposal or user)
2. Ask for presentation format (summary or full)
3. Call create_presentation MCP tool
4. Save PowerPoint deck
5. Summarize key slides and recommendation

## Usage
```
/generate-deck
```

## Required Information
- Company name
- IRR (as decimal, e.g., 0.35)
- MOIC (e.g., 4.2)
- Total investment (millions)
- Current EBITDA (millions)

## Optional Information
- Year 7 EBITDA projection
- Presentation format (summary/full)
- Custom output path

## Presentation Formats

### Summary (5 slides)
- Executive dashboard cover
- Financial highlights
- Risk assessment
- Key recommendations
- Next steps timeline

### Full (20+ slides)
All summary slides plus:
- Deal structure details
- Projections and assumptions
- Sensitivity analysis
- Due diligence priorities
- Integration framework
- Governance and monitoring
- Exit strategy
- Implementation roadmap

## Output
- PowerPoint presentation (Nuvini branded)
- Slide count
- File location
- Key recommendation
- Conditions for approval
