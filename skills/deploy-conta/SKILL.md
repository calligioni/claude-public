---
name: deploy-conta
description: "Full deployment pipeline for Contably on OCI. Runs verify → guardian → push → monitor OCI DevOps → approve production → health check. Auto-fixes issues until code is production-ready. Triggers on: deploy conta, deploy contably, deploy staging, deploy production, deploy to oci, ship to prod."
argument-hint: "[environment: staging|production|all] [--skip-guardian] [--skip-verify]"
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

# Deploy — Contably OCI Deployment Pipeline

End-to-end deployment skill that takes code from current state to production on OCI. Runs pre-flight checks, auto-fixes issues, pushes to trigger OCI DevOps, monitors the pipeline, approves production, and validates the live environment. Loops until code is production-ready.

## Arguments

- `/deploy` — deploy to staging (default)
- `/deploy staging` — deploy to staging only
- `/deploy production` or `/deploy prod` — full pipeline: staging → approve → production
- `/deploy all` — same as production (staging + prod)
- `--skip-guardian` — skip the /contably-guardian pre-deploy check
- `--skip-verify` — skip the /verify type-check/lint/build step

## Infrastructure Context

- **OCI Region:** `sa-saopaulo-1`
- **OCIR Registry:** `sa-saopaulo-1.ocir.io/gr5ovmlswwos`
- **K8s Namespace:** `contably-staging` (staging) / `contably` (production)
- **OKE Cluster OCID:** `ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaarqeang2k3wo452nek7zaw5ufjtdmaqxupo6m2zgofckxzb7tcsvq`
- **Git Remote:** `origin` → `https://github.com/Contably/contably.git`
- **Main Branch:** `main`
- **VPS SSH:** `root@100.77.51.51` (Tailscale — for staging endpoint tests)
- **Staging URLs:** `https://staging-api.contably.ai` (API), `https://staging.contably.ai` (dashboard), `https://staging-portal.contably.ai` (portal)
- **Production URLs:** `https://api.contably.ai` (API), `https://contably.ai` / `https://admin.contably.ai` (dashboard), `https://portal.contably.ai` (portal)

### OCI DevOps Pipeline Chain

```
git push origin main
    ↓ (GitHub mirror sync)
CI Pipeline (build_spec_ci.yaml)
  → Frontend CI, backend lint/typecheck/tests, security scans
    ↓ (on success)
Build+Push Pipeline (build_spec_images.yaml)
  → Build contably-api, contably-admin, contably-portal
  → Push to OCIR with IMAGE_TAG={commit_sha:0:7}
    ↓ (auto-trigger)
Deploy Pipeline (deploy_spec_staging.yaml → manual approval → deploy_spec_prod.yaml)
  → Stage 1: Deploy to staging (kubectl set image + rollout restart)
  → Stage 2: Manual approval gate (1 approval required)
  → Stage 3: Deploy to production
```

### OCI CLI Commands Reference

```bash
# List recent build runs
oci devops build-run list --build-pipeline-id $PIPELINE_ID --limit 5 --sort-order DESC

# Get build run status
oci devops build-run get --build-run-id $BUILD_RUN_ID

# List deployments
oci devops deployment list --deploy-pipeline-id $PIPELINE_ID --limit 5 --sort-order DESC

# Get deployment status
oci devops deployment get --deployment-id $DEPLOYMENT_ID

# Approve production deployment
oci devops deployment approve --deployment-id $DEPLOYMENT_ID --action APPROVE --reason "Staging verified"
```

## Workflow

### Phase 0: Parse Arguments & Detect State

1. Parse the user's arguments to determine:
   - **Target environment:** staging (default) or production (staging + approval + prod)
   - **Skip flags:** `--skip-guardian`, `--skip-verify`

2. Detect current state:

   ```bash
   git status --short                    # Uncommitted changes?
   git log --oneline -1                  # Current HEAD
   git log --oneline origin/main..HEAD   # Unpushed commits?
   ```

3. If there are uncommitted changes, ask the user: "There are uncommitted changes. Should I commit them first?" If yes, stage and commit with a conventional commit message.

### Phase 1: Local Verification Loop (auto-fix until clean)

**Goal:** Ensure the code passes all local checks before pushing. Loop up to 3 times.

**Iteration N:**

1. **Run /verify** (unless `--skip-verify`):
   - Invoke the `verify` skill via the Skill tool
   - If FAIL: invoke the `test-and-fix` skill to auto-fix
   - Re-run /verify after fixes
   - If still failing after 3 iterations, ask the user whether to proceed or abort

2. **Run /contably-guardian** (unless `--skip-guardian`):
   - Invoke the `contably-guardian` skill via the Skill tool
   - If `DEPLOY BLOCKED`: analyze the blocking issues
     - For code-level issues (CHECK 1-5): attempt auto-fix using Edit tool, then re-run guardian
     - For infra issues (Layer 2): report to user — these typically need manual intervention
     - For runtime issues (Layer 3): skip if staging is unreachable (will be checked post-deploy)
   - If `DEPLOY APPROVED` or `DEPLOY APPROVED WITH WARNINGS`: proceed

3. **Run /review-changes** on any auto-fix commits:
   - If fixes were applied, invoke `review-changes` skill to validate the fixes don't introduce new issues
   - If review finds CRITICAL issues, fix and re-review (max 2 iterations)

4. After all checks pass, commit any fix changes:
   ```
   fix(deploy): auto-fix {summary of what was fixed}
   ```

### Phase 2: Push to Trigger OCI DevOps

1. Push to main:

   ```bash
   GITHUB_TOKEN= git push origin main
   ```

2. Record the commit SHA for tracking:

   ```bash
   IMAGE_TAG=$(git rev-parse --short HEAD)
   ```

3. Report to user:
   ```
   Pushed {commit_sha} to origin/main. OCI DevOps pipeline will trigger via GitHub mirror sync.
   IMAGE_TAG: {IMAGE_TAG}
   ```

### Phase 3: Monitor CI Pipeline

The OCI DevOps pipeline is triggered by the GitHub mirror sync (not immediately on push). Allow up to 2 minutes for the mirror to sync and the pipeline to start.

1. **Wait for CI build run to appear:**

   ```bash
   # Poll for a build run matching our commit (check every 30s, max 4 minutes)
   oci devops build-run list \
     --project-id $DEVOPS_PROJECT_ID \
     --limit 3 \
     --sort-order DESC \
     --output json
   ```

   Look for a build run with `IN_PROGRESS` or `ACCEPTED` state that was created after our push.

   **To get the project ID:** Read it from Terraform state or grep the Terraform files:

   ```bash
   # The project ID is not hardcoded — get it from the most recent build run
   # or from OCI CLI listing
   oci devops project list \
     --compartment-id $(oci iam compartment list --query 'data[0].id' --raw-output) \
     --name contably \
     --output json 2>/dev/null | jq -r '.data.items[0].id // empty'
   ```

   If the project ID cannot be determined programmatically, fall back to checking git push status and report that the pipeline was triggered.

2. **Poll CI status** (every 30 seconds, max 15 minutes):

   ```bash
   oci devops build-run get --build-run-id $BUILD_RUN_ID --query 'data."lifecycle-state"' --raw-output
   ```

   Report progress milestones to the user:
   - `ACCEPTED` → "CI pipeline queued..."
   - `IN_PROGRESS` → "CI running: {stage_name}..."
   - `SUCCEEDED` → "CI passed. Build+Push pipeline starting..."
   - `FAILED` → proceed to Phase 3a (CI failure recovery)

3. **If CI cannot be polled** (OCI CLI auth issues, project ID unknown):
   - Report: "Push complete. Monitor the pipeline in the OCI DevOps console."
   - Skip to Phase 5 (health check) with a delay to allow deployment to complete.

### Phase 3a: CI Failure Recovery (auto-fix loop)

If the CI pipeline fails:

1. Get the build run logs:

   ```bash
   oci devops build-run get --build-run-id $BUILD_RUN_ID --output json | jq '.data."build-outputs"'
   ```

2. Parse the failure:
   - **Frontend CI failure** (typecheck, lint, build): auto-fix locally, commit, re-push
   - **Backend lint/typecheck failure** (ruff, mypy): auto-fix locally, commit, re-push
   - **Backend test failure** (pytest): invoke `test-and-fix` skill, commit, re-push
   - **Security scan failure** (gitleaks): BLOCK — report to user, do not auto-fix (may be a real secret leak)
   - **Security scan failure** (trivy CRITICAL): report to user with CVE details, suggest dependency update

3. After fix: return to Phase 2 (push again). Max 3 CI retry cycles.

4. If still failing after 3 cycles: report all failures and ask the user for guidance.

### Phase 4: Monitor Build+Push and Deploy Pipelines

After CI succeeds, the build+push pipeline auto-triggers:

1. **Poll build+push status** (every 45 seconds, max 20 minutes — image builds are slow):

   ```bash
   oci devops build-run list \
     --project-id $DEVOPS_PROJECT_ID \
     --limit 1 \
     --sort-order DESC \
     --output json
   ```

   Look for the build_push pipeline run (different pipeline ID from CI).

2. **On build+push success**, the deployment pipeline auto-triggers. Poll deployment:

   ```bash
   oci devops deployment list \
     --project-id $DEVOPS_PROJECT_ID \
     --limit 1 \
     --sort-order DESC \
     --output json
   ```

3. **Poll staging deployment status** (every 30 seconds, max 10 minutes):
   - `ACCEPTED` → "Staging deployment queued..."
   - `IN_PROGRESS` → "Deploying to staging..."
   - `SUCCEEDED` → "Staging deploy complete. Running health checks..."
   - `FAILED` → Report failure details, suggest rollback command

### Phase 5: Staging Health Check

After staging deployment succeeds (or after a timeout if we couldn't poll):

1. **Wait 30 seconds** for pods to settle after rollout.

2. **Run /oci-health staging:**
   - Invoke the `oci-health` skill via the Skill tool with argument `staging`
   - If ALL UP: proceed to Phase 6
   - If DEGRADED or DOWN:
     - Pull pod logs: `kubectl logs -n contably-staging -l app=contably-api --tail=50`
     - If the issue is a code bug (import error, config error): auto-fix, commit, re-push (return to Phase 2)
     - If the issue is infra (node pressure, image pull failure): report to user
     - Max 2 health-check retry cycles

3. **Additional staging smoke tests** (beyond what /oci-health does):

   ```bash
   # Test that the staging dashboard is responding
   curl -sI https://staging.contably.ai/robots.txt 2>/dev/null | head -5
   curl -sI https://staging.contably.ai/sitemap.xml 2>/dev/null | head -5

   # Verify security headers on staging
   curl -sI https://staging.contably.ai/ 2>/dev/null | grep -iE 'x-frame|x-content|x-xss|referrer|permissions|content-security'

   # Test staging API health endpoint
   curl -s --max-time 10 https://staging-api.contably.ai/health 2>/dev/null
   ```

### Phase 6: Production Gate

**Only if target is production/all.**

1. **Ask the user for confirmation:**

   ```
   Staging is healthy. Ready to approve production deployment.

   Staging deploy details:
   - Commit: {sha}
   - Image tag: {IMAGE_TAG}
   - Pods: all running
   - Health: ALL UP

   Approve production deployment? (yes/no)
   ```

2. **If approved**, approve the OCI DevOps manual gate:

   ```bash
   # Get the deployment ID (should already be tracked from Phase 4)
   oci devops deployment approve \
     --deployment-id $DEPLOYMENT_ID \
     --action APPROVE \
     --reason "Staging verified via /deploy skill. Commit: $COMMIT_SHA"
   ```

3. **If the user says no**: report current state and exit. The deployment stays at the approval gate.

### Phase 7: Monitor Production Deployment

1. **Poll production deployment** (every 30 seconds, max 15 minutes):

   ```bash
   oci devops deployment get --deployment-id $DEPLOYMENT_ID --query 'data."lifecycle-state"' --raw-output
   ```

2. **On success**: proceed to Phase 8.

3. **On failure**:
   - Report failure details
   - Suggest rollback: `kubectl rollout undo deployment/contably-api -n contably`
   - Ask user if they want to rollback
   - Do NOT auto-fix production — always ask first

### Phase 8: Production Health Check

1. **Run /oci-health production:**
   - Invoke the `oci-health` skill via the Skill tool with argument `production`

2. **If ALL UP**: report success and exit.

3. **If issues found**:
   - Report the diagnostic details
   - Suggest rollback command if critical
   - Ask user for next steps

### Phase 9: Final Report

Output a deployment summary:

```markdown
# Deploy Complete

| Stage               | Status   | Duration |
| ------------------- | -------- | -------- |
| Verify              | PASS     | 45s      |
| Guardian            | APPROVED | 2m       |
| Push                | {sha}    | 1s       |
| CI Pipeline         | PASS     | 8m       |
| Build+Push          | PASS     | 12m      |
| Staging Deploy      | PASS     | 3m       |
| Staging Health      | ALL UP   | 30s      |
| Production Approval | APPROVED | —        |
| Production Deploy   | PASS     | 3m       |
| Production Health   | ALL UP   | 30s      |

**Total time:** ~30m
**Auto-fixes applied:** {count} ({summary})
**Commits:** {list of commit SHAs}
```

## Error Recovery Summary

| Failure                     | Action                                  | Max Retries |
| --------------------------- | --------------------------------------- | ----------- |
| /verify fails               | Invoke /test-and-fix, re-verify         | 3           |
| /contably-guardian BLOCKED  | Auto-fix code issues, re-run guardian   | 2           |
| /review-changes CRITICAL    | Fix and re-review                       | 2           |
| CI lint/typecheck fail      | Auto-fix locally, re-push               | 3           |
| CI test fail                | Invoke /test-and-fix, re-push           | 3           |
| CI security fail (gitleaks) | STOP — report to user                   | 0           |
| Build+Push fail             | Report to user (usually infra)          | 0           |
| Staging deploy fail         | Report + suggest rollback               | 0           |
| Staging health DOWN         | Auto-fix if code bug, re-push           | 2           |
| Production deploy fail      | Report + suggest rollback               | 0           |
| Production health DOWN      | Report + suggest rollback (NO auto-fix) | 0           |

## Rules

1. **Never auto-fix production issues** — always report and ask the user
2. **Never skip security scan failures** — gitleaks BLOCK is absolute
3. **Always confirm before approving production** — even in agent-spawned context
4. **Commit fixes with conventional commits** — `fix(deploy): {description}`
5. **Track all auto-fix commits** — report them in the final summary
6. **Max 3 full push cycles** — if code still fails CI after 3 rounds, stop and report
7. **Respect the pipeline chain** — don't bypass OCI DevOps by deploying directly via kubectl
8. **If OCI CLI is unauthenticated** — fall back to push-only mode with manual monitoring instructions
9. **Log timing for each phase** — report durations in the final summary
10. **If invoked as agent-spawned** — skip user confirmations, auto-approve staging, still confirm production

## Subagent Model Tiers

| Task                          | Model                                       |
| ----------------------------- | ------------------------------------------- |
| /verify invocation            | haiku (inherits from verify skill)          |
| /test-and-fix invocation      | sonnet (inherits from test-and-fix skill)   |
| /contably-guardian invocation | opus (inherits from guardian skill)         |
| /review-changes invocation    | sonnet (inherits from review-changes skill) |
| /oci-health invocation        | haiku (inherits from oci-health skill)      |
| OCI CLI polling               | direct (no subagent — run in orchestrator)  |
| Auto-fix edits                | direct (run in orchestrator)                |
