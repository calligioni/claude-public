#!/bin/bash
# WorktreeCreate Hook - Auto-setup new worktrees
# Location: ~/.claude-setup/hooks/worktree-create.sh
#
# Triggered when parallel-dev or maketree creates a new worktree.
# Copies env files, installs dependencies, and sets up the workspace.

set -euo pipefail

# Parse input from Claude Code
INPUT=$(cat 2>/dev/null || echo '{}')
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // .cwd // ""' 2>/dev/null || echo "")

# Fallback: try to detect from environment
if [ -z "$WORKTREE_PATH" ] || [ "$WORKTREE_PATH" = "null" ]; then
  WORKTREE_PATH="${WORKTREE_CWD:-$(pwd)}"
fi

if [ -z "$WORKTREE_PATH" ] || [ ! -d "$WORKTREE_PATH" ]; then
  echo '{}' # Must output valid JSON
  exit 0
fi

# Find the main repo root (parent of worktree)
MAIN_REPO=$(git -C "$WORKTREE_PATH" rev-parse --git-common-dir 2>/dev/null | sed 's|/\.git$||' || echo "")
if [ -z "$MAIN_REPO" ] || [ ! -d "$MAIN_REPO" ]; then
  echo '{}'
  exit 0
fi

LOG_FILE="$HOME/.claude/logs/worktree-setup.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$(date)] $1" >> "$LOG_FILE"
}

log "WorktreeCreate: $WORKTREE_PATH (main: $MAIN_REPO)"

# 1. Copy env files from main repo
for env_file in .env .env.local .env.development .env.development.local; do
  if [ -f "$MAIN_REPO/$env_file" ] && [ ! -f "$WORKTREE_PATH/$env_file" ]; then
    cp "$MAIN_REPO/$env_file" "$WORKTREE_PATH/$env_file"
    log "  Copied $env_file"
  fi
done

# 2. Install dependencies based on lock file
cd "$WORKTREE_PATH"

if [ -f "pnpm-lock.yaml" ]; then
  pnpm install --frozen-lockfile --prefer-offline 2>/dev/null &
  log "  Installing deps with pnpm (background)"
elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
  bun install --frozen-lockfile 2>/dev/null &
  log "  Installing deps with bun (background)"
elif [ -f "yarn.lock" ]; then
  yarn install --frozen-lockfile 2>/dev/null &
  log "  Installing deps with yarn (background)"
elif [ -f "package-lock.json" ]; then
  npm ci 2>/dev/null &
  log "  Installing deps with npm (background)"
elif [ -f "Gemfile.lock" ]; then
  bundle install 2>/dev/null &
  log "  Installing deps with bundler (background)"
elif [ -f "requirements.txt" ]; then
  pip install -r requirements.txt -q 2>/dev/null &
  log "  Installing deps with pip (background)"
fi

# 3. Copy local config files that aren't tracked
for config_file in .env.test .npmrc .yarnrc.yml; do
  if [ -f "$MAIN_REPO/$config_file" ] && [ ! -f "$WORKTREE_PATH/$config_file" ]; then
    cp "$MAIN_REPO/$config_file" "$WORKTREE_PATH/$config_file"
    log "  Copied $config_file"
  fi
done

log "WorktreeCreate: setup complete for $WORKTREE_PATH"

# Must output valid JSON for Claude Code hook validation
echo '{"additionalContext": "Worktree setup: env files copied, dependencies installing in background"}'
exit 0
