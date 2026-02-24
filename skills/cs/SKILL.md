---
description: Check and sync Claude setup with remote repository
allowed-tools: Bash
---

## Argument Syntax
- `$0` - First argument
- `$1` - Second argument
- `$ARGUMENTS` - Full argument string
- `$ARGUMENTS[0]` - Indexed access

# Claude Setup Sync Check

Check if your local Claude setup is in sync with the remote repository. Automatically commits and pushes local changes when ahead.

## Process

1. Fetch latest from remote without merging
2. Compare local HEAD with remote HEAD
3. Check for uncommitted local changes
4. If local has changes or is ahead: commit and push automatically
5. If behind: report and recommend pull
6. Report final sync status

## Usage

```
/cs
```

## Behavior

- **UP TO DATE**: No action needed
- **LOCAL CHANGES**: Auto-commit with message "chore: sync claude setup" and push
- **AHEAD**: Auto-push to remote
- **BEHIND**: Report only (manual pull recommended to avoid conflicts)
- **DIVERGED**: Report only (manual reconciliation needed)

## Implementation

Run the following on the Claude setup repository at `$HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup`:

```bash
# Fetch latest from remote
git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup fetch origin master --quiet

# Check for uncommitted changes first
CHANGES=$(git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup status --short)

# If there are local changes, commit them
if [ -n "$CHANGES" ]; then
    git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup add -A
    git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup commit -m "chore: sync claude setup"
fi

# Get commit hashes after potential commit
LOCAL=$(git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup rev-parse HEAD)
REMOTE=$(git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup rev-parse origin/master)
BASE=$(git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup merge-base HEAD origin/master)

# Determine sync status and take action
if [ "$LOCAL" = "$REMOTE" ]; then
    echo "UP TO DATE"
elif [ "$LOCAL" = "$BASE" ]; then
    echo "BEHIND - manual pull recommended"
    git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup log --oneline HEAD..origin/master
elif [ "$REMOTE" = "$BASE" ]; then
    echo "AHEAD - pushing to remote..."
    git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup push origin master
    echo "PUSHED SUCCESSFULLY"
else
    echo "DIVERGED - manual reconciliation needed"
    echo "Local commits not on remote:"
    git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup log --oneline origin/master..HEAD
    echo "Remote commits not on local:"
    git -C $HOME/Library/Mobile Documents/com~apple~CloudDocs/claude-setup log --oneline HEAD..origin/master
fi
```

Present results clearly with:

- Current sync status
- Actions taken (committed X files, pushed Y commits)
- Summary of any remaining differences
