#!/bin/bash
# Setup script to migrate secrets from .env to macOS Keychain
# Run this on each Mac separately - secrets are stored locally (do NOT sync via iCloud)

set -e

SERVICE_PREFIX="claude-code"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "Claude Code Keychain Setup"
echo "======================================"
echo ""

# Function to add a secret to Keychain
add_secret() {
    local key_name="$1"
    local value="$2"
    local service="${SERVICE_PREFIX}-${key_name}"

    if [ -z "$value" ]; then
        echo -e "${YELLOW}⊘ Skipping $key_name (empty value)${NC}"
        return 0
    fi

    # Delete existing entry if it exists (silently)
    security delete-generic-password -a "$USER" -s "$service" 2>/dev/null || true

    # Add new entry
    if security add-generic-password -a "$USER" -s "$service" -w "$value" 2>/dev/null; then
        echo -e "${GREEN}✓ Added $key_name to Keychain${NC}"
    else
        echo -e "${RED}✗ Failed to add $key_name${NC}"
        return 1
    fi
}

# Function to prompt for a secret value
prompt_secret() {
    local key_name="$1"
    local current_value="$2"
    local description="$3"

    echo ""
    echo -e "${YELLOW}$description${NC}"
    if [ -n "$current_value" ]; then
        # Mask the value, showing only first 8 chars
        local masked="${current_value:0:8}..."
        echo "Current value: $masked"
        read -p "Press Enter to keep, or type new value: " new_value
        if [ -n "$new_value" ]; then
            echo "$new_value"
        else
            echo "$current_value"
        fi
    else
        read -p "Enter value (or press Enter to skip): " new_value
        echo "$new_value"
    fi
}

echo "This script will store your API keys in macOS Keychain."
echo "Secrets are stored locally in this machine's Keychain."
echo ""
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Load existing values from .env if it exists
ENV_FILE="$HOME/.claude/.env"
if [ -f "$ENV_FILE" ]; then
    echo "Found existing .env file. Loading current values..."
    source "$ENV_FILE" 2>/dev/null || true
fi

echo ""
echo "======================================"
echo "Required Secrets"
echo "======================================"

# GitHub Token
GITHUB_VALUE=$(prompt_secret "github-token" "${GITHUB_TOKEN:-$GITHUB_PERSONAL_ACCESS_TOKEN}" "GitHub Personal Access Token (for github MCP server)")
add_secret "github-token" "$GITHUB_VALUE"

# Anthropic API Key
ANTHROPIC_VALUE=$(prompt_secret "anthropic-api-key" "$ANTHROPIC_API_KEY" "Anthropic API Key")
add_secret "anthropic-api-key" "$ANTHROPIC_VALUE"

# Brave Search API Key
BRAVE_VALUE=$(prompt_secret "brave-api-key" "$BRAVE_API_KEY" "Brave Search API Key (for brave-search MCP server)")
add_secret "brave-api-key" "$BRAVE_VALUE"

echo ""
echo "======================================"
echo "Optional Secrets"
echo "======================================"

# Slack
SLACK_BOT_VALUE=$(prompt_secret "slack-bot-token" "$SLACK_BOT_TOKEN" "Slack Bot Token (optional)")
add_secret "slack-bot-token" "$SLACK_BOT_VALUE"

SLACK_TEAM_VALUE=$(prompt_secret "slack-team-id" "$SLACK_TEAM_ID" "Slack Team ID (optional)")
add_secret "slack-team-id" "$SLACK_TEAM_VALUE"

# Notion
NOTION_VALUE=$(prompt_secret "notion-api-key" "$NOTION_API_KEY" "Notion API Key (optional)")
add_secret "notion-api-key" "$NOTION_VALUE"

# Resend
RESEND_VALUE=$(prompt_secret "resend-api-key" "$RESEND_API_KEY" "Resend API Key (optional)")
add_secret "resend-api-key" "$RESEND_VALUE"

# Database URL
DB_VALUE=$(prompt_secret "database-url" "$DATABASE_URL" "Database URL (optional, e.g., postgresql://...)")
add_secret "database-url" "$DB_VALUE"

# DigitalOcean
DO_VALUE=$(prompt_secret "digitalocean-token" "$DIGITALOCEAN_TOKEN" "DigitalOcean API Token (optional, for digitalocean MCP server)")
add_secret "digitalocean-token" "$DO_VALUE"

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Your secrets are now stored in macOS Keychain."
echo "Run this script on each Mac separately. Keys do not sync via iCloud."
echo ""

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠ IMPORTANT: Your old .env file still exists at:${NC}"
    echo "  $ENV_FILE"
    echo ""
    echo "To complete the migration, you should:"
    echo "  1. Verify secrets load correctly: source ~/.claude/hooks/load-secrets.sh && echo \$GITHUB_TOKEN"
    echo "  2. Delete the plaintext .env file: rm $ENV_FILE"
    echo ""
fi

echo "To verify Keychain storage, run:"
echo "  security find-generic-password -a \"\$USER\" -s \"claude-code-github-token\" -w"
echo ""
