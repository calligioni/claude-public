#!/usr/bin/env bash
# scaffold-generator.sh - Generate scaffolding files from templates
# Usage: scaffold-generator.sh <feature-name> <worktree-path> [scaffold-set]

set -euo pipefail

CONFIG_FILE=".worktree-scaffold.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Convert to PascalCase: user-auth -> UserAuth
to_pascal_case() {
  echo "$1" | sed -E 's/(^|[-_])([a-z])/\U\2/g'
}

# Convert to SCREAMING_SNAKE: user-auth -> USER_AUTH
to_screaming_snake() {
  echo "$1" | tr '[:lower:]-' '[:upper:]_'
}

# Get git author name
get_author() {
  git config user.name 2>/dev/null || echo "Unknown"
}

# Substitute variables in string
substitute_vars() {
  local content="$1"
  local name="$2"
  local pascal_name
  local screaming_name
  local date_str
  local author
  
  pascal_name=$(to_pascal_case "$name")
  screaming_name=$(to_screaming_snake "$name")
  date_str=$(date +%Y-%m-%d)
  author=$(get_author)
  
  # Perform substitutions
  content="${content//\{name\}/$name}"
  content="${content//\{Name\}/$pascal_name}"
  content="${content//\{NAME\}/$screaming_name}"
  content="${content//\{date\}/$date_str}"
  content="${content//\{author\}/$author}"
  
  echo "$content"
}

# Generate scaffold files
generate_scaffold() {
  local feature_name="$1"
  local worktree_path="$2"
  local scaffold_set="${3:-default}"
  
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_warn "No $CONFIG_FILE found, skipping scaffolding"
    return 0
  fi
  
  log_info "Generating scaffold files (set: $scaffold_set)"
  
  # Check if scaffold set exists
  local scaffold_count
  scaffold_count=$(jq -r ".scaffolds.\"$scaffold_set\" | length // 0" "$CONFIG_FILE")
  
  if [[ "$scaffold_count" -eq 0 ]]; then
    log_warn "Scaffold set '$scaffold_set' not found or empty"
    return 0
  fi
  
  local files_created=0
  
  # Process each scaffold entry
  jq -c ".scaffolds.\"$scaffold_set\"[]" "$CONFIG_FILE" 2>/dev/null | while read -r entry; do
    local path_template
    local template_name
    
    path_template=$(echo "$entry" | jq -r '.path')
    template_name=$(echo "$entry" | jq -r '.template')
    
    # Substitute variables in path
    local file_path
    file_path=$(substitute_vars "$path_template" "$feature_name")
    local full_path="${worktree_path}/${file_path}"
    
    # Get template content
    local template_content
    template_content=$(jq -r ".templates.\"$template_name\" // \"\"" "$CONFIG_FILE")
    
    if [[ -z "$template_content" ]]; then
      log_warn "Template '$template_name' not found, skipping $file_path"
      continue
    fi
    
    # Substitute variables in content
    local content
    content=$(substitute_vars "$template_content" "$feature_name")
    
    # Create directory if needed
    mkdir -p "$(dirname "$full_path")"
    
    # Check if file exists
    if [[ -f "$full_path" ]]; then
      log_warn "File exists, skipping: $file_path"
      continue
    fi
    
    # Write file
    echo -e "$content" > "$full_path"
    log_success "Created: $file_path"
    ((files_created++)) || true
  done
  
  # Run post-scaffold hook if defined
  local post_hook
  post_hook=$(jq -r '.hooks.postScaffold // ""' "$CONFIG_FILE")
  
  if [[ -n "$post_hook" ]]; then
    log_info "Running post-scaffold hook: $post_hook"
    (cd "$worktree_path" && eval "$post_hook")
  fi
  
  log_success "Scaffolding complete"
}

# Main
main() {
  local feature_name="${1:-}"
  local worktree_path="${2:-}"
  local scaffold_set="${3:-default}"
  
  if [[ -z "$feature_name" ]] || [[ -z "$worktree_path" ]]; then
    echo "Usage: scaffold-generator.sh <feature-name> <worktree-path> [scaffold-set]"
    exit 1
  fi
  
  generate_scaffold "$feature_name" "$worktree_path" "$scaffold_set"
}

main "$@"
