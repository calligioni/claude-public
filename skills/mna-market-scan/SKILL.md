---
name: mna-market-scan
description: "Proactive deal sourcing via web intelligence for Nuvini Group's M&A pipeline. Performs periodic web searches for Brazilian B2B SaaS companies matching Nuvini's investment criteria (R$5M-100M revenue, Rule of 40 threshold, vertical fit). Sources from Crunchbase, LinkedIn, tech press (Startups.com.br, Distrito), M&A advisory newsletters, and founder networks. Scores candidates against Nuvini investment thesis and filters out companies already in the pipeline. Generates weekly target lists with preliminary scores and suggested outreach approaches. This is Arnold's first and primary skill — he is the operations and deal sourcing agent. Triggers on: market scan, deal sourcing, target search, pipeline generation, find targets, scout deals, prospecção."
argument-hint: "[vertical or 'b2b-saas'] [--criteria '...'] [--scan | --weekly-report | --add-to-pipeline | --exclusion-list]"
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
  - mcp__firecrawl__*
  - mcp__google-workspace__sheets_getText
  - mcp__google-workspace__sheets_getRange
  - mcp__google-workspace__sheets_find
  - mcp__google-workspace__docs_getText
  - mcp__google-workspace__docs_create
  - mcp__google-workspace__docs_appendText
  - mcp__google-workspace__drive_search
  - mcp__google-workspace__gmail_createDraft
  - mcp__google-workspace__time_getCurrentDate
  - mcp__memory__search_nodes
  - mcp__memory__open_nodes
  - mcp__memory__add_observations
  - mcp__memory__create_entities
  - mcp__memory__create_relations
tool-annotations:
  mcp__firecrawl__*: { readOnlyHint: true, openWorldHint: true }
  mcp__google-workspace__sheets_getText: { readOnlyHint: true }
  mcp__google-workspace__sheets_getRange: { readOnlyHint: true }
  mcp__google-workspace__sheets_find: { readOnlyHint: true }
  mcp__google-workspace__docs_getText: { readOnlyHint: true }
  mcp__google-workspace__docs_create: { idempotentHint: false }
  mcp__google-workspace__docs_appendText: { idempotentHint: false }
  mcp__google-workspace__drive_search: { readOnlyHint: true }
  mcp__google-workspace__gmail_createDraft: { idempotentHint: false }
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
---

# mna-market-scan — Proactive Deal Sourcing via Web Intelligence

**Agent:** Arnold
**Entity:** NVNI Group Limited (NASDAQ: NVNI) — M&A Operations
**Purpose:** Arnold's primary mission is proactive deal sourcing. This skill runs structured web intelligence scans to identify Brazilian B2B SaaS acquisition targets matching Nuvini's investment thesis before they surface in broker-originated processes. All identified candidates are YELLOW confidence and require human review before any contact or addition to the official M&A pipeline.

## Usage

```
/mna-market-scan b2b-saas --scan
/mna-market-scan b2b-saas --weekly-report
/mna-market-scan "Company Name" --add-to-pipeline
/mna-market-scan --exclusion-list
/mna-market-scan b2b-saas --criteria 'revenue > R$10M, Rule of 40 > 20'
```

## Sub-commands

| Command             | Description                                                                                             |
| ------------------- | ------------------------------------------------------------------------------------------------------- |
| `--scan`            | Run a fresh web intelligence scan against default or custom criteria; return scored candidate list      |
| `--weekly-report`   | Compile and format the weekly target list with scores, profiles, and suggested outreach; save to Drive  |
| `--add-to-pipeline` | Add a qualified candidate (pending human confirmation) to the mna-pipeline tracker                      |
| `--exclusion-list`  | View or update the exclusion list of companies already in pipeline, passed, or known non-fits           |
| `--criteria`        | Override default investment criteria for a custom scan (pass as quoted JSON or natural language string) |

---

## Process

### Phase 1: Load Investment Criteria and Exclusion List

Call `mcp__google-workspace__time_getCurrentDate` to timestamp the scan.

**Default Nuvini Investment Criteria:**

| Criterion           | Target                                                                    | Hard Minimum           |
| ------------------- | ------------------------------------------------------------------------- | ---------------------- |
| Geography           | Brazil (HQ or primary market)                                             | Brazil operations req. |
| Business model      | B2B SaaS / recurring revenue                                              | SaaS or SaaS-like ARR  |
| Annual revenue      | R$5M – R$100M (net)                                                       | R$3M net               |
| Revenue growth YoY  | >15%                                                                      | Positive               |
| Rule of 40          | >20 (Revenue growth % + EBITDA%)                                          | >0                     |
| Vertical fit        | HCM, ERP, logistics, agri, fintech, legal-tech, edtech, marketplace infra | Configurable           |
| Ownership structure | Founder-owned or PE-backed (1st fund seeking exit)                        | —                      |
| Team quality signal | Technical founder, LinkedIn-verifiable leadership                         | —                      |
| SaaS metrics        | NRR >90%, churn <15%/yr (estimated)                                       | —                      |

Load exclusion list from memory: `mcp__memory__search_nodes` query `mna-market-scan exclusion`. Also cross-check against the mna-pipeline active tracker sheet (`sheets_find`: `name contains 'Pipeline' and mimeType = 'application/vnd.google-apps.spreadsheet'`) to extract company names already in any pipeline stage.

If `--criteria` flag is passed, parse the custom criteria string and merge with defaults (overrides win).

### Phase 2: Web Intelligence Scan (`--scan`)

Run searches across all source channels in parallel. For each source, execute 3-5 targeted queries. Collect company names, URLs, and summary information. De-duplicate across sources.

#### Source Channels and Query Strategies

**Crunchbase / Startups.com.br:**

- `WebSearch`: "B2B SaaS Brazil 2024 2025 funding seed series A" + vertical terms
- `WebSearch`: "empresa SaaS B2B Brasil receita recorrente" + vertical terms
- `WebFetch` or `mcp__firecrawl__*` on result URLs to extract: company name, founding year, funding history, employee count, product description, headquarters

**Distrito Intelligence:**

- `WebSearch`: "Distrito radar SaaS Brazil B2B" + current year
- `WebFetch` on `https://distrito.me` relevant pages for SaaS company profiles
- `mcp__firecrawl__*` for deep extraction if JS-rendered content

**Tech Press (Startups.com.br, Startupi, Pipeline/The WIRED Brazil):**

- `WebSearch`: "startups SaaS B2B Brasil 2025 crescimento ARR MRR"
- `WebSearch`: "software empresarial Brasil vertical SaaS aquisição M&A 2025"
- `WebFetch` on article URLs to extract company mentions and financial signals

**LinkedIn (via WebSearch):**

- `WebSearch`: site:linkedin.com/company "B2B SaaS" Brazil + vertical keywords
- `WebSearch`: "founder CEO Brazil SaaS" + target verticals (for team quality signal)

**M&A Advisory and Broker Newsletters:**

- `WebSearch`: "assessoria M&A SaaS Brasil 2025 teaser" OR "processo competitivo SaaS Brasil"
- `WebSearch`: "Brazil software company acquisition 2025 deal" OR "SaaS Brazil M&A deal"
- `WebSearch`: "Fuse Capital Canary Kaszek portfolio exit 2025"

**Accelerator and Fund Portfolio Searches:**

- `WebSearch`: "ACE Startups portfolio B2B SaaS 2024"
- `WebSearch`: "Cubo Itaú startups SaaS B2B"
- `WebSearch`: "Softbank Brazil portfolio SaaS"
- `WebSearch`: "Redpoint eventures portfolio SaaS"

**Product Review Sites:**

- `WebSearch`: site:g2.com/categories "Brazil" "B2B" software reviews
- `WebSearch`: site:capterra.com.br SaaS empresarial

#### Per-Candidate Data Extraction

For each company identified, attempt to extract (via `WebFetch` or `mcp__firecrawl__*`):

| Field                   | Source                                      | Method               |
| ----------------------- | ------------------------------------------- | -------------------- |
| Company name            | Any source                                  | Direct extraction    |
| Website URL             | Any source                                  | Direct extraction    |
| Founded year            | Crunchbase / LinkedIn / website             | WebFetch / Firecrawl |
| Headquarters city       | LinkedIn / website                          | WebFetch             |
| Employee count (est.)   | LinkedIn                                    | WebSearch + WebFetch |
| Product category        | Website / G2                                | WebFetch / Firecrawl |
| Revenue estimate (est.) | Press, funding announcements, industry data | WebSearch            |
| Funding history         | Crunchbase / Startups.com.br                | WebFetch / Firecrawl |
| Investors               | Crunchbase                                  | WebFetch             |
| Founder names           | LinkedIn / website                          | WebFetch             |
| ARR/MRR signals         | Press quotes, pitch decks leaked, G2        | WebSearch            |
| Vertical / ICP          | Website / G2 category                       | WebFetch             |
| Recent news             | Google News                                 | WebSearch            |

### Phase 3: Score Candidates

Apply the Nuvini Candidate Scoring Matrix to each company identified. Maximum score: 100 points.

#### Scoring Matrix

| Dimension                 | Weight | Scoring Logic                                                                 |
| ------------------------- | ------ | ----------------------------------------------------------------------------- |
| Revenue range fit         | 25 pts | R$5M-R$100M = 25; R$3M-R$5M or R$100M-R$150M = 15; out of range = 0           |
| Revenue growth signal     | 15 pts | >30% YoY = 15; 15-30% = 10; <15% = 5; declining = 0                           |
| Rule of 40 signal         | 15 pts | >40 = 15; 20-40 = 10; 0-20 = 5; negative = 0                                  |
| Vertical fit              | 20 pts | Core vertical (HCM/ERP/logistics/agri/fintech) = 20; adjacent = 10; other = 5 |
| Team quality signal       | 10 pts | Technical founder + verifiable leadership = 10; partial = 5; unclear = 0      |
| Ownership structure       | 10 pts | Founder-owned = 10; PE first fund = 8; VC-backed (later stage) = 4            |
| Data quality / confidence | 5 pts  | All fields sourced = 5; partial data = 3; minimal data = 1                    |

Bonus points (up to +5): Active press coverage in last 90 days suggesting growth or liquidity event.
Penalty (-10): Company is in a regulated sector requiring special approvals (banking license, healthcare data).

**Minimum score to include in output:** 40 points.
**Minimum score to recommend for outreach:** 65 points.
**Minimum score to recommend for pipeline addition (pending review):** 70 points.

### Phase 4: Filter Against Exclusion List

Cross-reference all scored candidates against:

1. Companies in the active mna-pipeline (any stage, including Passed).
2. The Arnold exclusion list in memory (`mna-market-scan:exclusion-list` entity).
3. The 8 current portfolio companies: Effecti, Leadlovers, Ipê Digital, DataHub, Mercos, Onclick, Dataminer, MK Solutions.

Remove any matches from the output list. Log filtered count.

### Phase 5: Generate Outreach Approach

For candidates scoring >= 65, generate a suggested outreach approach:

- **Channel**: Cold email via Arnold's AgentMail inbox | LinkedIn InMail | warm intro via investor network
- **Angle**: "Nuvini acquires [vertical] SaaS leaders in Brazil" | "Growth capital + operational platform" | "Portfolio synergy with [relevant portfolio company]"
- **Subject line draft**: 1-2 options per candidate (DO NOT send — draft only)
- **Key talking points**: 2-3 points tailored to company stage and vertical

All outreach drafts are YELLOW confidence and must be reviewed and approved by the human team before any contact is initiated.

### Phase 6: Save and Report

**`--scan` mode:** Return scored candidate list in structured format. Save to memory: `mcp__memory__add_observations` on entity `mna-market-scan:scan-log` with scan date, query summary, and candidate count.

**`--weekly-report` mode:**

1. Create a Google Doc via `docs_create`: title `Market Scan — Weekly Targets — {date}` in folder `M&A/Market Scans/`.
2. Write full report (see Output Format).
3. `mcp__memory__add_observations` on `mna-market-scan:weekly-report-log`.

**`--add-to-pipeline` mode:**

1. Confirm the named company scored >= 70.
2. Check exclusion list — abort if already present.
3. In user-direct mode: require explicit human confirmation before adding.
4. Invoke `mna-pipeline` via note in output, providing the company name and preliminary score for Arnold to log in the pipeline tracker as "Stage: Sourced — Source: Market Scan".
5. Add company to exclusion list in memory to prevent re-discovery.

**`--exclusion-list` mode:**

- Load `mna-market-scan:exclusion-list` from memory.
- Display all entries with reason code (in-pipeline, passed, non-fit, competitor, regulated).
- Accept `--add "Company Name" --reason "..."` to append a new exclusion.

---

## Data Sources

| Source                  | Tool                             | Data Retrieved                                  |
| ----------------------- | -------------------------------- | ----------------------------------------------- |
| Crunchbase              | `WebSearch` + `WebFetch`         | Funding history, employee count, founding year  |
| Startups.com.br         | `WebSearch` + `WebFetch`         | Brazilian startup news, ARR signals, profiles   |
| Distrito                | `WebFetch` + `mcp__firecrawl__*` | Radar reports, SaaS company listings            |
| LinkedIn                | `WebSearch`                      | Team quality, headcount, founder background     |
| G2 / Capterra           | `WebSearch` + `WebFetch`         | Product category, user reviews, market segment  |
| Google News             | `WebSearch`                      | Recent press coverage, funding announcements    |
| VC / PE fund portfolios | `WebSearch` + `WebFetch`         | Portfolio company discovery via fund pages      |
| mna-pipeline Sheet      | `sheets_find` + `sheets_getText` | Active pipeline — companies to exclude          |
| Memory Graph            | `memory__search_nodes`           | Exclusion list, prior scan logs, scored targets |

---

## Output Format

### Scan Output (`--scan`)

```
MARKET SCAN RESULTS — NUVINI M&A — {date}
==========================================
Vertical: B2B SaaS | Geography: Brazil
Criteria: Revenue R$5M-R$100M | Rule of 40 > 20 | Vertical fit
Sources queried: 8 | Candidates found: XX | After exclusion filter: XX | Qualifying (score >= 40): XX

TOP CANDIDATES:

  Rank  Company            Score  Revenue Est.  Vertical        Ownership   Outreach Rec.
  ----  -----------------  -----  ------------  --------------  ----------  -------------
  1     {Company Name}      82    R${X}M        HCM / HRTech    Founder     YES (warm intro)
  2     {Company Name}      76    R${X}M        ERP / SMB       VC-backed   YES (cold email)
  3     {Company Name}      71    R${X}M        Logistics SaaS  Founder     YES (LinkedIn)
  4     {Company Name}      58    R${X}M        EdTech          Founder     MONITOR
  5     {Company Name}      44    R${X}M        Fintech SaaS    PE-backed   LOW PRIORITY
  ...

EXCLUDED (already in pipeline / known): {N} companies

CONFIDENCE: YELLOW — All targets require human review before outreach or pipeline addition.
```

### Company Profile Summary (per candidate)

```
CANDIDATE PROFILE
Company:     {Name}
Website:     {URL}
Founded:     {Year}
HQ:          {City, State, Brazil}
Vertical:    {Category}
Employees:   {est. range}
Revenue:     {est. R$XM – R$YM}
Funding:     {Total raised / bootstrapped}
Investors:   {Names or "Bootstrapped"}
Founders:    {Names + titles}

NUVINI SCORE:  {XX}/100  |  Tier: {A/B/C}

Score Breakdown:
  Revenue range fit:    XX/25
  Revenue growth:       XX/15
  Rule of 40 signal:    XX/15
  Vertical fit:         XX/20
  Team quality:         XX/10
  Ownership structure:  XX/10
  Data confidence:      XX/5

THESIS FIT:
  {1-2 sentences on why this company fits Nuvini's thesis}

SIGNALS:
  + {Positive signal 1}
  + {Positive signal 2}
  - {Risk or unknown 1}

SUGGESTED OUTREACH:
  Channel:  {Email / LinkedIn / Warm Intro}
  Angle:    "{Outreach angle}"
  Subject:  "{Draft subject line}"
  Key points:
    1. {Point}
    2. {Point}

DATA SOURCES:  {list of URLs/sources used}
CONFIDENCE: YELLOW — Human review required before any contact.
```

### Weekly Report (`--weekly-report`)

```
WEEKLY M&A MARKET SCAN REPORT
NUVINI GROUP | Week of {Monday date} | Generated: {date}
==========================================================

EXECUTIVE SUMMARY:
  Scans completed:     {N} (vs. prior week: {N})
  New candidates:      {N}
  Recommend outreach:  {N}
  Added to pipeline:   {N} (pending review)
  Exclusion list size: {N}

NEW THIS WEEK (score >= 65):
  [Candidate profiles as above — top 5-10]

MONITOR LIST (score 40-64):
  [Abbreviated list — company, score, vertical, reason for monitoring]

PIPELINE ADDITIONS RECOMMENDED (score >= 70):
  [Company names and scores — awaiting human approval]

SOURCING FUNNEL THIS WEEK:
  Sources searched → Candidates found → After dedup → After exclusion → Scored >= 40 → Score >= 65
  {N} sources → {N} raw → {N} deduped → {N} filtered → {N} qualifying → {N} actionable

CONFIDENCE: YELLOW — No outreach or pipeline additions made without human approval.
```

---

## Confidence Scoring

| Tier   | Threshold | Behavior                                                                      |
| ------ | --------- | ----------------------------------------------------------------------------- |
| Green  | > 95%     | Auto-proceed (exclusion list reads and deduplication only)                    |
| Yellow | 80–95%    | Human review required before outreach or pipeline addition — ALL scan outputs |
| Red    | < 80%     | Do not surface candidate; flag for manual investigation only                  |

**All identified targets are YELLOW confidence minimum.** Arnold never initiates outreach autonomously.

Candidate data confidence is reduced when:

- Revenue estimates are not directly sourced (press quotes, pitch decks, or analyst estimates only).
- Founding year or team information cannot be verified.
- No recent news or activity signal in the last 12 months.
- Company website is inactive or under construction.
- Ownership structure is ambiguous (holding company, complex structure).

Downgrade individual candidate to RED (flag only, do not surface for outreach) if:

- Company operates in a sector requiring regulatory approvals to acquire (Brazilian banking, healthcare data, telecom).
- Evidence of financial distress (failed rounds, layoffs, shutdown rumors).
- Existing investor has right of first refusal or anti-sale provisions visible in public filings.

---

## Integration

| Agent / Skill | Role                                                                       |
| ------------- | -------------------------------------------------------------------------- |
| mna-pipeline  | Receive qualified candidates for pipeline entry (Stage: Sourced)           |
| mna-toolkit   | Triage and IC Brief generation once a candidate enters the pipeline        |
| mna-nda-gen   | NDA generation when a candidate progresses to first meeting                |
| Cris          | Hands off qualified targets; Cris owns formal M&A process from IOI onwards |
| WebSearch     | Primary web intelligence tool for all scan queries                         |
| Firecrawl     | Deep extraction from JS-rendered pages (Crunchbase, Distrito, fund sites)  |
| Memory Graph  | Persistent exclusion list, scan logs, and scored candidate history         |
| Scheduler     | Weekly scan automation trigger (every Monday 08:00 BRT)                    |

---

## Arnold's Operating Principles

Arnold is the operations and deal sourcing agent. His primary function is building a continuous, proprietary top-of-funnel for Nuvini's M&A engine — finding companies before they are in a formal process, before brokers are engaged, and before prices reflect competition.

**Core behaviors:**

1. Run scans weekly (or on-demand). Never rely on a single source.
2. Score objectively — do not inflate scores for companies that seem interesting qualitatively.
3. Maintain a clean exclusion list. Never resurface a passed company unless criteria change.
4. Surface insights about market trends (valuations, sector activity, competitor acquisitions) in weekly reports.
5. Never make direct contact with any company without explicit human approval.
6. Always log scan results to memory for trend analysis over time.

---

## Examples

```
/mna-market-scan b2b-saas --scan
→ Full scan across 8 sources, returns scored candidate list filtered against active pipeline

/mna-market-scan b2b-saas --weekly-report
→ Compiles all new candidates into weekly Google Doc report saved to M&A/Market Scans/

/mna-market-scan "Empresa XYZ" --add-to-pipeline
→ Validates score >= 70, confirms with user, logs to mna-pipeline as Stage: Sourced

/mna-market-scan --exclusion-list
→ Displays all excluded companies with reason codes; allows adding new exclusions

/mna-market-scan "hcm" --criteria 'revenue > R$15M, Rule of 40 > 30'
→ Custom scan targeting HCM vertical with higher revenue and Rule of 40 threshold
```
