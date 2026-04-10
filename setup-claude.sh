#!/bin/bash
# Claude Code Setup Script
# ========================
# Run this on new machines to sync Claude Code config via git
#
# Usage: curl -sL "path/to/this/script" | bash
#    or: ./setup-claude.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

echo ""
echo "=================================="
echo "  Claude Code Git-Synced Setup"
echo "=================================="
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is for macOS only"
    exit 1
fi

# Define paths
CLAUDE_DIR="$HOME/.claude"
SETUP_DIR="$HOME/.claude-setup"

# Check if git repo exists
if [[ ! -d "$SETUP_DIR" ]]; then
    print_error "claude-setup repo not found: $SETUP_DIR"
    print_info "Clone it: git clone https://github.com/escotilha/claude.git ~/.claude-setup"
    exit 1
fi
print_success "claude-setup repo found"

# Create .claude directory
mkdir -p "$CLAUDE_DIR"
print_success "Created ~/.claude directory"

# Define items to symlink
declare -a ITEMS=("settings.json" "agents" "skills" "hooks" "commands")

# Create symlinks
for item in "${ITEMS[@]}"; do
    SOURCE="$SETUP_DIR/$item"
    TARGET="$CLAUDE_DIR/$item"

    if [[ ! -e "$SOURCE" ]]; then
        print_warning "Source not found, skipping: $item"
        continue
    fi

    # Remove existing file/symlink if it exists
    if [[ -e "$TARGET" || -L "$TARGET" ]]; then
        rm -rf "$TARGET"
        print_info "Removed existing: $item"
    fi

    # Create symlink
    ln -s "$SOURCE" "$TARGET"
    print_success "Linked: $item"
done

echo ""
echo "=================================="
echo "  Environment Variables"
echo "=================================="
echo ""
print_info "Add these to your ~/.zshrc or ~/.bashrc:"
echo ""
cat << 'ENV_VARS'
# Claude Code / MCP Server tokens
export DIGITALOCEAN_TOKEN="your_do_token"
export GITHUB_TOKEN="your_github_token"
export ANTHROPIC_API_KEY="your_anthropic_key"
export SLACK_BOT_TOKEN="your_slack_token"
export SLACK_TEAM_ID="your_slack_team_id"
# Add other tokens as needed
ENV_VARS

echo ""
echo "=================================="
echo "  Install Claude Code"
echo "=================================="
echo ""

# Check if Claude Code is installed
if command -v claude &> /dev/null; then
    print_success "Claude Code is already installed"
    claude --version 2>/dev/null || true
else
    print_warning "Claude Code not found"
    print_info "Install with: npm install -g @anthropic-ai/claude-code"
fi

echo ""
echo "=================================="
echo "  Setup Complete!"
echo "=================================="
echo ""
print_success "Claude Code config is now synced via git"
echo ""
echo "Synced items:"
for item in "${ITEMS[@]}"; do
    if [[ -L "$CLAUDE_DIR/$item" ]]; then
        echo "  • $item"
    fi
done
echo ""
print_info "Restart your terminal and run 'claude' to start"
echo ""
