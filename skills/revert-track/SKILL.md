---
name: revert-track
description: "Revert a logical unit of work (feature, phase, track) via related commits. Reads state from /parallel-dev, /deep-plan, /ship. Triggers on: revert track, revert feature, undo feature, revert phase, undo last deep-plan."
argument-hint: "<feature-id | 'last' | commit-range>"
user-invocable: true
context: fork
model: sonnet
effort: medium
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
tool-annotations:
  Bash: { destructiveHint: true, idempotentHint: false }
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

# Revert Track

Revert a logical unit of work — a feature branch, a deep-plan implementation phase, or a manual commit range — as a single clean operation.

Inspired by Conductor's track-based revert pattern: instead of reverting arbitrary individual commits, this skill identifies all commits belonging to a logical track and reverts them as a unit.

## Trigger Patterns

- `/revert-track <feature-id>` - Revert a specific feature from parallel-dev
- `/revert-track last` - Revert the last completed track (auto-detects source)
- `/revert-track <sha1>..<sha2>` - Revert a manual commit range
- `/revert-track --dry-run <target>` - Show what would be reverted without executing

## Workflow

### Step 1: Identify Commits

Based on the input, find all commits belonging to the track:

#### From `.parallel-dev-state.json`

```bash
cat .parallel-dev-state.json 2>/dev/null
```

If found, extract the feature by ID:

- Read `features[].id` matching the argument
- Get the `branch` field (e.g., `feature/auth`)
- Find all commits on that branch not on main:

```bash
git log --oneline main..feature/{feature-id}
```

#### From `.deep-plan-state.json`

```bash
cat .deep-plan-state.json 2>/dev/null
```

If found:

- Read the `commits` array directly — it contains all SHAs from the implementation phase
- If `commits` is empty, fall back to git log search:

```bash
git log --oneline --grep="Step [0-9]" --since="{startedAt}" HEAD
```

#### From manual commit range

If the argument matches `<sha>..<sha>` format:

```bash
git log --oneline {sha1}..{sha2}
```

#### Auto-detect (`last`)

When argument is `last`, check state files in order:

1. `.parallel-dev-state.json` — find the most recently completed feature
2. `.deep-plan-state.json` — find the implementation commits
3. Fall back to: last N commits matching `feat(` or `fix(` prefix

### Step 2: Analyze Impact

Before confirming, show the user what will be reverted:

```
/revert-track auth

Found 5 commits for feature "auth" (branch: feature/auth):

  abc1234 feat(auth): add OAuth2 login with Google
  def5678 feat(auth): session management with Redis
  ghi9012 feat(auth): JWT token refresh
  jkl3456 fix(auth): handle expired refresh tokens
  mno7890 feat(auth): add logout endpoint

Files affected: 12
  src/auth/login.ts (added)
  src/auth/session.ts (added)
  src/auth/jwt.ts (added)
  src/api/routes/auth.ts (modified)
  ...

Tests affected: 3
  src/auth/__tests__/login.test.ts (added)
  src/auth/__tests__/session.test.ts (added)
  src/auth/__tests__/jwt.test.ts (added)
```

Show file count, test count, and whether any of those files have been modified by OTHER commits after the track (potential conflict risk).

### Step 3: Conflict Risk Assessment

Check if any files touched by the track have been modified after the track's last commit:

```bash
# Get files changed by the track
git diff --name-only {first-commit}^..{last-commit}

# Check if any of those files have newer commits
for file in $files; do
  git log --oneline {last-commit}..HEAD -- "$file"
done
```

If conflicts are likely, warn the user:

```
WARNING: 2 files have been modified after this track:
  src/api/routes/auth.ts — 1 commit after (by "api-endpoints" feature)
  src/lib/redis.ts — 2 commits after

Revert may produce merge conflicts. Proceed anyway?
```

### Step 4: Confirm and Execute

Use AskUserQuestion to confirm:

```
question: "Revert these 5 commits for feature 'auth'?"
header: "Revert"
options:
  - label: "Yes, revert all"
    description: "Create a single revert commit undoing all 5 commits"
  - label: "Dry run only"
    description: "Show the revert diff without committing"
  - label: "Cancel"
    description: "Do nothing"
```

**If "Yes, revert all":**

```bash
# Revert all commits in reverse chronological order as a single commit
git revert --no-commit {last-commit} {second-to-last} ... {first-commit}
git commit -m "revert({feature-id}): undo {N} commits

Reverted commits:
- {sha1} {message1}
- {sha2} {message2}
...

Reason: [user can add reason]"
```

**If "Dry run":**

```bash
git diff HEAD..$(git stash create "revert-preview") 2>/dev/null || \
git revert --no-commit {commits} && git diff --cached && git reset --hard HEAD
```

Show the diff and stop.

### Step 5: Post-Revert

After successful revert:

1. Update state files if they exist:
   - `.parallel-dev-state.json`: set feature status to `"reverted"`
   - `.deep-plan-state.json`: set `implement.status` to `"reverted"`
2. Run tests if available to verify the revert didn't break anything
3. Show summary:

```
Reverted feature "auth" (5 commits) in a single commit: {revert-sha}

To undo this revert: git revert {revert-sha}
```

## Error Handling

### No State File Found

```
No state files found (.parallel-dev-state.json, .deep-plan-state.json).

Options:
1. Specify a commit range: /revert-track abc1234..def5678
2. Specify a branch: /revert-track --branch feature/auth
3. Search by pattern: /revert-track --grep "feat(auth)"
```

### Feature Not Found

```
Feature "payments" not found in .parallel-dev-state.json.

Available features:
- auth (completed, 5 commits)
- dashboard (in_progress, 3 commits)
- api-endpoints (merged, 8 commits)

Did you mean one of these?
```

### Merge Conflicts During Revert

```
Merge conflict in src/api/routes/auth.ts

Options:
1. Resolve manually and continue: git revert --continue
2. Abort the revert: git revert --abort
3. Force revert (discard conflicting changes): not recommended
```

## Rules

- **NEVER execute a revert without explicit user confirmation** — this is destructive
- Always show what will be reverted before confirming
- Always check for post-track modifications that could cause conflicts
- Prefer `git revert` over `git reset` — revert preserves history
- Create a single revert commit, not N individual reverts
- Update state files after successful revert
- If `--dry-run` is passed, never modify anything
