#!/usr/bin/env bash
# worktree-manager.sh - Core worktree operations
# Usage: worktree-manager.sh <command> [args...]

set -euo pipefail

CONFIG_FILE=".worktree-scaffold.json"
DEFAULT_WORKTREE_DIR="../"
DEFAULT_BRANCH_PREFIX="feature/"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Load configuration from .worktree-scaffold.json
load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    WORKTREE_DIR=$(jq -r '.worktreeDir // "../"' "$CONFIG_FILE")
    BRANCH_PREFIX=$(jq -r '.branchPrefix // "feature/"' "$CONFIG_FILE")
  else
    WORKTREE_DIR="$DEFAULT_WORKTREE_DIR"
    BRANCH_PREFIX="$DEFAULT_BRANCH_PREFIX"
  fi
}

# Validate feature name (alphanumeric + hyphens)
validate_feature_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]]; then
    log_error "Invalid feature name: '$name'"
    log_error "Must start with letter, contain only alphanumeric and hyphens"
    return 1
  fi
}

# Convert to PascalCase: user-auth -> UserAuth
to_pascal_case() {
  echo "$1" | sed -r 's/(^|-)([a-z])/\U\2/g'
}

# Convert to SCREAMING_SNAKE: user-auth -> USER_AUTH
to_screaming_snake() {
  echo "$1" | tr '[:lower:]-' '[:upper:]_'
}

# Get git author name
get_author() {
  git config user.name 2>/dev/null || echo "Unknown"
}

# Check if we're in a git repository
check_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not in a git repository"
    return 1
  fi
}

# Create a single worktree
create_worktree() {
  local feature_name="$1"
  local scaffold_set="${2:-default}"
  
  validate_feature_name "$feature_name" || return 1
  load_config
  
  local branch_name="${BRANCH_PREFIX}${feature_name}"
  local worktree_path="${WORKTREE_DIR}${feature_name}"
  
  # Get absolute path for cleaner output
  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  local abs_worktree_path
  abs_worktree_path=$(cd "$repo_root" && cd "$(dirname "$worktree_path")" 2>/dev/null && pwd)/$(basename "$worktree_path")
  
  log_info "Creating worktree for feature: $feature_name"
  log_info "Branch: $branch_name"
  log_info "Path: $worktree_path"
  
  # Check if worktree already exists
  if git worktree list | grep -q "$worktree_path"; then
    log_warn "Worktree already exists at $worktree_path"
    return 1
  fi
  
  # Create worktree (with new branch if needed)
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    log_info "Using existing branch: $branch_name"
    git worktree add "$worktree_path" "$branch_name"
  else
    log_info "Creating new branch: $branch_name"
    git worktree add "$worktree_path" -b "$branch_name"
  fi
  
  log_success "Worktree created at: $abs_worktree_path"
  
  # Output JSON for scaffold script
  echo "{\"feature\":\"$feature_name\",\"path\":\"$worktree_path\",\"branch\":\"$branch_name\",\"scaffold\":\"$scaffold_set\"}"
}

# List all worktrees with details
list_worktrees() {
  log_info "Active worktrees:"
  echo ""
  printf "%-50s %-30s %-20s\n" "PATH" "BRANCH" "STATUS"
  printf "%s\n" "$(printf '=%.0s' {1..100})"
  
  git worktree list --porcelain | while read -r line; do
    case "$line" in
      "worktree "*)
        worktree_path="${line#worktree }"
        ;;
      "HEAD "*)
        head_sha="${line#HEAD }"
        ;;
      "branch "*)
        branch="${line#branch refs/heads/}"
        ;;
      "detached")
        branch="(detached)"
        ;;
      "")
        # End of entry, print it
        if [[ -n "${worktree_path:-}" ]]; then
          # Get status
          local status="clean"
          if [[ -d "$worktree_path" ]]; then
            local changes
            changes=$(cd "$worktree_path" && git status --porcelain 2>/dev/null | wc -l)
            if [[ "$changes" -gt 0 ]]; then
              status="${changes} changes"
            fi
          fi
          printf "%-50s %-30s %-20s\n" "$worktree_path" "${branch:-unknown}" "$status"
        fi
        # Reset for next entry
        worktree_path=""
        head_sha=""
        branch=""
        ;;
    esac
  done
  echo ""
}

# Remove a worktree
remove_worktree() {
  local feature_name="$1"
  local force="${2:-false}"
  local delete_branch="${3:-false}"
  
  load_config
  
  local worktree_path="${WORKTREE_DIR}${feature_name}"
  local branch_name="${BRANCH_PREFIX}${feature_name}"
  
  log_info "Removing worktree: $worktree_path"
  
  # Check if worktree exists
  if ! git worktree list | grep -q "$worktree_path"; then
    log_error "Worktree not found: $worktree_path"
    return 1
  fi
  
  # Check for uncommitted changes
  if [[ -d "$worktree_path" ]]; then
    local changes
    changes=$(cd "$worktree_path" && git status --porcelain 2>/dev/null | wc -l)
    if [[ "$changes" -gt 0 ]] && [[ "$force" != "true" ]]; then
      log_warn "Worktree has $changes uncommitted changes"
      log_warn "Use --force to remove anyway"
      return 1
    fi
  fi
  
  # Remove worktree
  if [[ "$force" == "true" ]]; then
    git worktree remove --force "$worktree_path"
  else
    git worktree remove "$worktree_path"
  fi
  
  log_success "Worktree removed: $worktree_path"
  
  # Optionally delete branch
  if [[ "$delete_branch" == "true" ]]; then
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
      log_info "Deleting branch: $branch_name"
      git branch -d "$branch_name" 2>/dev/null || git branch -D "$branch_name"
      log_success "Branch deleted: $branch_name"
    fi
  fi
  
  # Prune stale worktree entries
  git worktree prune
}

# Show help
show_help() {
  cat << EOF
Worktree Manager - Parallel feature development

USAGE:
  worktree-manager.sh <command> [args...]

COMMANDS:
  create <name> [scaffold]   Create worktree with optional scaffold set
  list                       List all active worktrees
  remove <name> [--force] [--delete-branch]
                             Remove worktree and optionally delete branch
  help                       Show this help message

EXAMPLES:
  worktree-manager.sh create user-auth
  worktree-manager.sh create payment-flow component
  worktree-manager.sh list
  worktree-manager.sh remove user-auth --delete-branch

CONFIG:
  Place .worktree-scaffold.json in project root for custom settings.
EOF
}

# Main command dispatcher
main() {
  check_git_repo || exit 1
  
  local command="${1:-help}"
  shift || true
  
  case "$command" in
    create)
      create_worktree "$@"
      ;;
    list)
      list_worktrees
      ;;
    remove)
      local name="${1:-}"
      local force="false"
      local delete_branch="false"
      shift || true
      for arg in "$@"; do
        case "$arg" in
          --force) force="true" ;;
          --delete-branch) delete_branch="true" ;;
        esac
      done
      remove_worktree "$name" "$force" "$delete_branch"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      log_error "Unknown command: $command"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
