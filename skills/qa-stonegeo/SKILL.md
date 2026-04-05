---
name: qa-stonegeo
description: "Full QA cycle for StoneGEO platform with code analysis + browser testing. Covers all 6 dashboard pages, tRPC API, Clerk auth, multi-tenancy. Uses typecheck + build verification. Triggers on: qa stonegeo, stonegeo qa, test stonegeo, qa cycle stonegeo."
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
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - mcp__chrome-devtools__*
  - mcp__memory__*
memory: user
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
  Write: { destructiveHint: false, idempotentHint: true }
  Edit: { destructiveHint: false, idempotentHint: true }
  mcp__memory__delete_entities: { destructiveHint: true, idempotentHint: true }
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

# QA StoneGEO Skill (v1.0)

Full QA lifecycle for StoneGEO -- a B2B GEO (Generative Engine Optimization) monitoring platform. Autonomous cycle that analyzes code, runs typecheck + build, tests via browser when available, fixes issues, and verifies. Loops until clean.

## About StoneGEO

**Product**: GEO monitoring dashboard for tracking brand visibility in AI search engines (ChatGPT, Claude, Gemini, Perplexity).

**Tech Stack**:

- Framework: Next.js 15 (App Router, Turbopack)
- API: tRPC 11 (react-query)
- DB: PostgreSQL via Prisma 6 (Supabase hosted)
- Auth: Clerk (organizations + personal workspaces)
- Styling: TailwindCSS 4 with custom Stone brand tokens
- Background jobs: Trigger.dev (worker app)
- Monorepo: Turborepo with pnpm
- Deployment: Render (auto-deploy on push to master)

**Monorepo Structure**:

```
stonegeo/
  apps/
    web/          -- Next.js dashboard (main target)
    worker/       -- Trigger.dev background jobs
  packages/
    db/           -- Prisma client + schema + seed
    core/         -- Shared Zod schemas
    config/       -- Env validation
```

**Dashboard Pages** (all under `apps/web/src/app/(dashboard)/`):
| Route | Page | Features |
|-------------|-----------------|-------------------------------------------------------------|
| /overview | Overview | Aggregate KPIs (mention rate, citation rate, SoV, clusters) |
| /visibility | AI Visibility | Objectives, clusters, metric snapshots, run status |
| /audit | Site Audit | robots.txt, sitemap, llms.txt analysis per crawl run |
| /sources | Source Map | Crawled pages, citation matches, page type filters |
| /backlog | Action Backlog | Prioritized items with status management |
| /settings | Settings | Brand CRUD, objectives, API key info |

**tRPC Routers** (`apps/web/src/server/trpc/routers/`):

- `brand.ts` -- list, create, getById
- `audit.ts` -- listCrawlRuns, getRobotsAudit, getSitemapAudit, getLlmsTxtAudit
- `cluster.ts` -- list, create
- `run.ts` -- listObjectiveRuns, getRunDetails, getRunRecords
- `metrics.ts` -- getClusterMetrics, getOverview
- `source-map.ts` -- listPages, getCitedPages
- `backlog.ts` -- list, updateStatus

**Auth Flow**: Clerk middleware protects all `/overview`, `/audit`, `/visibility`, `/sources`, `/backlog`, `/settings`, and `/api/trpc` routes. Auto-provisions tenants on first tRPC call (maps `clerkOrgId` to tenant). Seeds demo data for new tenants.

**Multi-tenancy**: All queries scoped by `tenantId` via `tenantProcedure` middleware. Tenant resolved from Clerk org or personal user key.

**Brand Colors**:

- `stone-green`: #00a868
- `stone-green-light`: #00c878
- `stone-green-dark`: #008a54
- `stone-dark`: #0d0d0d
- `stone-charcoal`: #1a1a2e

## QA Execution Flow

### Phase 1: Pre-Flight

```bash
# 1. Verify project
cd /Volumes/AI/Code/stonegeo
cat package.json | head -3  # Confirm "stonegeo"

# 2. Run typecheck
pnpm typecheck 2>&1 | tail -20

# 3. Run production build
pnpm --filter @stonegeo/web build 2>&1 | tail -30

# 4. Check for lint errors
pnpm lint 2>&1 | tail -20
```

If typecheck or build fails, fix immediately before proceeding.

### Phase 2: Code Analysis (Parallel Subagents)

Spawn 3 explore agents to cover different aspects:

**Agent 1: UI/UX Consistency**

- All 6 pages use consistent header pattern (green bar + h1 + subtitle)
- All pages have ErrorBanner components for tRPC error states
- Loading skeletons present on all data-fetching pages
- Empty states link to Settings when brand is needed
- Brand selector present on pages that filter by brand (Audit, Visibility, Sources)
- All disabled buttons have tooltips

**Agent 2: API/Data Integrity**

- All tRPC queries use `tenantProcedure` (never `publicProcedure` for data)
- No N+1 queries in Prisma includes
- Proper `enabled` guards on conditional queries
- No non-null assertions (`!`) on potentially null values without guards
- Mutation error callbacks present
- Cache invalidation after mutations

**Agent 3: Security/Auth**

- Clerk middleware covers all protected routes
- Webhook signature verification present
- No sensitive data in client components
- CSRF protection via tRPC batch endpoint
- Environment variables not exposed to client (only `NEXT_PUBLIC_*`)

### Phase 3: Browser Testing

**Tool selection:** Use `browse` CLI (primary) or Chrome DevTools MCP (fallback).

```bash
# Detect browse
test -x ~/.local/bin/browse && echo "browse available" || echo "fallback to Chrome MCP"
```

Start dev server:

```bash
pnpm --filter @stonegeo/web dev &
# Wait for "Ready in" message, note port (usually 3000 or 3001)
BASE=http://localhost:3000
```

Test each of the 6 dashboard routes using `browse`:

**Navigate and inspect each route:**

```bash
# Navigate
browse goto $BASE/overview

# Check console errors
browse console --errors

# Verify loading states + interactive elements (look for skeleton refs)
browse snapshot -i

# Verify empty state text
browse text

# Check responsive layout (sidebar collapse at <lg)
browse responsive

# Diff after interaction to verify state transitions
browse snapshot -D
```

**Repeat for all routes:** `/overview`, `/visibility`, `/audit`, `/sources`, `/backlog`, `/settings`

**Clerk auth verification** (on each route):

```bash
# Look for Clerk component refs (@e refs for SignIn, UserButton, OrganizationSwitcher)
browse snapshot -i | grep -i "clerk\|sign-in\|org-switch\|user-button"
```

**Screenshot on failure:**

```bash
browse screenshot /tmp/stonegeo-<route>-failure.png
```

**Headed mode escalation:** For visual/CSS/layout failures that headless screenshots can't diagnose, escalate to `/open-gstack-browser` — a steerable Chromium with Claude Code sidebar for live interactive debugging.

If `browse` is unavailable, fall back to `mcp__chrome-devtools__*` tools for navigation, console inspection, and screenshots.

### Phase 4: Fix Issues

For each discovered issue:

1. Classify severity (P0-P3)
2. Group by root cause
3. Fix in priority order
4. Run typecheck after each fix batch
5. Run build after all fixes

### Phase 5: Verify

1. Re-run typecheck: `pnpm typecheck`
2. Re-run build: `pnpm --filter @stonegeo/web build`
3. Re-run browser tests if available
4. Verify no regressions

### Phase 6: Deploy

```bash
# StoneGEO deploys via Render auto-deploy on push to master
git add -A
git commit -m "fix: QA cycle fixes -- [summary]"
git push origin master
```

Post-deploy verification:

- Check Render dashboard for successful deploy
- Verify production URL loads

## Known Issues Registry

Track issues across sessions. Update this list after each QA run.

### Fixed (QA Run 2026-02-27, Cycle 1)

- Claude-User crawler missing from robots audit seed data
- Header inconsistency across 4 pages (Sources empty state, Audit)
- Disabled "New Sprint" button missing tooltip
- robots.txt parser rewrite for edge cases
- Error state missing on Overview page
- Empty `tooling/` directory

### Fixed (QA Run 2026-02-27, Cycle 2)

- Error states missing on Visibility, Audit, Sources, Backlog, Settings pages
- Sources page header inconsistency in empty state
- Sources page missing brand selector for multi-brand tenants
- Sources page duplicate unfiltered query optimized
- Backlog mutation missing error display

### Open P2 Items (carry forward)

- Overview chart sections show objective lists instead of actual Recharts visualizations
- ConfidenceIndicator component unused (created but never imported)
- EngineBadge component unused (created but never imported)
- Webhook handler missing `organization.updated` and `organization.deleted` events
- Webhook hardcodes MEMBER role for all new org memberships
- Error states could be extracted into a shared ErrorBanner component (DRY)

## Autonomous Operation Rules

### Never Stop For

- Type errors -- fix them
- Build errors -- fix them
- Missing error states -- add them
- UI inconsistencies -- fix them
- Unused components -- note for cleanup
- Minor code quality issues -- fix inline

### Only Stop For (ask user)

- Destructive database operations (DROP, TRUNCATE)
- Deleting user files/directories
- Git history rewriting (force push, rebase)
- Production infrastructure changes
- Spending money (new services)

## Feature Coverage Matrix

| Feature          | Route         | Key Checks                                           |
| ---------------- | ------------- | ---------------------------------------------------- |
| Overview KPIs    | /overview     | 4 metric cards, error banner, loading skeletons      |
| Overview Charts  | /overview     | Chart placeholders, empty state                      |
| AI Visibility    | /visibility   | Brand selector, objectives, clusters, run status     |
| Site Audit       | /audit        | robots/sitemap/llms.txt cards, audit history table   |
| Source Map       | /sources      | Brand selector, page type filter, citations table    |
| Action Backlog   | /backlog      | Priority/status filters, status mutation, error UI   |
| Settings Brands  | /settings     | Brand CRUD form, brand list, expand objectives       |
| Settings Objects | /settings     | Objectives grid, KPI targets display                 |
| Auth: Sign-in    | /             | Clerk SignInButton, branded landing page             |
| Auth: Protected  | middleware    | All dashboard routes protected, API routes protected |
| Auth: Webhook    | /api/webhooks | Svix verification, org+member sync                   |
| Auth: Tenant     | trpc/init     | Auto-provision, demo data seeding                    |
| Sidebar Nav      | layout        | Active state, collapsed mobile, org switcher         |

## Completion Signal

```json
{
  "status": "complete",
  "project": "stonegeo",
  "cycles": 1,
  "typecheck": "pass",
  "build": "pass",
  "issuesFixed": 0,
  "openP2": 6,
  "deployed": false
}
```

## Version

**Current Version:** 1.1.0
**Last Updated:** 2026-03-14

### Changelog

- **1.1.0**: Phase 3 browser testing migrated to `browse` CLI (primary)
  - `browse` at `~/.local/bin/browse` is now the primary tool for all browser testing
  - Per-route commands: `goto`, `console --errors`, `snapshot -i`, `text`, `responsive`, `snapshot -D`
  - Clerk component detection via `browse snapshot -i | grep -i "clerk|..."`
  - Screenshot on failure via `browse screenshot`
  - Chrome DevTools MCP (`mcp__chrome-devtools__*`) retained as fallback
  - Detection: `test -x ~/.local/bin/browse`

- **1.0.0**: Initial skill generated from /qa-cycle
  - Full project discovery: 6 dashboard pages, 7 tRPC routers, Clerk auth
  - Code analysis approach (typecheck + build + code review)
  - Browser testing support via Chrome DevTools MCP
  - Error state coverage across all pages
  - Sources page brand selector + query optimization
  - Known issues registry for cross-session tracking
