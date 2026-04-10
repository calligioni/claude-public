#!/bin/bash
# ============================================================
# Load Claude Code secrets from macOS Keychain
# ============================================================
# Source this file in your shell profile (.zshrc or .bashrc):
#   eval "$(~/.claude/bin/load-keychain-secrets.sh)"
#
# Or source directly:
#   source ~/.claude/bin/load-keychain-secrets.sh
#
# Secrets are stored in Keychain with service prefix "claude-code-"
# Stored locally per machine. For Claude Code, keys are also in settings.json env block.
# ============================================================

SERVICE_PREFIX="claude-code"

# Function to get secret from Keychain (silent, no prompts)
get_keychain_secret() {
    security find-generic-password -a "$USER" -s "${SERVICE_PREFIX}-$1" -w 2>/dev/null
}

# Load each secret if it exists
load_secret() {
    local env_var="$1"
    local key_name="$2"
    local value
    value=$(get_keychain_secret "$key_name")
    if [ -n "$value" ]; then
        export "$env_var"="$value"
        # Output for eval mode
        echo "export $env_var='$value'"
    fi
}

# Required secrets
load_secret "GITHUB_TOKEN" "github-token"
load_secret "GITHUB_PERSONAL_ACCESS_TOKEN" "github-token"
load_secret "ANTHROPIC_API_KEY" "anthropic-api-key"
load_secret "BRAVE_API_KEY" "brave-api-key"

# Optional secrets
load_secret "DIGITALOCEAN_TOKEN" "digitalocean-token"
load_secret "SLACK_BOT_TOKEN" "slack-bot-token"
load_secret "SLACK_TEAM_ID" "slack-team-id"
load_secret "SLACK_APP_TOKEN" "slack-app-token"
load_secret "NOTION_API_KEY" "notion-api-key"
load_secret "RESEND_API_KEY" "resend-api-key"
load_secret "DATABASE_URL" "database-url"
load_secret "GMAIL_CLIENT_ID" "gmail-client-id"
load_secret "GMAIL_CLIENT_SECRET" "gmail-client-secret"
load_secret "GMAIL_REFRESH_TOKEN" "gmail-refresh-token"
load_secret "GOOGLE_CALENDAR_API_KEY" "google-calendar-api-key"
