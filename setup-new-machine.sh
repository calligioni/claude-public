#!/bin/bash
# ============================================================
# Claude Code - New Machine Setup Script
# ============================================================
# This script sets up Claude Code configuration on a new Mac.
# It creates symlinks to iCloud-synced configs and loads
# secrets from macOS Keychain (which syncs via iCloud Keychain).
#
# Prerequisites:
# 1. iCloud must be enabled and synced
# 2. iCloud Keychain must be enabled (for secrets)
# 3. Claude Code must be installed
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
ICLOUD_CLAUDE="$HOME/.claude-setup"
CLAUDE_DIR="$HOME/.claude"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Claude Code - New Machine Setup                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check iCloud sync
if [ ! -d "$ICLOUD_CLAUDE" ]; then
    echo -e "${RED}✗ iCloud claude-setup folder not found!${NC}"
    echo "  Expected: $ICLOUD_CLAUDE"
    echo ""
    echo "  Please ensure:"
    echo "  1. iCloud Drive is enabled in System Settings"
    echo "  2. iCloud has finished syncing"
    echo "  3. The claude-setup folder exists in iCloud Drive"
    exit 1
fi
echo -e "${GREEN}✓ iCloud claude-setup folder found${NC}"

# Check Claude directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}Creating ~/.claude directory...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi
echo -e "${GREEN}✓ ~/.claude directory exists${NC}"

# Check iCloud Keychain (just informational)
echo -e "${GREEN}✓ Prerequisites check complete${NC}"
echo ""

# Create symlinks
echo -e "${YELLOW}Creating symlinks to iCloud configs...${NC}"

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
create_symlink "$ICLOUD_CLAUDE/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
create_symlink "$ICLOUD_CLAUDE/agents" "$CLAUDE_DIR/agents" "agents"
create_symlink "$ICLOUD_CLAUDE/commands" "$CLAUDE_DIR/commands" "commands"
create_symlink "$ICLOUD_CLAUDE/hooks" "$CLAUDE_DIR/hooks" "hooks"
create_symlink "$ICLOUD_CLAUDE/skills" "$CLAUDE_DIR/skills" "skills"
create_symlink "$ICLOUD_CLAUDE/rules" "$CLAUDE_DIR/rules" "rules"

echo ""

# Verify Keychain secrets
echo -e "${YELLOW}Checking Keychain secrets...${NC}"
echo "(Secrets sync automatically via iCloud Keychain)"
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
    echo "If this is a secondary Mac, ensure iCloud Keychain is enabled"
    echo "and fully synced. Secrets should appear automatically."
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

echo "Your Claude Code configuration is now synced via iCloud."
echo ""
echo "What's synced:"
echo "  • settings.json - MCP servers, hooks, permissions"
echo "  • agents/       - Custom agent definitions"
echo "  • commands/     - Custom slash commands"
echo "  • hooks/        - Session hooks and scripts"
echo "  • skills/       - Custom skills"
echo "  • rules/        - Coding standards and conventions"
echo ""
echo "Secrets (via iCloud Keychain):"
echo "  • API keys stored securely in macOS Keychain"
echo "  • Automatically sync to all your Macs"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Run 'claude' to start using Claude Code"
echo ""
if [ $MISSING_REQUIRED -eq 1 ]; then
    echo -e "${YELLOW}Note: Run ~/.claude/hooks/setup-keychain.sh to configure missing secrets${NC}"
fi
