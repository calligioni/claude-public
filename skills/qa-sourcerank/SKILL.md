---
name: qa-sourcerank
description: "Full QA cycle for SourceRank AI with swarm-parallel persona testing: discover bugs via 4 concurrent virtual user personas on production, generate CTO/CPO reports, fix issues via /qa-fix, verify via /qa-verify, detect regressions. True parallel execution via TeamCreate swarm. Uses psql for QA issue tracking in SourceRank Supabase DB. Triggers on: qa sourcerank, sourcerank qa, test sourcerank, qa cycle sourcerank."
user-invocable: true
context: fork
model: opus
effort: high
allowed-tools:
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeamCreate
  - TeamDelete
  - SendMessage
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - mcp__chrome-devtools__*
  - mcp__playwright__*
  - mcp__browserless__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__chrome-devtools__click: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__fill: { destructiveHint: false, idempotentHint: false }
  mcp__chrome-devtools__navigate_page:
    { readOnlyHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
  SendMessage: { openWorldHint: true, idempotentHint: false }
  TeamDelete: { destructiveHint: true, idempotentHint: true }
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

# QA SourceRank Skill (v4.1 - browse CLI Primary + Self-Healing Autonomous)

Full QA lifecycle for SourceRank AI with **self-healing autonomous operation**. Runs end-to-end without stopping — discovers bugs, fixes them, deploys, verifies, and loops until **100% coverage**. Learns from every repair via MCP memory so repeated issues get fixed faster. The orchestrator (opus) **NEVER aborts** — even if 100% of features are broken, it proceeds to fix them.

## What It Does

When you run `/qa-sourcerank`, it orchestrates a **continuous loop** that only stops at 100% coverage:

1. **PRE-FLIGHT** - Check existing open issues, warm up Render, load repair memory patterns
2. **DISCOVER** - Spawn 4 persona agents **in parallel** via TeamCreate swarm that test production, track feature coverage, and report bugs to QA DB
3. **CROSS-PERSONA DETECTION** - Real-time pattern analysis as personas report back (systemic bugs, permission leaks, etc.)
4. **REPORT** - Generate CTO and CPO reports from QA database
5. **COVERAGE REPORT** - Feature coverage matrix showing approved/blocked/untested per persona
6. **TRIAGE** - Strategic triage of discovered issues (skip if systemic root cause is obvious)
7. **FIX** - Opus developers fix bugs in parallel, informed by repair memory from past sessions
8. **VERIFY** - Haiku agents verify fixes via browser testing on production
9. **REGRESSION CHECK** - Compare with previous sessions, detect regressions
10. **DEPLOY + CONTINUE** - Deploy decision based on coverage %. Loop until 100% approved
11. **LEARN** - Save successful repair patterns to MCP memory for future sessions

## Browser Tool: browse CLI

**Primary browser tool:** `~/.local/bin/browse` — compiled headless Chromium CLI, ~100ms per call, zero MCP token overhead.

**Detection:**

```bash
test -x ~/.local/bin/browse && echo "browse available" || echo "fallback to Chrome DevTools MCP"
```

**Command reference:**

| Command                                  | Purpose                           |
| ---------------------------------------- | --------------------------------- |
| `browse goto <url>`                      | Navigate to URL                   |
| `browse snapshot -i`                     | Interactive elements with @e refs |
| `browse snapshot -i -C`                  | + non-ARIA clickable @c refs      |
| `browse snapshot -D`                     | Diff vs previous snapshot         |
| `browse snapshot -a -o path.png`         | Annotated screenshot              |
| `browse screenshot [path]`               | Plain screenshot                  |
| `browse text`                            | Page text content                 |
| `browse click @e3`                       | Click element by ref              |
| `browse fill @e4 "value"`                | Fill input by ref                 |
| `browse console`                         | Console ring buffer               |
| `browse network`                         | Network ring buffer               |
| `browse links`                           | Extract all links                 |
| `browse forms`                           | Extract all forms                 |
| `browse js "expr"`                       | Evaluate JS                       |
| `browse cookies`                         | Get cookies                       |
| `browse cookie-import-browser [browser]` | Import from Chrome/Arc/Brave      |
| `browse perf`                            | Performance metrics               |

**Headed mode escalation:** For visual/CSS/layout failures that headless screenshots can't diagnose, escalate to `/open-gstack-browser` — a steerable Chromium with Claude Code sidebar for live interactive debugging.

**Fallback:** If `browse` is not available, fall back to `mcp__chrome-devtools__*` tools.

**Per-persona isolation:** Each persona agent MUST set a unique `BROWSE_STATE_FILE` env var so each gets its own Chromium instance, preventing session conflicts between the 4 concurrent testers:

```bash
# In each persona agent's spawn prompt, set before any browse command:
export BROWSE_STATE_FILE="/tmp/browse-state-{persona_slug}.json"
# e.g.:
export BROWSE_STATE_FILE="/tmp/browse-state-sarah.json"
export BROWSE_STATE_FILE="/tmp/browse-state-marcus.json"
export BROWSE_STATE_FILE="/tmp/browse-state-diana.json"
export BROWSE_STATE_FILE="/tmp/browse-state-alex.json"
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│               QA SOURCERANK ORCHESTRATOR (opus)                           │
│                                                                           │
│  PRE-FLIGHT: Render warmup + open issue check + load repair memory       │
│           │                                                               │
│           ▼                                                               │
│  Phase 0-1: Init + Environment Discovery                                  │
│           │                                                               │
│           ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │           PHASE 2: PERSONA SWARM (TeamCreate + sonnet × 4)         │  │
│  │                                                                      │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │  │
│  │  │  SARAH   │  │  MARCUS  │  │  DIANA   │  │   ALEX   │           │  │
│  │  │CMO/Admin │  │ SEO/Pwr  │  │ Agency   │  │ Brand Mgr│           │  │
│  │  │ (admin)  │◀─▶│ (member) │◀─▶│ (admin)  │◀─▶│ (member) │           │  │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │  │
│  │       │              │              │              │                 │  │
│  │       └──────────────┴──────────────┴──────────────┘                 │  │
│  │                          │                                           │  │
│  │             ┌────────────┴────────────┐                              │  │
│  │             │  REAL-TIME MESSAGING     │                              │  │
│  │             │ • Failure broadcasts     │                              │  │
│  │             │ • Duplicate alerts       │                              │  │
│  │             │ • Cross-persona patterns │                              │  │
│  │             └─────────────────────────┘                              │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│           │                                                               │
│           ▼                                                               │
│  Phase 3-4: CROSS-PERSONA + REPORTS + COVERAGE                           │
│           │                                                               │
│           ▼                                                               │
│  Phase 5: TRIAGE (inline — skip if systemic root cause obvious)          │
│           │                                                               │
│           ▼                                                               │
│  Phase 6: FIX (opus × N tasks, informed by repair memory)                │
│           │                                                               │
│           ▼                                                               │
│  Phase 6.5: LEARN (save repair patterns to MCP memory)                   │
│           │                                                               │
│           ▼                                                               │
│  Phase 7-8: VERIFY + REGRESSION CHECK                                    │
│           │                                                               │
│           ▼                                                               │
│  Phase 9: DEPLOY + CONTINUE                                              │
│           │                                                               │
│        commit, push, verify deploy, unblock features                     │
│           │                                                               │
│        100% features approved?                                           │
│        NO  + cycle < 10 ─────────────────────────────── (loop back)      │
│        YES → output final summary, stop                                   │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL (psql) │ MCP Memory (repair patterns + fix learnings)    │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

## Usage

```
/qa-sourcerank                     # Full cycle: discover → report → fix → verify
/qa-sourcerank --discover-only     # Only run persona discovery + report
/qa-sourcerank --fix-only          # Only fix open issues from DB
/qa-sourcerank --verify-only       # Only verify issues in TESTING status
/qa-sourcerank --report            # Generate CTO/CPO reports from current DB state
/qa-sourcerank --severity p0       # Full cycle but only for P0 issues
/qa-sourcerank --skip-fix          # Discover + report + verify (no auto-fix)
/qa-sourcerank --url URL           # Override target URL (default: prod)
/qa-sourcerank --limit N           # Max issues to process per phase
```

## About SourceRank AI

SourceRank is an enterprise B2B SaaS platform that monitors brand mentions across AI assistants (ChatGPT, Claude, Perplexity, Gemini, Google SGE) and provides competitive analysis, content quality assessment, and reputation management.

**Tech Stack:**

- Frontend: Next.js 14, React 18, TailwindCSS, Radix UI (shadcn/ui)
- Backend: Fastify 4.25, Node.js, TypeScript
- Database: PostgreSQL (Supabase), Drizzle ORM
- Auth: Supabase Auth (JWT)
- Queue: BullMQ, Redis
- Deployment: Render.com
- Package manager: pnpm (turborepo monorepo)

**Monorepo Structure:**

```
apps/
  web/          # Next.js frontend (port 3000)
  api/          # Fastify backend (port 4000)
  worker/       # BullMQ worker
packages/
  database/     # Drizzle ORM schema + migrations
  shared/       # Shared types and utilities
```

**Production URLs:**

- Web app: https://sourcerank-web.onrender.com
- API: https://sourcerank-api.onrender.com

**Key Routes (Next.js app router at `apps/web/app/[locale]/`):**

Public:

- `/` - Landing page
- `/about` - About page
- `/solutions` - Solutions page
- `/blog/innovation` - Blog
- `/sign-in` - Login
- `/sign-up` - Registration

Dashboard (authenticated):

- `/dashboard` - Main dashboard overview
- `/dashboard/brands` - Brand management
- `/dashboard/brands/[id]` - Brand detail
- `/dashboard/brands/[id]/facts` - Brand facts
- `/dashboard/monitor` - AI monitoring
- `/dashboard/content` - Content analysis
- `/dashboard/competitive` - Competitive analysis
- `/dashboard/competitive-intelligence` - Competitive intelligence
- `/dashboard/competitors` - Competitor tracking
- `/dashboard/authority` - Authority scoring
- `/dashboard/alerts` - Alerts center
- `/dashboard/alerts/hallucinations` - Hallucination detection
- `/dashboard/recommendations` - AI recommendations
- `/dashboard/quality` - Content quality
- `/dashboard/intelligence` - Intelligence hub
- `/dashboard/reports` - Reports
- `/dashboard/integrations` - Integrations (CMS, etc.)
- `/dashboard/integrations/[id]` - Integration detail
- `/dashboard/team` - Team management
- `/dashboard/settings` - Settings
- `/dashboard/settings/white-label` - White label config (with reports, CSS, email templates)
- `/dashboard/settings/billing` - Billing and subscription management
- `/dashboard/settings/ai-models` - AI model configuration
- `/dashboard/settings/api-keys` - API key management
- `/dashboard/settings/webhooks` - Webhook configuration
- `/dashboard/settings/api` - Public API documentation and keys
- `/dashboard/analytics` - Advanced analytics (trends, attribution, predictions, benchmarks)
- `/dashboard/stream` - Real-time event stream (mentions, alerts, metrics)
- `/dashboard/holding` - Holding/portfolio view
- `/dashboard/agency` - Agency mode
- `/dashboard/agency/clients` - Agency clients
- `/dashboard/agency/clients/[clientId]` - Agency client detail
- `/dashboard/agency/revenue` - Agency revenue
- `/dashboard/agency/margins` - Agency margins
- `/dashboard/readiness` - GEO Readiness Audit
- `/dashboard/site-audit` - Site audit issues and crawl results
- `/dashboard/backlog` - Content/issue backlog management
- `/dashboard/visibility` - Brand visibility tracking across AI engines
- `/accept-invitation` - Team invitation acceptance

**API Routes (Fastify at `apps/api/src/routes/`):**
brands, monitoring, content, intelligence, reports, alerts, billing, competitors, authority, organizations, users, competitive, recommendations, holdings, tokens, cms, agency, white-label, stream, analytics, platform, public, ai, backlog, site-audit, visibility, readiness

## QA Database Schema

Before first run, create the QA schema. Run via psql:

```sql
-- QA Sessions
CREATE TABLE IF NOT EXISTS qa_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  trigger VARCHAR(50) NOT NULL DEFAULT 'manual',
  status VARCHAR(20) NOT NULL DEFAULT 'started',
  personas TEXT[] DEFAULT '{}',
  summary TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);

-- QA Issues
CREATE TABLE IF NOT EXISTS qa_issues (
  id SERIAL PRIMARY KEY,
  session_id UUID REFERENCES qa_sessions(id),
  title TEXT NOT NULL,
  severity VARCHAR(20) NOT NULL DEFAULT 'p2-medium',
  status VARCHAR(30) NOT NULL DEFAULT 'open',
  category VARCHAR(30),
  persona VARCHAR(50),
  endpoint TEXT,
  http_status INTEGER,
  error_message TEXT,
  expected TEXT,
  actual TEXT,
  affected_page TEXT,
  reproduction_steps JSONB DEFAULT '[]',
  assigned_to VARCHAR(100),
  fixed_by VARCHAR(100),
  commit_hash VARCHAR(40),
  original_issue_id INTEGER REFERENCES qa_issues(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- QA Issue Comments
CREATE TABLE IF NOT EXISTS qa_issue_comments (
  id SERIAL PRIMARY KEY,
  issue_id INTEGER REFERENCES qa_issues(id),
  author VARCHAR(100) NOT NULL,
  comment_type VARCHAR(20) DEFAULT 'note',
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- QA Verifications
CREATE TABLE IF NOT EXISTS qa_verifications (
  id SERIAL PRIMARY KEY,
  issue_id INTEGER REFERENCES qa_issues(id),
  session_id UUID REFERENCES qa_sessions(id),
  persona VARCHAR(50),
  passed BOOLEAN NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- QA Persona Sessions
CREATE TABLE IF NOT EXISTS qa_persona_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID REFERENCES qa_sessions(id),
  persona VARCHAR(50) NOT NULL,
  satisfaction INTEGER CHECK (satisfaction BETWEEN 1 AND 10),
  pages_visited TEXT[] DEFAULT '{}',
  workflows_tested TEXT[] DEFAULT '{}',
  observations TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- QA Feature Coverage (tracks per-feature approval status)
CREATE TABLE IF NOT EXISTS qa_feature_coverage (
  id SERIAL PRIMARY KEY,
  session_id UUID REFERENCES qa_sessions(id),
  feature_key VARCHAR(60) NOT NULL,
  feature_name TEXT NOT NULL,
  persona VARCHAR(50) NOT NULL,
  route TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'untested',
  -- status: untested | in_progress | tested | approved | blocked
  workflows_total INTEGER NOT NULL DEFAULT 0,
  workflows_passed INTEGER NOT NULL DEFAULT 0,
  workflows_failed INTEGER NOT NULL DEFAULT 0,
  blocking_issue_ids INTEGER[] DEFAULT '{}',
  tested_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  notes TEXT,
  UNIQUE(session_id, feature_key, persona)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_qa_issues_session ON qa_issues(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_issues_status ON qa_issues(status);
CREATE INDEX IF NOT EXISTS idx_qa_issues_severity ON qa_issues(severity);
CREATE INDEX IF NOT EXISTS idx_qa_verifications_issue ON qa_verifications(issue_id);
CREATE INDEX IF NOT EXISTS idx_qa_persona_sessions_session ON qa_persona_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_feature_coverage_session ON qa_feature_coverage(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_feature_coverage_status ON qa_feature_coverage(status);
```

**IMPORTANT:** If `qa_feature_coverage` table does not exist, create it at session start. All other QA tables already exist.

## Feature Registry

The QA skill tracks **feature coverage** to ensure every feature is tested and approved before the cycle ends. Features are seeded into `qa_feature_coverage` at session start.

### Feature Matrix (56 coverage rows across 4 personas)

```
SARAH (CMO/Admin) — 17 features:
  landing-page        | /                              | Landing page messaging, CTAs, pricing, demo sections
  sign-in             | /sign-in                       | Login flow
  dashboard-overview  | /dashboard                     | Dashboard KPIs and widgets
  brands-list         | /dashboard/brands              | Brand management and overview
  brand-detail        | /dashboard/brands/[id]         | Brand detail with AI mentions
  competitive-analysis| /dashboard/competitive         | Competitive analysis
  competitive-intel   | /dashboard/competitive-intelligence | Deep competitive intel
  reports             | /dashboard/reports             | Report generation and export
  alerts              | /dashboard/alerts              | Alert configuration and review
  team-management     | /dashboard/team                | Team management
  settings            | /dashboard/settings            | Organization settings
  billing             | /dashboard/settings/billing    | Billing plans, subscription, invoices
  analytics           | /dashboard/analytics           | Advanced analytics (trends, attribution, predictions, benchmarks)
  stream              | /dashboard/stream              | Real-time event stream (mentions, alerts, metrics)
  ai-models           | /dashboard/settings/ai-models  | AI model provider configuration
  api-keys            | /dashboard/settings/api-keys   | API key creation and management
  visibility          | /dashboard/visibility          | Brand visibility tracking across AI engines

MARCUS (SEO/Member) — 16 features:
  dashboard-overview  | /dashboard                     | Daily overview
  monitor             | /dashboard/monitor             | AI monitoring (mentions, hallucinations, prompt library, brand facts)
  content-analysis    | /dashboard/content             | Content analysis and optimization
  authority           | /dashboard/authority           | Authority scoring and citations
  quality             | /dashboard/quality             | Content quality scores
  recommendations     | /dashboard/recommendations     | AI recommendations
  brand-facts         | /dashboard/brands/[id]/facts   | Brand facts management
  intelligence        | /dashboard/intelligence        | Intelligence hub
  integrations        | /dashboard/integrations        | CMS integrations
  readiness           | /dashboard/readiness           | AI readiness / GEO audit scoring
  integration-detail  | /dashboard/integrations/[id]   | Integration detail and config
  analytics           | /dashboard/analytics           | Analytics trends, attribution, predictions
  stream              | /dashboard/stream              | Real-time event stream monitoring
  site-audit          | /dashboard/site-audit          | Site audit issues and crawl results
  backlog             | /dashboard/backlog             | Content/issue backlog management
  visibility          | /dashboard/visibility          | Visibility sprint results and engine breakdown

DIANA (Agency) — 11 features:
  agency-dashboard    | /dashboard/agency              | Agency dashboard overview
  agency-clients      | /dashboard/agency/clients      | Client management
  agency-client-detail| /dashboard/agency/clients/[id] | Client detail
  agency-revenue      | /dashboard/agency/revenue      | Revenue tracking
  agency-margins      | /dashboard/agency/margins      | Margin analysis
  brands-list         | /dashboard/brands              | All brands across clients
  white-label         | /dashboard/settings/white-label| White label config (reports branding, CSS, email templates)
  reports             | /dashboard/reports             | Client report generation
  holding             | /dashboard/holding             | Portfolio/holding view
  webhooks            | /dashboard/settings/webhooks   | Webhook endpoint configuration
  public-api          | /dashboard/settings/api        | Public API docs and key management

ALEX (Brand Manager) — 12 features:
  dashboard-overview  | /dashboard                     | Dashboard overview
  brand-detail        | /dashboard/brands/[id]         | Brand deep dive
  alerts              | /dashboard/alerts              | Alert center
  hallucinations      | /dashboard/alerts/hallucinations | Hallucination detection
  competitors         | /dashboard/competitors         | Competitor tracking
  competitive-analysis| /dashboard/competitive         | Competitive landscape
  recommendations     | /dashboard/recommendations     | Brand recommendations
  quality             | /dashboard/quality             | Content quality review
  analytics           | /dashboard/analytics           | Analytics overview and predictions
  billing             | /dashboard/settings/billing    | Billing plans and invoices
  site-audit          | /dashboard/site-audit          | Site audit issues from brand perspective
  backlog             | /dashboard/backlog             | Backlog items for brand
```

### Seeding Feature Coverage (Phase 0)

At session start, seed all features into the coverage table:

```bash
# Seed Sarah's features
psql "$SRDB" -t -A -c "
INSERT INTO qa_feature_coverage (session_id, feature_key, feature_name, persona, route, workflows_total) VALUES
  ('{sid}', 'landing-page', 'Landing page messaging and CTAs', 'sarah', '/', 3),
  ('{sid}', 'sign-in', 'Login flow', 'sarah', '/sign-in', 1),
  ('{sid}', 'dashboard-overview', 'Dashboard KPIs and widgets', 'sarah', '/dashboard', 2),
  ('{sid}', 'brands-list', 'Brand management and overview', 'sarah', '/dashboard/brands', 2),
  ('{sid}', 'brand-detail', 'Brand detail with AI mentions', 'sarah', '/dashboard/brands/[id]', 2),
  ('{sid}', 'competitive-analysis', 'Competitive analysis', 'sarah', '/dashboard/competitive', 1),
  ('{sid}', 'competitive-intel', 'Deep competitive intel', 'sarah', '/dashboard/competitive-intelligence', 1),
  ('{sid}', 'reports', 'Report generation and export', 'sarah', '/dashboard/reports', 2),
  ('{sid}', 'alerts', 'Alert configuration and review', 'sarah', '/dashboard/alerts', 2),
  ('{sid}', 'team-management', 'Team management', 'sarah', '/dashboard/team', 2),
  ('{sid}', 'settings', 'Organization settings', 'sarah', '/dashboard/settings', 1),
  ('{sid}', 'billing', 'Billing plans and subscription', 'sarah', '/dashboard/settings/billing', 2),
  ('{sid}', 'analytics', 'Advanced analytics dashboard', 'sarah', '/dashboard/analytics', 2),
  ('{sid}', 'stream', 'Real-time event stream', 'sarah', '/dashboard/stream', 1),
  ('{sid}', 'ai-models', 'AI model configuration', 'sarah', '/dashboard/settings/ai-models', 2),
  ('{sid}', 'api-keys', 'API key management', 'sarah', '/dashboard/settings/api-keys', 2),
  ('{sid}', 'visibility', 'Brand visibility tracking', 'sarah', '/dashboard/visibility', 2)
ON CONFLICT (session_id, feature_key, persona) DO NOTHING;
"

# Seed Marcus's features
psql "$SRDB" -t -A -c "
INSERT INTO qa_feature_coverage (session_id, feature_key, feature_name, persona, route, workflows_total) VALUES
  ('{sid}', 'dashboard-overview', 'Daily overview', 'marcus', '/dashboard', 2),
  ('{sid}', 'monitor', 'AI monitoring setup and results', 'marcus', '/dashboard/monitor', 2),
  ('{sid}', 'content-analysis', 'Content analysis and optimization', 'marcus', '/dashboard/content', 2),
  ('{sid}', 'authority', 'Authority scoring and citations', 'marcus', '/dashboard/authority', 2),
  ('{sid}', 'quality', 'Content quality scores', 'marcus', '/dashboard/quality', 2),
  ('{sid}', 'recommendations', 'AI recommendations', 'marcus', '/dashboard/recommendations', 1),
  ('{sid}', 'brand-facts', 'Brand facts management', 'marcus', '/dashboard/brands/[id]/facts', 2),
  ('{sid}', 'intelligence', 'Intelligence hub', 'marcus', '/dashboard/intelligence', 1),
  ('{sid}', 'integrations', 'CMS integrations', 'marcus', '/dashboard/integrations', 2),
  ('{sid}', 'readiness', 'AI readiness scoring', 'marcus', '/dashboard/readiness', 2),
  ('{sid}', 'integration-detail', 'Integration detail and config', 'marcus', '/dashboard/integrations/[id]', 2),
  ('{sid}', 'analytics', 'Analytics trends and attribution', 'marcus', '/dashboard/analytics', 2),
  ('{sid}', 'stream', 'Real-time event stream', 'marcus', '/dashboard/stream', 1),
  ('{sid}', 'site-audit', 'Site audit issues and crawl results', 'marcus', '/dashboard/site-audit', 2),
  ('{sid}', 'backlog', 'Content/issue backlog management', 'marcus', '/dashboard/backlog', 2),
  ('{sid}', 'visibility', 'Visibility sprint results and engine breakdown', 'marcus', '/dashboard/visibility', 2)
ON CONFLICT (session_id, feature_key, persona) DO NOTHING;
"

# Seed Diana's features
psql "$SRDB" -t -A -c "
INSERT INTO qa_feature_coverage (session_id, feature_key, feature_name, persona, route, workflows_total) VALUES
  ('{sid}', 'agency-dashboard', 'Agency dashboard overview', 'diana', '/dashboard/agency', 2),
  ('{sid}', 'agency-clients', 'Client management', 'diana', '/dashboard/agency/clients', 2),
  ('{sid}', 'agency-client-detail', 'Client detail', 'diana', '/dashboard/agency/clients/[id]', 2),
  ('{sid}', 'agency-revenue', 'Revenue tracking', 'diana', '/dashboard/agency/revenue', 1),
  ('{sid}', 'agency-margins', 'Margin analysis', 'diana', '/dashboard/agency/margins', 1),
  ('{sid}', 'brands-list', 'All brands across clients', 'diana', '/dashboard/brands', 1),
  ('{sid}', 'white-label', 'White label configuration', 'diana', '/dashboard/settings/white-label', 2),
  ('{sid}', 'reports', 'Client report generation', 'diana', '/dashboard/reports', 1),
  ('{sid}', 'holding', 'Portfolio/holding view', 'diana', '/dashboard/holding', 1),
  ('{sid}', 'webhooks', 'Webhook endpoint configuration', 'diana', '/dashboard/settings/webhooks', 2),
  ('{sid}', 'public-api', 'Public API docs and key management', 'diana', '/dashboard/settings/api', 2)
ON CONFLICT (session_id, feature_key, persona) DO NOTHING;
"

# Seed Alex's features
psql "$SRDB" -t -A -c "
INSERT INTO qa_feature_coverage (session_id, feature_key, feature_name, persona, route, workflows_total) VALUES
  ('{sid}', 'dashboard-overview', 'Dashboard overview', 'alex', '/dashboard', 1),
  ('{sid}', 'brand-detail', 'Brand deep dive', 'alex', '/dashboard/brands/[id]', 2),
  ('{sid}', 'alerts', 'Alert center', 'alex', '/dashboard/alerts', 2),
  ('{sid}', 'hallucinations', 'Hallucination detection', 'alex', '/dashboard/alerts/hallucinations', 2),
  ('{sid}', 'competitors', 'Competitor tracking', 'alex', '/dashboard/competitors', 1),
  ('{sid}', 'competitive-analysis', 'Competitive landscape', 'alex', '/dashboard/competitive', 1),
  ('{sid}', 'recommendations', 'Brand recommendations', 'alex', '/dashboard/recommendations', 1),
  ('{sid}', 'quality', 'Content quality review', 'alex', '/dashboard/quality', 1),
  ('{sid}', 'analytics', 'Analytics overview and predictions', 'alex', '/dashboard/analytics', 1),
  ('{sid}', 'billing', 'Billing plans and invoices', 'alex', '/dashboard/settings/billing', 1),
  ('{sid}', 'site-audit', 'Site audit issues from brand perspective', 'alex', '/dashboard/site-audit', 1),
  ('{sid}', 'backlog', 'Backlog items for brand', 'alex', '/dashboard/backlog', 1)
ON CONFLICT (session_id, feature_key, persona) DO NOTHING;
"
```

## Database Access

The `mcp__postgres__query` tool is connected to a DIFFERENT database (Contably/Claudia), NOT SourceRank. For ALL database operations in this skill, use `psql` via Bash.

**Connection pattern for ALL SQL queries:**

```bash
# Set connection string shortcut at session start:
export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

# For SELECT queries (clean output, no headers):
psql "$SRDB" -t -A -c "SELECT id, title FROM qa_issues WHERE status = 'open'"

# For JSON output (recommended for structured data):
psql "$SRDB" -t -A -c "SELECT json_agg(t) FROM (SELECT id, title FROM qa_issues) t"

# For INSERT/UPDATE with RETURNING:
psql "$SRDB" -t -A -c "INSERT INTO qa_sessions (trigger, personas) VALUES ('qa-sourcerank', ARRAY['sarah','marcus','diana','alex']) RETURNING id"
```

**CRITICAL:**

- Always use `-t -A` flags for clean output (no headers, no alignment)
- Use `-c` for single queries
- Escape single quotes in values by doubling them (`''`)
- DO NOT use `mcp__postgres__query` — it points to the wrong database
- Always set `SRDB` env var at the start of the session for convenience

### Duplicate Detection

Before creating ANY issue, always run a duplicate check:

```bash
# Check by affected_page + similar title
psql "$SRDB" -t -A -c "
  SELECT id, title, status, severity
  FROM qa_issues
  WHERE (affected_page = '{page}' OR endpoint = '{endpoint}')
    AND status NOT IN ('closed', 'verified')
  ORDER BY created_at DESC
  LIMIT 5
"

# Check by error message pattern
psql "$SRDB" -t -A -c "
  SELECT id, title, status
  FROM qa_issues
  WHERE error_message ILIKE '%{key_error_phrase}%'
    AND status NOT IN ('closed', 'verified')
  LIMIT 3
"
```

If a duplicate is found, add a comment instead of creating a new issue:

```bash
psql "$SRDB" -t -A -c "
  INSERT INTO qa_issue_comments (issue_id, author, comment_type, content)
  VALUES ({existing_id}, '{persona}', 'note', 'Still reproducing as of {date}. {additional_context}')
"
```

## SourceRank User Personas

### Persona 1: Sarah Chen - CMO / Head of Marketing

**Role:** Organization admin, primary decision-maker
**Background:** CMO at a mid-size SaaS company (200 employees). Needs to understand how AI assistants recommend their product vs. competitors.
**Goals:** Track brand visibility across AI platforms, monitor competitive landscape, report to board
**Tech comfort:** Medium - uses dashboards daily, expects clear data visualization
**Frustration triggers:** Slow loading charts, unclear metrics, missing data, confusing navigation

**Test Routes:**

- `/` - Landing page (evaluate messaging clarity)
- `/sign-in` - Login flow
- `/dashboard` - Overview KPIs and widgets
- `/dashboard/brands` - Brand management and overview
- `/dashboard/brands/[id]` - Brand detail with AI mention data
- `/dashboard/competitive` - Competitive analysis
- `/dashboard/competitive-intelligence` - Deep competitive intel
- `/dashboard/reports` - Report generation and export
- `/dashboard/alerts` - Alert configuration and review
- `/dashboard/team` - Team management
- `/dashboard/settings` - Organization settings
- `/dashboard/settings/billing` - Billing and subscription management
- `/dashboard/analytics` - Advanced analytics dashboard
- `/dashboard/stream` - Real-time event stream
- `/dashboard/settings/ai-models` - AI model configuration
- `/dashboard/settings/api-keys` - API key management
- `/dashboard/visibility` - Brand visibility tracking across AI engines

**Test Workflows:**

1. Login → Dashboard → Check all KPI widgets load → Verify data freshness
2. Navigate to Brands → Select a brand → Review AI mention data → Check competitor comparison
3. Open Competitive Intelligence → Review Share of Voice → Verify charts render
4. Generate a report → Download PDF → Verify content accuracy
5. Check alerts → Review hallucination alerts → Mark as reviewed
6. Manage team → Invite new member → Verify invitation flow
7. Navigate settings → Update organization details → Verify persistence
8. Open Billing → Check subscription plan details → Review invoice history
9. Open Analytics → Check trends, attribution, predictions → Verify tab navigation
10. Open Stream → Connect to real-time feed → Verify events appear
11. Open AI Models → Check provider configuration → Verify model list loads
12. Open API Keys → Create key → Verify key appears in list
13. Open Visibility → Check visibility scores per AI engine → Verify data loads

---

### Persona 2: Marcus Rivera - SEO/Content Manager

**Role:** Organization member, daily active user
**Background:** Senior SEO manager responsible for optimizing content for both traditional search and AI discovery. Power user who logs in daily.
**Goals:** Monitor brand mentions, analyze content quality, track authority scores, optimize AI visibility
**Tech comfort:** High - power user, expects keyboard shortcuts and fast navigation
**Frustration triggers:** Slow page loads, too many clicks for common tasks, broken filters, stale data

**Test Routes:**

- `/dashboard` - Daily overview
- `/dashboard/monitor` - AI monitoring setup and results
- `/dashboard/content` - Content analysis and optimization
- `/dashboard/authority` - Authority scoring and citation tracking
- `/dashboard/quality` - Content quality scores
- `/dashboard/recommendations` - AI-generated recommendations
- `/dashboard/brands/[id]/facts` - Brand facts management
- `/dashboard/intelligence` - Intelligence hub
- `/dashboard/integrations` - CMS integrations
- `/dashboard/analytics` - Analytics trends and attribution
- `/dashboard/stream` - Real-time event stream monitoring
- `/dashboard/site-audit` - Site audit issues and crawl results
- `/dashboard/backlog` - Content/issue backlog management
- `/dashboard/visibility` - Visibility sprint results and engine breakdown

**Test Workflows:**

1. Login → Dashboard → Monitor page → Check latest AI mentions across platforms
2. Navigate to Content → Review content quality scores → Filter by platform → Sort by score
3. Check Authority → Review citation network → Verify scores update
4. View Recommendations → Check actionable items → Verify relevance
5. Manage Brand Facts → Add/edit facts → Verify they persist
6. Check Integrations → Review connected CMS → Verify sync status
7. Navigate to Intelligence → Review insights → Verify data accuracy
8. Open Monitor → Check hallucination alerts tab → Verify prompt library tab → Verify brand facts tab
9. Open Analytics → Check trends data → Test attribution tab → Review predictions tab
10. Open Stream → Select channel → Connect → Verify events flow
11. Open Site Audit → Review crawl results → Check issue list → Verify filtering works
12. Open Backlog → Review backlog items → Check priority/status filters → Verify sorting
13. Open Visibility → Check sprint results → Review engine breakdown → Verify charts render

---

### Persona 3: Diana Foster - Agency Owner

**Role:** Agency admin, manages multiple client brands
**Background:** Runs a digital marketing agency with 15 client accounts. Uses SourceRank to provide AI visibility reports to clients.
**Goals:** Manage multiple brands efficiently, generate client reports, track revenue, white-label the platform
**Tech comfort:** Medium-high - comfortable with SaaS tools, expects multi-account workflows
**Frustration triggers:** Slow brand switching, can't bulk-operate, missing client-facing features

**Test Routes:**

- `/dashboard/agency` - Agency dashboard overview
- `/dashboard/agency/clients` - Client management
- `/dashboard/agency/clients/[clientId]` - Client detail
- `/dashboard/agency/revenue` - Revenue tracking
- `/dashboard/agency/margins` - Margin analysis
- `/dashboard/brands` - All brands across clients
- `/dashboard/settings/white-label` - White label configuration (with reports, CSS, email templates)
- `/dashboard/reports` - Client report generation
- `/dashboard/holding` - Portfolio/holding view
- `/dashboard/settings/webhooks` - Webhook endpoint configuration
- `/dashboard/settings/api` - Public API docs and key management

**Test Workflows:**

1. Login → Agency Dashboard → Check client overview → Verify all clients listed
2. Navigate to Client detail → Check brand performance → Generate client report
3. Review Revenue page → Verify revenue data → Check margin calculations
4. Configure White Label → Upload logo → Set colors → Preview branded experience
5. Switch between client brands → Verify data isolation between clients
6. Generate multi-client report → Download → Verify all clients included
7. Holding view → Portfolio overview → Verify aggregated metrics
8. White Label → Check Reports tab → Check CSS tab → Generate email template preview
9. Open Webhooks → Create webhook → Verify it appears in list
10. Open Public API → View API docs → Check key management section

---

### Persona 4: Alex Park - Brand Manager

**Role:** Organization member, focuses on brand health
**Background:** Brand manager at a consumer tech company. Focused on reputation and how AI represents the brand.
**Goals:** Monitor brand reputation in AI, detect hallucinations, track competitor mentions, get alerts
**Tech comfort:** Medium - comfortable with marketing tools, not deeply technical
**Frustration triggers:** False positives in alerts, unclear what AI is saying about the brand, slow reports

**Test Routes:**

- `/dashboard` - Dashboard overview
- `/dashboard/brands/[id]` - Brand deep dive
- `/dashboard/alerts` - Alert center
- `/dashboard/alerts/hallucinations` - Hallucination detection
- `/dashboard/competitors` - Competitor tracking
- `/dashboard/competitive` - Competitive landscape
- `/dashboard/recommendations` - Brand recommendations
- `/dashboard/quality` - Content quality review
- `/dashboard/analytics` - Analytics overview and predictions
- `/dashboard/settings/billing` - Billing plans and invoices
- `/dashboard/site-audit` - Site audit issues from brand perspective
- `/dashboard/backlog` - Backlog items for brand

**Test Workflows:**

1. Login → Dashboard → Check brand health summary → Verify sentiment data
2. Navigate to Brand detail → Check AI mention timeline → Verify platform breakdown
3. Check Hallucination alerts → Review detected inaccuracies → Verify source links
4. Open Competitors → Compare brand vs competitors → Verify Share of Voice accuracy
5. Review Recommendations → Check brand-specific advice → Verify actionability
6. Check Content Quality → Review scores per platform → Verify scoring logic
7. Navigate between features → Verify breadcrumbs and navigation consistency
8. Open Analytics → Check overview metrics → Review predictions tab
9. Open Billing → View plan details → Check invoices section
10. Open Site Audit → Review audit issues for brand → Verify issue details load
11. Open Backlog → Check backlog items → Verify filtering and priority sorting

---

## Test Credentials

Since SourceRank uses Supabase Auth, the QA skill needs valid test credentials.

**Before first run, ensure test users exist.** Check with:

```sql
SELECT id, email, role FROM users LIMIT 10;
```

If no test users exist, the personas should test public pages (landing, sign-up flow) and report that test accounts are needed.

**QA Test Credentials (pre-configured, email-confirmed):**

```
Sarah Chen (CMO/Admin)     → qa-admin@sourcerank.ai / QATest2026sr   (org admin, Test Organization)
Marcus Rivera (SEO/Member) → qa-member@sourcerank.ai / QATest2026sr  (org member, Test Organization)
Diana Foster (Agency)      → qa-admin@sourcerank.ai / QATest2026sr   (same admin, test agency features)
Alex Park (Brand Manager)  → qa-member@sourcerank.ai / QATest2026sr  (same member, test brand features)
```

**Organization:** Test Organization (id: c44f4b71-292e-4a55-a55d-e83a0c341387, plan: growth, brand_limit: 3)

Both accounts share the same password. Sarah/Diana use the admin account, Marcus/Alex use the member account. This tests both role levels.

## Execution Flow

### CRITICAL ORCHESTRATOR RULES

1. **The orchestrator NEVER tests features itself.** It ONLY orchestrates: creates sessions, seeds data, spawns personas, collects results, generates reports, spawns fixers, deploys. ALL browser testing is done by spawned persona agents.
2. **ALL 4 personas MUST be spawned in a SINGLE message** with 4 parallel Task calls. NEVER spawn them sequentially or one-at-a-time. NEVER use TaskCreate for personas — use Task tool with 4 calls in ONE response. Sequential persona spawning is a CRITICAL BUG in the orchestrator.
3. **The orchestrator MUST loop autonomously** after each deploy: check coverage → if < 100%, spawn the next cycle's personas immediately. Never output a report and stop unless coverage = 100% or cycle = 10.
4. **Keep orchestrator turns lean.** Each turn should do ONE phase, not multiple phases. This preserves context for the full cycle.

### NEVER ABORT — ALWAYS PROCEED TO FIX

**This is the #1 rule of the skill.** Previous versions aborted when discovery found systemic failures (e.g., "92% of features broken"). This is WRONG. The correct behavior:

1. **If ALL features are blocked by the same systemic issue** — this is actually the BEST case. One fix will unblock everything. Proceed to triage → fix → deploy → verify.
2. **If personas report empty pages, timeouts, or rendering failures** — these are bugs to fix, NOT reasons to abort. Log them, proceed to Phase 5-6.
3. **If the same issue was found in previous sessions** — check repair memory for the fix pattern. Apply it immediately.
4. **The ONLY valid reason to stop** is if both `browse` CLI and Chrome DevTools MCP are completely unavailable (can't test at all). Even then, try curl-based API testing first.

**NEVER:**

- Write "ABORTED" in the session status
- Output "DO NOT DEPLOY" without first attempting fixes
- Stop after discovery without proceeding to fix
- Say "platform is unusable" — your job is to MAKE it usable
- Create a report and stop. The report is an intermediate step, not the output.

**ALWAYS:**

- Proceed through ALL phases regardless of how many bugs are found
- If 100% of features are blocked, that means there's likely 1-2 root causes — fix those
- Complete at least one full discover → fix → deploy → verify cycle before any output

### Pre-Flight Phase (runs before Phase 0)

Before starting any QA cycle, run pre-flight checks:

#### Step 1: Warm up Render (prevent cold-start timeouts)

```bash
# Wake up both services — Render free tier sleeps after 15min inactivity
echo "Warming up Render services..."
curl -s -o /dev/null -w 'Web: %{http_code} (%{time_total}s)\n' https://sourcerank-web.onrender.com
curl -s -o /dev/null -w 'API: %{http_code} (%{time_total}s)\n' https://sourcerank-api.onrender.com/health

# If either returned non-200, wait 15s and retry (cold start)
sleep 15
curl -s -o /dev/null -w 'Web retry: %{http_code} (%{time_total}s)\n' https://sourcerank-web.onrender.com
curl -s -o /dev/null -w 'API retry: %{http_code} (%{time_total}s)\n' https://sourcerank-api.onrender.com/health
```

#### Step 2: Check existing open issues from previous sessions

```bash
export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

# Check for unresolved systemic issues
EXISTING_ISSUES=$(psql "$SRDB" -t -A -c "
  SELECT json_agg(t) FROM (
    SELECT id, title, severity, status, affected_page, category
    FROM qa_issues
    WHERE status NOT IN ('closed', 'verified')
    ORDER BY severity, created_at DESC
    LIMIT 20
  ) t
")
echo "Existing open issues: $EXISTING_ISSUES"

# If there are P0/P1 issues that were already identified, we can skip discovery
# and go straight to fix → deploy → verify for those specific issues
CRITICAL_COUNT=$(psql "$SRDB" -t -A -c "
  SELECT COUNT(*) FROM qa_issues
  WHERE status NOT IN ('closed', 'verified')
    AND severity IN ('p0-critical', 'p1-high')
")
echo "Open critical/high issues: $CRITICAL_COUNT"
```

**If CRITICAL_COUNT > 0 AND these issues have reproduction steps:** Consider running `--fix-only` first to clear the backlog, then run full discovery. This avoids re-discovering known issues.

#### Step 3: Load repair memory patterns

```bash
# Search MCP memory for past SourceRank repair patterns
```

```
mcp__memory__search_nodes({ query: "repair:sourcerank" })
mcp__memory__search_nodes({ query: "repair:rendering" })
mcp__memory__search_nodes({ query: "repair:dashboard" })
mcp__memory__search_nodes({ query: "repair:api" })
```

Store the retrieved patterns — pass them to fix agents in Phase 6 so they can apply known solutions.

### Phase 0: Initialize QA Session

```bash
export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

# Ensure qa_feature_coverage table exists
psql "$SRDB" -c "
CREATE TABLE IF NOT EXISTS qa_feature_coverage (
  id SERIAL PRIMARY KEY,
  session_id UUID REFERENCES qa_sessions(id),
  feature_key VARCHAR(60) NOT NULL,
  feature_name TEXT NOT NULL,
  persona VARCHAR(50) NOT NULL,
  route TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'untested',
  workflows_total INTEGER NOT NULL DEFAULT 0,
  workflows_passed INTEGER NOT NULL DEFAULT 0,
  workflows_failed INTEGER NOT NULL DEFAULT 0,
  blocking_issue_ids INTEGER[] DEFAULT '{}',
  tested_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  notes TEXT,
  UNIQUE(session_id, feature_key, persona)
);
CREATE INDEX IF NOT EXISTS idx_qa_feature_coverage_session ON qa_feature_coverage(session_id);
CREATE INDEX IF NOT EXISTS idx_qa_feature_coverage_status ON qa_feature_coverage(status);
"

# Create a new QA session
SESSION_ID=$(psql "$SRDB" -t -A -c "
  INSERT INTO qa_sessions (trigger, personas)
  VALUES ('qa-sourcerank', ARRAY['sarah','marcus','diana','alex'])
  RETURNING id
")
echo "Session: $SESSION_ID"

# Seed feature coverage matrix (see Feature Registry section for full INSERT statements)
# Run all 4 persona seed INSERTs here using $SESSION_ID
```

Also check if the other QA tables exist. If not, create them (see QA Database Schema section above).

After seeding, verify coverage:

```bash
psql "$SRDB" -t -A -c "
  SELECT persona, COUNT(*) as features, COUNT(*) FILTER (WHERE status = 'untested') as untested
  FROM qa_feature_coverage WHERE session_id = '{sid}'
  GROUP BY persona ORDER BY persona
"
# Expected: sarah=16, marcus=13, diana=11, alex=10 — all untested
```

### Phase 1: Environment Discovery

1. Determine target URL:
   - If `--url` flag provided, use that
   - Else check for running local dev: `http://localhost:3000`
   - Else use production: `https://sourcerank-web.onrender.com`
2. Verify the site is accessible:
   ```bash
   # Primary: browse CLI (zero MCP overhead)
   browse goto {url} && browse text | head -20
   # Fallback if browse unavailable: mcp__chrome-devtools__navigate_page
   ```
3. Check API health: `curl -s https://sourcerank-api.onrender.com/health`

**Default: Test against production** (https://sourcerank-web.onrender.com).
For local testing, use `--url http://localhost:3000`.

### Phase 2: Spawn Persona Swarm (Parallel via TeamCreate)

**This is the core differentiator: true parallel execution.**

#### Step 2a: Create the QA Team

```
TeamCreate({
  team_name: "qa-sourcerank-{session_id_short}",
  description: "QA swarm for SourceRank session {session_id}"
})
```

#### Step 2b: Load Shared Context from DB

Before spawning personas, gather shared context ONCE:

```bash
# Open issues (for duplicate avoidance)
OPEN_ISSUES=$(psql "$SRDB" -t -A -c "
  SELECT json_agg(t) FROM (
    SELECT id, title, severity, status, affected_page, endpoint
    FROM qa_issues
    WHERE status NOT IN ('closed', 'verified')
    ORDER BY severity, created_at
  ) t
")

# Verification queue (recently fixed bugs to re-test)
VERIFY_QUEUE=$(psql "$SRDB" -t -A -c "
  SELECT json_agg(t) FROM (
    SELECT id, title, affected_page, reproduction_steps
    FROM qa_issues
    WHERE status = 'testing'
  ) t
")

# Previous session data for regression detection
PREV_SESSION=$(psql "$SRDB" -t -A -c "
  SELECT json_agg(t) FROM (
    SELECT s.id, s.started_at, s.summary,
      (SELECT COUNT(*) FROM qa_issues WHERE session_id = s.id) as issue_count
    FROM qa_sessions s
    WHERE s.status = 'completed'
    ORDER BY s.started_at DESC LIMIT 3
  ) t
")
```

#### Step 2c: Spawn ALL 4 Personas in Parallel

**CRITICAL: You MUST include all 4 Task() calls in a SINGLE assistant response.** This is how parallel execution works in Claude Code — multiple Task tool calls in one message run concurrently. If you call Task once, wait for it, then call the next, they run SEQUENTIALLY which defeats the purpose. Put all 4 in ONE response.

```
# ALL 4 Task calls in ONE assistant message (they run in parallel automatically):

Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  name: "sarah-tester",
  team_name: "qa-sourcerank-{session_id_short}",
  prompt: "{sarah persona prompt with full context}"
})

Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  name: "marcus-tester",
  team_name: "qa-sourcerank-{session_id_short}",
  prompt: "{marcus persona prompt with full context}"
})

Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  name: "diana-tester",
  team_name: "qa-sourcerank-{session_id_short}",
  prompt: "{diana persona prompt with full context}"
})

Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  name: "alex-tester",
  team_name: "qa-sourcerank-{session_id_short}",
  prompt: "{alex persona prompt with full context}"
})
```

#### Persona Agent Prompt Template

Each persona receives this prompt (fill in persona-specific fields):

```
You are {persona name}, a {role description}. {full persona background}.

TARGET URL: {url}
SESSION ID: {session_id}
SRDB CONNECTION: postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres
CREDENTIALS: {email} / {password}

CURRENTLY OPEN ISSUES (do NOT report duplicates):
{open_issues_json}

VERIFICATION QUEUE (re-test these fixed bugs):
{verify_queue_json}

== INSTRUCTIONS ==

STEP 0: Set up browser isolation (REQUIRED — prevents session conflicts with other personas):
export BROWSE_STATE_FILE="/tmp/browse-state-{slug}.json"
export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"

BROWSER TOOL PRIORITY:
1. PRIMARY: browse CLI (`~/.local/bin/browse`) — fast, zero MCP overhead
   - Navigation:   browse goto <url>
   - Page content: browse snapshot -i   (interactive elements with @e refs)
   - Page text:    browse text
   - Console:      browse console
   - Network:      browse network
   - Screenshot:   browse screenshot /tmp/{slug}-{page}.png
   - Click:        browse click @e<N>
   - Fill form:    browse fill @e<N> "value"
2. FALLBACK: mcp__chrome-devtools__* (only if browse is unavailable)

Login sequence using browse:
  browse goto {url}/sign-in
  browse snapshot -i   # find email/password fields by @e ref
  browse fill @e<email_ref> "{email}"
  browse fill @e<password_ref> "{password}"
  browse click @e<submit_ref>
  browse snapshot -i   # verify redirect to dashboard

STEP 1: Start your persona session:
psql "$SRDB" -t -A -c "INSERT INTO qa_persona_sessions (session_id, persona) VALUES ('{session_id}', '{slug}') RETURNING id"
SAVE the returned persona_session_id.

STEP 2: Test ALL your assigned features systematically.

YOUR FEATURE ASSIGNMENTS (you MUST test every one):
{feature_list_from_qa_feature_coverage}

For EACH feature in your assignment list:
a) Mark it as in_progress:
   psql "$SRDB" -t -A -c "UPDATE qa_feature_coverage SET status = 'in_progress', tested_at = NOW() WHERE session_id = '{session_id}' AND feature_key = '{feature_key}' AND persona = '{slug}'"
b) Navigate to the feature's route:
   browse goto {url}{route}
   browse snapshot -i   # inspect interactive elements
   browse text          # read page content
c) Test ALL workflows for that feature. For each page/action, evaluate:
   1. FUNCTIONALITY - Does it work? Any errors? Console errors?
      Check: browse console
   2. UX/USABILITY - Is it intuitive? Confusing? Too many clicks?
   3. PERFORMANCE - Is it fast? Any loading delays > 3s?
      Check: browse perf
   4. DATA ACCURACY - Do numbers/dates/statuses look correct?
   5. VISUAL - Do charts render? Are layouts broken? CSS loaded?
      Check: browse screenshot /tmp/{slug}-{feature_key}.png
   6. PERMISSIONS - Can you access only what your role allows?
      Check: browse network   (look for 401/403 responses)
d) After testing all workflows for that feature:
   - If ALL workflows pass (no bugs): Mark APPROVED:
     psql "$SRDB" -t -A -c "UPDATE qa_feature_coverage SET status = 'approved', approved_at = NOW(), workflows_passed = {passed}, workflows_failed = 0, notes = '{observations}' WHERE session_id = '{session_id}' AND feature_key = '{feature_key}' AND persona = '{slug}'"
   - If ANY workflow has a bug: Mark BLOCKED with the issue IDs:
     psql "$SRDB" -t -A -c "UPDATE qa_feature_coverage SET status = 'blocked', workflows_passed = {passed}, workflows_failed = {failed}, blocking_issue_ids = ARRAY[{issue_ids}], notes = '{observations}' WHERE session_id = '{session_id}' AND feature_key = '{feature_key}' AND persona = '{slug}'"

IMPORTANT: Do NOT skip any feature. Every feature must end with status 'approved' or 'blocked'.

STEP 3: For each bug found:
a) Check for duplicates FIRST:
   psql "$SRDB" -t -A -c "SELECT id, title, status FROM qa_issues WHERE (affected_page = '{page}' OR endpoint = '{endpoint}') AND status NOT IN ('closed', 'verified') LIMIT 5"
b) If NO duplicate, create new issue:
   psql "$SRDB" -t -A -c "INSERT INTO qa_issues (session_id, title, severity, category, persona, endpoint, http_status, error_message, expected, actual, affected_page, reproduction_steps) VALUES ('{session_id}', '{title}', '{severity}', '{category}', '{slug}', '{endpoint}', {http_status}, '{error}', '{expected}', '{actual}', '{page}', '{steps_json}'::jsonb) RETURNING id"
c) If duplicate found, add a comment:
   psql "$SRDB" -t -A -c "INSERT INTO qa_issue_comments (issue_id, author, comment_type, content) VALUES ({id}, '{slug}', 'note', 'Still reproducing as of today')"
d) BROADCAST the failure to your team so other personas know:
   SendMessage({ type: "broadcast", content: "BUG FOUND on {page}: {title} (severity: {severity})", summary: "Bug on {page}" })

STEP 4: Verify fixed bugs from the verification queue:
For each issue in TESTING status, follow its reproduction steps.
Record result:
   psql "$SRDB" -t -A -c "INSERT INTO qa_verifications (issue_id, session_id, persona, passed, notes) VALUES ({issue_id}, '{session_id}', '{slug}', {true|false}, '{notes}')"
If passed: psql "$SRDB" -t -A -c "UPDATE qa_issues SET status = 'verified', updated_at = NOW() WHERE id = {id}"
If failed: psql "$SRDB" -t -A -c "UPDATE qa_issues SET status = 'in_progress', updated_at = NOW() WHERE id = {id}"

STEP 5: Complete your persona session:
psql "$SRDB" -t -A -c "UPDATE qa_persona_sessions SET satisfaction = {score}, pages_visited = ARRAY[{pages}], workflows_tested = ARRAY[{workflows}], completed_at = NOW(), observations = '{observations}' WHERE id = '{persona_session_id}'"

STEP 6: Get your coverage summary:
psql "$SRDB" -t -A -c "SELECT feature_key, status FROM qa_feature_coverage WHERE session_id = '{session_id}' AND persona = '{slug}' ORDER BY feature_key"
Count: approved, blocked, untested.

STEP 7: Send your final report to the orchestrator:
SendMessage({
  type: "message",
  recipient: "orchestrator",
  content: "PERSONA COMPLETE: {slug}\nFeatures approved: {approved}/{total}\nFeatures blocked: {blocked}/{total}\nBugs found: {count}\nVerifications: {pass}/{total}\nSatisfaction: {score}/10\nKey observations: {observations}",
  summary: "{slug} complete: {approved}/{total} approved, {bug_count} bugs"
})

Write feedback AS THE PERSONA - first person, with their frustrations and satisfaction level.

RESILIENCE RULES:
- If a page shows empty content or takes >15s to load: wait 5 seconds, then retry ONCE (`browse goto <url>`). If still empty, mark as blocked.
- If `browse goto` fails or times out: try `curl -s -o /dev/null -w '%{http_code}' <url>` to check server response. If curl returns 200 but browse fails, note "client-side rendering failure" in the bug. Then try fallback: mcp__chrome-devtools__navigate_page.
- If you hit a crash or unrecoverable error on one feature: log it, mark it blocked, and CONTINUE to the next feature. NEVER stop early.
- You MUST complete ALL features and send your final report even if most features are blocked. Partial results are valuable.
- If you receive a broadcast about a known broken page, you can skip browser testing for that page but MUST still mark it as blocked with the referenced issue ID.

IMPORTANT:
- ALL bugs go to the database via psql. Do NOT write to files.
- ALWAYS check for duplicates before creating issues.
- BROADCAST failures so other personas can skip known-broken pages.
- Use psql with -t -A flags for clean output.
- Set SRDB env var at start: export SRDB="postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres"
```

### Phase 3: Cross-Persona Real-Time Detection

As personas send messages (via broadcast and direct messages), the orchestrator watches for patterns:

| Pattern                 | Detection                                          | Action                                                     |
| ----------------------- | -------------------------------------------------- | ---------------------------------------------------------- |
| Same bug on 2+ personas | Same `affected_page` or `endpoint` in broadcasts   | Flag as **systemic** — add `category = 'systemic'` comment |
| Permission leak         | Member persona can access admin features           | Flag as **CRITICAL security** — auto-escalate to P0        |
| UX inconsistency        | Same feature works differently for admin vs member | Flag for CPO report                                        |
| Performance bottleneck  | Multiple personas report slow page (>3s load)      | Flag for CTO report                                        |
| Data inconsistency      | Different roles see different data for same entity | Flag as **CRITICAL** data issue                            |
| Regression              | Previously CLOSED issue reappears                  | Auto-create P0 regression with `original_issue_id`         |

When the orchestrator detects a cross-persona pattern:

```bash
# Mark existing issues as systemic
psql "$SRDB" -t -A -c "
  INSERT INTO qa_issue_comments (issue_id, author, comment_type, content)
  VALUES ({issue_id}, 'orchestrator', 'pattern', 'SYSTEMIC: Same issue reported by {persona1} and {persona2}. Affects {affected_pages}.')
"
```

### Phase 4: Report Generation (CTO + CPO)

After all personas complete, generate both reports from DB data:

#### CTO Report (Technical)

```bash
# Issues by severity
psql "$SRDB" -t -A -c "SELECT severity, COUNT(*) as cnt FROM qa_issues WHERE session_id = '{session_id}' GROUP BY severity ORDER BY severity"

# Issues by category
psql "$SRDB" -t -A -c "SELECT category, COUNT(*) as cnt FROM qa_issues WHERE session_id = '{session_id}' GROUP BY category ORDER BY cnt DESC"

# Systemic issues (cross-persona)
psql "$SRDB" -t -A -c "
  SELECT i.id, i.title, i.severity, i.affected_page,
    (SELECT COUNT(DISTINCT c.author) FROM qa_issue_comments c WHERE c.issue_id = i.id AND c.comment_type = 'pattern') as personas_affected
  FROM qa_issues i
  WHERE i.session_id = '{session_id}'
    AND EXISTS (SELECT 1 FROM qa_issue_comments c WHERE c.issue_id = i.id AND c.comment_type = 'pattern')
"

# API errors (grouped by endpoint)
psql "$SRDB" -t -A -c "
  SELECT endpoint, http_status, COUNT(*) as occurrences, array_agg(DISTINCT persona) as reporters
  FROM qa_issues
  WHERE session_id = '{session_id}' AND endpoint IS NOT NULL
  GROUP BY endpoint, http_status
  ORDER BY occurrences DESC
"

# Regressions
psql "$SRDB" -t -A -c "
  SELECT id, title, original_issue_id
  FROM qa_issues
  WHERE session_id = '{session_id}' AND original_issue_id IS NOT NULL
"

# Trend vs previous sessions
psql "$SRDB" -t -A -c "
  SELECT s.id, s.started_at::date,
    COUNT(CASE WHEN i.severity = 'p0-critical' THEN 1 END) as p0,
    COUNT(CASE WHEN i.severity = 'p1-high' THEN 1 END) as p1,
    COUNT(CASE WHEN i.severity = 'p2-medium' THEN 1 END) as p2,
    COUNT(*) as total
  FROM qa_sessions s
  LEFT JOIN qa_issues i ON i.session_id = s.id
  GROUP BY s.id, s.started_at
  ORDER BY s.started_at DESC LIMIT 5
"
```

Format as:

```markdown
## CTO Report — QA Session {session_id}

### Critical Issues

{p0 + p1 issues with reproduction steps}

### Systemic Issues

{issues affecting multiple personas/pages}

### API Errors

{endpoint, status, frequency}

### Regressions

{previously fixed bugs that returned}

### Trend

{comparison table with last 5 sessions}

### Recommendations

{prioritized fix plan}
```

#### CPO Report (Product/UX)

```bash
# Persona satisfaction scores
psql "$SRDB" -t -A -c "
  SELECT persona, satisfaction, observations
  FROM qa_persona_sessions
  WHERE session_id = '{session_id}'
  ORDER BY satisfaction ASC
"

# UX-category issues
psql "$SRDB" -t -A -c "
  SELECT id, title, persona, affected_page, expected, actual
  FROM qa_issues
  WHERE session_id = '{session_id}' AND category IN ('ui', 'navigation', 'ux')
  ORDER BY severity
"

# Satisfaction trend across sessions
psql "$SRDB" -t -A -c "
  SELECT ps.persona, ps.satisfaction, s.started_at::date
  FROM qa_persona_sessions ps
  JOIN qa_sessions s ON ps.session_id = s.id
  WHERE s.status = 'completed'
  ORDER BY ps.persona, s.started_at DESC
"
```

Format as:

```markdown
## CPO Report — QA Session {session_id}

### User Satisfaction

| Persona | Score | Key Frustration |
| ------- | ----- | --------------- |

{per-persona satisfaction + observations}

### UX Issues

{navigation, usability, clarity issues}

### Satisfaction Trends

{per-persona trend over last sessions}

### Product Recommendations

{UX improvements, feature gaps, workflow friction}
```

### Phase 4.5: Coverage Report

After persona reports, generate a coverage matrix showing approval status:

```bash
# Feature coverage summary
psql "$SRDB" -t -A -c "
  SELECT
    persona,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE status = 'approved') as approved,
    COUNT(*) FILTER (WHERE status = 'blocked') as blocked,
    COUNT(*) FILTER (WHERE status = 'untested') as untested,
    ROUND(COUNT(*) FILTER (WHERE status = 'approved') * 100.0 / COUNT(*)) as pct_approved
  FROM qa_feature_coverage
  WHERE session_id = '{session_id}'
  GROUP BY persona
  ORDER BY persona
"

# Overall coverage
psql "$SRDB" -t -A -c "
  SELECT
    COUNT(*) as total_features,
    COUNT(*) FILTER (WHERE status = 'approved') as approved,
    COUNT(*) FILTER (WHERE status = 'blocked') as blocked,
    COUNT(*) FILTER (WHERE status = 'untested') as untested,
    ROUND(COUNT(*) FILTER (WHERE status = 'approved') * 100.0 / COUNT(*)) as overall_pct
  FROM qa_feature_coverage
  WHERE session_id = '{session_id}'
"

# Blocked features with their blocking issues
psql "$SRDB" -t -A -c "
  SELECT fc.feature_key, fc.persona, fc.blocking_issue_ids, fc.notes
  FROM qa_feature_coverage fc
  WHERE fc.session_id = '{session_id}' AND fc.status = 'blocked'
  ORDER BY fc.persona, fc.feature_key
"
```

Format as:

```markdown
## Coverage Report — QA Session {session_id}

### Overall: {approved}/{total} features approved ({pct}%)

| Persona | Approved | Blocked | Untested | Coverage |
| ------- | -------- | ------- | -------- | -------- |
| sarah   | {n}      | {n}     | {n}      | {pct}%   |
| marcus  | {n}      | {n}     | {n}      | {pct}%   |
| diana   | {n}      | {n}     | {n}      | {pct}%   |
| alex    | {n}      | {n}     | {n}      | {pct}%   |

### Blocked Features

{feature_key} ({persona}): blocked by issues #{ids} — {notes}
```

**IMPORTANT:** The cycle does NOT end until overall coverage = 100% approved.

### Phase 5: Triage (Opus)

After reports, escalate to opus for strategic triage:

```
Task({
  model: "opus",
  subagent_type: "general-purpose",
  prompt: "Given these QA issues from SourceRank discovery session:
    {issue_list_with_titles_severity_endpoints_categories}

    CTO Report Summary: {cto_summary}
    CPO Report Summary: {cpo_summary}

    Determine:
    1. Which are real bugs vs expected behavior or test environment artifacts?
    2. Priority order for fixing (considering dependencies between issues)
    3. Which issues likely share a root cause and should be fixed together?
    4. Any issues that are Render deployment/infra problems vs code bugs?

    Return a structured JSON fix plan:
    {
      'fix_groups': [
        { 'root_cause': '...', 'issue_ids': [...], 'priority': 1, 'approach': '...' }
      ],
      'skip': [{ 'issue_id': N, 'reason': 'environment artifact' }],
      'deploy_risk': 'low|medium|high'
    }"
})
```

### Phase 6: Fix (Always Opus)

Execute the triage plan. **All bug fixing uses opus** for highest-quality root cause analysis and fixes.

For each fix group (sorted by priority):

```
Task({
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "You are a senior developer fixing QA issues in SourceRank AI.

  CODEBASE: /Users/ps/code/Sourcerankai (pnpm monorepo: apps/web, apps/api, packages/database)
  DATABASE CONNECTION: export SRDB=\"postgresql://postgres.swpznmoctbtnmspmyrfu:Lmk48ZJTjRzCp4xh@aws-1-us-east-1.pooler.supabase.com:5432/postgres\"

  FIX GROUP (from triage):
  - Root cause: {root_cause}
  - Issue IDs: {issue_ids}
  - Approach: {approach}
  - Issues:
    {issue_details_with_titles_errors_reproduction_steps}

  INSTRUCTIONS:
  1. Claim all issues:
     psql \"$SRDB\" -t -A -c \"UPDATE qa_issues SET status = 'assigned', assigned_to = 'opus-dev', updated_at = NOW() WHERE id IN ({ids})\"
  2. Investigate the codebase — read relevant files, trace the bug
  3. Apply the minimal fix using Edit/Write tools
  4. For each fixed issue, update DB:
     psql \"$SRDB\" -t -A -c \"UPDATE qa_issues SET status = 'testing', fixed_by = 'opus-dev', updated_at = NOW() WHERE id = {id}\"
     psql \"$SRDB\" -t -A -c \"INSERT INTO qa_issue_comments (issue_id, author, comment_type, content) VALUES ({id}, 'opus-dev', 'fix', '{description}')\"
  5. Return a summary: which issues were fixed, what files were changed, and any issues you could not fix (with reason).

  REPAIR MEMORY (patterns from past successful fixes — apply if relevant):
  {repair_memory_patterns_from_preflight}

  IMPORTANT: Make minimal, focused fixes. Do not refactor surrounding code. Do not add unnecessary comments or type annotations.

  After fixing, return a structured summary:
  {
    'fixed_issues': [{ 'id': N, 'root_cause': '...', 'fix_approach': '...', 'files_changed': [...] }],
    'unfixed_issues': [{ 'id': N, 'reason': '...' }],
    'repair_pattern': { 'category': '...', 'symptom': '...', 'root_cause': '...', 'fix': '...', 'files': [...] }
  }"
})
```

Spawn one opus Task per fix group. If fix groups are independent, spawn them in **parallel**.

### Phase 6.5: Learn (Save Repair Patterns to Memory)

After each fix group completes, save the successful repair pattern to MCP memory so future sessions can apply the same fix immediately:

```
# For each successful fix, create a memory entity
mcp__memory__create_entities({
  entities: [{
    name: "repair:sourcerank:{category}:{short-description}",
    entityType: "repair-pattern",
    observations: [
      "Discovered: {today's date}",
      "Source: qa-sourcerank-fix",
      "Project: sourcerank",
      "Symptom: {what the personas reported — e.g., 'empty dashboard content'}",
      "Root cause: {what was actually wrong — e.g., 'API response shape mismatch in agency.ts'}",
      "Fix approach: {how it was fixed — e.g., 'changed destructuring to match {clients, total} shape'}",
      "Files changed: {list of files}",
      "Issue IDs: {original issue IDs from QA DB}",
      "Verified: {true/false — did verification pass?}",
      "Sessions applied: 1",
      "Last used: {today's date}"
    ]
  }]
})
```

**When loading patterns in Pre-Flight (for future sessions):**

If a persona reports a symptom that matches a known repair pattern:

1. Search memory: `mcp__memory__search_nodes({ query: "repair:sourcerank:{symptom_keywords}" })`
2. If pattern found AND previously verified: apply the fix immediately without full triage
3. Track usage: `mcp__memory__add_observations({ observations: [{ entityName: "repair:...", contents: ["Applied in: sourcerank - {date} - HELPFUL/NOT HELPFUL", "Sessions applied: {N+1}"] }] })`

**Learning loop:**

```
Session 1: Discovery finds bug → Fix → Save pattern to memory
Session 2: Same bug recurs → Pre-flight loads pattern → Fix immediately → Skip triage
Session 3: Bug doesn't recur → Pattern is validated as permanent fix
```

This creates a **self-improving QA system** that gets faster at fixing known issue types over time.

### Phase 7: Verify (Compose /qa-verify or Parallel)

**Option A: Compose `/qa-verify` sub-skill** (preferred):

```
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  prompt: "/qa-verify

  Database: Use psql with SRDB env var (NOT mcp__postgres__query).
  Target: {url}
  Session: {session_id}"
})
```

**Option B: Parallel verification via swarm** (for many issues):

Spawn sonnet verification agents in parallel, one per issue or batch:

```
# Spawn verification agents in parallel
Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  name: "verifier-batch-1",
  prompt: "Verify these QA issues are fixed on {url}:
    {issues_batch_1}

    BROWSER TOOL: Use browse CLI as primary (export BROWSE_STATE_FILE=/tmp/browse-state-verifier-1.json).
    For each issue: browse goto {url}{affected_page}, follow reproduction_steps, check browse console for errors.
    Fallback to mcp__chrome-devtools__* if browse unavailable.
    Record result via psql."
})

Task({
  subagent_type: "general-purpose",
  model: "sonnet",
  name: "verifier-batch-2",
  prompt: "Verify these QA issues are fixed on {url}:
    {issues_batch_2}

    BROWSER TOOL: Use browse CLI as primary (export BROWSE_STATE_FILE=/tmp/browse-state-verifier-2.json).
    For each issue: browse goto {url}{affected_page}, follow reproduction_steps, check browse console for errors.
    Fallback to mcp__chrome-devtools__* if browse unavailable.
    Record result via psql."
})
```

### Phase 8: Regression Check

```bash
# Regressions: previously closed issues that reappeared
psql "$SRDB" -t -A -c "
  SELECT i.id, i.title, i.severity, i.original_issue_id
  FROM qa_issues i
  WHERE i.status = 'open' AND i.original_issue_id IS NOT NULL
"

# Trend: compare issue counts across sessions
psql "$SRDB" -t -A -c "
  SELECT s.id, s.started_at::date,
    COUNT(CASE WHEN i.severity = 'p0-critical' THEN 1 END) as p0,
    COUNT(CASE WHEN i.severity = 'p1-high' THEN 1 END) as p1,
    COUNT(*) as total
  FROM qa_sessions s
  LEFT JOIN qa_issues i ON i.session_id = s.id
  WHERE s.status = 'completed'
  GROUP BY s.id, s.started_at
  ORDER BY s.started_at DESC LIMIT 5
"

# Verification bounce-backs (failed verification)
psql "$SRDB" -t -A -c "
  SELECT i.id, i.title, v.notes
  FROM qa_issues i
  JOIN qa_verifications v ON v.issue_id = i.id
  WHERE v.session_id = '{session_id}' AND v.passed = false
"
```

**Escalate to opus for cross-session analysis:**

```
Task({
  model: "opus",
  subagent_type: "general-purpose",
  prompt: "Compare these QA sessions for SourceRank:
    Previous: {prev_session_summaries}
    Current: {current_session_summary}

    Are any regressions real, or are they flaky/environment-dependent?
    What systemic patterns do you see across sessions?
    Is the overall quality trend improving or degrading?"
})
```

### Phase 9: Deploy + Continue Decision (Opus)

```
Task({
  model: "opus",
  subagent_type: "general-purpose",
  prompt: "QA cycle {N} summary for SourceRank:
    Fixes applied: {fixes_list}
    Verification results: {verification_summary}
    Regression status: {regression_info}
    Feature coverage: {approved}/{total} approved ({pct}%)
    Blocked features: {blocked_features_list}
    Remaining open issues: {open_count} ({open_list})

    1. Should we deploy these changes to production? (YES/NO + reasoning)
       Consider: risky changes, unverified fixes, regressions
    2. Feature coverage is {pct}%. Should we continue to reach 100%? (YES/NO)
       Consider: blocked features, open issues that block approval, diminishing returns only if coverage > 95%

    Return JSON:
    { 'deploy': true/false, 'deploy_reason': '...', 'continue': true/false, 'continue_reason': '...', 'coverage_pct': {pct} }"
})
```

- If deploy YES → commit, push, verify production endpoints
- If deploy NO → commit locally only
- After deploy, run the Post-Fix Coverage Update to unblock features
- If coverage < 100% + cycle < 10 → start next cycle automatically (re-test only blocked/untested features)
- If coverage = 100% AND zero open issues → output final summary, stop
- If cycle >= 10 → output final summary with remaining unapproved features, stop

### Session Completion

```bash
psql "$SRDB" -t -A -c "
  UPDATE qa_sessions
  SET status = 'completed',
      completed_at = NOW(),
      summary = '{summary}',
      metadata = jsonb_build_object(
        'cycles', {cycle_count},
        'total_issues', {total},
        'fixed', {fixed},
        'verified', {verified},
        'regressions', {regressions}
      )
  WHERE id = '{session_id}'
"
```

### Team Cleanup

After all phases complete:

```
# Shutdown each persona teammate
SendMessage({ type: "shutdown_request", recipient: "sarah-tester", content: "QA complete" })
SendMessage({ type: "shutdown_request", recipient: "marcus-tester", content: "QA complete" })
SendMessage({ type: "shutdown_request", recipient: "diana-tester", content: "QA complete" })
SendMessage({ type: "shutdown_request", recipient: "alex-tester", content: "QA complete" })

# Delete the team
TeamDelete()
```

## Autonomous Operation

This skill runs as a **continuous autonomous loop** until **all features are tested and approved**:

```
┌───────────────────────────────────────────────────────────────────┐
│                   CONTINUOUS QA LOOP                                │
│                                                                     │
│   discover (swarm) → cross-persona → report → coverage report →    │
│   triage (opus) → fix → commit → verify →                          │
│   re-test blocked features → update coverage →                     │
│   regression → deploy decision (opus) →                            │
│   confirm deploy →                                                  │
│                                                                     │
│   ┌─── 100% features approved? ───┐                                │
│   │ NO  + cycle < 10 → new cycle  │                                │
│   │ YES → final summary + stop    │                                │
│   └───────────────────────────────┘                                │
└───────────────────────────────────────────────────────────────────┘
```

### Stop Condition

The cycle stops ONLY when:

```bash
# Check if all features are approved
UNAPPROVED=$(psql "$SRDB" -t -A -c "
  SELECT COUNT(*) FROM qa_feature_coverage
  WHERE session_id = '{session_id}' AND status != 'approved'
")

OPEN_ISSUES=$(psql "$SRDB" -t -A -c "
  SELECT COUNT(*) FROM qa_issues
  WHERE session_id = '{session_id}' AND status NOT IN ('closed', 'verified')
")

# STOP when: unapproved = 0 AND open_issues = 0
# CONTINUE when: unapproved > 0 OR open_issues > 0 (and cycle < 10)
```

### Rules

- **Never ask the user** for confirmation, next steps, or permission at any point
- **Never stop between phases** — the full pipeline runs end-to-end
- After deploy, **verify the deployment succeeded** (check production endpoints)
- After confirming deploy, **check feature coverage** — if any features are NOT approved, continue
- If unapproved features remain → **start a new cycle automatically**
  - Cycle 2+ personas ONLY re-test features with status 'blocked' or 'untested' (not already approved)
  - After fixes are deployed, update blocked features back to 'untested' so they get re-tested
- If 100% features approved AND zero open issues → **output a final summary and stop**
- Each cycle focuses on progressively lower severity: P0 first cycle, P1 second, P2/P3 later
- **Max 10 cycles** per invocation to prevent infinite loops (if issues keep recurring, stop and report)
- The only exception: if `--discover-only`, `--fix-only`, `--verify-only`, or `--skip-fix` flags are set, run only those phases then stop

**IMPORTANT:** Never output messages like "Want me to continue?", "Should I proceed?", "Next step would be...", or any phrasing that implies waiting for user input. Just do it.

### Post-Fix Coverage Update

After fixes are deployed and verified, unblock features whose blocking issues are now resolved:

```bash
# Reset blocked features to 'untested' when their blocking issues are fixed
psql "$SRDB" -c "
  UPDATE qa_feature_coverage fc
  SET status = 'untested', blocking_issue_ids = '{}'
  WHERE fc.session_id = '{session_id}'
    AND fc.status = 'blocked'
    AND NOT EXISTS (
      SELECT 1 FROM unnest(fc.blocking_issue_ids) AS bid
      JOIN qa_issues i ON i.id = bid
      WHERE i.status NOT IN ('closed', 'verified', 'testing')
    )
"
```

### Cycle 2+ Persona Prompts

On subsequent cycles, personas only test features that are NOT approved:

```bash
# Get features that still need testing for this persona
psql "$SRDB" -t -A -c "
  SELECT feature_key, feature_name, route, status
  FROM qa_feature_coverage
  WHERE session_id = '{session_id}'
    AND persona = '{slug}'
    AND status != 'approved'
  ORDER BY feature_key
"
```

If a persona has ALL features approved, do NOT spawn that persona again.

### Cycle Tracking

Track cycle count, coverage progress, and log:

```
Cycle 1: 37 features tested → 28 approved, 9 blocked (75%). Fixed 6 P0+P1 bugs. Deployed.
Cycle 2: Re-tested 9 blocked → 7 approved, 2 blocked (95%). Fixed 2 P2 bugs. Deployed.
Cycle 3: Re-tested 2 blocked → 2 approved (100%). 0 open issues. DONE.
```

## Deployment (Render.com)

SourceRank deploys to Render.com. After fixes:

```bash
# Stage and commit fixes
git add -A && git commit -m "fix(qa): {summary of fixes}"

# Push triggers Render auto-deploy
git push origin master
```

**Post-deploy verification:**

```bash
# Check web health (wait for Render deploy — may take 2-5 min)
curl -s -o /dev/null -w '%{http_code}' https://sourcerank-web.onrender.com

# Check API health
curl -s https://sourcerank-api.onrender.com/health

# Check for errors in recent Render logs (if available via API)
# Otherwise, verify via browser that fixed pages work
```

**Rollback (if deployment fails):**

```bash
# Revert the last commit
git revert HEAD --no-edit
git push origin master

# Wait for Render to redeploy the reverted version
# Verify production is back to healthy state
```

## Model Allocation

### Model Flow per Phase

```
  ┌───────────────────────────────────────────────────────────────┐
  │                                                               │
  ▼                                                               │
PRE-FLIGHT: opus orchestrator (warmup, open issues, load memory)  │
                  ↓                                               │
Phase 0-1:  opus orchestrator (init session, seed, env discovery) │
                  ↓                                               │
Phase 2:    DISCOVER:  sonnet × 4 personas (PARALLEL swarm)       │
                  ↓                                               │
Phase 3-4:  opus orchestrator (cross-persona, reports, coverage)  │
                  ↓                                               │
Phase 5:    TRIAGE:  opus inline (skip if root cause is obvious)  │
                  ↓                                               │
Phase 6:    FIX:  opus × N tasks (PARALLEL per fix group)         │
                  ↓                                               │
Phase 6.5:  LEARN: opus orchestrator (save repair patterns)       │
                  ↓                                               │
Phase 7:    VERIFY: sonnet × N tasks (browser re-testing)         │
                  ↓                                               │
Phase 8-9:  opus orchestrator (regression, deploy, continue?)     │
                  ↓                                               │
            100% features approved?                               │
            NO  + cycle < 10 ─────────────────────────────────────┘
            YES → output final summary, stop
```

### Why This Allocation

- **Opus orchestrates everything** — best reasoning for never-abort behavior, triage, deploy decisions
- **Opus fixes bugs** — highest-quality root cause analysis and code changes
- **Sonnet discovers** — 4 persona testers (good enough for browser exploration, much cheaper than opus)
- **Sonnet verifies** — re-testing fixed bugs (simple pass/fail checks)
- Keep opus prompts **concise** — include only relevant data, not full file contents
- Group related bugs into fix groups so opus solves them together (fewer calls, better context)

## Swarm Communication Protocol

### Persona → Orchestrator (Results)

When a persona finishes testing:

```
SendMessage({
  type: "message",
  recipient: "orchestrator",
  content: "## Persona Complete: {name}\n\n**Bugs found:** {count}\n**Verifications:** {pass}/{total}\n**Satisfaction:** {score}/10\n\n### Key Issues\n{top_issues}\n\n### Observations\n{persona_observations}",
  summary: "{slug} done: {bugs} bugs, {score}/10"
})
```

### Persona → All (Failure Broadcast)

When a persona finds a bug, broadcast to all:

```
SendMessage({
  type: "broadcast",
  content: "## Bug Found on {page}\n\n**Severity:** {severity}\n**Error:** {error}\n\nOther testers: check this page or skip if already broken.",
  summary: "Bug on {page}: {title}"
})
```

### Orchestrator → Persona (Known Issue Alert)

When the orchestrator detects a systemic pattern:

```
SendMessage({
  type: "broadcast",
  content: "## Known Issue Detected\n\n**Pages affected:** {pages}\n**Issue:** {description}\n\nSkip testing these pages — already tracked as issue #{id}.",
  summary: "Skip {pages}: known issue"
})
```

## Flags Reference

| Flag              | Description                            | Phases Run                        |
| ----------------- | -------------------------------------- | --------------------------------- |
| (none)            | Full cycle                             | All phases                        |
| `--discover-only` | Run persona testing only               | Discover + Cross-Persona + Report |
| `--fix-only`      | Fix existing open issues               | Fix only                          |
| `--verify-only`   | Verify issues in TESTING status        | Verify only                       |
| `--report`        | Generate CTO/CPO reports from DB state | Report only                       |
| `--skip-fix`      | Discover + report + verify (no fix)    | Discover + Report + Verify        |
| `--severity X`    | Filter issues by severity              | Applies to all phases             |
| `--url URL`       | Override target URL (default: prod)    | Applies to discover + verify      |
| `--limit N`       | Max issues to process per phase        | Applies to fix + verify           |

## Completion Signal

```json
{
  "status": "complete|partial|blocked|failed",
  "summary": "Full QA cycle completed",
  "sessionId": "{session_uuid}",
  "cyclesCompleted": 2,
  "phases": {
    "discover": {
      "status": "complete",
      "newIssues": 8,
      "duplicates": 2,
      "personasTested": 4,
      "mode": "swarm-parallel"
    },
    "crossPersona": {
      "systemicBugs": 1,
      "permissionIssues": 0,
      "uxInconsistencies": 2,
      "performanceBottlenecks": 1,
      "dataInconsistencies": 0
    },
    "report": {
      "status": "complete",
      "ctoReport": "generated",
      "cpoReport": "generated"
    },
    "triage": {
      "fixGroups": 3,
      "skipped": 1,
      "deployRisk": "low"
    },
    "fix": {
      "status": "complete",
      "issuesFixed": 5,
      "issuesSkipped": 2,
      "issuesFailed": 1
    },
    "verify": {
      "status": "complete",
      "verified": 4,
      "failed": 1
    },
    "regression": {
      "regressionsDetected": 0,
      "previouslyClosed": 15,
      "stillClosed": 15
    }
  },
  "coverage": {
    "totalFeatures": 50,
    "approved": 50,
    "blocked": 0,
    "untested": 0,
    "coveragePct": 100
  },
  "overallHealth": {
    "totalOpenIssues": 0,
    "criticalOpen": 0,
    "trend": "improving",
    "avgSatisfaction": 7.2
  }
}
```

## Integration with Other Skills

```
/qa-sourcerank              →  THIS SKILL: full cycle orchestrator
/qa-fix                     →  Fix phase (composed by this skill)
/qa-verify                  →  Verify phase (composed by this skill)

/cto                        →  Can read CTO reports for technical strategy
/deep-plan                  →  Can plan implementation of complex fixes
/fulltest                   →  Complementary: page-level testing (CSS, JS, assets)
```

---

## Version

**Current Version:** 4.1.0
**Last Updated:** March 2026

### Changelog

- **4.1.0**: browse CLI as primary browser automation tool
  - Added "Browser Tool: browse CLI" section with full command reference
  - Persona agent prompts updated to use `browse goto`, `browse snapshot -i`, `browse text`, `browse console`, `browse network`, `browse screenshot`, `browse click`, `browse fill`
  - Per-persona isolation via `BROWSE_STATE_FILE` env var — each of the 4 concurrent testers gets its own Chromium instance
  - Phase 1 (environment discovery) uses `browse goto` + `browse text` for site accessibility check
  - Phase 7 (verification agents) use `browse goto` + `browse console` for re-testing
  - Chrome DevTools MCP retained as fallback in allowed-tools and in all prompts
  - Resilience rules updated: browse failure → curl check → MCP fallback (instead of MCP as only option)
- **4.0.0**: Self-healing autonomous operation + repair memory
  - Opus orchestrator (upgraded from sonnet) — better reasoning, never aborts
  - Sonnet persona agents (upgraded from haiku) — more reliable browser testing
  - **NEVER ABORT rule** — orchestrator always proceeds to fix phase, even if 100% features blocked
  - **Pre-flight phase** — Render warmup, open issue check, repair memory loading
  - **Repair memory** (Phase 6.5) — saves successful fix patterns to MCP memory for future sessions
  - **Self-healing loop** — loads past repair patterns before fixing, applies known solutions immediately
  - **Persona resilience** — retry on empty pages, timeout handling, always complete all features
  - **Smart triage shortcut** — skip opus triage call when systemic root cause is obvious
  - Architecture diagram updated to reflect opus orchestrator + memory feedback loop
  - Model flow updated: opus orchestrates, sonnet discovers/verifies, opus fixes
- **3.0.0**: Continuous coverage-driven QA + opus developer
  - Feature coverage tracking via `qa_feature_coverage` table (37 features across 4 personas)
  - Stop condition changed: cycle continues until 100% features approved (not just zero bugs)
  - Opus is now the primary developer for ALL bug fixes (parallel opus tasks per fix group)
  - Coverage report phase (Phase 4.5) between reports and triage
  - Post-fix coverage update: automatically unblock features when blocking issues are resolved
  - Cycle 2+ efficiency: personas only re-test blocked/untested features (skip approved)
  - Personas that have 100% coverage are not re-spawned in subsequent cycles
  - Max cycles increased from 5 to 10
  - Feature registry with 37 coverage rows seeded at session start
  - Coverage matrix in deploy decision (opus considers coverage % for continue decision)
- **2.0.0**: Swarm mode + full qa-cycle parity
  - True parallel persona testing via TeamCreate swarm
  - Real-time failure broadcasting between personas
  - Cross-persona pattern detection (systemic, permission, UX, perf, data)
  - CTO + CPO dual report generation from DB
  - Opus-powered triage with structured fix plans
  - Opus deploy + continue decisions
  - Compose /qa-fix and /qa-verify sub-skills
  - Formalized duplicate detection before every insert
  - Git revert rollback support
  - Bumped max cycles from 3 to 5
  - Added --skip-fix flag
  - Cycle tracking with progress logging
  - Swarm communication protocol (broadcast, direct message)
  - Team cleanup (shutdown + TeamDelete)
- **1.0.0**: Initial release (sequential persona testing)

### Requirements

- **browse CLI** at `~/.local/bin/browse` (primary browser automation — compiled headless Chromium, ~100ms/call)
- Chrome DevTools MCP (fallback when browse is unavailable)
- Browserless MCP (optional, for cloud browser sessions when local Chrome not available)
- Memory MCP (for pattern learning)
- psql CLI (for SourceRank Supabase DB access)
- Access to SourceRank production or local dev environment
- SourceRank codebase at /Users/ps/code/Sourcerankai

---

## Task Cleanup

Use `TaskUpdate` with `status: "deleted"` to clean up completed or stale task chains.

## Hook Events

- **TeammateIdle**: Triggers when a persona tester completes (swarm mode)
- **TaskCompleted**: Triggers when a fix or verify task is marked completed
