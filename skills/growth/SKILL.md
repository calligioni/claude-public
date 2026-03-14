---
name: growth
description: "SaaS growth engineering: landing page CRO, pricing strategy, signup flow optimization, onboarding CRO, email sequences, SEO (technical + programmatic + AI/GEO), competitor comparison pages, churn prevention, and A/B test design. Analyzes existing pages and generates actionable improvements. Triggers on: growth, cro, conversion optimization, pricing strategy, signup flow, onboarding, seo audit, churn, /growth."
argument-hint: "<url or page to optimize, or mode: cro|pricing|seo|onboarding|churn|full-audit>"
user-invocable: true
context: fork
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - WebSearch
  - WebFetch
  - mcp__firecrawl__*
  - mcp__chrome-devtools__*
  - mcp__playwright__*
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: true }  # browse CLI runs via Bash
  - AskUserQuestion
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: true }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__firecrawl__*: { readOnlyHint: true, openWorldHint: true }
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

# Growth — SaaS Growth Engineering

Structured frameworks for optimizing SaaS conversion funnels, pricing, retention, and acquisition. Each mode produces an actionable report with specific code/copy changes.

## Mode Selection

| Input                     | Mode             | What it does                                        |
| ------------------------- | ---------------- | --------------------------------------------------- |
| `cro <url>`               | Landing Page CRO | Analyze and optimize a landing/pricing page         |
| `pricing`                 | Pricing Strategy | Analyze pricing model, suggest optimizations        |
| `signup` or `signup flow` | Signup Flow CRO  | Optimize registration → activation funnel           |
| `onboarding`              | Onboarding CRO   | Optimize first-run experience → aha moment          |
| `seo`                     | SEO Audit        | Technical SEO + programmatic SEO + AI/GEO readiness |
| `churn`                   | Churn Prevention | Analyze retention, suggest interventions            |
| `email`                   | Email Sequences  | Design lifecycle email sequences                    |
| `competitor <url>`        | Comparison Page  | Build vs-competitor comparison page                 |
| `full-audit` or no args   | Full Audit       | Run all modes for the project                       |

---

## Mode 1: Landing Page CRO

**Goal:** Increase visitor → signup conversion rate.

### Process

1. **Fetch the page** via Firecrawl or Chrome DevTools
2. **Score against CRO framework:**

| Element            | Check                                                       | Weight |
| ------------------ | ----------------------------------------------------------- | ------ |
| **Hero clarity**   | Does the H1 state the value prop in <8 words?               | 20%    |
| **Social proof**   | Logos, testimonials, or numbers above the fold?             | 15%    |
| **CTA visibility** | Primary CTA visible without scrolling? High contrast?       | 20%    |
| **CTA copy**       | Action-oriented ("Start free trial") vs passive ("Submit")? | 10%    |
| **Friction**       | How many form fields? Can you start without signup?         | 15%    |
| **Speed**          | LCP < 2.5s? CLS < 0.1?                                      | 10%    |
| **Mobile**         | Responsive? Touch targets > 48px?                           | 10%    |

3. **Generate recommendations:**

```markdown
## CRO Report: {URL}

### Score: {X}/100

### Critical Fixes (expected +5-15% conversion lift)

1. {specific change with before/after copy}
2. {specific change with code diff}

### Quick Wins (expected +2-5% lift)

1. ...

### A/B Test Ideas

| Test                  | Hypothesis               | Primary Metric             |
| --------------------- | ------------------------ | -------------------------- |
| {variant description} | {why we think it'll win} | {signup rate / click rate} |
```

4. **If code access available:** Generate actual code diffs for the recommended changes.

---

## Mode 2: Pricing Strategy

**Goal:** Optimize pricing model for revenue and adoption.

### Process

1. **Analyze current pricing:**
   - Read pricing page/component code
   - Identify: tier count, price points, feature differentiation, billing frequency

2. **Apply pricing frameworks:**

   **Van Westendorp Price Sensitivity:**
   - Too cheap (quality concern)
   - Bargain (great deal)
   - Getting expensive (still acceptable)
   - Too expensive (won't buy)

   **Value Metric Analysis:**
   - What unit does the customer buy? (seats, API calls, storage, projects)
   - Does the value metric scale with customer success?
   - Is the metric easy to understand and predict?

3. **Competitive pricing research:**
   - WebSearch for competitor pricing pages
   - Build comparison matrix

4. **Generate recommendations:**

```markdown
## Pricing Analysis: {Product}

### Current Model

{description}

### Issues Found

| Issue                   | Impact                                      | Recommendation                 |
| ----------------------- | ------------------------------------------- | ------------------------------ |
| Free tier too generous  | Reduces upgrade urgency                     | Gate {feature} behind paid     |
| No annual discount      | Missing 20-30% revenue uplift               | Add 20% annual discount        |
| Value metric misaligned | Users pay per seat but value is per project | Consider project-based pricing |

### Recommended Pricing Table

| Tier | Price | Target | Key Differentiator |
| ---- | ----- | ------ | ------------------ |
```

---

## Mode 3: Signup Flow CRO

**Goal:** Reduce registration friction, increase activation rate.

### Process

1. **Map the current flow:**
   - How many steps from landing to first value?
   - What information is required at each step?
   - Where are the drop-off points?

2. **Score against signup best practices:**

| Factor             | Best Practice                                 | Current  |
| ------------------ | --------------------------------------------- | -------- |
| Fields             | 3 or fewer (email, password, name)            | {count}  |
| Social login       | Google/GitHub OAuth available                 | {yes/no} |
| Email verification | Delayed (after first value) or immediate?     | {type}   |
| Magic link         | Available as password alternative?            | {yes/no} |
| Progress indicator | Shows steps remaining?                        | {yes/no} |
| Error handling     | Inline validation, not form submission errors | {type}   |

3. **Activation metric:**
   - Define "aha moment" — what action makes users stick?
   - How many users reach it within first session?
   - What's blocking the path?

4. **Generate code changes** to reduce friction.

---

## Mode 4: Onboarding CRO

**Goal:** Get users from signup to "aha moment" faster.

### Process

1. **Identify the aha moment:**
   - For Contably: first financial report generated
   - For SourceRank: first repository analysis complete
   - Generic: first meaningful action with real data

2. **Map current onboarding:**
   - Steps between signup and aha moment
   - Where do users drop off?
   - What's optional vs required?

3. **Apply onboarding patterns:**

| Pattern                    | When to Use                    | Example                                        |
| -------------------------- | ------------------------------ | ---------------------------------------------- |
| **Progressive disclosure** | Complex product, many features | Show 3 core features first, unlock rest later  |
| **Checklist**              | Multiple setup steps needed    | "Complete your profile: 3/5 done"              |
| **Empty state design**     | Data-dependent product         | Show sample data, import wizard, or templates  |
| **Tooltip tour**           | UI-heavy product               | Highlight key buttons on first visit           |
| **Time-to-value shortcut** | Long setup process             | Pre-fill with sample data, skip optional steps |

4. **Generate implementation plan** with specific component/page changes.

---

## Mode 5: SEO Audit

**Goal:** Improve organic search visibility including AI/GEO readiness.

### Process

1. **Technical SEO:**

   ```
   Check: sitemap.xml, robots.txt, canonical tags, meta titles/descriptions,
   Open Graph tags, structured data (JSON-LD), H1-H6 hierarchy, internal linking,
   image alt text, Core Web Vitals (via Lighthouse), mobile-friendliness,
   HTTPS redirects, 404 handling, hreflang (if multi-language)
   ```

2. **Programmatic SEO opportunities:**
   - Identify data that could generate pages (e.g., "best {tool} for {industry}")
   - Template-driven page generation for long-tail keywords
   - Dynamic landing pages from database content

3. **AI/GEO readiness (Generative Engine Optimization):**

   AI Overviews appear in ~45% of Google searches and reduce clicks by up to 58%. Optimized content gets cited 3x more.

   **Visibility boost methods (Princeton GEO research):**
   | Method | Visibility Boost |
   |--------|-----------------|
   | Cite sources | +40% |
   | Add statistics | +37% |
   | Add quotations | +30% |
   | Authoritative tone | +25% |
   | Improve clarity | +20% |
   | Technical terms | +18% |
   | Keyword stuffing | **-10%** |

   **Structural checks:**
   - Key passages 40-60 words (optimal for snippet extraction)
   - H2/H3 headings matching query phrasing
   - Definition blocks, step-by-step blocks, comparison tables, pros/cons, FAQ
   - Schema markup (Product, FAQ, Organization JSON-LD)
   - "vs competitor" pages that AI can reference for comparison queries

   **Bot access check:**

   ```
   Verify robots.txt allows: GPTBot, ChatGPT-User, PerplexityBot,
   ClaudeBot, anthropic-ai, Google-Extended, Bingbot
   ```

   **Most-cited content types:** Comparison articles (~33%), definitive guides (~15%), original research (~12%), best-of lists (~10%)

4. **Generate report:**

```markdown
## SEO Audit: {Domain}

### Technical Score: {X}/100

| Issue | Severity | Pages Affected | Fix |
| ----- | -------- | -------------- | --- |

### Content Opportunities

| Keyword Cluster | Search Volume Est. | Current Ranking | Opportunity |
| --------------- | ------------------ | --------------- | ----------- |

### AI/GEO Readiness: {X}/100

| Factor            | Status   | Recommendation                        |
| ----------------- | -------- | ------------------------------------- |
| Structured data   | Missing  | Add Product, FAQ, Organization schema |
| Content clarity   | Moderate | Add comparison tables, data points    |
| Authority signals | Low      | Add case studies, benchmarks          |
```

---

## Mode 6: Churn Prevention

**Goal:** Identify and reduce user churn.

### Process

1. **Analyze codebase for retention signals:**
   - User activity tracking (last login, feature usage)
   - Billing/subscription logic (cancel flow, downgrade path)
   - Email/notification triggers

2. **Identify churn risk factors:**

| Risk Factor          | How to Detect           | Intervention               |
| -------------------- | ----------------------- | -------------------------- |
| Low engagement       | Last login > 7 days     | Re-engagement email        |
| Feature non-adoption | Key feature never used  | In-app tooltip/nudge       |
| Support friction     | High error rate in logs | Proactive help             |
| Billing shock        | Upcoming tier change    | Price change preview email |
| Missing integration  | No connected services   | Integration setup wizard   |

3. **Health score model (0-100):**

   ```
   Health = Login frequency (0.30) + Feature usage (0.25) +
            Support sentiment (0.15) + Billing health (0.15) +
            Engagement (0.15)
   ```

   - 80-100: Healthy (upsell opportunity)
   - 60-79: Needs attention (proactive check-in)
   - 40-59: At risk (intervention required)
   - 0-39: Critical (personal outreach)

4. **Cancel flow with dynamic save offers:**

   | Cancel Reason        | Primary Offer                | Fallback                |
   | -------------------- | ---------------------------- | ----------------------- |
   | Too expensive        | 20-30% discount 2-3 months   | Downgrade to lower tier |
   | Not using enough     | 1-3 month pause              | Free onboarding session |
   | Missing feature      | Roadmap preview + timeline   | Workaround guide        |
   | Switching competitor | Comparison + discount        | Feedback session        |
   | Technical issues     | Immediate support escalation | Credit + priority fix   |

   **Target benchmarks:** Cancel flow save rate 25-35%, offer acceptance 15-25%, pause reactivation 60-80%.

5. **Design additional interventions:**
   - Automated email sequences for at-risk users
   - In-app health score/engagement dashboard
   - Win-back sequence for churned users (2 emails over 30 days)

---

## Mode 7: Email Sequences

**Goal:** Design lifecycle email sequences that drive activation and retention.

### Sequences

| Sequence      | Trigger             | Goal              | Emails           |
| ------------- | ------------------- | ----------------- | ---------------- |
| Welcome       | Signup              | Activate          | 3-5 over 7 days  |
| Onboarding    | First login         | Reach aha moment  | 3-4 over 5 days  |
| Re-engagement | Inactive 7+ days    | Return to product | 2-3 over 14 days |
| Upgrade       | Hit free tier limit | Convert to paid   | 2-3 over 7 days  |
| Win-back      | Cancelled           | Resubscribe       | 2 over 30 days   |

For each email, generate:

- Subject line (with A/B variant)
- Preview text
- Body copy (plain text + HTML structure)
- CTA button text and destination
- Send timing (days after trigger, time of day)

---

## Mode 8: Competitor Comparison Page

**Goal:** Create a "Product vs Competitor" page optimized for search and conversion.

### Process

1. **Research competitor:**
   - Fetch competitor site via Firecrawl
   - Extract: pricing, features, positioning
   - WebSearch for reviews and complaints

2. **Build comparison matrix:**

| Feature   | Our Product    | Competitor       | Verdict            |
| --------- | -------------- | ---------------- | ------------------ |
| {feature} | {our approach} | {their approach} | {who wins and why} |

3. **Generate page:**
   - SEO-optimized title: "{Product} vs {Competitor}: {Year} Comparison"
   - Feature-by-feature comparison with honest assessment
   - Migration guide (if applicable)
   - CTA: "Try {Product} free" with positioning against competitor weakness

---

## Output

All reports are written to `.claude/growth/` directory:

```
.claude/growth/
├── cro-report-{slug}.md
├── pricing-analysis.md
├── signup-flow-audit.md
├── onboarding-plan.md
├── seo-audit.md
├── churn-prevention.md
├── email-sequences/
│   ├── welcome.md
│   ├── onboarding.md
│   └── re-engagement.md
└── vs-{competitor}.md
```

---

## Model Routing

| Mode              | Model  | Rationale                                |
| ----------------- | ------ | ---------------------------------------- |
| CRO analysis      | sonnet | Pattern matching + copy suggestions      |
| Pricing strategy  | opus   | Strategic thinking, competitive analysis |
| Signup/onboarding | sonnet | UX patterns, code changes                |
| SEO audit         | sonnet | Technical checks + content analysis      |
| Churn analysis    | sonnet | Data pattern recognition                 |
| Email copy        | sonnet | Creative writing, structured output      |
| Competitor page   | opus   | Research synthesis, positioning strategy |

---

## Usage

```bash
# Analyze a landing page
/growth cro https://contably.ai

# Review pricing model
/growth pricing

# Optimize signup flow
/growth signup

# Full growth audit
/growth full-audit

# Build comparison page
/growth competitor https://quickbooks.com
```

---

## Version

**v1.0.0** — Initial release. 8 modes covering the full SaaS growth stack: CRO, pricing, signup, onboarding, SEO/GEO, churn, email sequences, competitor comparison.
