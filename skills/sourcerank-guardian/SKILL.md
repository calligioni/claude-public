---
name: sourcerank-guardian
description: "Pre-deploy guardian for SourceRank AI. Runs a comprehensive multi-layer analysis before any deploy to staging or production on Render. Covers code-level review (auth bypass, timing attacks, org isolation, secrets, API validation, dependency CVEs), infrastructure review (Render config, CORS, CSRF, rate limiting, worker health), runtime validation (health checks, auth enforcement, security headers, TLS), and diff-aware analysis. Uses parallel subagents for speed. Triggers on: sourcerank guardian, pre-deploy check, guardian sourcerank, sourcerank pre-deploy."
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
  - WebFetch
  - Agent
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - AskUserQuestion
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: true }
  Read: { readOnlyHint: true, idempotentHint: true }
  Glob: { readOnlyHint: true, idempotentHint: true }
  Grep: { readOnlyHint: true, idempotentHint: true }
  WebFetch: { readOnlyHint: true, openWorldHint: true }
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

# SourceRank Guardian - Pre-Deploy Safety Gate

Last line of defense before broken code reaches staging or production. This skill performs a comprehensive multi-layer analysis of the SourceRank AI codebase, Render infrastructure, and runtime environment to catch architectural problems that surface-level testing misses.

## Context

SourceRank AI is a brand visibility monitoring SaaS that tracks how brands appear across AI platforms (ChatGPT, Claude, Perplexity, Gemini). The stack:

- **Frontend:** Next.js 14 (App Router, React 18, next-intl i18n)
- **Backend:** Fastify (TypeScript, Node.js 20), plugin-based architecture
- **Database:** PostgreSQL (Supabase) + Drizzle ORM + raw Supabase client (mixed)
- **Queue:** BullMQ workers + Redis (ioredis)
- **Auth:** Supabase Auth (JWT) + API key auth (timing-safe, SHA-256 hashed)
- **Payments:** Stripe (token-based billing with webhooks)
- **Infrastructure:** Render (web, API, worker services), Supabase (DB + auth)
- **Monorepo:** Turborepo + pnpm workspaces
- **CI/CD:** GitHub Actions (ci.yml, e2e.yml)

### Why This Skill Exists

A CTO review (2026-03-15) uncovered 2 critical and 4 high-severity issues that testing alone missed:

1. Admin endpoint timing attack (string `!==` instead of `timingSafeEqual`)
2. Broad `/admin/` URL-pattern auth bypass in Supabase auth plugin
3. Org metadata injection via user-writable `user_metadata.organization_id`
4. Hardcoded superadmin email
5. Unbounded `SELECT *` from ai_mentions for dashboard aggregation (DoS vector)
6. Framework CVEs (Next.js 14.2.35, Fastify 4.x)

This guardian catches these classes of problems before they reach production.

## Codebase Map

These are the key paths the guardian must analyze. Pass these to subagents to avoid wasteful file discovery.

### API Source

- `apps/api/src/routes/` — 29 route modules (brands/, monitoring/, tokens/, holdings/, organizations/, users/, alerts/, analytics/, billing/, cms/, competitive/, competitors/, content/, intelligence/, platform/, public/, readiness/, recommendations/, reports/, site-audit/, stream/, test-query/, visibility/, white-label/, agency/, authority/, ai/, backlog/)
- `apps/api/src/plugins/` — auth, CSRF, permissions, rate limiting, token metering, API versioning, public API auth
- `apps/api/src/services/` — 44 service files (api-key-service, cache-service, ai-influence-score, crisis-detector, etc.)
- `apps/api/src/utils/superadmin.ts` — superadmin check (env var or fallback)
- `apps/api/src/index.ts` — Fastify entry point, plugin registration

### Database

- `packages/database/src/` — Drizzle schema definitions
- `packages/database/drizzle/` — Drizzle config
- `packages/database/migrations/` — SQL migrations

### Frontend

- `apps/web/` — Next.js 14 app (App Router, React 18)
- `apps/web/src/app/` — page routes
- `apps/web/src/components/` — UI components

### Shared Packages

- `packages/types/` — shared TypeScript types
- `packages/utils/` — shared utilities

### Worker

- `apps/worker/src/` — BullMQ worker jobs (monitoring, scheduling)
- `apps/worker/src/jobs/` — individual job handlers
- `apps/worker/src/index.ts` — worker entry point

### Infrastructure

- `render.yaml` — Render blueprint (services, databases, env vars)
- `.github/workflows/ci.yml` — lint, typecheck, security audit, unit tests, build
- `.github/workflows/e2e.yml` — Playwright E2E tests

### Config

- `.env.example` — all required env vars
- `turbo.json` — Turborepo task graph
- `pnpm-workspace.yaml` — monorepo config

## Workflow

### Step 0: Identify Deploy Target

Ask the user (if not specified):

- Deploy target: staging or production?
- Is there a specific commit range to review, or review HEAD against the last deployed commit?

If the user says "just run it" or does not specify, default to:

- Target: production (Render auto-deploys on push)
- Range: last 5 commits on current branch

### Step 1: Diff-Aware Analysis (Layer 4 — runs first in orchestrator)

This runs in the orchestrator because it determines which files changed and informs the scope of Layers 1-3.

1. Run `git log --oneline -10` in `/Users/ps/code/Sourcerankai` to see recent commits
2. Run `git diff --name-only HEAD~5..HEAD` (or the specified range) to get changed files
3. Categorize changed files into risk buckets:

| Bucket             | Files Matching                                                                           | Risk     |
| ------------------ | ---------------------------------------------------------------------------------------- | -------- |
| AUTH_CHANGED       | `*/plugins/supabase-auth.ts`, `*/plugins/permissions.ts`, `*/plugins/public-api-auth.ts` | CRITICAL |
| ADMIN_CHANGED      | `*/utils/superadmin.ts`, any route with `/admin/` path                                   | CRITICAL |
| API_KEY_CHANGED    | `*/services/api-key-service.ts`                                                          | CRITICAL |
| ROUTES_CHANGED     | `apps/api/src/routes/**/*.ts`                                                            | HIGH     |
| PLUGINS_CHANGED    | `apps/api/src/plugins/*.ts`                                                              | HIGH     |
| MIGRATIONS_CHANGED | `packages/database/migrations/*`                                                         | HIGH     |
| WORKER_CHANGED     | `apps/worker/**`                                                                         | MEDIUM   |
| ENV_CHANGED        | `.env*`, `render.yaml`                                                                   | HIGH     |
| CI_CHANGED         | `.github/workflows/*`                                                                    | MEDIUM   |
| FRONTEND_CHANGED   | `apps/web/**`                                                                            | LOW      |

4. Check if new route files were added that are NOT registered in the main server file (`apps/api/src/index.ts`)
5. Store the diff summary and risk buckets to pass to Layer 1-3 subagents

### Step 2: Launch Parallel Analysis (Layers 1, 2, 3)

Spawn three subagents in parallel using the Agent tool. Pass each the diff summary from Step 1 so they can prioritize changed files.

#### Subagent 1: Code-Level Review (Layer 1) — model: sonnet

Spawn prompt:

```
You are a code-level security and correctness reviewer for SourceRank AI, a brand visibility monitoring SaaS.
Working directory: /Users/ps/code/Sourcerankai

CHANGED FILES (focus review here):
{diff_summary_from_step_1}

Run ALL of the following checks. For each check, report PASS, FAIL, or WARN with specific file:line references.

CHECK 1 - AUTH BYPASS AUDIT:
- Read apps/api/src/plugins/supabase-auth.ts — list every URL pattern that skips auth
- Verify each skip pattern is narrowly scoped (exact path match, not broad .includes())
- Check that /admin/ routes have their own auth enforcement (x-admin-key with timingSafeEqual)
- Verify no new route modules were added that would match a skip pattern accidentally
- FAIL if: any broad pattern like .includes('/admin/') that could match unintended routes
- FAIL if: any admin endpoint uses direct string comparison (!==) instead of timingSafeEqual

CHECK 2 - TIMING-SAFE KEY COMPARISON:
- Grep all .ts files in apps/api/ for patterns: !== expectedKey, !== process.env, key !== , secret !==
- These indicate timing-unsafe string comparisons for secrets
- The correct pattern is crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b))
- Verify apps/api/src/services/api-key-service.ts uses timingSafeEqual (reference implementation)
- FAIL if: any secret/key comparison uses !== or === instead of timingSafeEqual

CHECK 3 - ORGANIZATION ISOLATION:
- Read apps/api/src/plugins/supabase-auth.ts — check how organizationId is resolved
- Verify organizationId NEVER comes from user_metadata (user-writable in Supabase)
- Verify organizationId comes from database lookup (dbUser.organizationId) or falls back to user.id
- Grep all route files for direct references to user_metadata — flag any that use it for authorization decisions
- FAIL if: organizationId derived from user_metadata
- WARN if: any route reads user_metadata for authorization purposes

CHECK 4 - SUPERADMIN SECURITY:
- Read apps/api/src/utils/superadmin.ts
- Verify SUPERADMIN_EMAIL is read from env var (process.env.SUPERADMIN_EMAIL), not hardcoded
- Check that isSuperAdmin uses case-insensitive comparison
- FAIL if: email is hardcoded without env var fallback
- WARN if: only a single superadmin is supported (no comma-separated list)

CHECK 5 - UNBOUNDED QUERIES:
- Grep all route files for .select('*') without .limit() — these fetch all rows
- Specifically check the brands dashboard endpoint for in-memory aggregation of ai_mentions
- Grep for patterns like: .from('ai_mentions').select('*').eq('brand_id' — without limit or pagination
- The correct pattern is either: column projection (.select('platform, sentiment')), count-only (.select('*', { count: 'exact', head: true })), or bounded by date range
- FAIL if: any endpoint fetches unbounded SELECT * for aggregation purposes
- WARN if: SELECT * is used where column projection would suffice

CHECK 6 - SECRETS AUDIT:
- Grep the entire repo (excluding node_modules/, .git/, dist/) for patterns: sk-ant-, sk_live_, sk_test_, ghp_, gho_, AKIA, supabase_service_role_key\s*=\s*["'][^<], password\s*=\s*["'][^<]
- Check .gitignore — verify .env is listed
- Verify no .env files (not .env.example) are tracked in git: run `git ls-files '*.env' ':!*.example'`
- FAIL if: any hardcoded secrets found or .env files tracked in git

CHECK 7 - INPUT VALIDATION:
- Grep route files for request.body, request.params, request.query usage
- Verify each has a corresponding Zod schema validation (schema.parse or schema.safeParse)
- Check for any routes that use request.body directly without Zod validation
- WARN if: any route handler accesses request.body without schema validation

CHECK 8 - DEPENDENCY CVEs:
- Read apps/web/package.json — check next version (must be >= 14.2.36 or patched)
- Read apps/api/package.json — check fastify version (must be >= 5.7.2 or patched 4.x)
- Run: cd /Users/ps/code/Sourcerankai && pnpm audit --json 2>/dev/null | head -100
- FAIL if: known CVE versions detected (next < 14.2.36, fastify < 4.29.2)
- WARN if: pnpm audit reports any high/critical vulnerabilities

OUTPUT FORMAT:
For each check, output exactly:
## CHECK N - NAME: PASS|FAIL|WARN
Findings: (specific file:line references)
Impact: (what could go wrong)
Fix: (recommended action)
```

#### Subagent 2: Infrastructure Review (Layer 2) — model: sonnet

Spawn prompt:

```
You are an infrastructure reviewer for SourceRank AI, deployed on Render with Supabase.
Working directory: /Users/ps/code/Sourcerankai

CHANGED FILES (focus review here):
{diff_summary_from_step_1}

Run ALL of the following checks. For each check, report PASS, FAIL, or WARN with specific file:line references.

CHECK 1 - RENDER BLUEPRINT:
- Read render.yaml — verify all services are defined (web, api, worker)
- Verify health check paths are configured for web and API services
- Verify NODE_ENV=production is set
- Check that sensitive env vars use sync: false (not hardcoded in render.yaml)
- FAIL if: secrets hardcoded in render.yaml
- WARN if: health check not configured for any service

CHECK 2 - CORS CONFIGURATION:
- Read apps/api/src/index.ts or wherever CORS is configured
- Verify CORS_ORIGIN is read from env var, not hardcoded
- Verify no wildcard (*) origin
- Verify no raw IPs in CORS origins
- FAIL if: wildcard origin or raw IPs
- WARN if: CORS origin includes localhost in production config

CHECK 3 - CSRF PROTECTION:
- Read apps/api/src/plugins/csrf.ts
- Verify COOKIE_SECRET is required in production (not optional/fallback)
- Verify the plugin does not fall back to a dev secret in production
- Verify CSRF is applied to state-changing routes (POST, PUT, DELETE)
- FAIL if: CSRF can run with a default/dev secret in production
- WARN if: random per-instance secret used (breaks across scaled instances)

CHECK 4 - RATE LIMITING:
- Read apps/api/src/plugins/rate-limit-public.ts and any rate limit config
- Verify rate limiting is applied to public-facing endpoints
- Verify rate limiting is applied to auth endpoints (login, token refresh)
- WARN if: no rate limiting on auth or public endpoints

CHECK 5 - WORKER RESILIENCE:
- Read apps/worker/src/index.ts
- Check uncaughtException and unhandledRejection handlers
- Verify the process exits (process.exit(1)) after uncaught exceptions, not continues
- Verify BullMQ workers have retry configuration and concurrency limits
- FAIL if: uncaughtException handler keeps process alive
- WARN if: no retry/backoff configuration on queues

CHECK 6 - CI/CD PIPELINE:
- Read .github/workflows/ci.yml
- Check: are all jobs blocking? (no continue-on-error: true)
- Check: does security audit run on every PR?
- Check: are typecheck and tests required to pass?
- Read .github/workflows/e2e.yml — verify E2E tests run
- WARN if: any CI job has continue-on-error: true
- WARN if: security audit is missing

CHECK 7 - REDIS/BULLMQ SECURITY:
- Grep for BullMQ connection configs — verify they include connection timeouts
- Check if Redis URLs use TLS (rediss://) in production env references
- Verify no Redis passwords are hardcoded in source
- WARN if: connection timeouts not configured
- WARN if: Redis connection does not specify TLS for production

OUTPUT FORMAT:
For each check, output exactly:
## CHECK N - NAME: PASS|FAIL|WARN
Findings: (specific file:line references)
Impact: (what could go wrong)
Fix: (recommended action)
```

#### Subagent 3: Runtime Validation (Layer 3) — model: haiku

Spawn prompt:

```
You are a runtime validator for SourceRank AI's production environment.
This is a lightweight smoke test layer — if the site is not reachable, report all checks as SKIP (not FAIL).

Run the following checks using Bash (curl commands). All checks should be non-destructive and read-only.

CHECK 1 - HEALTH CHECK:
- Run: curl -s -o /dev/null -w "%{http_code}" https://api.sourcerank.ai/health --max-time 10
- Run: curl -s -o /dev/null -w "%{http_code}" https://app.sourcerank.ai --max-time 10
- PASS if: API returns 200 and web returns 200
- FAIL if: either returns non-200
- SKIP if: connection timeout

CHECK 2 - AUTH ENFORCEMENT:
- Test endpoints that MUST require authentication (should return 401 without a token):
  1. curl -s -o /dev/null -w "%{http_code}" https://api.sourcerank.ai/api/v1/brands --max-time 10
  2. curl -s -o /dev/null -w "%{http_code}" https://api.sourcerank.ai/api/v1/organizations --max-time 10
  3. curl -s -o /dev/null -w "%{http_code}" https://api.sourcerank.ai/api/v1/users/me --max-time 10
  4. curl -s -o /dev/null -w "%{http_code}" https://api.sourcerank.ai/api/v1/tokens --max-time 10
  5. curl -s -o /dev/null -w "%{http_code}" https://api.sourcerank.ai/api/v1/alerts --max-time 10
- PASS if: all return 401 or 403
- FAIL if: any returns 200 or 2xx (data exposed without auth)

CHECK 3 - ADMIN ENDPOINT LOCKDOWN:
- Run: curl -s -o /dev/null -w "%{http_code}" -X POST https://api.sourcerank.ai/admin/brands/test/monitor/trigger --max-time 10
- PASS if: returns 401 or 403 (requires admin key)
- FAIL if: returns 200 or triggers monitoring without auth

CHECK 4 - CORS HEADERS:
- Run: curl -s -I -H "Origin: https://evil.com" https://api.sourcerank.ai/health --max-time 10
- Check the Access-Control-Allow-Origin header in response
- PASS if: header is absent or does not echo back https://evil.com
- FAIL if: Access-Control-Allow-Origin is * or echoes back the evil origin

CHECK 5 - SECURITY HEADERS:
- Run: curl -s -I https://api.sourcerank.ai/health --max-time 10
- Check for presence of:
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY or SAMEORIGIN
  - X-DNS-Prefetch-Control
  - X-Download-Options
- PASS if: Helmet headers present (at least X-Content-Type-Options)
- WARN if: any expected header missing

CHECK 6 - TLS CERTIFICATE:
- Run: curl -sv https://api.sourcerank.ai/health 2>&1 | grep -E "SSL certificate|subject:|expire"
- Also: curl -sv https://app.sourcerank.ai 2>&1 | grep -E "SSL certificate|subject:|expire"
- Verify certificates are valid and not expiring within 14 days
- PASS if: valid certificates with >14 days remaining
- WARN if: certificate expires within 14 days

CHECK 7 - WEBHOOK ENDPOINT:
- Run: curl -s -o /dev/null -w "%{http_code}" -X POST https://api.sourcerank.ai/api/v1/webhooks/stripe -H "Content-Type: application/json" -d '{}' --max-time 10
- PASS if: returns 400 (bad payload) or 401 (Stripe signature validation fails) — NOT 200
- FAIL if: returns 200 (webhook processed without valid Stripe signature)

OUTPUT FORMAT:
For each check, output exactly:
## CHECK N - NAME: PASS|FAIL|WARN|SKIP
Findings: (raw curl output or summary)
```

### Step 3: Collect and Synthesize Results

After all three subagents complete:

1. Collect their reports
2. Build the consolidated guardian report

### Step 4: Generate Guardian Report

Output the final report in this format:

```markdown
# SourceRank Guardian Report

**Date:** {date}
**Target:** {staging|production}
**Commit range:** {range}
**Overall verdict:** DEPLOY APPROVED / DEPLOY BLOCKED

## Summary

| Layer              | Checks Run | Pass  | Fail  | Warn  | Skip  |
| ------------------ | ---------- | ----- | ----- | ----- | ----- |
| L1: Code Review    | 8          | N     | N     | N     | 0     |
| L2: Infrastructure | 7          | N     | N     | N     | 0     |
| L3: Runtime        | 7          | N     | N     | N     | N     |
| L4: Diff Analysis  | N          | N     | N     | N     | 0     |
| **Total**          | **N**      | **N** | **N** | **N** | **N** |

## Blocking Issues (FAIL)

{List each FAIL with file:line, impact, and recommended fix}

## Warnings (WARN)

{List each WARN with file:line, impact, and recommended fix}

## Diff Risk Assessment

{Summary of changed files grouped by risk bucket from Step 1}

## Detailed Results

### Layer 1: Code-Level Review

{Full output from Subagent 1}

### Layer 2: Infrastructure Review

{Full output from Subagent 2}

### Layer 3: Runtime Validation

{Full output from Subagent 3}

### Layer 4: Diff-Aware Analysis

{Detailed diff analysis from Step 1}
```

### Step 5: Deploy Decision

- If ANY check has status **FAIL**: output `DEPLOY BLOCKED` and list the blocking issues
- If only **WARN** and **PASS**: output `DEPLOY APPROVED WITH WARNINGS`
- If all **PASS**: output `DEPLOY APPROVED`

Ask the user if they want to:

1. Proceed with deploy (if approved)
2. Fix the blocking issues first (if blocked)
3. Generate a fix plan for the warnings

## Known Issues (Pre-Seeded)

These are known issues from the 2026-03-15 CTO review. The guardian should check for them and note their current status:

1. **Admin timing attack (S3):** `apps/api/src/routes/monitoring/index.ts` used `!==` for admin key comparison instead of `timingSafeEqual`. Should be fixed — verify.

2. **Broad admin auth bypass (S4):** `apps/api/src/plugins/supabase-auth.ts` used `request.url.includes('/admin/')` to skip auth. Should be narrowed to specific endpoint — verify.

3. **Org metadata injection (S8):** `apps/api/src/plugins/supabase-auth.ts` used `user.user_metadata?.organization_id` for organizationId fallback. Should use `user.id` instead — verify.

4. **Hardcoded superadmin (S5):** `apps/api/src/utils/superadmin.ts` had `SUPERADMIN_EMAIL = 'admin@sourcerank.ai'` hardcoded. Should read from env var — verify.

5. **Unbounded mention fetch (S6):** Dashboard endpoint at `apps/api/src/routes/brands/index.ts` did `SELECT * FROM ai_mentions WHERE brand_id = ?` without limit for aggregation. Should use column projection and bounded queries — verify.

6. **Framework CVEs (S1, S2):** Next.js 14.2.35 (DoS via RSC) and Fastify ^4.25.0 (Content-Type bypass). Should be upgraded — verify current versions.

7. **CSRF secret fallback (S7):** `apps/api/src/plugins/csrf.ts` falls back to dev secret or random per-instance secret in production. Should refuse to start without configured COOKIE_SECRET.

8. **Worker uncaughtException (S9):** `apps/worker/src/index.ts` keeps process alive after uncaughtException. Should crash and let Render restart.

9. **Mixed DB access:** Some routes use Drizzle ORM, others use raw Supabase client. Inconsistency risk — track but don't block deploys.

## Invocation Examples

```
# Full guardian check before production deploy
/sourcerank-guardian

# Guardian check for staging
/sourcerank-guardian staging

# Guardian check focused on last 3 commits
/sourcerank-guardian production last 3 commits

# Quick guardian (skip runtime checks if site is down)
/sourcerank-guardian --skip-runtime
```
