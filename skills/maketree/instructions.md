# Instructions for /maketree Skill

When the user invokes `/maketree`, follow these steps:

## 1. Validate Environment

Check that we're in a git repository:
```bash
git rev-parse --show-toplevel
```

If not in a git repo, inform user and exit.

Store the repo root and parent directory:
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
PARENT_DIR=$(dirname "$REPO_ROOT")
```

## 2. Parse Arguments

- No args or `create`: Check for local config, then create worktrees or run discovery
- `list`: List existing worktrees and exit
- `clean`: Remove all feature worktrees and exit
- `discover`: Force re-discovery even if config exists

## 3. Check for Local Configuration

Look for `.worktree-scaffold.json` in the repo root:

```bash
CONFIG_FILE="$REPO_ROOT/.worktree-scaffold.json"
```

**Decision tree:**
- If config exists AND has `worktrees` array with entries → Use existing config (go to step 6)
- If config exists but no `worktrees` array → Run discovery (go to step 4)
- If config doesn't exist → Run discovery (go to step 4)
- If user specified `discover` command → Run discovery (go to step 4)

## 4. Discovery Phase

### 4.1 Get All Feature Branches

```bash
# Get all local and remote branches, filter for feature-like patterns
git branch -a --format='%(refname:short)' | \
  grep -E '^(feature/|feat/|fix/|hotfix/|origin/feature/|origin/feat/|origin/fix/|origin/hotfix/)' | \
  sed 's|^origin/||' | \
  sort -u
```

### 4.2 Get Existing Worktrees

```bash
git worktree list --porcelain | grep "^worktree " | sed 's/^worktree //'
```

### 4.3 Build Discovery Table

For each discovered branch:
1. Extract the name (strip prefix): `feature/user-auth` → `user-auth`
2. Determine suggested path: `$PARENT_DIR/$name`
3. Check if worktree already exists for this branch
4. Mark existing worktrees with `[exists]`

### 4.4 Present Discovery Results

Display a numbered table:

```
Discovered Feature Branches:

| #  | Name                        | Branch                              | Path                    | Status   |
|----|-----------------------------|-------------------------------------|-------------------------|----------|
| 1  | user-auth                   | feature/user-auth                   | ../user-auth            |          |
| 2  | payment-flow                | feature/payment-flow                | ../payment-flow         |          |
| 3  | dark-mode                   | fix/dark-mode                       | ../dark-mode            | [exists] |

Total: 3 branches found (1 already has worktree)
```

If no feature branches found:
```
No feature branches found in this repository.

To create a new feature branch and worktree, use:
  git worktree add ../feature-name -b feature/feature-name
```

## 5. Get User Selection

Use AskUserQuestion to prompt the user:

**Question:** "Which worktrees would you like to create?"

**Options:**
- "All" - Create worktrees for all discovered branches
- "Select specific" - Let me enter numbers (e.g., 1,2,3)
- "Skip" - Don't create any worktrees now

If user selects "Select specific", ask for the numbers in a follow-up.

### 5.1 Save Preferences

After user selection, save to `.worktree-scaffold.json`:

```json
{
  "worktreeDir": "../",
  "branchPrefix": "feature/",
  "worktrees": [
    { "name": "user-auth", "branch": "feature/user-auth" },
    { "name": "payment-flow", "branch": "feature/payment-flow" }
  ]
}
```

If config already exists, merge the `worktrees` array (preserve other fields like `scaffolds`, `templates`).

## 6. Create Worktrees

For each worktree in the config (or selection):

```bash
BRANCH="feature/user-auth"
NAME="user-auth"
WORKTREE_PATH="$PARENT_DIR/$NAME"

# Check if worktree already exists
if git worktree list | grep -q "$WORKTREE_PATH"; then
  echo "• $NAME already exists at $WORKTREE_PATH"
else
  # Check if branch exists
  if git show-ref --verify --quiet "refs/heads/$BRANCH" || \
     git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    # Use existing branch
    git worktree add "$WORKTREE_PATH" "$BRANCH" 2>&1
    echo "✓ Created: $NAME"
  else
    echo "✗ Failed: $NAME (branch $BRANCH not found)"
  fi
fi
```

## 7. Generate Summary Report

Create a summary with three sections:

### Newly Created
List all worktrees successfully created in this run.

### Already Existed
List worktrees that were already set up.

### Failed
List any branches that couldn't be created with reason.

### Terminal Commands
Provide `cd` commands for all accessible worktrees:
```bash
cd /path/to/projects/user-auth
cd /path/to/projects/payment-flow
# etc.
```

## 8. List Command

If user runs `/maketree list`:

```bash
git worktree list
```

Format output as a clean table showing:
- Worktree path
- Current branch
- Status (clean / N uncommitted changes)

Example output:
```
Active Worktrees:

| Path                              | Branch                  | Status            |
|-----------------------------------|-------------------------|-------------------|
| /path/to/projects/my-project      | main                    | clean             |
| /path/to/projects/user-auth       | feature/user-auth       | 3 uncommitted     |
| /path/to/projects/payment-flow    | feature/payment-flow    | clean             |
```

## 9. Clean Command

If user runs `/maketree clean`:

1. Get list of all worktrees except main repo
2. For each feature worktree:
   - Check for uncommitted changes
   - Warn if dirty
   - Ask for confirmation using AskUserQuestion
   - Remove with `git worktree remove <path>`
3. Run `git worktree prune` to clean up references

## Error Handling

- **"fatal: 'X' is already used by worktree at 'Y'"**: Worktree exists at different location. Report this in "Already Existed" section.
- **"fatal: invalid reference"**: Branch doesn't exist locally or remotely. Try fetching first.
- **"Not a git repository"**: User must run from within a git repo.
- **"Cannot remove worktree with uncommitted changes"**: Warn user, offer --force option.

## Output Format

Use these symbols for visual clarity:
- ✓ Success (created)
- • Neutral (already existed)
- ✗ Error (failed)

Keep output concise and actionable. Always end with terminal commands the user can copy/paste.

## Branch Pattern Recognition

The skill recognizes these branch patterns:
- `feature/*` - Feature branches
- `feat/*` - Short feature branches
- `fix/*` - Bug fix branches
- `hotfix/*` - Urgent fix branches

Excluded from discovery:
- `main`, `master`, `develop`, `staging`, `production`
- `HEAD`
- Release branches (`release/*`)
