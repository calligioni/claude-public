#!/bin/bash
# ============================================================
# Claude Code - New Machine Setup Script
# ============================================================
# This script sets up Claude Code configuration on a new Mac.
# It creates symlinks to git-synced configs and loads
# secrets from macOS Keychain (local per machine).
#
# Prerequisites:
# 1. claude-setup git repo must be cloned to ~/.claude-setup
# 2. Claude Code must be installed
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/.../setup-new-machine.sh | bash
#   OR
#   ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-setup/setup-new-machine.sh
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SETUP_DIR="$HOME/.claude-setup"
CLAUDE_DIR="$HOME/.claude"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Claude Code - New Machine Setup                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check git repo
if [ ! -d "$SETUP_DIR" ]; then
    echo -e "${RED}✗ claude-setup repo not found!${NC}"
    echo "  Expected: $SETUP_DIR"
    echo ""
    echo "  Please clone the repo first:"
    echo "  git clone https://github.com/escotilha/claude.git ~/.claude-setup"
    exit 1
fi
echo -e "${GREEN}✓ claude-setup repo found${NC}"

# Check Claude directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}Creating ~/.claude directory...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi
echo -e "${GREEN}✓ ~/.claude directory exists${NC}"

echo -e "${GREEN}✓ Prerequisites check complete${NC}"
echo ""

# Create symlinks
echo -e "${YELLOW}Creating symlinks to git-synced configs...${NC}"

create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ]; then
        # Already a symlink, check if pointing to right place
        current=$(readlink "$target")
        if [ "$current" = "$source" ]; then
            echo -e "${GREEN}✓ $name already linked${NC}"
            return 0
        else
            echo -e "${YELLOW}↻ Updating $name symlink${NC}"
            rm "$target"
        fi
    elif [ -e "$target" ]; then
        # File/folder exists, back it up
        echo -e "${YELLOW}⚠ Backing up existing $name to ${target}.backup${NC}"
        mv "$target" "${target}.backup.$(date +%Y%m%d%H%M%S)"
    fi

    ln -sf "$source" "$target"
    echo -e "${GREEN}✓ Linked $name${NC}"
}

# Create all symlinks
create_symlink "$SETUP_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
create_symlink "$SETUP_DIR/agents" "$CLAUDE_DIR/agents" "agents"
create_symlink "$SETUP_DIR/commands" "$CLAUDE_DIR/commands" "commands"
create_symlink "$SETUP_DIR/hooks" "$CLAUDE_DIR/hooks" "hooks"
create_symlink "$SETUP_DIR/skills" "$CLAUDE_DIR/skills" "skills"
create_symlink "$SETUP_DIR/rules" "$CLAUDE_DIR/rules" "rules"

echo ""

# Verify Keychain secrets
echo -e "${YELLOW}Checking Keychain secrets...${NC}"
echo "(Secrets are stored locally per machine. For Claude Code, also in settings.json env block.)"
echo ""

check_secret() {
    local name="$1"
    local service="claude-code-$name"
    if security find-generic-password -a "$USER" -s "$service" -w >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $name${NC}"
        return 0
    else
        echo -e "${YELLOW}○ $name (not configured)${NC}"
        return 1
    fi
}

MISSING_REQUIRED=0

echo "Required:"
check_secret "github-token" || MISSING_REQUIRED=1
check_secret "brave-api-key" || MISSING_REQUIRED=1
check_secret "anthropic-api-key" || true  # Not always required

echo ""
echo "Optional:"
check_secret "digitalocean-token" || true
check_secret "slack-bot-token" || true
check_secret "notion-api-key" || true
check_secret "resend-api-key" || true
check_secret "database-url" || true

echo ""

# If missing required secrets, offer to run setup
if [ $MISSING_REQUIRED -eq 1 ]; then
    echo -e "${YELLOW}Some required secrets are missing.${NC}"
    echo "If this is your primary Mac, run the setup script:"
    echo "  ~/.claude/hooks/setup-keychain.sh"
    echo ""
    echo "On a secondary Mac, run setup-keychain.sh to add keys to this machine's Keychain."
    echo "Claude Code also reads keys from the settings.json env block (synced via git)."
    echo ""
fi

# Add load-secrets to shell profile if not present
echo -e "${YELLOW}Checking shell profile...${NC}"

add_to_profile() {
    local profile="$1"
    local load_line='eval "$(~/.claude/hooks/load-secrets.sh 2>/dev/null)"'

    if [ -f "$profile" ]; then
        if grep -q "load-secrets.sh" "$profile"; then
            echo -e "${GREEN}✓ load-secrets already in $profile${NC}"
            return 0
        fi
    fi

    echo "" >> "$profile"
    echo "# Load Claude Code secrets from Keychain" >> "$profile"
    echo "$load_line" >> "$profile"
    echo -e "${GREEN}✓ Added load-secrets to $profile${NC}"
}

# Detect shell and update appropriate profile
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ]; then
    add_to_profile "$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "/bin/bash" ]; then
    add_to_profile "$HOME/.bashrc"
    add_to_profile "$HOME/.bash_profile"
fi

echo ""
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Your Claude Code configuration is now synced via git."
echo ""
echo "What's synced:"
echo "  • settings.json - MCP servers, hooks, permissions"
echo "  • agents/       - Custom agent definitions"
echo "  • commands/     - Custom slash commands"
echo "  • hooks/        - Session hooks and scripts"
echo "  • skills/       - Custom skills"
echo "  • rules/        - Coding standards and conventions"
echo ""
echo "Secrets:"
echo "  • API keys in macOS Keychain (local per machine)"
echo "  • Also available via settings.json env block (synced via git)"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Run 'claude' to start using Claude Code"
echo ""
if [ $MISSING_REQUIRED -eq 1 ]; then
    echo -e "${YELLOW}Note: Run ~/.claude/hooks/setup-keychain.sh to configure missing secrets${NC}"
fi
