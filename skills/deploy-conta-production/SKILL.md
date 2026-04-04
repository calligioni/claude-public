---
name: deploy-conta-production
description: "Promote Contably from staging to production on OCI. Verifies staging is healthy, approves the OCI DevOps production gate, monitors the production deploy, and validates the live environment. Triggers on: deploy conta production, promote to production, push to production, production deploy, go live."
argument-hint: "[--skip-staging-check]"
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
  - Skill
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - AskUserQuestion
memory: user
tool-annotations:
  Bash: { destructiveHint: false, idempotentHint: true, openWorldHint: true }
  Read: { readOnlyHint: true, idempotentHint: true }
  Glob: { readOnlyHint: true, idempotentHint: true }
  Grep: { readOnlyHint: true, idempotentHint: true }
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

# Deploy Production — Contably OCI

Promotes the current staging deployment to production. Assumes `/deploy-conta-staging` has already been run and staging is healthy. This skill verifies staging, asks for confirmation, approves the OCI DevOps production gate, monitors the rollout, and validates the production environment.

This skill DOES NOT push code or run CI. It only promotes what's already on staging.

## Arguments

- `--skip-staging-check` — skip the staging health verification (use when you've already manually verified)
- `--auto-approve` — skip the confirmation prompt and auto-approve the OCI DevOps production gate (used by `/deploy-conta-full` after staging is verified green)

## Infrastructure Context

- **OCI Region:** `sa-saopaulo-1`
- **OCIR Registry:** `sa-saopaulo-1.ocir.io/gr5ovmlswwos`
- **K8s Namespace (staging):** `contably-staging`
- **K8s Namespace (production):** `contably`
- **OKE Cluster OCID:** `ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaarqeang2k3wo452nek7zaw5ufjtdmaqxupo6m2zgofckxzb7tcsvq`
- **Staging URLs:**
  - API: `https://staging-api.contably.ai`
  - Dashboard: `https://staging.contably.ai`
  - Portal: `https://staging-portal.contably.ai`
- **Production URLs:**
  - API: `https://api.contably.ai`
  - Dashboard: `https://contably.ai` / `https://admin.contably.ai`
  - Portal: `https://portal.contably.ai`

### OCI CLI Commands Reference

```bash
# List deployments (find the one waiting for approval)
oci devops deployment list --deploy-pipeline-id $PIPELINE_ID --limit 5 --sort-order DESC --output json

# Get deployment status
oci devops deployment get --deployment-id $DEPLOYMENT_ID

# Approve production deployment
oci devops deployment approve --deployment-id $DEPLOYMENT_ID --action APPROVE --reason "Staging verified"
```

## Workflow

### Phase 1: Verify Staging is Healthy (unless `--skip-staging-check`)

1. **Check what's currently deployed on staging:**

   ```bash
   # Get the current staging image tag
   kubectl get deployment contably-api -n contably-staging -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null

   # Get the current staging pods status
   kubectl get pods -n contably-staging -l app=contably-api --no-headers 2>/dev/null
   ```

2. **Run /oci-health staging:**
   - Invoke the `oci-health` skill via the Skill tool with argument `staging`
   - If ALL UP: proceed
   - If DEGRADED or DOWN: **STOP** — report to user. Do not promote a broken staging to production.
     ```
     Staging is not healthy. Run /deploy-conta-staging first to fix and redeploy.
     ```

3. **Quick smoke tests on staging:**

   ```bash
   curl -s --max-time 10 https://staging-api.contably.ai/health 2>/dev/null
   curl -sI --max-time 10 https://staging.contably.ai/ 2>/dev/null | head -3
   curl -sI --max-time 10 https://staging-portal.contably.ai/ 2>/dev/null | head -3
   ```

### Phase 2: Find Pending Production Deployment

1. **Get the OCI DevOps project ID:**

   ```bash
   oci devops project list \
     --compartment-id $(oci iam compartment list --query 'data[0].id' --raw-output) \
     --name contably \
     --output json 2>/dev/null | jq -r '.data.items[0].id // empty'
   ```

2. **Find the deployment waiting for approval:**

   ```bash
   oci devops deployment list \
     --project-id $DEVOPS_PROJECT_ID \
     --limit 5 \
     --sort-order DESC \
     --output json
   ```

   Look for a deployment with `lifecycle-state` of `IN_PROGRESS` that has a manual approval stage pending. The deployment pipeline has a staging stage (already completed) followed by a manual approval gate and then the production stage.

3. **If no pending deployment found:**
   - Check if the staging deploy pipeline ran successfully
   - If the pipeline hasn't reached the approval gate yet, wait and poll (every 30s, max 5 minutes)
   - If there's genuinely no pipeline to approve, report: "No pending production deployment found. Run `/deploy-conta-staging` first."

### Phase 3: Confirm and Approve

1. **If `--auto-approve` is set**, skip the confirmation prompt and go directly to step 3.

2. **Otherwise, present the deployment details to the user:**

   ```
   Ready to promote to production.

   Current staging state:
   - Image: {image_tag}
   - Staging health: ALL UP
   - Staging API: https://staging-api.contably.ai ✓
   - Staging Dashboard: https://staging.contably.ai ✓
   - Staging Portal: https://staging-portal.contably.ai ✓

   Production will be updated:
   - API: https://api.contably.ai
   - Dashboard: https://contably.ai
   - Portal: https://portal.contably.ai

   Approve production deployment? (yes/no)
   ```

   If the user says no: report current state and exit. The deployment stays at the approval gate.

3. **Approve the OCI DevOps manual gate:**

   ```bash
   oci devops deployment approve \
     --deployment-id $DEPLOYMENT_ID \
     --action APPROVE \
     --reason "Staging verified via /deploy-conta-production. Image: $IMAGE_TAG"
   ```

### Phase 4: Monitor Production Deployment

1. **Poll production deployment** (every 30 seconds, max 15 minutes):

   ```bash
   oci devops deployment get --deployment-id $DEPLOYMENT_ID --query 'data."lifecycle-state"' --raw-output
   ```

   Report progress:
   - `IN_PROGRESS` → "Deploying to production..."
   - `SUCCEEDED` → "Production deploy complete. Running health checks..."
   - `FAILED` → Report failure, suggest rollback

2. **On failure**:
   - Report failure details
   - Suggest rollback: `kubectl rollout undo deployment/contably-api -n contably`
   - Ask user if they want to rollback
   - Do NOT auto-fix production — always ask first

### Phase 5: Production Health Check

1. **Wait 30 seconds** for pods to settle after rollout.

2. **Run /oci-health production:**
   - Invoke the `oci-health` skill via the Skill tool with argument `production`

3. **Quick production smoke tests:**

   ```bash
   curl -s --max-time 10 https://api.contably.ai/health 2>/dev/null
   curl -sI --max-time 10 https://contably.ai/ 2>/dev/null | head -3
   curl -sI --max-time 10 https://portal.contably.ai/ 2>/dev/null | head -3

   # Verify security headers
   curl -sI https://contably.ai/ 2>/dev/null | grep -iE 'x-frame|x-content|x-xss|referrer|permissions|content-security'
   ```

4. **If ALL UP**: proceed to final report.

5. **If issues found**:
   - Report the diagnostic details
   - Suggest rollback command if critical
   - Ask user for next steps
   - **Never auto-fix production**

### Phase 6: Final Report

```markdown
# Production Deploy Complete

| Stage             | Status   | Duration |
| ----------------- | -------- | -------- |
| Staging Health    | ALL UP   | 15s      |
| Approval          | APPROVED | —        |
| Production Deploy | PASS     | 3m       |
| Production Health | ALL UP   | 30s      |

**Total time:** ~5m
**Image tag:** {IMAGE_TAG}

Production is live at:

- https://api.contably.ai
- https://contably.ai
- https://portal.contably.ai
```

## Error Recovery Summary

| Failure                | Action                                        | Max Retries |
| ---------------------- | --------------------------------------------- | ----------- |
| Staging health DOWN    | STOP — tell user to run /deploy-conta-staging | 0           |
| No pending deployment  | STOP — tell user to run /deploy-conta-staging | 0           |
| Production deploy fail | Report + suggest rollback                     | 0           |
| Production health DOWN | Report + suggest rollback (NO auto-fix)       | 0           |

## Rules

1. **NEVER auto-fix production** — always report and ask the user
2. **NEVER push code** — this skill only promotes existing staging deployments
3. **ALWAYS confirm before approving** — unless `--auto-approve` is passed (used by `/deploy-conta-full` after staging verification)
4. **If staging is unhealthy, STOP** — do not promote broken code
5. **If OCI CLI is unauthenticated** — report and exit (cannot approve without CLI)
6. **Log timing for each phase** — report durations in the final summary
7. **Suggest rollback on any production failure** — `kubectl rollout undo deployment/contably-api -n contably`

## Subagent Model Tiers

| Task                   | Model  |
| ---------------------- | ------ |
| /oci-health staging    | haiku  |
| /oci-health production | haiku  |
| OCI CLI polling        | direct |
