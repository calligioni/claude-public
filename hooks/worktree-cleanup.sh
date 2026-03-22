#!/bin/bash
# Worktree Cleanup Hook - Runs on SubagentStop and SessionEnd
# Location: ~/.claude-setup/hooks/worktree-cleanup.sh
#
# 1. Removes junk directories created by hook output parsing bugs
#    (directories named like '{"additionalContext": ...}')
# 2. Prunes stale git worktrees that are no longer referenced
# 3. Removes empty worktree directories left behind

set -euo pipefail

LOG_FILE="$HOME/.claude/logs/worktree-cleanup.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date)] $1" >> "$LOG_FILE"
}

# Parse input from Claude Code to get the working directory
INPUT=$(cat 2>/dev/null || echo '{}')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")

if [ -z "$CWD" ] || [ "$CWD" = "null" ]; then
  CWD="$(pwd)"
fi

# Find the git repo root
REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -z "$REPO_ROOT" ]; then
  echo '{}'
  exit 0
fi

CLEANED=0

# 1. Remove junk directories named with JSON (from hook output parsing bugs)
while IFS= read -r -d '' junk_dir; do
  if [ -d "$junk_dir" ]; then
    rm -rf "$junk_dir"
    log "Removed junk directory: $junk_dir"
    CLEANED=$((CLEANED + 1))
  fi
done < <(find "$REPO_ROOT" -maxdepth 1 -name '*additionalContext*' -type d -print0 2>/dev/null)

# Also check parent directory (worktrees are often created alongside the repo)
PARENT_DIR=$(dirname "$REPO_ROOT")
while IFS= read -r -d '' junk_dir; do
  if [ -d "$junk_dir" ]; then
    rm -rf "$junk_dir"
    log "Removed junk directory (parent): $junk_dir"
    CLEANED=$((CLEANED + 1))
  fi
done < <(find "$PARENT_DIR" -maxdepth 1 -name '*additionalContext*' -type d -print0 2>/dev/null)

# 2. Prune stale git worktrees (references to directories that no longer exist)
PRUNED=$(git -C "$REPO_ROOT" worktree prune 2>&1 || echo "")
if [ -n "$PRUNED" ]; then
  log "Pruned stale worktrees: $PRUNED"
fi

# 3. Remove empty worktree directories (claude-worktree-* pattern)
while IFS= read -r -d '' wt_dir; do
  # Only remove if it's not a registered worktree and is essentially empty
  if ! git -C "$REPO_ROOT" worktree list --porcelain 2>/dev/null | grep -q "$wt_dir"; then
    # Check if directory is empty or only has .claude folder
    file_count=$(find "$wt_dir" -maxdepth 1 -not -name '.' -not -name '.claude' | wc -l)
    if [ "$file_count" -le 1 ]; then
      rm -rf "$wt_dir"
      log "Removed empty worktree directory: $wt_dir"
      CLEANED=$((CLEANED + 1))
    fi
  fi
done < <(find "$PARENT_DIR" -maxdepth 1 -name 'claude-worktree-*' -type d -print0 2>/dev/null)
while IFS= read -r -d '' wt_dir; do
  if ! git -C "$REPO_ROOT" worktree list --porcelain 2>/dev/null | grep -q "$wt_dir"; then
    file_count=$(find "$wt_dir" -maxdepth 1 -not -name '.' -not -name '.claude' | wc -l)
    if [ "$file_count" -le 1 ]; then
      rm -rf "$wt_dir"
      log "Removed empty worktree directory: $wt_dir"
      CLEANED=$((CLEANED + 1))
    fi
  fi
done < <(find "$REPO_ROOT" -maxdepth 1 -name 'claude-worktree-*' -type d -print0 2>/dev/null)

if [ "$CLEANED" -gt 0 ]; then
  log "Total cleaned: $CLEANED directories"
fi

echo '{}'
exit 0
