---
name: oci-health
description: "Check if Contably on OCI is up. Tests API, admin dashboard, client portal, K8s pods, OCI DevOps pipelines, and services. If anything is down, generates a diagnostic report with root cause and fix steps. Triggers on: oci health, is contably up, check staging, check production, contably status, oci status."
argument-hint: "[environment: staging|production|both]"
user-invocable: true
context: fork
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Write
  - mcp__browserless__*
tool-annotations:
  Bash: { readOnlyHint: true, idempotentHint: true, openWorldHint: true }
  Write: { destructiveHint: false, idempotentHint: true }
invocation-contexts:
  user-direct:
    verbosity: high
    outputFormat: markdown
  agent-spawned:
    verbosity: minimal
    outputFormat: structured
---

# OCI Health — Contably Infrastructure Health Check

Check whether Contably is up on OCI (staging and/or production). If anything is down, produce a diagnostic report with root cause analysis and remediation steps.

## Arguments

- `/oci-health` — check both environments (default)
- `/oci-health staging` — check staging only
- `/oci-health production` or `/oci-health prod` — check production only
- `/oci-health both` or `/oci-health all` — check both environments

## Infrastructure Context

- **Platform**: OCI (Oracle Cloud Infrastructure) — NO VPS, everything runs on OKE (Kubernetes)
- **Active cluster**: `contably-oke-staging` (this serves PRODUCTION traffic despite the name)
- **Load Balancer IP**: `137.131.156.136`
- **Staging URLs**: `https://staging-api.contably.ai` (API), `https://staging.contably.ai` (dashboard), `https://staging-portal.contably.ai` (portal)
- **Production URLs**: `https://api.contably.ai` (API), `https://contably.ai` / `https://admin.contably.ai` (dashboard), `https://portal.contably.ai` (portal)
- **K8s namespace**: `contably-staging` (staging) / `contably` (production)
- **Health endpoint**: `GET /health` (returns JSON with status, timestamp, environment, version, git_commit)
- **Registry**: `sa-saopaulo-1.ocir.io/gr5ovmlswwos/`
- **kubectl auth**: Session-based (`oci session authenticate`), expires in 1 hour
- **CI/CD**: OCI DevOps pipelines (CI pipeline + build/push pipeline + deploy pipeline)
- **Pipeline OCIDs**: Obtained via `terraform output` from `infrastructure/terraform/oci/`
  - `devops_project_id` — DevOps project OCID
  - `devops_ci_pipeline_id` — CI build pipeline (lint, type-check, tests)
  - `devops_deploy_pipeline_id` — Deploy pipeline (staging -> approval -> production)

## Check Sequence

Run these checks **in parallel where possible** (group independent checks together). All checks run from the **local Mac** which has kubectl and OCI CLI access.

### 1. Kubernetes Cluster Health

Use `-n contably-staging` for staging checks and `-n contably` for production checks.

```bash
# Cluster connectivity
kubectl cluster-info 2>&1 | head -3

# Node health
kubectl get nodes 2>&1

# All deployments in namespace (use -n contably-staging or -n contably)
kubectl get deployments -n <NAMESPACE> -o wide 2>&1

# All pods with status
kubectl get pods -n <NAMESPACE> -o wide 2>&1

# Any pods NOT in Running state (critical signal)
kubectl get pods -n <NAMESPACE> --field-selector='status.phase!=Running' 2>&1

# Recent events sorted by timestamp (errors, warnings)
kubectl get events -n <NAMESPACE> --sort-by='.lastTimestamp' --field-selector type=Warning 2>&1 | tail -20

# HPA status (are we at capacity?)
kubectl get hpa -n <NAMESPACE> 2>&1
```

### 2. Endpoint Health Checks

Run from **local Mac** using public URLs:

```bash
echo '=== Production API ==='
curl -s -w '\nHTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://api.contably.ai/health 2>&1

echo ''
echo '=== Production Dashboard ==='
curl -s -o /dev/null -w 'HTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://contably.ai/ 2>&1

echo ''
echo '=== Production Portal ==='
curl -s -o /dev/null -w 'HTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://portal.contably.ai/ 2>&1

echo ''
echo '=== Staging API ==='
curl -s -w '\nHTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://staging-api.contably.ai/health 2>&1

echo ''
echo '=== Staging Dashboard ==='
curl -s -o /dev/null -w 'HTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://staging.contably.ai/ 2>&1

echo ''
echo '=== Staging Portal ==='
curl -s -o /dev/null -w 'HTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://staging-portal.contably.ai/ 2>&1
```

For staging-only, skip the production checks. For production-only, skip staging.

### 3. Service-Level Checks

Use `-n contably-staging` for staging, `-n contably` for production.

```bash
# Ingress status
kubectl get ingress -n <NAMESPACE> 2>&1

# Services
kubectl get svc -n <NAMESPACE> 2>&1

# Check if any pods have restarted recently (CrashLoopBackOff indicator)
kubectl get pods -n <NAMESPACE> -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.restartCount}{"\t"}{.state}{"\n"}{end}{end}' 2>&1
```

### 4. OCI DevOps Pipeline Status

Check recent CI builds and deployments:

```bash
# Get pipeline OCIDs from terraform (run from project root)
cd /Users/ps/code/contably/infrastructure/terraform/oci
CI_PIPELINE_ID=$(terraform output -raw devops_ci_pipeline_id 2>/dev/null)
DEPLOY_PIPELINE_ID=$(terraform output -raw devops_deploy_pipeline_id 2>/dev/null)
PROJECT_ID=$(terraform output -raw devops_project_id 2>/dev/null)

# Recent CI build runs (last 5)
if [ -n "$CI_PIPELINE_ID" ]; then
  echo '=== Recent CI Builds ==='
  oci devops build-run list \
    --build-pipeline-id "$CI_PIPELINE_ID" \
    --sort-by timeCreated \
    --sort-order DESC \
    --limit 5 \
    --query 'data.items[*].{id:id, status:"lifecycle-state", commit:"commit-info"."commit-hash", started:"time-created"}' \
    --output table 2>&1
fi

# Recent deployments (last 5)
if [ -n "$DEPLOY_PIPELINE_ID" ]; then
  echo '=== Recent Deployments ==='
  oci devops deployment list \
    --deploy-pipeline-id "$DEPLOY_PIPELINE_ID" \
    --sort-by timeCreated \
    --sort-order DESC \
    --limit 5 \
    --query 'data.items[*].{id:id, status:"lifecycle-state", type:"deployment-type", started:"time-created"}' \
    --output table 2>&1
fi
```

If terraform output is unavailable, fall back to listing by project:

```bash
# Fallback: list all build runs in the DevOps project
oci devops build-run list \
  --project-id "$PROJECT_ID" \
  --sort-by timeCreated \
  --sort-order DESC \
  --limit 5 \
  --output table 2>&1

# Fallback: list all deployments in the DevOps project
oci devops deployment list \
  --project-id "$PROJECT_ID" \
  --sort-by timeCreated \
  --sort-order DESC \
  --limit 5 \
  --output table 2>&1
```

### 5. Recent Logs (only if issues found)

If any check fails, pull diagnostic logs:

Use `-n contably-staging` for staging logs, `-n contably` for production logs.

```bash
# API pod logs (last 50 lines)
kubectl logs -n <NAMESPACE> -l app=contably-api --tail=50 --since=10m 2>&1

# Celery worker logs
kubectl logs -n <NAMESPACE> -l app=contably-celery-worker --tail=30 --since=10m 2>&1

# Describe failing pods
kubectl describe pod -n <NAMESPACE> <pod-name> 2>&1
```

### 6. Image Version Check

Use `-n contably-staging` for staging, `-n contably` for production.

```bash
# What's deployed vs what's latest on main
kubectl get deployments -n <NAMESPACE> -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.template.spec.containers[*].image}{"\n"}{end}' 2>&1

# Latest commit on main
git log --oneline -1 origin/main 2>&1
```

## Decision Logic

After running checks, categorize the status:

| Status             | Condition                                                        |
| ------------------ | ---------------------------------------------------------------- |
| **ALL UP**         | All endpoints return 200, all pods Running, no warnings          |
| **DEGRADED**       | Some pods unhealthy but endpoints respond, or high restart count |
| **PARTIAL OUTAGE** | Some endpoints down, some up                                     |
| **DOWN**           | Health endpoint unreachable or all pods failing                  |

## Output Format

### If everything is healthy:

```
## Contably OCI Status: ALL UP

| Component        | Status | Response Time | Version    |
|-----------------|--------|---------------|------------|
| API (production) | UP     | 0.23s         | abc1234    |
| Dashboard        | UP     | 0.15s         |            |
| Portal           | UP     | 0.18s         |            |
| Celery Workers   | UP     | 2/2 pods      |            |
| Celery Beat      | UP     | 1/1 pods      |            |

Pods: 8/8 Running | Restarts (24h): 0 | HPA: nominal
CI Pipeline: Last 3 builds SUCCEEDED | Deploy Pipeline: Last deploy SUCCEEDED
```

### If something is wrong:

```
## Contably OCI Status: [DEGRADED/PARTIAL OUTAGE/DOWN]

### Status Summary

| Component        | Status | Details                    |
|-----------------|--------|----------------------------|
| API (production) | DOWN   | HTTP 502, pod CrashLoop    |
| Dashboard        | UP     | 0.15s                      |
| ...              |        |                            |

### Diagnostic Report

#### Problem 1: API pods in CrashLoopBackOff

**Symptoms:**
- /health returns HTTP 502
- Pod `contably-api-xxx` restarted 14 times in last hour

**Root Cause:**
- Latest deployment (abc1234) has import error in `routes/__init__.py`
- Error: `ModuleNotFoundError: No module named 'src.api.routes.xyz'`

**Evidence:**
```

[pod logs showing the error]

```

**Fix Steps:**
1. Fix the import in `apps/api/src/api/routes/__init__.py`
2. Push to main (OCI DevOps mirror syncs every 15 min, then auto-deploys)
3. Or force mirror sync: `oci devops repository mirror --repository-id <MIRROR_REPO_OCID>`
4. Or rollback: `kubectl rollout undo deployment/contably-api -n contably`

#### Problem 2: ...

### Quick Recovery Commands

- Rollback API (staging): `kubectl rollout undo deployment/contably-api -n contably-staging`
- Rollback API (production): `kubectl rollout undo deployment/contably-api -n contably`
- Restart API (staging): `kubectl rollout restart deployment/contably-api -n contably-staging`
- Restart API (production): `kubectl rollout restart deployment/contably-api -n contably`
- Force mirror sync: `oci devops repository mirror --repository-id <MIRROR_REPO_OCID>`
- Check CI pipeline: `oci devops build-run list --build-pipeline-id <CI_PIPELINE_OCID> --limit 3`
- Check deploy pipeline: `oci devops deployment list --deploy-pipeline-id <DEPLOY_PIPELINE_OCID> --limit 3`
- Re-auth kubectl: `oci session authenticate --region sa-saopaulo-1 --profile-name oke-session`
```

## Rules

1. **Never modify anything** — this is a read-only diagnostic skill
2. **Always check kubectl connectivity first** — if kubectl fails, say so and suggest `oci session authenticate --region sa-saopaulo-1 --profile-name oke-session`
3. **Parallelize checks** — run kubectl checks and HTTP health checks concurrently
4. **Only pull logs if something is wrong** — don't dump logs when everything is healthy
5. **Include actionable fix steps** — don't just say "it's down", say exactly what to run to fix it
6. **Show response times** — slow responses (>2s) are a degradation signal even if status is 200
7. **Compare deployed version to main** — drift means CI/CD may be broken
8. **Keep output concise when healthy** — a table is enough. Only expand for problems.
9. **If kubectl auth expired** — report it clearly and suggest re-authentication via `oci session authenticate`
10. **Report CI/CD status** — check OCI DevOps pipelines for recent build/deploy failures using `oci devops build-run list` and `oci devops deployment list`
