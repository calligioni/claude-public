---
name: compliance-board-package
description: "Compile and distribute board meeting packages for NVNI. Auto-aggregates materials from all Nuvini OS agents (financials from Julia, M&A from Cris, compliance from Marco, KPIs from Zuck, capital from Bella), formats as a professional Google Doc board package, and distributes 5 business days before the meeting. Triggers on: board package, board meeting, board materials, prepare board deck, director package."
argument-hint: "[generate|status|distribute]"
user-invocable: true
context: fork
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_appendText
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_getRange
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__time_getCurrentDate
  - mcp__google-workspace__calendar_listEvents
  - mcp__memory__create_entities
  - mcp__memory__search_nodes
  - mcp__memory__add_observations
  - mcp__memory__open_nodes
  - mcp__memory__read_graph
tool-annotations:
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__google-workspace__gmail_createDraft:
    { openWorldHint: true, idempotentHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__docs_appendText: { idempotentHint: false }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__calendar_listEvents: { readOnlyHint: true }
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

# compliance-board-package — Board Meeting Package Compiler

**Agent:** Scheduler
**Entity:** NVNI Group Limited
**Trigger:** 5 business days before scheduled board meeting, or on-demand via command

You are a board package compilation agent. Your job is to aggregate materials from all active Nuvini OS agents, compile them into a structured board-ready document, and distribute to directors on the appropriate schedule.

## Commands

| Command              | Description                                                   |
| -------------------- | ------------------------------------------------------------- |
| `generate` (default) | Compile full board package from all agent data sources        |
| `status`             | Show what sections are complete, pending, or missing          |
| `distribute`         | Send completed board package to directors and board secretary |

---

## Phase 1: Identify Next Board Meeting

1. Call `mcp__google-workspace__time_getCurrentDate` for TODAY.
2. Call `mcp__google-workspace__calendar_listEvents` on the primary Nuvini calendar to find the next event containing `"Board Meeting"` or `"Board of Directors"`.
3. Record: `meeting_date`, `meeting_time`, `attendees`.
4. Compute: `days_until_meeting = meeting_date - TODAY`.
5. If `days_until_meeting <= 5`: auto-trigger generation (unless already generated for this meeting).
6. If no meeting found in next 90 days: log warning and proceed with on-demand generation if manually invoked.

---

## Phase 2: Section Compilation

Compile each section by pulling from the relevant agent's data source. Mark each section as `COMPLETE`, `PARTIAL`, or `MISSING`.

### Section 1: Meeting Agenda

Retrieve from:

- Calendar event description (if structured)
- Memory: `mcp__memory__search_nodes` with query `"board agenda {next_meeting_date}"`
- Prior package (look for last board package Google Doc and extract agenda)

Default agenda structure if not pre-defined:

```
1. Call to Order and Quorum
2. Approval of Prior Meeting Minutes
3. Financial Highlights (CEO/CFO)
4. M&A Pipeline Update
5. Compliance and Legal Update
6. Portfolio Performance Review
7. Capital Structure Update
8. New Business
9. Action Items Review
10. Adjournment
```

### Section 2: Financial Highlights

Source: Julia's data (finance-closing-orchestrator output)

Pull from Google Sheet `"Nuvini Financial Dashboard"` or `"Board Financial Summary"`:

- Net Revenue (consolidated, current month vs. prior month vs. budget)
- Gross Margin (%)
- EBITDA (adjusted, trailing 12 months)
- Cash position (total, by entity)
- Burn rate (if applicable)
- Working capital summary
- Key variances vs. budget and prior year

Format as narrative + table:

```
FINANCIAL HIGHLIGHTS — {MONTH} {YEAR}
Revenue:  R$XX.XM   (+X% MoM, +X% YoY)  [vs budget: +X%]
EBITDA:   R$XX.XM   (XX% margin)
Cash:     $X.XM USD + R$XX.XM BRL
```

### Section 3: M&A Pipeline Summary

Source: Cris's pipeline data

Pull from Google Sheet `"M&A Pipeline"` or `"Deal Register"`:

- Total deals in pipeline: count by stage
- New deals added since last board meeting
- Deals advancing (stage change)
- Deals dropped / killed
- Active LOIs or signed term sheets
- Expected closing timelines for stage 4+ deals

Format:

```
M&A PIPELINE — {MONTH} {YEAR}
Pipeline: {N} active deals
  - Stage 1 (Screening):    {N}
  - Stage 2 (Preliminary):  {N}
  - Stage 3 (Diligence):    {N}
  - Stage 4 (Negotiation):  {N}
  - Stage 5 (Closing):      {N}

New since last meeting: {N} (list names/sectors)
Near-term closings: [deal name — expected close date]
```

### Section 4: Compliance Status

Source: Marco's legal-compliance-calendar output

Pull from `"Nuvini Regulatory Calendar"` sheet:

- All RED and CRITICAL items (must address in board meeting)
- Upcoming ORANGE items for board awareness
- Open items from prior meeting
- Any active NASDAQ deficiency or SEC inquiry
- Notable jurisdiction-specific events

Format:

```
COMPLIANCE STATUS — {TODAY}
CRITICAL: {N} items
  - [Item] — due {date} — {days} days
RED: {N} items
  - [Item] — due {date} — {days} days
ORANGE (awareness): {N} items
```

### Section 5: Portfolio Performance Summary

Source: Zuck's KPI data (portfolio-nor-ingest output)

Pull from `"Portfolio Dashboard"` or `"NOR Dashboard"` Google Sheet:

- NOR by company (current month vs. prior month)
- MoM growth rate per company
- Portfolio aggregate NOR
- Companies above/below target
- Any companies with declining revenue (>5% MoM)

Format:

```
PORTFOLIO PERFORMANCE — {MONTH} {YEAR}
Portfolio NOR: R$XX.XM (+X% MoM)

Company Performance:
  Effecti:     R$X.XM  (+X%)  [ON TRACK]
  Leadlovers:  R$X.XM  (-X%)  [ALERT — declining]
  Ipê:         R$X.XM  (+X%)  [ON TRACK]
  ...
```

### Section 6: Capital Instruments Status

Source: Bella's ir-capital-register output

Pull from `"NVNI Capital Register"` sheet:

- Total debt outstanding
- Instruments maturing in next 90 days
- Any in-the-money convertible notes
- Warrant exercise activity
- Dilution summary

Format:

```
CAPITAL STRUCTURE — {TODAY}
Total Debt: $XX.XM
Instruments maturing <90 days: {N}
NVNIW warrants outstanding: XX.XM at $X.XX
Fully diluted share count: XXX.XM
```

### Section 7: Action Items from Prior Meeting

Pull from memory: `mcp__memory__search_nodes` with query `"board action items prior meeting"`

Display:

```
PRIOR MEETING ACTION ITEMS
  [ ] Item 1 — Owner: {name} — Status: OPEN/CLOSED
  [x] Item 2 — Owner: {name} — Status: CLOSED on {date}
  [ ] Item 3 — Owner: {name} — Status: IN PROGRESS
```

---

## Phase 3: Generate Google Doc

1. Create new Google Doc via `mcp__google-workspace__docs_create`:
   - Title: `NVNI Board Package — {meeting_date} — CONFIDENTIAL`
2. Append each section in order using `mcp__google-workspace__docs_appendText`.
3. Include cover page:

   ```
   NVNI Group Limited
   Board of Directors Meeting
   {meeting_date} | {meeting_time}
   CONFIDENTIAL AND PRIVILEGED

   Prepared by: Nuvini OS (Scheduler Agent)
   Generated: {TODAY}
   ```

4. Log document ID and link in memory.

---

## Command: status

Check which sections are complete without generating the full package:

```
BOARD PACKAGE STATUS — Meeting: {meeting_date} ({N} days away)
==============================================================
Section 1: Meeting Agenda          [COMPLETE / MISSING]
Section 2: Financial Highlights    [COMPLETE / PARTIAL — missing cash position]
Section 3: M&A Pipeline            [COMPLETE / MISSING — pipeline sheet not found]
Section 4: Compliance Status       [COMPLETE]
Section 5: Portfolio Performance   [PARTIAL — 2 companies missing NOR data]
Section 6: Capital Instruments     [COMPLETE]
Section 7: Prior Action Items      [PARTIAL — N items need status update]

Overall: X/7 sections complete
Recommended: Generate now if meeting is within 5 business days
```

---

## Command: distribute

1. Verify the board package Google Doc exists (from prior `generate` run).
2. Confirm all 7 sections are at least PARTIAL (not MISSING).
3. If any section is MISSING: warn before distributing. Require explicit confirmation.
4. Send email to board distribution list:

Recipients:

- Board members (from `Board_Composition` tab or memory)
- Board Secretary
- CEO, CFO (cc)
- Legal (cc)

**Email template:**

```
Subject: NVNI Board Package — {meeting_date}

Dear Board Members,

Please find attached the board package for the NVNI Board of Directors meeting
scheduled for {meeting_date} at {meeting_time}.

Board Package: [Google Doc Link]

Please review all sections prior to the meeting. Any questions or corrections
should be directed to the Board Secretary by {review_deadline}.

Meeting Details:
  Date: {meeting_date}
  Time: {meeting_time}
  Location / Dial-in: [from calendar event]

This document is confidential and intended solely for NVNI Board members.

— Scheduler (Nuvini OS)
On behalf of: {board_secretary_name}
```

---

## Data Sources

| Source                    | Tool                   | Purpose                             |
| ------------------------- | ---------------------- | ----------------------------------- |
| Nuvini Calendar           | `calendar_listEvents`  | Find next board meeting             |
| Financial Dashboard Sheet | `sheets_getRange`      | Section 2: Financials               |
| M&A Pipeline Sheet        | `sheets_getRange`      | Section 3: M&A                      |
| Regulatory Calendar Sheet | `sheets_getRange`      | Section 4: Compliance               |
| Portfolio Dashboard Sheet | `sheets_getRange`      | Section 5: Portfolio                |
| Capital Register Sheet    | `sheets_getRange`      | Section 6: Capital                  |
| Memory graph              | `memory__search_nodes` | Agenda, action items, prior package |
| Today's date              | `time_getCurrentDate`  | Meeting countdown                   |

## Error Handling

- **Board meeting not found in calendar**: Proceed with on-demand generation. Do not auto-distribute.
- **Section data unavailable**: Mark as MISSING. Include placeholder with `[DATA PENDING — {source_agent}]` notation.
- **Document creation fails**: Retry once. If still failing, output full package as formatted text to terminal.
- **Distribution list empty**: Do not send. Prompt user to provide director email list.
- **Package already generated for same meeting**: Warn before regenerating. Offer to append updates only.

## Confidence Scoring

| Tier   | Threshold | Behavior                                 |
| ------ | --------- | ---------------------------------------- |
| Green  | > 95%     | Auto-proceed with section                |
| Yellow | 80–95%    | Human review before inclusion            |
| Red    | < 80%     | Mark section as NEEDS REVIEW in document |

**All financial, regulatory, and capital structure content defaults to Yellow regardless of confidence.** Board package must be reviewed by CFO and Legal before distribution. Distribution command requires explicit human approval when any section is below Green.

## Examples

```
/compliance board-package
→ Generates full board package for next scheduled meeting

/compliance board-package status
→ Shows completion status for each section

/compliance board-package distribute
→ Sends completed package to board distribution list
```
