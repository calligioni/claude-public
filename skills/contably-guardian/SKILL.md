---
name: contably-guardian
description: "Pre-deploy guardian for Contably. Multi-layer analysis (code, infra, runtime, diff-aware) before deploy to staging/production. Parallel subagents. Triggers on: contably guardian, pre-deploy check, guardian, contably pre-deploy."
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

# Contably Guardian - Pre-Deploy Safety Gate

Last line of defense before broken code reaches staging or production. This skill performs a comprehensive multi-layer analysis of the Contably codebase, infrastructure, and runtime environment to catch architectural problems that surface-level testing misses.

## Context

Contably is an AI-powered accounting SaaS for Brazilian companies. The stack:

- **Backend:** FastAPI (Python 3.11), SQLAlchemy async, Alembic migrations, Celery workers
- **Frontend:** React admin dashboard (Vite), Next.js client portal
- **Database:** MySQL 8.0 (migrated from PostgreSQL) with async drivers
- **Infrastructure:** OCI (Oracle Cloud), OKE (Kubernetes), OCIR (container registry)
- **Auth:** Clerk (JWT via clerk_user_id) + legacy JWT auth
- **CI/CD:** OCI DevOps (build_spec_ci.yaml → build_spec_images.yaml → deploy specs)

### Why This Skill Exists

Black-box testing (like /fulltest-skill) catches surface-level UI and API issues but misses deep architectural problems. An external review caught three critical issues that testing alone missed:

1. K8s migration race condition (entrypoint.sh running alembic upgrade on every pod startup)
2. Zero RLS test coverage after PG-to-MySQL migration
3. Production template still referencing DigitalOcean infrastructure instead of OCI

This skill is the structural review that prevents those classes of problems from reaching production.

## Codebase Map

These are the key paths the guardian must analyze. Pass these to subagents to avoid wasteful file discovery.

### API Source

- `apps/api/src/api/routes/` -- all route modules (auth/, admin/, tenancy/, client/, portal/, integrations/, workflows/, intelligence/, system/, accounting/, reconciliation/, reports/, transactions/, financial_reports/, industry_rules/, payroll/, monthly_closing/)
- `apps/api/src/api/deps/` -- dependencies (auth.py, user_context.py, permissions.py, company_access.py, rate_limiting.py, pagination.py, database.py)
- `apps/api/src/api/main.py` -- app setup, CORS, middleware
- `apps/api/src/api/routers/__init__.py` -- route registration (register_routers function)
- `apps/api/src/models/` -- all SQLAlchemy models (27 files with company_id tenant isolation)
- `apps/api/src/config/settings.py` -- Settings class (CORS, metrics_allowed_ips, DB config)
- `apps/api/entrypoint.sh` -- container entrypoint (migration + uvicorn)

### Migrations

- `apps/api/alembic/` -- migration scripts (env.py + versions/)
- `apps/api/Dockerfile.migrate` -- dedicated migration container

### Infrastructure

- `infrastructure/kubernetes/base/` -- base K8s manifests (api-deployment.yaml, ingress.yaml, configmap.yaml, secret.yaml, etc.)
- `infrastructure/kubernetes/overlays/oci/` -- OCI staging overlay
- `infrastructure/kubernetes/overlays/oci-prod/` -- OCI production overlay (network-policies.yaml, ingress-oci-prod.yaml)
- `infrastructure/kubernetes/overlays/staging/` -- staging overlay
- `infrastructure/kubernetes/overlays/prod/` -- production overlay

### CI/CD (OCI DevOps)

- `infrastructure/oci-devops/build_spec_ci.yaml` -- lint, typecheck, tests, security scans
- `infrastructure/oci-devops/build_spec_images.yaml` -- build Docker images, push to OCIR
- `infrastructure/oci-devops/deploy_spec_staging.yaml` -- deploy to staging OKE
- `infrastructure/oci-devops/deploy_spec_prod.yaml` -- deploy to production OKE

### Templates & Config

- `apps/api/.env.production.template` -- production env template
- `apps/api/.env.example` -- dev env example
- `infrastructure/.env.production.template` -- infra-level production template

### Tests

- `apps/api/tests/unit/` -- unit tests (test_rls.py, test_multitenancy.py, test_auth\*.py, test_cors.py, etc.)
- `apps/api/tests/integration/` -- integration tests (test_api_auth.py, test_api_routes.py, test_p1_api_endpoints.py)

### Frontend

- `apps/admin/` -- React admin dashboard (Vite, TypeScript)
- `apps/client-portal/` -- Next.js client portal
- `apps/admin/.env.production` -- admin production env

## Workflow

### Step 0: Identify Deploy Target

Ask the user (if not specified):

- Deploy target: staging or production?
- Is there a specific commit range to review, or review HEAD against the last deployed commit?

If the user says "just run it" or does not specify, default to:

- Target: staging
- Range: last 5 commits on current branch

### Step 1: Diff-Aware Analysis (Layer 4 -- runs first in orchestrator)

This runs in the orchestrator because it determines which files changed and informs the scope of Layers 1-3.

1. Run `git log --oneline -10` in `/Users/ps/code/contably` to see recent commits
2. Run `git diff --name-only HEAD~5..HEAD` (or the specified range) to get changed files
3. Categorize changed files into risk buckets:

| Bucket             | Files Matching                                                                         | Risk     |
| ------------------ | -------------------------------------------------------------------------------------- | -------- |
| AUTH_CHANGED       | `*/routes/auth/*`, `*/deps/auth.py`, `*/deps/user_context.py`, `*/deps/permissions.py` | CRITICAL |
| MODELS_CHANGED     | `*/models/*.py`                                                                        | HIGH     |
| MIGRATIONS_CHANGED | `*/alembic/versions/*`                                                                 | HIGH     |
| K8S_CHANGED        | `infrastructure/kubernetes/**`                                                         | HIGH     |
| ROUTES_CHANGED     | `*/routes/**/*.py`                                                                     | MEDIUM   |
| ENV_CHANGED        | `.env*`, `*template*`                                                                  | HIGH     |
| CI_CHANGED         | `.github/workflows/*`                                                                  | MEDIUM   |
| ENTRYPOINT_CHANGED | `entrypoint.sh`                                                                        | CRITICAL |
| FRONTEND_CHANGED   | `apps/admin/**`, `apps/client-portal/**`                                               | LOW      |

4. Check if new route files were added that are NOT in the registration list (`apps/api/src/api/routers/__init__.py`)
5. Store the diff summary and risk buckets to pass to Layer 1-3 subagents

### Step 2: Launch Parallel Analysis (Layers 1, 2, 3)

Spawn three subagents in parallel using the Agent tool. Pass each the diff summary from Step 1 so they can prioritize changed files.

#### Subagent 1: Code-Level Review (Layer 1) -- model: sonnet

Spawn prompt:

```
You are a code-level security and correctness reviewer for Contably, an AI accounting SaaS.
Working directory: /Users/ps/code/contably

CHANGED FILES (focus review here):
{diff_summary_from_step_1}

Run ALL of the following checks. For each check, report PASS, FAIL, or WARN with specific file:line references.

CHECK 1 - TENANT ISOLATION AUDIT:
- Read apps/api/src/models/ and list every model class that has a company_id column
- For each such model, verify there is a corresponding test in apps/api/tests/ that validates tenant isolation (filtering by company_id)
- Grep for any raw SQL queries (text(), execute()) that do NOT include a company_id filter
- Check apps/api/src/api/deps/company_access.py for the CompanyAccessChecker implementation
- FAIL if: any model with company_id has zero test coverage for tenant filtering
- WARN if: raw SQL queries exist without company_id filters

CHECK 2 - MIGRATION SAFETY:
- Read apps/api/entrypoint.sh — check if it runs alembic upgrade head inline (race condition with multiple pods)
- Check if apps/api/Dockerfile.migrate exists and is used (correct pattern: K8s Job or init container for migrations)
- Read infrastructure/kubernetes/base/api-deployment.yaml — check if it uses an initContainer for migrations
- Check infrastructure/kubernetes/base/ for a migration Job manifest (e.g., seed-database-job.yaml or similar)
- FAIL if: entrypoint.sh runs alembic upgrade head AND no K8s Job/initContainer handles migrations separately
- WARN if: entrypoint.sh has a fallback DDL path (inline ALTER TABLE statements)

CHECK 3 - AUTH COVERAGE:
- List all Python files in apps/api/src/api/routes/ recursively
- For each route file, check if it imports or uses any of: get_current_user, get_current_active_user, get_current_client_user, require_admin, require_manager, require_roles, require_master_admin, require_af_admin, company_access, RoleChecker, bearer_scheme
- Known exceptions (no auth required): health endpoints, webhook receivers (clerk_webhooks.py), public portal resolve endpoints
- FAIL if: any non-exception route file has zero auth dependency usage
- List the specific unprotected routes found

CHECK 4 - SECRETS AUDIT:
- Grep the entire repo (excluding .venv/, node_modules/, .git/) for patterns: sk-ant-, sk_live_, sk_test_, ghp_, gho_, AKIA, password\s*=\s*["'][^<], api_key\s*=\s*["'][^<]
- Check .gitignore at repo root, apps/api/, apps/admin/, apps/client-portal/ — verify .env is listed
- Verify no .env files (not .env.example or .env.*template) are tracked in git: run `git ls-files '*.env' ':!*.example' ':!*.template'`
- FAIL if: any hardcoded secrets found or .env files tracked in git

CHECK 5 - DATABASE COMPATIBILITY (PG-to-MySQL):
- Grep all .py files under apps/api/src/ for PostgreSQL-specific operators: @>, ?column, #>>, #>, ->, ->>, ~~, ILIKE, SIMILAR TO, array_agg, jsonb_, JSONB, UUID(as_uuid
- Check if sqlalchemy.dialects.postgresql is imported anywhere outside of alembic/
- Grep alembic/versions/ for postgresql-specific syntax in recent migrations (last 5 files)
- WARN if: PostgreSQL-specific operators found in non-migration code
- Note: The base model at apps/api/src/models/base.py imports UUID from sqlalchemy.dialects.postgresql — flag this specifically

CHECK 6 - CONFIG CONSISTENCY:
- Read apps/api/.env.production.template — grep for "digitalocean", "DigitalOcean", "DO_", "DIGITALOCEAN", "nyc3", "registry.digitalocean.com"
- Read infrastructure/.env.production.template — same grep
- Any reference to DigitalOcean in production templates is a FAIL (infrastructure is on OCI)
- Check apps/api/src/config/settings.py for any hardcoded DigitalOcean references
- Check apps/api/src/api/routers/__init__.py for comments referencing DigitalOcean (known issue: register_routers docstring mentions "DigitalOcean App Platform")

CHECK 7 - CORS ORIGINS:
- Read CORS_ORIGINS from apps/api/.env.production.template
- Read CORS configuration from apps/api/src/api/main.py
- Verify no wildcard (*) origin is configured
- Verify no raw IPs (e.g., http://10.0.x.x, http://192.168.x.x) in CORS origins
- Verify all domains in CORS_ORIGINS match known Contably domains: contably.ai, admin.contably.ai, app.contably.ai, portal.contably.ai
- FAIL if: wildcard origin or raw IPs found

CHECK 8 - DEPENDENCY VULNERABILITIES (quick check):
- Read apps/api/requirements.txt — check for known problematic versions (just flag very old major versions)
- Read the root package.json and pnpm-lock.yaml date — flag if lockfile is older than 90 days
- Note: Full vulnerability scanning runs in CI (Trivy, pip-audit, pnpm audit) — this is just a quick local check
- WARN if: lockfile appears stale

OUTPUT FORMAT:
For each check, output exactly:
## CHECK N - NAME: PASS|FAIL|WARN
Findings: (specific file:line references)
Impact: (what could go wrong)
Fix: (recommended action)
```

#### Subagent 2: Infrastructure Review (Layer 2) -- model: sonnet

Spawn prompt:

```
You are an infrastructure reviewer for Contably, deployed on OCI (Oracle Cloud) with OKE (Kubernetes).
Working directory: /Users/ps/code/contably

CHANGED FILES (focus review here):
{diff_summary_from_step_1}

Run ALL of the following checks. For each check, report PASS, FAIL, or WARN with specific file:line references.

CHECK 1 - INGRESS TLS:
- Read infrastructure/kubernetes/base/ingress.yaml
- Verify: TLS is configured with valid hosts (contably.ai, api.contably.ai, portal.contably.ai)
- Verify: ssl-redirect annotation is "true"
- Verify: cert-manager.io/cluster-issuer annotation points to letsencrypt-prod
- Read infrastructure/kubernetes/overlays/oci-prod/ingress-oci-prod.yaml — check for any overrides
- Read infrastructure/kubernetes/overlays/oci/ingress-oci.yaml — check for staging overrides
- FAIL if: TLS not configured, ssl-redirect missing, or hosts mismatch actual domains

CHECK 2 - DEPLOYMENT HEALTH:
- Read infrastructure/kubernetes/base/api-deployment.yaml
- Verify: resource limits are set (both requests and limits for cpu and memory)
- Verify: livenessProbe, readinessProbe, and startupProbe are configured
- Verify: securityContext has runAsNonRoot: true, readOnlyRootFilesystem: true, allowPrivilegeEscalation: false
- Read infrastructure/kubernetes/base/celery-worker-deployment.yaml — same checks (except probes may differ for workers)
- Read infrastructure/kubernetes/base/celery-beat-deployment.yaml — same checks
- FAIL if: any deployment missing resource limits or probes
- WARN if: security context is incomplete

CHECK 3 - NETWORK POLICIES:
- Read infrastructure/kubernetes/overlays/oci-prod/network-policies.yaml
- Verify: default-deny policy exists (deny all ingress and egress)
- Verify: API pods can only receive ingress from ingress-nginx namespace
- Verify: API/Celery pods can only reach DB (port 5432) and Redis (port 6379) via specific IPs
- Verify: Dashboard/Portal pods cannot reach DB or Redis directly
- Verify: Flower pod can only reach Redis, not DB
- Check infrastructure/kubernetes/overlays/oci/network-policies.yaml — staging should have equivalent policies
- FAIL if: default-deny missing or DB/Redis accessible from dashboard/portal pods
- WARN if: staging network policies are less restrictive than production

CHECK 4 - METRICS ENDPOINT:
- Grep apps/api/src/config/settings.py for metrics_allowed_ips
- Grep apps/api/src/api/main.py for /metrics endpoint configuration
- Verify METRICS_ALLOWED_IPS is set in production configmap or .env.production.template
- Read infrastructure/kubernetes/base/configmap.yaml — check for METRICS_ALLOWED_IPS
- WARN if: metrics endpoint has no IP restriction in production config
- FAIL if: metrics endpoint is completely unprotected (no middleware checking source IP)

CHECK 5 - CI/CD PIPELINE:
- Read .github/workflows/oci-deploy.yaml
- Verify: deploy-staging job has `needs: build` (not running in parallel with CI)
- Verify: deploy-production requires manual approval (environment protection rules)
- Read .github/workflows/ci.yaml
- Check: does oci-deploy.yaml reference ci.yaml as a dependency? (It should — deploy should not happen if CI fails)
- WARN if: deploy can happen without CI passing (no needs: ci dependency in oci-deploy.yaml)
- FAIL if: production deploy has no manual approval gate

CHECK 6 - CONTAINER SECURITY:
- Read apps/api/Dockerfile — check for: non-root user, no secrets in build args, multi-stage build
- Read apps/admin/Dockerfile — same checks
- Read apps/client-portal/Dockerfile — same checks
- WARN if: any Dockerfile runs as root or copies .env files into the image

CHECK 7 - SECRETS MANAGEMENT:
- Read infrastructure/kubernetes/base/secret.yaml — verify it uses placeholder values (not real secrets)
- Read infrastructure/kubernetes/overlays/oci-prod/secrets-patch.yaml — same check
- Verify .github/workflows/oci-deploy.yaml patches secrets from GitHub Secrets (not from repo files)
- FAIL if: real secrets found in any yaml file in the repo

OUTPUT FORMAT:
For each check, output exactly:
## CHECK N - NAME: PASS|FAIL|WARN
Findings: (specific file:line references)
Impact: (what could go wrong)
Fix: (recommended action)
```

#### Subagent 3: Runtime Validation (Layer 3) -- model: haiku

Spawn prompt:

```
You are a runtime validator for Contably's staging environment.
This is a lightweight smoke test layer — if staging is not reachable, report all checks as SKIP (not FAIL).

Run the following checks using Bash (curl commands). All checks should be non-destructive and read-only.

CHECK 1 - HEALTH CHECK:
- Run: curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/health --max-time 10
- Run: curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/api/v1/health --max-time 10
- PASS if: both return 200
- FAIL if: either returns non-200
- SKIP if: connection timeout (staging may be down)

CHECK 2 - AUTH ENFORCEMENT:
- Test 5 endpoints that MUST require authentication (should return 401 or 403 without a token):
  1. curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/api/v1/companies --max-time 10
  2. curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/api/v1/invoices --max-time 10
  3. curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/api/v1/bank-transactions --max-time 10
  4. curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/api/v1/users/me --max-time 10
  5. curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/api/v1/accounting-firms --max-time 10
- PASS if: all return 401 or 403
- FAIL if: any returns 200 or 2xx (data exposed without auth)

CHECK 3 - METRICS LOCKDOWN:
- Run: curl -s -o /dev/null -w "%{http_code}" https://api.contably.ai/metrics --max-time 10
- PASS if: returns 403, 404, or connection refused
- FAIL if: returns 200 (metrics exposed to public)

CHECK 4 - CORS HEADERS:
- Run: curl -s -I -H "Origin: https://evil.com" https://api.contably.ai/api/v1/health --max-time 10
- Check the Access-Control-Allow-Origin header in response
- PASS if: header is absent or does not echo back https://evil.com
- FAIL if: Access-Control-Allow-Origin is * or echoes back the evil origin

CHECK 5 - SECURITY HEADERS:
- Run: curl -s -I https://api.contably.ai/api/v1/health --max-time 10
- Check for presence of:
  - Strict-Transport-Security (HSTS)
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY or SAMEORIGIN
- PASS if: all three present
- WARN if: any missing (some may be set at ingress level)
- Note: CSP is typically set on frontend apps, not APIs — do not FAIL for missing CSP on API

CHECK 6 - TLS CERTIFICATE:
- Run: curl -sv https://api.contably.ai/health 2>&1 | grep -E "SSL certificate|subject:|expire"
- Verify certificate is valid and not expiring within 14 days
- PASS if: valid certificate with >14 days remaining
- WARN if: certificate expires within 14 days

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
# Contably Guardian Report

**Date:** {date}
**Target:** {staging|production}
**Commit range:** {range}
**Overall verdict:** DEPLOY APPROVED / DEPLOY BLOCKED

## Summary

| Layer              | Checks Run | Pass  | Fail  | Warn  | Skip  |
| ------------------ | ---------- | ----- | ----- | ----- | ----- |
| L1: Code Review    | N          | N     | N     | N     | 0     |
| L2: Infrastructure | N          | N     | N     | N     | 0     |
| L3: Runtime        | N          | N     | N     | N     | N     |
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

These are known issues from past reviews. The guardian should still check for them but can note "known issue, tracked" if found:

1. **entrypoint.sh migration race:** `apps/api/entrypoint.sh` runs `alembic upgrade head` on every pod startup. With replicas=2, two pods race to migrate. Mitigation: Dockerfile.migrate exists for a dedicated migration Job, but entrypoint.sh still has the inline path.

2. **PostgreSQL dialect in base model:** `apps/api/src/models/base.py` imports `UUID` from `sqlalchemy.dialects.postgresql`. DB is MySQL. This may work if UUID is used generically but is a compatibility risk.

3. **CI non-blocking:** Several CI jobs have `continue-on-error: true` (backend-lint, backend-typecheck, backend-test, python-audit, npm-audit). This means deploy can proceed even with test failures.

## Invocation Examples

```
# Full guardian check before staging deploy
/contably-guardian

# Guardian check for production deploy
/contably-guardian production

# Guardian check focused on last 3 commits
/contably-guardian staging last 3 commits

# Quick guardian (skip runtime checks if staging is down)
/contably-guardian --skip-runtime
```
