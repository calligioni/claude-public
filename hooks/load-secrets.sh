#!/bin/bash
# Load secrets from macOS Keychain
# Secrets are stored locally per machine (they do NOT sync via iCloud Keychain)
# Run this script on SessionStart to populate environment variables

# Keychain service prefix for Claude Code secrets
SERVICE_PREFIX="claude-code"

# Function to get a secret from Keychain
get_secret() {
    local key_name="$1"
    local service="${SERVICE_PREFIX}-${key_name}"
    security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null
}

# Function to export a secret if it exists
export_if_exists() {
    local env_var="$1"
    local key_name="$2"
    local value
    value=$(get_secret "$key_name")
    if [ -n "$value" ]; then
        export "$env_var"="$value"
        echo "export $env_var='$value'"
    fi
}

# Load all Claude Code secrets
# The echo statements allow the parent process to capture and use these values

export_if_exists "GITHUB_TOKEN" "github-token"
export_if_exists "GITHUB_PERSONAL_ACCESS_TOKEN" "github-token"
export_if_exists "ANTHROPIC_API_KEY" "anthropic-api-key"
export_if_exists "BRAVE_API_KEY" "brave-api-key"
export_if_exists "SLACK_BOT_TOKEN" "slack-bot-token"
export_if_exists "SLACK_TEAM_ID" "slack-team-id"
export_if_exists "SLACK_APP_TOKEN" "slack-app-token"
export_if_exists "NOTION_API_KEY" "notion-api-key"
export_if_exists "RESEND_API_KEY" "resend-api-key"
export_if_exists "GMAIL_CLIENT_ID" "gmail-client-id"
export_if_exists "GMAIL_CLIENT_SECRET" "gmail-client-secret"
export_if_exists "GMAIL_REFRESH_TOKEN" "gmail-refresh-token"
export_if_exists "GOOGLE_CALENDAR_API_KEY" "google-calendar-api-key"
export_if_exists "DATABASE_URL" "database-url"
export_if_exists "DIGITALOCEAN_TOKEN" "digitalocean-token"
