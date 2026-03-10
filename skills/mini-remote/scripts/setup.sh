#!/bin/bash
# ============================================================================
# Mini Remote — First-Time Setup
# Configures SSH, Slack, and Claude Code for remote execution
# ============================================================================

set -e

CONFIG_FILE="$HOME/.mini-remote.env"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║     🤖 Mini Remote — Setup Wizard        ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ---- Step 1: Mac Mini SSH Config ----
echo -e "${YELLOW}Step 1/4: Mac Mini SSH Configuration${NC}"
echo ""

if [ -f "$CONFIG_FILE" ]; then
    echo -e "  Found existing config at ${BLUE}$CONFIG_FILE${NC}"
    source "$CONFIG_FILE"
    echo "  Current settings:"
    echo "    MINI_HOST=$MINI_HOST"
    echo "    MINI_USER=$MINI_USER"
    echo "    MINI_WORKSPACE=$MINI_WORKSPACE"
    echo ""
    read -p "  Keep existing config? (y/n): " keep_config
    if [ "$keep_config" = "y" ] || [ "$keep_config" = "Y" ]; then
        echo -e "  ${GREEN}✓ Keeping existing config${NC}"
    else
        rm "$CONFIG_FILE"
    fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    read -p "  Mac Mini Tailscale hostname or IP: " mini_host
    read -p "  SSH username on Mac Mini: " mini_user
    read -p "  Base workspace directory on Mini [/Users/$mini_user/workspace]: " mini_workspace
    mini_workspace=${mini_workspace:-"/Users/$mini_user/workspace"}
    
    read -p "  Slack Incoming Webhook URL: " slack_webhook
    
    cat > "$CONFIG_FILE" << EOF
# Mini Remote Configuration
# Generated on $(date)
MINI_HOST="$mini_host"
MINI_USER="$mini_user"
MINI_WORKSPACE="$mini_workspace"
SLACK_WEBHOOK_URL="$slack_webhook"
EOF
    
    chmod 600 "$CONFIG_FILE"
    echo -e "  ${GREEN}✓ Config saved to $CONFIG_FILE${NC}"
    
    # Source the new config
    source "$CONFIG_FILE"
fi

# ---- Step 2: Test SSH Connection ----
echo ""
echo -e "${YELLOW}Step 2/4: Testing SSH Connection${NC}"

if ssh -o ConnectTimeout=10 -o BatchMode=yes "$MINI_USER@$MINI_HOST" "echo 'connected'" 2>/dev/null; then
    echo -e "  ${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "  ${RED}✗ Cannot connect to $MINI_USER@$MINI_HOST${NC}"
    echo ""
    echo "  Troubleshooting:"
    echo "    1. Is Tailscale running on both machines?"
    echo "    2. Is SSH enabled on the Mac Mini?"
    echo "       System Settings → General → Sharing → Remote Login"
    echo "    3. Set up SSH key auth:"
    echo "       ssh-copy-id $MINI_USER@$MINI_HOST"
    echo ""
    echo "  Fix the connection and re-run this setup."
    exit 1
fi

# ---- Step 3: Verify Claude Code on Mini ----
echo ""
echo -e "${YELLOW}Step 3/4: Checking Claude Code on Mac Mini${NC}"

CLAUDE_PATH=$(ssh "$MINI_USER@$MINI_HOST" "which claude 2>/dev/null || echo 'NOT_FOUND'")

if [ "$CLAUDE_PATH" = "NOT_FOUND" ]; then
    echo -e "  ${RED}✗ Claude Code CLI not found on Mac Mini${NC}"
    echo ""
    echo "  Install it on the Mini:"
    echo "    npm install -g @anthropic-ai/claude-code"
    echo ""
    echo "  Then re-run this setup."
    exit 1
else
    echo -e "  ${GREEN}✓ Claude Code found at $CLAUDE_PATH${NC}"
    
    # Check version
    CLAUDE_VERSION=$(ssh "$MINI_USER@$MINI_HOST" "claude --version 2>/dev/null || echo 'unknown'")
    echo -e "  Version: $CLAUDE_VERSION"
fi

# ---- Step 4: Install executor scripts on Mini ----
echo ""
echo -e "${YELLOW}Step 4/4: Installing executor scripts on Mac Mini${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_SCRIPTS_DIR="$MINI_WORKSPACE/.mini-remote"

ssh "$MINI_USER@$MINI_HOST" "mkdir -p $REMOTE_SCRIPTS_DIR"

for script in executor.sh safety_check.sh notify.sh status.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        scp "$SCRIPT_DIR/$script" "$MINI_USER@$MINI_HOST:$REMOTE_SCRIPTS_DIR/$script"
        ssh "$MINI_USER@$MINI_HOST" "chmod +x $REMOTE_SCRIPTS_DIR/$script"
        echo -e "  ${GREEN}✓ Installed $script${NC}"
    else
        echo -e "  ${YELLOW}⚠ $script not found locally — skipping${NC}"
    fi
done

# Copy the env file to Mini for Slack notifications
scp "$CONFIG_FILE" "$MINI_USER@$MINI_HOST:$REMOTE_SCRIPTS_DIR/.env"
echo -e "  ${GREEN}✓ Synced configuration${NC}"

# ---- Step 5: Test Slack ----
echo ""
echo -e "${YELLOW}Bonus: Testing Slack notification${NC}"

if [ -n "$SLACK_WEBHOOK_URL" ]; then
    SLACK_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H 'Content-type: application/json' \
        --data '{"text":"🤖 Mini Remote — Setup complete! Ready to receive tasks."}' \
        "$SLACK_WEBHOOK_URL")
    
    if [ "$SLACK_RESPONSE" = "200" ]; then
        echo -e "  ${GREEN}✓ Slack notification sent successfully${NC}"
    else
        echo -e "  ${RED}✗ Slack webhook returned HTTP $SLACK_RESPONSE${NC}"
        echo "  Check your webhook URL and try again."
    fi
else
    echo -e "  ${YELLOW}⚠ No Slack webhook configured — skipping${NC}"
fi

# ---- Done ----
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗"
echo "║     ✅ Setup Complete!                    ║"
echo "╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  You're ready to use /mini commands."
echo "  Example:"
echo "    /mini \"run a full security analysis\""
echo ""
echo "  Queue multiple:"
echo "    /mini queue"
echo "    1. \"security audit\""
echo "    2. \"add rate limiting\""
echo "    3. \"write test suite\""
echo ""
