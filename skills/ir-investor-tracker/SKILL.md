---
name: ir-investor-tracker
description: "Investor relationship management CRM for NVNI Group Limited (NASDAQ: NVNI). Maintains a structured database of investors with interaction history, instrument details, capital deployed, materials sent, and engagement scores. Auto-logs interactions when IR emails are dispatched via AgentMail. Generates follow-up reminders for investors not contacted in 30+ days and produces engagement dashboards. All outputs are YELLOW confidence minimum and are subject to SEC Regulation FD compliance for foreign private issuers. Triggers on: investor tracker, investor CRM, investor follow-up, engagement score, investor contacts, LP tracking."
argument-hint: "[investor-name or 'all'] [--dashboard | --follow-ups | --engagement | --log-interaction | --add-investor]"
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
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_appendText
  - mcp__google-workspace__docs_replaceText
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__gmail_search
  - mcp__google-workspace__gmail_get
  - mcp__google-workspace__gmail_send
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__calendar_listEvents
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__search_nodes
  - mcp__memory__open_nodes
  - mcp__memory__add_observations
  - mcp__memory__create_entities
  - mcp__memory__create_relations
tool-annotations:
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__docs_appendText: { idempotentHint: false }
  mcp__google-workspace__docs_replaceText: { idempotentHint: false }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
  mcp__google-workspace__gmail_search: { readOnlyHint: true }
  mcp__google-workspace__gmail_get: { readOnlyHint: true }
  mcp__google-workspace__gmail_send:
    { openWorldHint: true, idempotentHint: false }
  mcp__google-workspace__gmail_createDraft: { idempotentHint: false }
  mcp__google-workspace__calendar_listEvents: { readOnlyHint: true }
  mcp__memory__search_nodes: { readOnlyHint: true }
  mcp__memory__open_nodes: { readOnlyHint: true }
  mcp__memory__add_observations: { idempotentHint: false }
  mcp__memory__create_entities: { idempotentHint: false }
  mcp__memory__create_relations: { idempotentHint: false }
invocation-contexts:
  user-direct:
    verbosity: high
    confirmDestructive: true
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    confirmDestructive: false
    outputFormat: structured
memory: user
---

# ir-investor-tracker — Investor Relationship CRM

**Agent:** Bella
**Entity:** NVNI Group Limited (NASDAQ: NVNI)
**Purpose:** Maintain a living CRM of all NVNI investors and prospective investors. Track every touchpoint — emails, meetings, materials distributed, capital deployed — and surface follow-up actions. All outputs that contain non-public information or will be shared externally must comply with SEC Regulation FD and applicable disclosure rules for foreign private issuers filing on Form 20-F.

## Usage

```
/ir-investor-tracker all --dashboard
/ir-investor-tracker "Investor Name" --log-interaction
/ir-investor-tracker all --follow-ups
/ir-investor-tracker all --engagement
/ir-investor-tracker --add-investor
```

## Sub-commands

| Command             | Description                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------- |
| `--dashboard`       | Full CRM summary: investor list, capital by instrument, last contact dates, open follow-ups |
| `--follow-ups`      | List all investors not contacted in 30+ days, sorted by days since last interaction         |
| `--engagement`      | Engagement score report: rank all investors by activity, responsiveness, and capital tier   |
| `--log-interaction` | Record a new interaction (email, meeting, call, materials sent) for a named investor        |
| `--add-investor`    | Add a new investor record with full profile fields                                          |

---

## Process

### Phase 1: Load Investor Database

Call `mcp__google-workspace__time_getCurrentDate` to anchor relative date calculations.

Locate the Investor CRM master sheet via `sheets_find` using query: `name contains 'Investor CRM' or name contains 'IR Contacts'`. Fall back to `drive_search` with `name contains 'Investor' and mimeType = 'application/vnd.google-apps.spreadsheet'`.

The CRM sheet contains the following columns per investor record:

| Field               | Type         | Description                                              |
| ------------------- | ------------ | -------------------------------------------------------- |
| `investor_id`       | string       | Unique identifier (e.g., INV-001)                        |
| `name`              | string       | Individual name                                          |
| `entity`            | string       | Firm, fund, or holding company name                      |
| `type`              | enum         | Individual, Institutional, Family Office, Strategic      |
| `country`           | string       | Country of residence / domicile                          |
| `email`             | string       | Primary contact email                                    |
| `instrument`        | enum         | Convertible Note, PIPE, Debenture, Warrant, Common Stock |
| `amount_usd`        | number       | Capital deployed or committed (USD)                      |
| `entry_date`        | date         | Date of initial investment or first contact              |
| `last_contact_date` | date         | Date of most recent logged interaction                   |
| `materials_sent`    | string       | Deck version(s) and Q&A documents sent                   |
| `follow_up_status`  | enum         | Open, Pending Response, Closed, Prospect                 |
| `engagement_score`  | number 0-100 | Computed score (see Engagement Scoring section)          |
| `notes`             | string       | Freeform notes, last discussed topics                    |

### Phase 2: Mode Execution

#### `--dashboard`

1. Load all rows from CRM sheet via `sheets_getText` or `sheets_getRange`.
2. Compute summary statistics:
   - Total investors by type and instrument.
   - Total capital deployed by instrument category.
   - Count of investors by follow-up status.
   - Count of investors with no contact in 30+ / 60+ / 90+ days.
3. Render dashboard output (see Output Format).

#### `--follow-ups`

1. Load last_contact_date for all investors.
2. Calculate days since last contact relative to today.
3. Filter to investors where days since contact >= 30.
4. Sort descending by days since contact.
5. For each: suggest a follow-up action (check-in email, send updated deck, schedule call).
6. Output follow-up task list with draft subject lines.

#### `--engagement`

1. Compute engagement score for each investor using the scoring matrix below.
2. Rank all investors from highest to lowest score.
3. Flag tier: Tier 1 (score >= 70), Tier 2 (40-69), Tier 3 (< 40).
4. Surface "at risk" investors: Tier 1 or 2 with no contact in 45+ days.

Engagement Score Components:

| Factor                               | Max Points |
| ------------------------------------ | ---------- |
| Capital deployed (>$500K = 30 pts)   | 30         |
| Response rate to emails (historical) | 20         |
| Meeting frequency (last 12 months)   | 20         |
| Materials opened / requests received | 15         |
| Days since last contact (recency)    | 15         |

Deduct 10 pts if follow_up_status = "Pending Response" for >14 days.

#### `--log-interaction`

Prompt (or accept as arguments) the following:

- Investor name or ID
- Interaction type: email | meeting | call | materials-sent | inbound-inquiry
- Date (default: today)
- Summary (1-3 sentence description)
- Materials sent (if any): deck version, Q&A document name
- Follow-up action required (yes/no, if yes: description and due date)

Steps:

1. Locate the investor record in the CRM sheet.
2. Update `last_contact_date` to today's date.
3. Append interaction to the Communication Log sheet (separate tab or doc).
4. If materials sent: update `materials_sent` field.
5. If follow-up required: add to follow-up queue with due date.
6. Update `engagement_score` based on new interaction.
7. `mcp__memory__add_observations` on the relevant investor entity in memory graph.

Auto-log trigger: When Bella dispatches an IR email via AgentMail or Gmail, scan the recipient against the CRM and auto-create a `--log-interaction` entry of type `email` with the email subject and send date.

#### `--add-investor`

Collect required fields (name, entity, email, instrument, amount_usd, entry_date). Validate:

- Email format is valid.
- Instrument is one of the allowed enum values.
- Amount is numeric USD.
- No duplicate email in existing CRM.

Append new row to CRM sheet. Create memory entity: `investor:{slug-name}` with observations for capital tier, instrument, and entry date. Create relation: `ir-investor-tracker → tracks → investor:{slug-name}`.

### Phase 3: Regulation FD Compliance Check

Before generating any output that will be emailed or shared outside the IR team:

1. Scan output for non-public financial data (specific revenue figures not yet disclosed in SEC filings, undisclosed M&A activity, unreleased earnings).
2. If detected: flag as RED and require explicit human approval before distribution.
3. All investor communications must be consistent with information in the most recent 20-F, 6-K, or press release on file.
4. Confirm via `drive_search` that referenced materials (deck version, Q&A) have been previously cleared for investor distribution.

---

## Data Sources

| Source                       | Tool                              | Data Retrieved                               |
| ---------------------------- | --------------------------------- | -------------------------------------------- |
| Investor CRM Sheet           | `sheets_find` + `sheets_getRange` | Investor records, contact dates, instruments |
| Communication Log Sheet      | `sheets_getText`                  | Historical interaction log                   |
| ir:capital-register          | `sheets_find` + `sheets_getRange` | Instrument details, amounts, maturity dates  |
| Gmail / AgentMail Sent Items | `gmail_search`                    | Auto-detection of sent IR emails             |
| Calendar                     | `calendar_listEvents`             | Logged investor meetings                     |
| Memory Graph                 | `memory__search_nodes`            | Cached investor entities and relations       |

Drive search for CRM: `name contains 'Investor CRM' and mimeType = 'application/vnd.google-apps.spreadsheet'`

---

## Output Format

### Dashboard (`--dashboard`)

```
INVESTOR CRM DASHBOARD — NVNI — {date}
=======================================

CAPITAL DEPLOYED:
  Convertible Notes:   $X.XM  (N investors)
  PIPE:                $X.XM  (N investors)
  Debentures:          $X.XM  (N investors)
  Warrants:            N outstanding (exercise price: $X.XX)
  Total Active:        $XX.XM across N investors

FOLLOW-UP STATUS:
  Open:                N investors
  Pending Response:    N investors (avg N days waiting)
  No contact 30+ days: N investors  ← ACTION REQUIRED
  No contact 60+ days: N investors  ← URGENT

ENGAGEMENT TIERS:
  Tier 1 (score >= 70): N investors
  Tier 2 (score 40-69): N investors
  Tier 3 (score < 40):  N investors

TOP 5 INVESTORS BY ENGAGEMENT SCORE:
  1. {Name} ({Entity}) — Score: XX — Last contact: X days ago
  ...

CONFIDENCE: YELLOW — Internal use only. SEC Regulation FD applies to all external distribution.
```

### Follow-Up List (`--follow-ups`)

```
INVESTOR FOLLOW-UP LIST — NVNI — {date}
========================================
Investors requiring contact (30+ days since last interaction):

  Priority  Investor              Entity               Days  Last Topic          Suggested Action
  --------  --------------------  -------------------  ----  ------------------  --------------------------------
  URGENT    {Name}                {Entity}              92   Q3 deck sent        Schedule earnings call
  HIGH      {Name}                {Entity}              61   Intro meeting       Send Q4 deck + follow-up email
  MEDIUM    {Name}                {Entity}              34   Capital call Q&A    Check-in email

DRAFT SUBJECT LINES AVAILABLE: run --log-interaction to record outreach.
CONFIDENCE: YELLOW — Internal use only.
```

### Engagement Report (`--engagement`)

```
INVESTOR ENGAGEMENT REPORT — NVNI — {date}
===========================================
Scoring period: last 12 months

  Rank  Investor              Score  Tier  Capital   Instrument         Alert
  ----  --------------------  -----  ----  --------  -----------------  ------------------
  1     {Name}                  87    T1   $X.XM     Convertible Note
  2     {Name}                  74    T1   $X.XM     PIPE
  ...
  N     {Name}                  28    T3   $X.XM     Common Stock       At risk: 67 days

AT-RISK INVESTORS (Tier 1/2, no contact 45+ days): N
CONFIDENCE: YELLOW — Internal analytics only.
```

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                                       |
| ------ | --------- | ------------------------------------------------------------------------------ |
| Green  | > 95%     | Auto-proceed (internal read-only queries only)                                 |
| Yellow | 80–95%    | Human review required before any external communication — ALL investor outputs |
| Red    | < 80%     | Full manual verification required — block external distribution                |

**All investor-facing outputs are YELLOW confidence minimum.** Downgrade to RED if:

- Any capital figure cannot be traced to the ir:capital-register or a signed instrument document.
- Output includes non-public financial data not yet filed with the SEC.
- Regulation FD scan detects selective disclosure risk.
- CRM data is older than 7 days without a confirmed refresh.

---

## Integration

| Agent / Skill          | Role                                                         |
| ---------------------- | ------------------------------------------------------------ |
| ir:capital-register    | Source of truth for instrument type, amounts, and maturities |
| AgentMail / Gmail      | Auto-log sent IR emails as CRM interactions                  |
| ir-deck-updater        | Reference deck version when logging materials sent           |
| ir-qna-draft           | Log Q&A documents sent to investors                          |
| ir-press-release-draft | Confirm disclosure status before investor outreach           |
| Marco                  | Legal review for Regulation FD compliance on communications  |
| Scheduler              | Trigger weekly follow-up reminder scan                       |

---

## Examples

```
/ir-investor-tracker all --dashboard
→ Full CRM overview: capital by instrument, engagement tiers, urgent follow-ups

/ir-investor-tracker all --follow-ups
→ Sorted list of investors needing contact, with suggested outreach actions

/ir-investor-tracker "John Smith" --log-interaction
→ Record new interaction: prompts for type, date, summary, materials sent

/ir-investor-tracker all --engagement
→ Ranked engagement score table with at-risk investor alerts

/ir-investor-tracker --add-investor
→ Interactive prompt to add new investor to CRM and memory graph
```
