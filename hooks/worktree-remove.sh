#!/bin/bash
# WorktreeRemove Hook - Cleanup worktrees on removal
# Location: ~/.claude-setup/hooks/worktree-remove.sh
#
# Triggered when a worktree is removed. Cleans up node_modules,
# build artifacts, and logs the removal.

set -euo pipefail

INPUT=$(cat 2>/dev/null || echo '{}')
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // .cwd // ""' 2>/dev/null || echo "")

LOG_FILE="$HOME/.claude/logs/worktree-setup.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date)] WorktreeRemove: ${WORKTREE_PATH:-unknown}" >> "$LOG_FILE"

# Clean up heavy directories before git worktree remove
if [ -n "$WORKTREE_PATH" ] && [ -d "$WORKTREE_PATH" ]; then
  # Remove node_modules, build artifacts to speed up removal
  rm -rf "$WORKTREE_PATH/node_modules" 2>/dev/null || true
  rm -rf "$WORKTREE_PATH/.next" 2>/dev/null || true
  rm -rf "$WORKTREE_PATH/dist" 2>/dev/null || true
  rm -rf "$WORKTREE_PATH/.turbo" 2>/dev/null || true
  echo "[$(date)] WorktreeRemove: cleaned artifacts for $WORKTREE_PATH" >> "$LOG_FILE"
fi

# Must output valid JSON
echo '{}'
exit 0
