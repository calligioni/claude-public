---
description: Run complete end-to-end M&A analysis on a company opportunity
argument-hint: [company-name or PDF path]
allowed-tools: Read, Write, Bash, WebFetch, TaskCreate, TaskUpdate, TaskList, Task
---

## Argument Syntax
- `$0` - First argument
- `$1` - Second argument
- `$ARGUMENTS` - Full argument string
- `$ARGUMENTS[0]` - Indexed access

# Analyze M&A Deal

Run complete end-to-end M&A analysis on a company opportunity.

## Process
1. Gather company data from user or documents
2. Run triage analysis (score 0-10)
3. If score ≥ 7, generate financial proposal
4. If IRR ≥ 20%, create board presentation
5. Provide final recommendation

## Usage
```
/analyze-deal
```

The assistant will:
- Ask for company details (or extract from provided documents)
- Run triage scoring
- Generate proposal if qualified
- Create board deck if returns meet hurdles
- Deliver complete analysis package

## Output
- Triage report with score and recommendation
- Excel financial model (if qualified)
- PowerPoint board presentation (if hurdles met)
- Next steps and recommendations
