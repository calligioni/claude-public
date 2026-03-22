---
name: deploy-conta-staging
description: "Deploy Contably to staging on OCI. Runs verify → guardian → push → monitor CI/build → deploy to staging-*.contably.ai → health check. Auto-fixes issues until staging is green. Triggers on: deploy conta staging, deploy staging, push to staging, staging deploy."
argument-hint: "[--skip-guardian] [--skip-verify]"
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

# Deploy Staging — Contably OCI

Deploys Contably to the staging environment (`staging-*.contably.ai`). Runs pre-flight checks, auto-fixes issues, pushes to trigger OCI DevOps, monitors the pipeline through CI → build → staging deploy, and validates the staging environment. Loops until staging is green.

This skill ONLY deploys to staging. To promote to production, use `/deploy-conta-production`.

## Arguments

- `--skip-guardian` — skip the /contably-guardian pre-deploy check
- `--skip-verify` — skip the /verify type-check/lint/build step

## Infrastructure Context

- **OCI Region:** `sa-saopaulo-1`
- **OCIR Registry:** `sa-saopaulo-1.ocir.io/gr5ovmlswwos`
- **K8s Namespace:** `contably-staging`
- **OKE Cluster OCID:** `ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaarqeang2k3wo452nek7zaw5ufjtdmaqxupo6m2zgofckxzb7tcsvq`
- **Git Remote:** `origin` → `https://github.com/Contably/contably.git`
- **Main Branch:** `main`
- **Staging URLs:**
  - API: `https://staging-api.contably.ai`
  - Dashboard: `https://staging.contably.ai`
  - Portal: `https://staging-portal.contably.ai`

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
Deploy Staging (deploy_spec_staging.yaml)
  → Deploy to contably-staging namespace
  → *** STOPS HERE — does NOT touch production ***
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
```

## Workflow

### Phase 0: Detect State

1. Detect current state:

   ```bash
   git status --short                    # Uncommitted changes?
   git log --oneline -1                  # Current HEAD
   git log --oneline origin/main..HEAD   # Unpushed commits?
   ```

2. If there are uncommitted changes, ask the user: "There are uncommitted changes. Should I commit them first?" If yes, stage and commit with a conventional commit message.

### Phase 1: Local Verification Loop (auto-fix until clean)

**Goal:** Ensure the code passes all local checks before pushing. Loop up to 3 times.

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

   **To get the project ID:**

   ```bash
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

### Phase 4: Monitor Build+Push and Staging Deploy

After CI succeeds, the build+push pipeline auto-triggers:

1. **Poll build+push status** (every 45 seconds, max 20 minutes — image builds are slow):

   ```bash
   oci devops build-run list \
     --project-id $DEVOPS_PROJECT_ID \
     --limit 1 \
     --sort-order DESC \
     --output json
   ```

2. **On build+push success**, the staging deployment pipeline auto-triggers. Poll deployment:

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
   - If ALL UP: proceed to final report
   - If DEGRADED or DOWN:
     - Pull pod logs: `kubectl logs -n contably-staging -l app=contably-api --tail=50`
     - If the issue is a code bug (import error, config error): auto-fix, commit, re-push (return to Phase 2)
     - If the issue is infra (node pressure, image pull failure): report to user
     - Max 2 health-check retry cycles

3. **Additional staging smoke tests:**

   ```bash
   # Test staging endpoints
   curl -sI https://staging.contably.ai/ 2>/dev/null | head -5
   curl -s --max-time 10 https://staging-api.contably.ai/health 2>/dev/null
   curl -sI https://staging-portal.contably.ai/ 2>/dev/null | head -5

   # Verify security headers on staging
   curl -sI https://staging.contably.ai/ 2>/dev/null | grep -iE 'x-frame|x-content|x-xss|referrer|permissions|content-security'
   ```

### Phase 6: Final Report

Output a deployment summary:

```markdown
# Staging Deploy Complete

| Stage          | Status   | Duration |
| -------------- | -------- | -------- |
| Verify         | PASS     | 45s      |
| Guardian       | APPROVED | 2m       |
| Push           | {sha}    | 1s       |
| CI Pipeline    | PASS     | 8m       |
| Build+Push     | PASS     | 12m      |
| Staging Deploy | PASS     | 3m       |
| Staging Health | ALL UP   | 30s      |

**Total time:** ~26m
**Auto-fixes applied:** {count} ({summary})
**Commits:** {list of commit SHAs}

Staging is live at:

- https://staging-api.contably.ai
- https://staging.contably.ai
- https://staging-portal.contably.ai

To promote to production: `/deploy-conta-production`
```

## Error Recovery Summary

| Failure                     | Action                                | Max Retries |
| --------------------------- | ------------------------------------- | ----------- |
| /verify fails               | Invoke /test-and-fix, re-verify       | 3           |
| /contably-guardian BLOCKED  | Auto-fix code issues, re-run guardian | 2           |
| /review-changes CRITICAL    | Fix and re-review                     | 2           |
| CI lint/typecheck fail      | Auto-fix locally, re-push             | 3           |
| CI test fail                | Invoke /test-and-fix, re-push         | 3           |
| CI security fail (gitleaks) | STOP — report to user                 | 0           |
| Build+Push fail             | Report to user (usually infra)        | 0           |
| Staging deploy fail         | Report + suggest rollback             | 0           |
| Staging health DOWN         | Auto-fix if code bug, re-push         | 2           |

## Rules

1. **This skill NEVER touches production** — it stops after staging health check
2. **Never skip security scan failures** — gitleaks BLOCK is absolute
3. **Commit fixes with conventional commits** — `fix(deploy): {description}`
4. **Track all auto-fix commits** — report them in the final summary
5. **Max 3 full push cycles** — if code still fails CI after 3 rounds, stop and report
6. **Respect the pipeline chain** — don't bypass OCI DevOps by deploying directly via kubectl
7. **If OCI CLI is unauthenticated** — fall back to push-only mode with manual monitoring instructions
8. **Log timing for each phase** — report durations in the final summary

## Subagent Model Tiers

| Task                          | Model  |
| ----------------------------- | ------ |
| /verify invocation            | haiku  |
| /test-and-fix invocation      | sonnet |
| /contably-guardian invocation | opus   |
| /review-changes invocation    | sonnet |
| /oci-health invocation        | haiku  |
| OCI CLI polling               | direct |
| Auto-fix edits                | direct |
