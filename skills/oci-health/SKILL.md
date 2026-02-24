---
name: oci-health
description: "Check if Contably on OCI is up. Tests API, admin dashboard, client portal, K8s pods, and services. If anything is down, generates a diagnostic report with root cause and fix steps. Triggers on: oci health, is contably up, check staging, check production, contably status, oci status."
argument-hint: "[environment: staging|production|both]"
user-invocable: true
context: fork
model: haiku
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

- `/oci-health` — check staging (default)
- `/oci-health staging` — check staging only
- `/oci-health production` or `/oci-health prod` — check production only
- `/oci-health both` or `/oci-health all` — check both environments

## Infrastructure Context

- **VPS SSH**: `root@100.77.51.51` (Tailscale) — has kubectl access and can reach staging ingress
- **Staging ingress IP**: `137.131.156.136` (mapped in VPS /etc/hosts)
- **Staging URLs**: `https://staging.contably.ai`, `https://staging-api.contably.ai`
- **Production URLs**: `https://contably.ai`, `https://api.contably.ai`, `https://portal.contably.ai`
- **K8s namespace**: `contably`
- **Health endpoint**: `GET /health` (returns JSON with status, timestamp, environment, version, git_commit)
- **Registry**: `sa-saopaulo-1.ocir.io/gr5ovmlswwos/`
- **kubectl context**: `context-ckxzb7tcsvq` (available on local Mac via `kubectl`, NOT on VPS)

## Check Sequence

Run these checks **in parallel where possible** (group independent checks together). Use the local `kubectl` for K8s checks (the Mac has the kubeconfig), and SSH to VPS for HTTP endpoint checks (VPS has /etc/hosts mapping for staging).

### 1. Kubernetes Cluster Health

Run from **local Mac** (has kubeconfig):

```bash
# Cluster connectivity
kubectl cluster-info 2>&1 | head -3

# All deployments in contably namespace
kubectl get deployments -n contably -o wide 2>&1

# All pods with status
kubectl get pods -n contably -o wide 2>&1

# Any pods NOT in Running state (critical signal)
kubectl get pods -n contably --field-selector='status.phase!=Running' 2>&1

# Recent events (errors, warnings)
kubectl get events -n contably --sort-by='.lastTimestamp' --field-selector type=Warning 2>&1 | tail -20

# HPA status (are we at capacity?)
kubectl get hpa -n contably 2>&1
```

### 2. Endpoint Health Checks

Run from **VPS** (has DNS/hosts mapping):

```bash
ssh root@100.77.51.51 "
echo '=== API Health ==='
curl -s -w '\nHTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 http://137.131.156.136/health 2>&1

echo ''
echo '=== Admin Dashboard ==='
curl -s -o /dev/null -w 'HTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 http://137.131.156.136/ 2>&1

echo ''
echo '=== API v1 Check ==='
curl -s -w '\nHTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 http://137.131.156.136/api/v1/companies/ 2>&1

echo ''
echo '=== Production API ==='
curl -s -w '\nHTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://api.contably.ai/health 2>&1

echo ''
echo '=== Production Dashboard ==='
curl -s -o /dev/null -w 'HTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://contably.ai/ 2>&1

echo ''
echo '=== Production Portal ==='
curl -s -o /dev/null -w 'HTTP_CODE:%{http_code} TIME:%{time_total}s' --max-time 10 https://portal.contably.ai/ 2>&1
"
```

For staging-only, skip the production checks. For production-only, skip staging.

### 3. Service-Level Checks

Run from **local Mac**:

```bash
# Ingress status
kubectl get ingress -n contably 2>&1

# Services
kubectl get svc -n contably 2>&1

# Check if any pods have restarted recently (CrashLoopBackOff indicator)
kubectl get pods -n contably -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.restartCount}{"\t"}{.state}{"\n"}{end}{end}' 2>&1
```

### 4. Recent Logs (only if issues found)

If any check fails, pull diagnostic logs:

```bash
# API pod logs (last 50 lines)
kubectl logs -n contably -l app=contably-api --tail=50 --since=10m 2>&1

# Celery worker logs
kubectl logs -n contably -l app=contably-celery-worker --tail=30 --since=10m 2>&1

# Describe failing pods
kubectl describe pod -n contably <pod-name> 2>&1
```

### 5. Image Version Check

```bash
# What's deployed vs what's latest on master
kubectl get deployments -n contably -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.template.spec.containers[*].image}{"\n"}{end}' 2>&1

# Latest commit on master
git log --oneline -1 origin/master 2>&1
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
| API (staging)    | UP     | 0.23s         | abc1234    |
| Dashboard        | UP     | 0.15s         |            |
| Portal           | UP     | 0.18s         |            |
| Celery Workers   | UP     | 2/2 pods      |            |
| Celery Beat      | UP     | 1/1 pods      |            |

Pods: 8/8 Running | Restarts (24h): 0 | HPA: nominal
```

### If something is wrong:

```
## Contably OCI Status: [DEGRADED/PARTIAL OUTAGE/DOWN]

### Status Summary

| Component        | Status | Details                    |
|-----------------|--------|----------------------------|
| API (staging)    | DOWN   | HTTP 502, pod CrashLoop    |
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
2. Push to master (auto-deploys)
3. Or rollback: `kubectl rollout undo deployment/contably-api -n contably`

#### Problem 2: ...

### Quick Recovery Commands

- Rollback API: `kubectl rollout undo deployment/contably-api -n contably`
- Restart API: `kubectl rollout restart deployment/contably-api -n contably`
- Check CI/CD: `gh run list --limit 3`
- Manual deploy: see deploy pattern in MEMORY.md
```

## Rules

1. **Never modify anything** — this is a read-only diagnostic skill
2. **Always check kubectl connectivity first** — if kubectl fails, say so and suggest `oci ce cluster create-kubeconfig`
3. **Parallelize checks** — run kubectl checks and SSH health checks concurrently
4. **Only pull logs if something is wrong** — don't dump logs when everything is healthy
5. **Include actionable fix steps** — don't just say "it's down", say exactly what to run to fix it
6. **Show response times** — slow responses (>2s) are a degradation signal even if status is 200
7. **Compare deployed version to master** — drift means CI/CD may be broken
8. **Keep output concise when healthy** — a table is enough. Only expand for problems.
9. **If kubectl is unavailable** — fall back to HTTP-only checks via VPS SSH
10. **Report CI/CD status** — if deploy is failing, that's part of the health picture. Run `gh run list --limit 3` to check.
