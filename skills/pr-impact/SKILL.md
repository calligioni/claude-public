---
name: pr-impact
description: "PR Impact Optimizer for Nuvini (NVNI). Score, optimize, and backtest press releases for stock impact + SEC compliance. Triggers on: pr impact, press release, optimize pr, score pr, pr analysis, pr optimizer, /pr-impact."
argument-hint: "<mode: analyze|backtest|simulate|collect> [draft text or .docx path]"
user-invocable: true
context: fork
model: opus
effort: high
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - WebSearch
  - WebFetch
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: true }
  Write: { destructiveHint: false, idempotentHint: true }
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

# PR Impact Optimizer

Analyzes, scores, and optimizes press releases for maximum positive stock price impact while ensuring SEC compliance. Built on empirical data from 111 Nasdaq small-cap press releases that drove 50%+ stock moves with next-day follow-through (Jan 2025 - Mar 2026).

## Project Location

- **Data pipeline**: `/Volumes/AI/Code/pr-impact/`
- **Database**: `/Volumes/AI/Code/pr-impact/data/pr_impact.db` (SQLite)
- **Rubrics**: `/Volumes/AI/Code/pr-impact/output/rubrics.json` (generic) and `rubrics_nvni.json` (NVNI-adapted)
- **Pattern report**: `/Volumes/AI/Code/pr-impact/output/pattern_report.md`
- **Calibration examples**: `/Volumes/AI/Code/pr-impact/output/calibration_examples.json`
- **NVNI backtest**: `/Volumes/AI/Code/pr-impact/output/nvni_backtest.md`

## Mode Detection

Parse the user's input to determine mode:

1. **`analyze <text or .docx path>`** — Score a PR draft against rubrics + SEC compliance
2. **`backtest [ticker] [date range]`** — Compare algorithm predictions vs actual stock price impact
3. **`simulate <draft .docx path>`** — Generate 3 optimized variants, score each
4. **`collect`** — Re-run the data collection pipeline (scripts 01-09)

If no mode specified, default to `analyze` if text/file is provided, or ask the user.

---

## Mode 1: ANALYZE

### Step 1: Load Context

Read the following files to establish scoring context:

```bash
# Load rubrics and calibration data
cat /Volumes/AI/Code/pr-impact/output/rubrics_nvni.json
cat /Volumes/AI/Code/pr-impact/output/calibration_examples.json
cat /Volumes/AI/Code/pr-impact/output/pattern_report.md
```

### Step 2: Extract PR Text

If the input is a `.docx` file:

```bash
python3 -c "
import zipfile, xml.etree.ElementTree as ET
with zipfile.ZipFile('PATH_TO_DOCX') as z:
    tree = ET.parse(z.open('word/document.xml'))
    ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
    for p in tree.findall('.//w:p', ns):
        texts = [t.text for t in p.findall('.//w:t', ns) if t.text]
        if texts: print(''.join(texts))
"
```

If the input is plain text, use it directly.

### Step 3: Run Feature Extraction

```bash
python3 -c "
import sys; sys.path.insert(0, '/Volumes/AI/Code/pr-impact')
from lib.features import extract_all_features
from lib.lexicon import LexiconScorer
import json

scorer = LexiconScorer()
# Pass the title, first paragraph, and full text
feats = extract_all_features(TITLE, FIRST_PARA, FULL_TEXT)
lexicon = scorer.score(FULL_TEXT)
feats.update(lexicon)
print(json.dumps(feats, indent=2))
"
```

### Step 4: Spawn 4 Parallel Analysis Agents

Launch all 4 agents simultaneously in a single message:

#### Agent 1: SEC Compliance Analyst (sonnet)

```
Prompt: You are an SEC compliance analyst reviewing a press release for a Nasdaq-listed company (NVNI, Nuvini Group, micro-cap ~$25M, Foreign Private Issuer).

Review this PR for compliance with:
1. Rule 10b-5: Any unsubstantiated claims or material omissions?
2. Reg FD: Is all material info disclosed simultaneously to all investors?
3. PSLRA Safe Harbor: Are forward-looking statements properly identified with specific cautionary language (not boilerplate)?
4. Rule 425 (if M&A): Is the Rule 425 legend present? Will this be filed as 8-K/6-K?
5. Reg G: If non-GAAP metrics are used, is reconciliation referenced?
6. AI-washing: Are AI capability claims specific and substantiated? (SEC 2026 enforcement priority)

PR Text:
{FULL_PR_TEXT}

Extracted features:
{FEATURES_JSON}

Score from 0-100 where:
- 90-100: Fully compliant, no issues
- 70-89: Minor issues, safe to release with fixes
- 50-69: Material issues requiring attention
- 0-49: Do not release — compliance failures

Output format:
COMPLIANCE_SCORE: [number]
ISSUES:
- [severity: HIGH/MEDIUM/LOW] [issue description] — [specific recommendation]
SAFE_TO_RELEASE: [YES/NO/WITH_FIXES]
```

#### Agent 2: Content Analyst (sonnet)

```
Prompt: You are a financial PR content analyst. Score this press release against empirical patterns from 111 Nasdaq small-cap PRs that drove 50%+ stock price increases.

RUBRICS (derived from top 50 performers):
{RUBRICS_JSON}

CALIBRATION EXAMPLES (real PRs with known outcomes):
{CALIBRATION_EXAMPLES_JSON}

KEY PATTERNS FROM TOP PERFORMERS:
- Headlines with numbers: 62% of top 50 vs 44% of rest
- Positive sentiment score: +0.0015 in top 50 vs -0.0012 in rest
- More management quotes: 0.9 avg in top 50 vs 0.3 in rest
- Longer lead paragraphs: 38 words in top 50 vs 27 in rest
- Higher specificity (concrete numbers, names, dates)

PR Text:
{FULL_PR_TEXT}

Score each dimension 0-100:
1. HEADLINE: length, specificity, numbers, action verbs, urgency
2. LEAD_PARAGRAPH: materiality of first fact, growth metrics, strategic rationale
3. SENTIMENT: positive/negative ratio, uncertainty language, confidence signals
4. SPECIFICITY: concrete numbers, dollar amounts, percentages, named entities, timelines

Overall CONTENT_SCORE: weighted average

For each dimension, provide:
- Score
- What works well
- Top 1-2 specific improvements with example rewritten text
```

#### Agent 3: Structure Analyst (sonnet)

```
Prompt: You are a financial PR structure analyst. Evaluate the structural quality of this press release.

PR Text:
{FULL_PR_TEXT}

Extracted features:
{FEATURES_JSON}

Score each dimension 0-100:
1. INVERTED_PYRAMID: Is the most material information in the first paragraph? Does importance decrease down the page?
2. READABILITY: Flesch-Kincaid target is grade 10-14 for financial PRs. Current grade: {readability_score}
3. QUOTE_QUALITY: Are management quotes substantive (adding strategic color) or generic ("we're excited")?
4. SECTION_ORGANIZATION: Clear sections with headers? Logical flow?
5. LENGTH: Optimal range is 800-1500 words. Current: {word_count}

Overall STRUCTURE_SCORE: weighted average

For each low-scoring dimension, provide specific structural recommendations.
```

#### Agent 4: Market Context Analyst (haiku)

```
Prompt: You are a market context analyst for NVNI (Nuvini Group, Nasdaq micro-cap, ~$25M market cap, B2B SaaS serial acquirer in Latin America, Foreign Private Issuer).

NVNI-specific factors:
- Recently regained Nasdaq compliance (Oct 2025)
- Appointed Chief AI Officer (Phoebe Wang, Mar 2026)
- Serial acquirer model (7 portfolio companies, 22,400+ customers)
- Micro-cap dynamics: low liquidity, high information asymmetry
- FPI filing via 6-K

NVNI adjustments from backtest:
- AI mentions get amplified market reaction
- M&A announcements drive outsized moves for serial acquirers
- Post-compliance-regain PRs have higher baseline impact
- Micro-cap volume means moderate interest = big price moves

PR Type: {pr_type}

Provide a CONTEXT_MULTIPLIER (0.5x to 2.0x) based on:
1. How well this PR type historically performs for NVNI
2. Current market conditions for micro-cap/AI stocks
3. NVNI-specific narrative factors (compliance recovery, AI strategy, M&A model)

Output:
CONTEXT_MULTIPLIER: [number]
RATIONALE: [2-3 bullet points]
```

### Step 5: Synthesize Results

Combine the 4 agent outputs:

```
PR_IMPACT_SCORE = (
    0.30 * CONTENT_SCORE +
    0.25 * STRUCTURE_SCORE +
    0.25 * COMPLIANCE_SCORE +
    0.20 * 50  # baseline
) * CONTEXT_MULTIPLIER

Predicted Impact:
- 80-100: Very High (historically correlates with 50%+ moves)
- 60-79: High (historically correlates with 10-50% moves)
- 40-59: Medium (historically correlates with 0-10% moves)
- 0-39: Low (may have negative market reaction)
```

If COMPLIANCE_SCORE < 70: add prominent warning "DO NOT RELEASE WITHOUT FIXING COMPLIANCE ISSUES"

### Step 6: Output Report

```markdown
# PR Impact Analysis: {PR_TITLE}

## Overall Score: XX/100 — Predicted Impact: [Very High|High|Medium|Low]

### SEC Compliance: XX/100 [PASS|WARN|FAIL]

{compliance_issues}

### Content Score: XX/100

- Headline: XX/100
- Lead Paragraph: XX/100
- Sentiment Profile: XX/100
- Specificity: XX/100

### Structure Score: XX/100

- Inverted Pyramid: XX/100
- Readability: Grade XX (target: 10-14)
- Quote Quality: XX/100
- Organization: XX/100

### Market Context Multiplier: X.Xx

{context_rationale}

### Top 3 Improvements (Ordered by Expected Impact)

1. {specific actionable change with example rewritten text}
2. {specific actionable change with example rewritten text}
3. {specific actionable change with example rewritten text}
```

### Step 7: Export to Word (.docx)

After writing the markdown report, export it to a Word document alongside the `.md` file.

Save the markdown report to a file first:

```bash
# Save markdown report
REPORT_DIR="/Volumes/AI/Code/pr-impact/output/reports"
mkdir -p "$REPORT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_MD="$REPORT_DIR/pr-impact-${TIMESTAMP}.md"
# Write the report markdown to $REPORT_MD
```

Then convert to `.docx` using pandoc:

```bash
pandoc "$REPORT_MD" \
  -o "${REPORT_MD%.md}.docx" \
  --from markdown \
  --to docx \
  --toc \
  --toc-depth=3 \
  --metadata title="PR Impact Analysis: {PR_TITLE}" \
  --metadata date="$(date +%Y-%m-%d)" \
  --metadata author="PR Impact Optimizer — Nuvini" \
  2>&1
```

If pandoc is not installed:

```bash
which pandoc || { echo "pandoc not found — install with: brew install pandoc"; }
```

Report both file paths to the user:

- Markdown: `$REPORT_MD`
- Word: `${REPORT_MD%.md}.docx`

---

## Mode 2: SIMULATE

### Step 1: Load and Analyze Original Draft

Run the full ANALYZE mode on the original draft to establish baseline score.

### Step 2: Generate 3 Variants

Using the original PR text and the analysis results, generate 3 rewritten variants:

**Variant A: Maximum Clarity**

- Restructure for strict inverted pyramid
- Lead with the single most material quantitative fact
- Front-load the headline with specific numbers
- Remove all vague qualifiers ("approximately", "expected to")
- Keep management quotes but move them after hard facts

**Variant B: Narrative-Driven**

- Lead with the strategic transformation story
- Frame the announcement as a milestone in a larger narrative
- Emphasize competitive moat and market positioning
- Use strong action verbs in headline ("Transforms", "Launches", "Secures")
- Include forward-looking vision from CEO

**Variant C: Data-Dense**

- Front-load ALL quantitative metrics in headline and first paragraph
- Include specific dollar amounts, percentages, customer counts, country counts
- Structure as fact-sheet format with bullet points of key metrics
- Minimize narrative, maximize data density
- Target investors doing quick scans

### Step 3: Score All Variants

Run the 4-agent analysis pipeline on each variant. Present comparative results.

### Step 4: Output Comparative Report

```markdown
# PR Simulation: {TITLE} — 3 Variants

## Scores Comparison

| Dimension    | Original | Variant A (Clarity) | Variant B (Narrative) | Variant C (Data-Dense) |
| ------------ | -------- | ------------------- | --------------------- | ---------------------- |
| Overall      | XX       | XX                  | XX                    | XX                     |
| Content      | XX       | XX                  | XX                    | XX                     |
| Structure    | XX       | XX                  | XX                    | XX                     |
| Compliance   | XX       | XX                  | XX                    | XX                     |
| Context Mult | X.Xx     | X.Xx                | X.Xx                  | X.Xx                   |

## Variant A: Maximum Clarity

{full rewritten headline and first 2 paragraphs}
{key changes made}

## Variant B: Narrative-Driven

{full rewritten headline and first 2 paragraphs}
{key changes made}

## Variant C: Data-Dense

{full rewritten headline and first 2 paragraphs}
{key changes made}

## Recommendation

{which variant scores highest and why}
{specific elements to combine from multiple variants}
```

### Step 5: Export to Word (.docx)

Save the simulation report and export to Word, same pattern as ANALYZE mode:

```bash
REPORT_DIR="/Volumes/AI/Code/pr-impact/output/reports"
mkdir -p "$REPORT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_MD="$REPORT_DIR/pr-simulation-${TIMESTAMP}.md"
# Write the simulation report markdown to $REPORT_MD

pandoc "$REPORT_MD" \
  -o "${REPORT_MD%.md}.docx" \
  --from markdown \
  --to docx \
  --toc \
  --toc-depth=3 \
  --metadata title="PR Simulation: {TITLE} — 3 Variants" \
  --metadata date="$(date +%Y-%m-%d)" \
  --metadata author="PR Impact Optimizer — Nuvini" \
  2>&1
```

Report both file paths to the user.

---

## Mode 3: BACKTEST

### Default: NVNI Backtest

Read and present `/Volumes/AI/Code/pr-impact/output/nvni_backtest.md`.

If the user provides a different ticker, run:

```bash
python3 /Volumes/AI/Code/pr-impact/scripts/09_backtest_nvni.py
```

(modify the script to accept ticker as argument, or run inline).

---

## Mode 4: COLLECT

Re-run the full data pipeline:

```bash
cd /Volumes/AI/Code/pr-impact
python3 scripts/01_screen_tickers.py
python3 scripts/02_fetch_prices.py
python3 scripts/03_find_spikes.py
python3 scripts/04_map_cik.py
python3 scripts/05_fetch_filings.py
python3 scripts/06_fetch_pr_text.py
python3 scripts/07_rank_and_select.py
python3 scripts/08_extract_features.py
python3 scripts/09_backtest_nvni.py
```

Report progress and final row counts after each step.

---

## SEC Compliance Boundaries

### This skill CAN:

- Optimize headline structure and word choice for clarity and impact
- Suggest emphasis on genuinely material positive developments
- Recommend optimal PR structure (inverted pyramid, strategic rationale placement)
- Analyze which factual framings historically correlate with positive market reception
- Ensure forward-looking statements are properly hedged
- Suggest specific, meaningful risk factors instead of generic boilerplate
- Flag potential AI-washing in AI-related claims

### This skill MUST NOT:

- Suggest language designed to artificially inflate stock price
- Recommend timing press releases to coincide with short squeezes or options expiry
- Advise withholding material negative information to amplify positive PR impact
- Suggest misleading comparisons or cherry-picked metrics
- Recommend coordinated social media campaigns alongside PR distribution
- Generate false or unsubstantiated claims about company performance

### Key SEC Regulations:

- **Reg FD**: Material info disclosed simultaneously to all investors
- **Rule 10b-5**: No untrue statements or misleading omissions
- **PSLRA Safe Harbor**: Forward-looking statements must be identified + specific cautionary language
- **Rule 425**: M&A PRs must include Rule 425 legend and be filed same-day
- **Reg G**: Non-GAAP metrics require reconciliation reference

---

## Data Foundation

The scoring algorithm is calibrated against:

- **111 press releases** from Nasdaq small-caps (<$300M market cap)
- **Criteria**: 50%+ daily return with positive next-day follow-through
- **Ranked by**: Combined volume ratio (60% day 1 + 40% day 2)
- **Features**: 23 linguistic/structural dimensions per PR
- **NVNI-specific**: Backtested against 30 NVNI PRs with actual stock price reactions
- **Time period**: January 2025 — March 2026

Key empirical findings:

- Top performers have **62% numbers in headlines** (vs 44% for rest)
- **Positive net sentiment** in top 50 (vs slightly negative in rest)
- **3x more management quotes** in top 50
- **40% longer lead paragraphs** in top 50
- **100% include forward-looking language**; 78% have safe harbor language
