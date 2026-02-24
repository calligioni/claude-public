---
description: Run quick triage analysis on potential M&A target
argument-hint: [company-name]
allowed-tools: Read, Bash, WebFetch, TaskCreate, TaskUpdate, TaskList
---

## Argument Syntax
- `$0` - First argument
- `$1` - Second argument
- `$ARGUMENTS` - Full argument string
- `$ARGUMENTS[0]` - Indexed access

# M&A Triage

Run quick triage analysis on a potential acquisition target.

## Process
1. Ask user for company financial metrics
2. Call triage_deal MCP tool
3. Present score (0-10) and recommendation
4. Identify strengths, weaknesses, and red flags
5. Recommend next steps

## Usage
```
/triage
```

## Required Information
- Company name
- Revenue (millions)
- EBITDA (millions)

## Optional Information
- Growth rate (%)
- EBITDA margin (%)
- Churn rate
- Customer count
- Business model
- Market vertical

## Output
- Overall score (0-10)
- Recommendation (PROCEED/REVIEW/REJECT)
- Scoring breakdown
- Strengths and weaknesses
- Red flags
- Strategic fit assessment
- Next step recommendation
