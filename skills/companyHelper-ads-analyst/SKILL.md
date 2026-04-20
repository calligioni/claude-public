---
name: companyHelper-ads-analyst
description: Orchestrate competitive ad research. Extracts ads from Meta Ad Library, generates strategy report, deep-dives top creatives, and analyzes all landing pages. One command for complete competitor intelligence. Also triggers on ads-analyst install or ads-analyst setup to run the install wizard.
---

# Ads Analyst

Orchestrate the full competitive research pipeline in one command.

## Install

If the user says `/ads-analyst install` or `/ads-analyst setup`, run this install wizard instead of the normal workflow. Walk through each step conversationally.

This skill is an orchestrator that calls 4 sub-skills. All 5 are bundled together in this package. The install wizard makes sure everything is in place and connected.

### Step 1: Check sub-skills are installed

All 4 sub-skills must be in `~/.claude/skills/`. Check each:

```bash
for skill in meta-ads-extractor meta-ads-analyser ad-creative-analysis landing-page-analysis; do
  if [ -f ~/.claude/skills/$skill/SKILL.md ]; then echo "OK: $skill"; else echo "MISSING: $skill"; fi
done
```

**If any are missing:** This package includes all 4 sub-skills. Tell the user to copy the missing directories from the package to `~/.claude/skills/`:
- `meta-ads-extractor/` — Extracts ad creatives from Meta Ad Library
- `meta-ads-analyser/` — Generates strategy report from extracted assets
- `ad-creative-analysis/` — Deep-dives individual ads (video + image)
- `landing-page-analysis/` — Analyzes landing pages behind ad CTAs

### Step 2: Check browser automation

The extraction and landing page skills need browser automation to interact with Meta Ad Library and capture landing page screenshots.

**Check:** Look for available Playwright/browser MCP tools. Search for `mcp__playwriter__` or similar browser-control tools.

**If missing:** Walk the user through setting up browser automation:

**Option A: Playwriter MCP (recommended)**
1. Install the Playwriter extension in VS Code / Claude Code
2. This gives Claude access to control a Chrome browser
3. Verify: check that `mcp__playwriter__execute` tool is available

**Option B: Playwright directly**
1. `npm install -g playwright`
2. `npx playwright install chromium`
3. The extraction skill uses browser evaluate/navigate commands — ensure the browser MCP is connected

**Why it's needed:** Meta Ad Library is a dynamic web app. The skill needs to navigate it, scroll to load ads, and extract media URLs from the DOM. Landing page analysis also needs screenshots.

### Step 3: Check Gemini API key

The `ad-creative-analysis` sub-skill uses Google's Gemini API to analyze video ads (frame-by-frame understanding) and image ads.

**Check:**
```bash
echo ${GEMINI_API_KEY:+"OK: GEMINI_API_KEY is set"} || echo "MISSING: GEMINI_API_KEY"
```

**If missing:**
1. Go to Google AI Studio: https://aistudio.google.com/apikey
2. Create an API key (free tier gives generous usage)
3. Add to your shell profile:
   ```bash
   export GEMINI_API_KEY="your-key-here"
   ```
4. Restart your terminal / Claude Code session

**Why it's needed:** Gemini 2.0 Flash analyzes video ads by uploading them to the Gemini Files API, then running multimodal analysis. For image ads, it provides detailed visual element breakdowns. Without it, the deep-dive phase won't work for video ads (image ads can fall back to Claude's built-in vision).

### Step 4: Check curl

The extraction skill downloads ad assets (images + videos) via curl from Facebook's CDN.

```bash
which curl && echo "OK: curl" || echo "MISSING: curl"
```

curl is pre-installed on macOS and most Linux distros. If somehow missing: `brew install curl` or `sudo apt install curl`.

### Step 5: Check Telegram (optional)

The skill can deliver the final report via Telegram. This is optional — if not configured, the report is saved locally.

**Ask the user:** "Do you want report delivery via Telegram? (Optional — you can skip this)"

**If yes:**
1. Create a Telegram bot via @BotFather
2. Get your Telegram user ID (message @userinfobot)
3. Set environment variables:
   ```bash
   export TELEGRAM_BOT_TOKEN="your-bot-token"
   export TELEGRAM_ALLOWED_USER="your-user-id"
   ```
4. Verify: send a test message via the bot

**If no:** Skip — reports will be saved to the local `output/meta-ads/` directory.

### Step 6: Test the pipeline

Run a quick validation:
1. Verify browser can navigate to `https://www.facebook.com/ads/library/` (test browser automation)
2. Verify Gemini API responds: run a simple test call with the API key
3. Verify all sub-skill files have their supporting files (references, scripts, templates)

```bash
# Check sub-skill supporting files
ls ~/.claude/skills/meta-ads-extractor/references/dom-selectors.md 2>/dev/null && echo "OK: DOM selectors" || echo "MISSING: dom-selectors.md"
ls ~/.claude/skills/meta-ads-extractor/scripts/extract-and-download.sh 2>/dev/null && echo "OK: extract script" || echo "MISSING: extract-and-download.sh"
ls ~/.claude/skills/meta-ads-analyser/templates/report-template.html 2>/dev/null && echo "OK: report template" || echo "MISSING: report-template.html"
ls ~/.claude/skills/ad-creative-analysis/references/prompts.md 2>/dev/null && echo "OK: analysis prompts" || echo "MISSING: prompts.md (ad-creative)"
ls ~/.claude/skills/landing-page-analysis/references/prompts.md 2>/dev/null && echo "OK: landing prompts" || echo "MISSING: prompts.md (landing-page)"
```

### Step 7: Report status

```
Ads Analyst — Install Summary

  Sub-skills:
    meta-ads-extractor:    [OK/MISSING]
    meta-ads-analyser:     [OK/MISSING]
    ad-creative-analysis:  [OK/MISSING]
    landing-page-analysis: [OK/MISSING]

  Dependencies:
    Browser automation:    [OK/MISSING] — Playwright/Playwriter MCP
    Gemini API key:        [OK/MISSING] — For video/image ad analysis
    curl:                  [OK/MISSING] — For downloading ad assets
    Telegram (optional):   [OK/SKIPPED] — For report delivery

  Status: [Ready to use / X items need attention]

How it works:
  1. Give it a competitor name or Facebook page URL
  2. It extracts all their active ads from Meta Ad Library
  3. Generates a strategy report with funnel mapping
  4. Deep-dives the top ads with AI analysis
  5. Analyzes every landing page behind the ads
  6. Delivers a complete intelligence package

Try it: /ads-analyst Nike
```

---

## Role

You are the Ads Analyst. Your job is to:
1. **Extract** — Pull all ad creatives from Meta Ad Library
2. **Analyze** — Generate strategy report with funnel mapping
3. **Deep-dive** — Detailed breakdown of top-performing ads
4. **Map funnels** — Analyze every unique landing page
5. **Compile** — Deliver complete intelligence package

## Usage

```
/ads_analyst {competitor}              → default 5 deep-dives
/ads_analyst {competitor} top 10       → analyze top 10 ads
/ads_analyst {competitor} all          → deep-dive every ad
```

## Workflow

### Phase 1: Extraction

Run `/meta_ads_extractor` to:
- Get Page ID from Facebook page
- Load Meta Ad Library with all active ads
- Extract image URLs (600×600 max) and video URLs (full quality)
- Extract CTA destination URLs
- Download all assets

**Checkpoint:** "Found X images and Y videos from {competitor}. Proceeding with analysis..."

### Phase 2: Strategy Report

Run `/meta_ads_analyser` to:
- Analyze each creative (dimensions, hook, copy, emotion)
- Map ads to landing pages (identify funnels)
- Identify testing patterns and strategy
- Generate HTML report with inline media

**Checkpoint:** "Generated strategy report. Identified N funnels. Now deep-diving top ads..."

### Phase 3: Deep-Dive Top Ads

Determine how many ads to deep-dive:
- Default: 5 (or fewer if total ads < 5)
- User-specified: "top N" parameter
- All: if user says "all"

For video ads: Use Gemini video understanding via `/ad_creative_analysis`
For image ads: Use vision model via `/ad_creative_analysis`

Each deep-dive covers:
- Frame-by-frame breakdown (video) / element analysis (image)
- Hook effectiveness score
- Script/copy full transcription
- What makes it work (tactical takeaways)
- What could be improved

**Checkpoint:** "Completed deep-dives on X ads. Now analyzing landing pages..."

### Phase 4: Landing Page Analysis

1. Collect all unique CTA URLs from extracted ads
2. Dedupe (many ads → same landing page)
3. Run `/landing_page_analysis` on each unique URL:
   - Screenshot the page
   - Analyze above-fold, offer, social proof, CTAs
   - Identify funnel position and conversion strategy

**Checkpoint:** "Analyzed X unique landing pages. Compiling final report..."

### Phase 5: Master Report

Compile everything into one deliverable:

```
output/meta-ads/{advertiser-slug}/
├── assets/
│   ├── {slug}-image-01.jpg
│   ├── {slug}-video-01.mp4
│   └── landing-{page}.jpg
├── {slug}-analysis.html        (strategy report with inline media)
├── deep-dives/
│   ├── ad-01-breakdown.md      (individual ad deep-dives)
│   ├── ad-02-breakdown.md
│   └── ...
├── landing-pages/
│   ├── page-01-analysis.md     (landing page analyses)
│   └── ...
└── MASTER-REPORT.md            (executive summary + links to all)
```

### Master Report Structure

```markdown
# {Competitor} Ad Intelligence Report

Generated: {date}

## Executive Summary
- Total ads analyzed: X
- Funnels identified: Y
- Key insight 1
- Key insight 2
- Key insight 3

## Quick Stats
| Metric | Value |
|--------|-------|
| Active ads | X |
| Video ads | Y |
| Image ads | Z |
| Unique landing pages | N |
| Primary aspect ratio | 4:5 |
| Avg video duration | 30s |

## Strategy Overview
[High-level acquisition strategy, testing patterns, funnel flow]

## Top Ads (Deep-Dives)
1. [Ad Name] — [Why it works] → deep-dives/ad-01-breakdown.md
2. [Ad Name] — [Why it works] → deep-dives/ad-02-breakdown.md
...

## Funnels
### Funnel 1: [Name/Offer]
- Landing page: [URL] → landing-pages/page-01-analysis.md
- Ads driving to this funnel: X
- Funnel type: TOFU/BOFU

### Funnel 2: [Name/Offer]
...

## Key Takeaways
1. [Actionable insight for our campaigns]
2. [Creative pattern we should test]
3. [Landing page element to adopt]
4. [Gap/opportunity we can exploit]

## Files
- Full strategy report: {slug}-analysis.html
- All assets: assets/
- Deep-dives: deep-dives/
- Landing page analyses: landing-pages/
```

## Delivery

1. Zip the entire folder
2. Send via Telegram with summary:

```
✅ {Competitor} Ad Intelligence Complete

📊 {X} ads extracted ({Y} videos, {Z} images)
🔍 {N} ads deep-dived
📄 {M} landing pages analyzed
🎯 {F} funnels identified

Key finding: [One-line headline insight]

Sending the full package now...
```

3. Send the zip file

## Phase 6: Handoff to Head of Marketing

After delivering competitor intel, prompt for next step:

```
"Ready to plan your campaign based on these learnings?

Next step: I'll analyze YOUR brand and create a campaign proposal 
that applies what we learned from {competitor}.

To proceed, I need your website URL:
→ /head_of_marketing https://your-brand.com

Or if you want to analyze more competitors first, just say so."
```

**When user provides their URL:**
- Pass competitor learnings as context
- Invoke `/head_of_marketing` with the URL
- Include key patterns summary for campaign planning

## Quality Gates

### Gate 1: Extraction
- [ ] Page ID found correctly?
- [ ] Assets downloading without errors?
- [ ] Got both images AND videos?

### Gate 2: Analysis
- [ ] Strategy report generated?
- [ ] Funnels correctly mapped?
- [ ] Aspect ratios captured?

### Gate 3: Deep-Dives
- [ ] Video analysis working (Gemini)?
- [ ] Image analysis working (vision)?
- [ ] All requested ads analyzed?

### Gate 4: Landing Pages
- [ ] All unique URLs captured?
- [ ] Screenshots taken successfully?
- [ ] Analysis complete for each?

### Gate 5: Delivery
- [ ] Master report compiled?
- [ ] All files organized?
- [ ] Zip created and sent?

## Error Handling

**Page ID not found:**
- Try alternate extraction method (al:android:url meta tag)
- Ask user for direct Facebook page URL

**No ads found:**
- Check if advertiser has active ads
- Try removing country filter
- Report back to user

**Video analysis fails:**
- Check file upload to Gemini
- Verify file is under 2GB
- Fall back to thumbnail analysis

**Landing page blocked:**
- Note as "gated/blocked" in report
- Screenshot what's visible
- Move to next URL

## Pipeline Position

```
┌─────────────┐    ┌─────────────────────┐    ┌────────────────────┐
│ ads_analyst │ → │  head_of_marketing  │ → │  creative_director │
│ (research)  │    │  (brand + campaign) │    │  (build assets)    │
└─────────────┘    └─────────────────────┘    └────────────────────┘
       ↑
  YOU ARE HERE
```

## Sub-Skills Reference

| Skill | Purpose | Input |
|-------|---------|-------|
| `/meta_ads_extractor` | Download ad creatives | Advertiser name/URL |
| `/meta_ads_analyser` | Strategy report | Assets folder |
| `/ad_creative_analysis` | Individual ad deep-dive | Image/video file |
| `/landing_page_analysis` | Landing page breakdown | URL |

## Handoff Reference

| Next Step | Skill | What You Pass |
|-----------|-------|---------------|
| Plan campaign | `/head_of_marketing` | Competitor learnings, key patterns |
