# Rollback and Recovery Mechanisms

Comprehensive guide for rollback and recovery operations within the CPO AI workflow.

---

## Rollback Overview

### Why Rollbacks Are Needed

Rollbacks are essential for maintaining project stability when:

- **Stage implementation fails** - Code breaks after completing a stage
- **Tests reveal regressions** - New features break existing functionality
- **Integration issues emerge** - Stages work in isolation but fail together
- **Deployment failures** - Production deployment causes incidents
- **Scope creep detected** - Implementation drifted from plan
- **User feedback** - Stakeholder requests reverting changes

### Types of Rollbacks

| Rollback Type | Scope | Use Case |
|---------------|-------|----------|
| **Story Rollback** | Single user story | One story broke something |
| **Stage Rollback** | All changes in one stage | Stage implementation failed |
| **Phase Rollback** | Return to end of previous phase | Major replanning needed |
| **Project Rollback** | Full reset to planning | Start implementation over |
| **Deployment Rollback** | Revert production only | Production incident |

### Auto-Checkpoint Strategy

The CPO workflow creates automatic checkpoints at critical points:

```
Project Timeline with Checkpoints:
──────────────────────────────────────────────────────────
│ Phase 2 Complete │ Stage 1 │ Stage 2 │ Stage 3 │ Deploy │
──────────────────────────────────────────────────────────
       ▲               ▲           ▲         ▲         ▲
       │               │           │         │         │
    [planning]    [stage-1]   [stage-2] [stage-3] [prod-v1]
                  -complete   -complete -complete
```

---

## Git-Based Rollbacks

### Stage Rollback

Revert to the state before a specific stage started.

```bash
# Step 1: Find the commit before the stage started
git log --oneline --grep="Stage [N-1]" | head -1

# Alternative: Find by checkpoint tag
git tag -l "checkpoint/stage-*" | sort -V

# Step 2: Get the commit hash
ROLLBACK_COMMIT=$(git log --oneline --grep="Stage 2" | head -1 | cut -d' ' -f1)

# Step 3: Reset to that commit
git reset --hard $ROLLBACK_COMMIT

# Step 4: Update master-project.json to reflect rollback
jq '.stages |= map(
  if .id == "S3" then .status = "pending" | .startedAt = null | .completedAt = null
  else . end
)' master-project.json > tmp.json && mv tmp.json master-project.json

# Step 5: Log the rollback in progress file
echo "## $(date -Iseconds) - ROLLBACK: Stage 3" >> cpo-progress.md
echo "Reason: [describe reason]" >> cpo-progress.md
echo "Reverted to commit: $ROLLBACK_COMMIT" >> cpo-progress.md
```

### Phase Rollback

Reset to the end of a previous phase (e.g., back to planning complete).

```bash
# Reset to end of Phase 2 (planning complete)
PLANNING_COMMIT=$(git log --oneline --grep="planning complete" | head -1 | cut -d' ' -f1)
git reset --hard $PLANNING_COMMIT

# Or use the planning checkpoint tag
git reset --hard checkpoint/phase-2-complete

# Reset all stages to pending
jq '.stages |= map(.status = "pending" | .startedAt = null | .completedAt = null | .testedAt = null) | .currentStage = null' \
  master-project.json > tmp.json && mv tmp.json master-project.json

# Clean up stage-specific files
rm -f prd.json progress.md
```

### Project Rollback

Full reset to the beginning of implementation, preserving planning artifacts.

```bash
# Find the initial project setup commit
INIT_COMMIT=$(git log --oneline --reverse | head -1 | cut -d' ' -f1)

# Or use project initialization tag
git reset --hard checkpoint/project-initialized

# Reset master-project.json while preserving project definition
jq '.stages |= map(.status = "pending" | .startedAt = null | .completedAt = null | .testedAt = null) |
    .project.status = "planning" |
    .currentStage = null' \
  master-project.json > tmp.json && mv tmp.json master-project.json

# Remove implementation artifacts
rm -rf node_modules dist .next
rm -f prd.json progress.md

# Reinitialize if needed
npm install
```

---

## Auto-Checkpoint Strategy

### Creating Checkpoints

Create checkpoints automatically before and after each stage.

```bash
# Before starting Stage N
create_checkpoint_before_stage() {
  local stage_num=$1
  local stage_name=$2

  # Backup master-project.json
  mkdir -p .checkpoints
  cp master-project.json ".checkpoints/master-project-before-stage-${stage_num}.json"

  # Create git tag
  git add -A
  git commit -m "checkpoint: before Stage ${stage_num} - ${stage_name}" --allow-empty
  git tag -a "checkpoint/stage-${stage_num}-start" -m "Checkpoint before Stage ${stage_num}: ${stage_name}"

  echo "Checkpoint created: checkpoint/stage-${stage_num}-start"
}

# After completing Stage N (when tests pass)
create_checkpoint_after_stage() {
  local stage_num=$1
  local stage_name=$2

  # Backup master-project.json
  cp master-project.json ".checkpoints/master-project-after-stage-${stage_num}.json"

  # Create git tag
  git tag -a "checkpoint/stage-${stage_num}-complete" -m "Checkpoint after Stage ${stage_num}: ${stage_name} - All tests passing"

  echo "Checkpoint created: checkpoint/stage-${stage_num}-complete"
}
```

### Checkpoint File Structure

```
.checkpoints/
├── master-project-before-stage-1.json
├── master-project-after-stage-1.json
├── master-project-before-stage-2.json
├── master-project-after-stage-2.json
├── env-backup-stage-1.env
└── database-schema-stage-2.sql
```

### Database Schema Checkpoints

For database-heavy stages, also checkpoint the schema.

```bash
# Backup current schema before database changes
backup_database_schema() {
  local stage_num=$1

  # For Prisma
  npx prisma db pull
  cp prisma/schema.prisma ".checkpoints/schema-stage-${stage_num}.prisma"

  # For raw PostgreSQL
  pg_dump --schema-only $DATABASE_URL > ".checkpoints/schema-stage-${stage_num}.sql"
}
```

---

## master-project.json Backup

### Automatic Backup Script

```bash
#!/bin/bash
# backup-project-state.sh

STAGE_NUM=$1
CHECKPOINT_DIR=".checkpoints"

mkdir -p $CHECKPOINT_DIR

# Backup master-project.json
cp master-project.json "${CHECKPOINT_DIR}/master-project-stage-${STAGE_NUM}.json"

# Backup environment (without secrets)
grep -v "KEY\|SECRET\|PASSWORD" .env.example > "${CHECKPOINT_DIR}/env-stage-${STAGE_NUM}.env"

# Record git state
git rev-parse HEAD > "${CHECKPOINT_DIR}/git-ref-stage-${STAGE_NUM}.txt"
git status --short > "${CHECKPOINT_DIR}/git-status-stage-${STAGE_NUM}.txt"

echo "Backup complete for Stage ${STAGE_NUM}"
```

### Restore from Backup

```bash
#!/bin/bash
# restore-project-state.sh

STAGE_NUM=$1
CHECKPOINT_DIR=".checkpoints"

# Restore master-project.json
if [ -f "${CHECKPOINT_DIR}/master-project-stage-${STAGE_NUM}.json" ]; then
  cp "${CHECKPOINT_DIR}/master-project-stage-${STAGE_NUM}.json" master-project.json
  echo "Restored master-project.json from Stage ${STAGE_NUM}"
else
  echo "Error: Backup not found for Stage ${STAGE_NUM}"
  exit 1
fi

# Restore git state
GIT_REF=$(cat "${CHECKPOINT_DIR}/git-ref-stage-${STAGE_NUM}.txt")
git reset --hard $GIT_REF

echo "Restored to git ref: $GIT_REF"
```

---

## Rollback Commands for CPO

### Quick Reference Commands

| Command | Action | Git Operation |
|---------|--------|---------------|
| `rollback stage` | Revert current stage, reset to previous | `git reset --hard checkpoint/stage-{N-1}-complete` |
| `rollback stage N` | Revert to before specific stage | `git reset --hard checkpoint/stage-{N}-start` |
| `rollback phase` | Reset to end of previous phase | `git reset --hard checkpoint/phase-{N-1}-complete` |
| `rollback project` | Full reset to Phase 2 (keep planning) | `git reset --hard checkpoint/phase-2-complete` |
| `rollback deploy` | Revert production deployment | Platform-specific (see below) |

### Command Implementation

Add these to the Quick Commands section in SKILL.md:

```javascript
// Rollback implementation functions

async function rollbackStage(stageNumber = null) {
  // If no stage specified, rollback current stage
  const masterProject = JSON.parse(fs.readFileSync('master-project.json'));
  const targetStage = stageNumber || getCurrentStageNumber(masterProject);

  // Find the checkpoint
  const checkpoint = `checkpoint/stage-${targetStage}-start`;

  // Verify checkpoint exists
  const checkpointExists = await exec(`git tag -l "${checkpoint}"`);
  if (!checkpointExists.stdout.trim()) {
    throw new Error(`Checkpoint ${checkpoint} not found. Available checkpoints: ${await listCheckpoints()}`);
  }

  // Perform rollback
  await exec(`git reset --hard ${checkpoint}`);

  // Update master-project.json
  masterProject.stages = masterProject.stages.map(stage => {
    if (parseInt(stage.id.replace('S', '')) >= targetStage) {
      return {
        ...stage,
        status: 'pending',
        startedAt: null,
        completedAt: null,
        testedAt: null
      };
    }
    return stage;
  });
  masterProject.currentStage = null;

  fs.writeFileSync('master-project.json', JSON.stringify(masterProject, null, 2));

  // Log rollback
  const logEntry = `\n## ${new Date().toISOString()} - ROLLBACK: Stage ${targetStage}\n` +
                   `Rolled back to checkpoint: ${checkpoint}\n` +
                   `Stages reset: ${targetStage} and above\n`;
  fs.appendFileSync('cpo-progress.md', logEntry);

  return { success: true, checkpoint, stagesReset: targetStage };
}

async function rollbackPhase(phaseNumber) {
  const checkpoint = `checkpoint/phase-${phaseNumber}-complete`;
  await exec(`git reset --hard ${checkpoint}`);

  // Reset all stages
  const masterProject = JSON.parse(fs.readFileSync('master-project.json'));
  masterProject.stages = masterProject.stages.map(stage => ({
    ...stage,
    status: 'pending',
    startedAt: null,
    completedAt: null,
    testedAt: null
  }));
  masterProject.project.status = phaseNumber === 2 ? 'planning' : 'implementing';
  masterProject.currentStage = null;

  fs.writeFileSync('master-project.json', JSON.stringify(masterProject, null, 2));

  return { success: true, checkpoint };
}

async function rollbackProject() {
  // Keep only planning artifacts
  await rollbackPhase(2);

  // Clean up implementation files
  await exec('rm -rf node_modules dist .next');
  await exec('rm -f prd.json progress.md');

  return { success: true, message: 'Project reset to planning phase' };
}

async function listCheckpoints() {
  const result = await exec('git tag -l "checkpoint/*" | sort -V');
  return result.stdout.trim().split('\n');
}
```

---

## Recovery from Failed Deployments

### Platform-Specific Rollback Commands

#### Vercel

```bash
# List recent deployments
vercel ls --limit 10

# Get previous deployment URL
PREVIOUS_DEPLOY=$(vercel ls --limit 2 | tail -1 | awk '{print $1}')

# Rollback to previous deployment
vercel rollback $PREVIOUS_DEPLOY

# Or promote a specific deployment to production
vercel promote [deployment-url] --scope [team]
```

#### Railway

```bash
# List recent deployments
railway deployment list

# Rollback to previous deployment
railway deployment rollback

# Or rollback to specific deployment ID
railway deployment rollback --id [deployment-id]
```

#### DigitalOcean App Platform

```bash
# List recent deployments
doctl apps list-deployments [app-id]

# Rollback to specific deployment
doctl apps create-deployment [app-id] --force-build

# For immediate rollback, use previous commit
git revert HEAD
git push origin main
```

### Database Migration Rollback

```bash
# Prisma: Rollback last migration
npx prisma migrate resolve --rolled-back [migration-name]

# Or reset to specific migration
npx prisma migrate reset --to [migration-name]

# Drizzle: Manual rollback (create down migration)
npm run db:rollback

# Direct SQL rollback (if migrations tracked)
psql $DATABASE_URL < .checkpoints/schema-stage-{N}.sql
```

### Environment Variable Restore

```bash
# From Vercel
vercel env pull .env.production.backup
vercel env add [VAR_NAME] --environment production

# From Railway
railway variables --json > env-backup.json

# Restore from backup
cat env-backup.json | jq -r 'to_entries[] | "\(.key)=\(.value)"' | while read line; do
  railway variables set "$line"
done
```

---

## Disaster Recovery

### Full Project Backup

```bash
#!/bin/bash
# full-backup.sh

PROJECT_NAME=$1
BACKUP_DIR="backups/${PROJECT_NAME}-$(date +%Y%m%d-%H%M%S)"

mkdir -p $BACKUP_DIR

# Backup entire repository
git bundle create "${BACKUP_DIR}/repo.bundle" --all

# Backup master-project.json and checkpoints
cp master-project.json "${BACKUP_DIR}/"
cp -r .checkpoints "${BACKUP_DIR}/"

# Backup environment template
cp .env.example "${BACKUP_DIR}/"

# Backup database schema
pg_dump --schema-only $DATABASE_URL > "${BACKUP_DIR}/schema.sql"

# Create manifest
cat > "${BACKUP_DIR}/manifest.json" << EOF
{
  "project": "${PROJECT_NAME}",
  "timestamp": "$(date -Iseconds)",
  "gitRef": "$(git rev-parse HEAD)",
  "branch": "$(git branch --show-current)",
  "stages": $(jq '.stages | length' master-project.json)
}
EOF

# Compress backup
tar -czf "${BACKUP_DIR}.tar.gz" -C backups "$(basename $BACKUP_DIR)"
rm -rf $BACKUP_DIR

echo "Backup created: ${BACKUP_DIR}.tar.gz"
```

### Restore from GitHub

```bash
#!/bin/bash
# restore-from-github.sh

REPO_URL=$1
TARGET_DIR=$2

# Clone repository
git clone $REPO_URL $TARGET_DIR
cd $TARGET_DIR

# Restore latest checkpoint
LATEST_CHECKPOINT=$(git tag -l "checkpoint/*" | sort -V | tail -1)
if [ -n "$LATEST_CHECKPOINT" ]; then
  git checkout $LATEST_CHECKPOINT
  echo "Restored to checkpoint: $LATEST_CHECKPOINT"
fi

# Restore dependencies
npm install

# Verify restoration
if [ -f "master-project.json" ]; then
  echo "Project restored successfully"
  jq '.project.name, .project.status' master-project.json
else
  echo "Warning: master-project.json not found"
fi
```

### Archive Management

```bash
# List all backups
ls -la backups/*.tar.gz

# Extract specific backup
tar -xzf backups/myproject-20240115-143022.tar.gz -C restore/

# Verify backup integrity
tar -tzf backups/myproject-20240115-143022.tar.gz

# Clean old backups (keep last 5)
ls -t backups/*.tar.gz | tail -n +6 | xargs rm -f
```

---

## Rollback Decision Matrix

Use this matrix to determine the appropriate rollback action:

| Symptom | Likely Cause | Recommended Action |
|---------|--------------|-------------------|
| Build fails after stage | Code syntax/import errors | `rollback stage` |
| Tests fail in new stage | Implementation bugs | Fix first, then `rollback stage` if unfixable |
| Tests fail in previous stages | Regression introduced | `rollback stage` + investigate |
| Production 500 errors | Deployment issue | `rollback deploy` immediately |
| Database connection errors | Migration/config issue | Check env, then `rollback stage` with DB restore |
| Performance degradation | Inefficient code | Profile first, `rollback stage` if severe |
| Scope creep detected | Implementation drifted | `rollback stage` + update plan |
| Major replanning needed | Requirements changed | `rollback phase` to Phase 2 |
| Start fresh needed | Multiple failures | `rollback project` |

---

## Summary Checklist

Before performing any rollback:

- [ ] Document the reason for rollback in cpo-progress.md
- [ ] Verify the target checkpoint exists (`git tag -l "checkpoint/*"`)
- [ ] Backup current state if needed (`./backup-project-state.sh current`)
- [ ] Notify team members if collaborative project
- [ ] Check for uncommitted changes (`git status`)

After rollback:

- [ ] Verify master-project.json reflects correct state
- [ ] Run test suite to confirm stability
- [ ] Update cpo-progress.md with rollback completion
- [ ] Reinstall dependencies if needed (`npm install`)
- [ ] Verify database state matches code state
