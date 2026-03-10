#!/bin/bash
# ============================================================================
# Mini Remote — Dispatcher
# Runs on LOCAL machine (MacBook Air). SSHs into Mac Mini, starts executor
# in detached mode, and returns immediately.
# ============================================================================

set -e

CONFIG_FILE="$HOME/.mini-remote.env"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ---- Parse Arguments ----
REPO_URL=""
BRANCH=""
REPO_NAME=""
PROMPTS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo) REPO_URL="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --repo-name) REPO_NAME="$2"; shift 2 ;;
        --prompts) PROMPTS="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# ---- Validate ----
if [ -z "$REPO_URL" ] || [ -z "$BRANCH" ] || [ -z "$REPO_NAME" ] || [ -z "$PROMPTS" ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo "Usage: dispatch.sh --repo URL --branch BRANCH --repo-name NAME --prompts 'p1|||p2|||p3'"
    exit 1
fi

# ---- Load Config ----
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Config not found. Run setup.sh first.${NC}"
    exit 1
fi

source "$CONFIG_FILE"

# ---- Verify Mini is reachable ----
echo -e "${BLUE}🔗 Checking Mac Mini connection...${NC}"

if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$MINI_USER@$MINI_HOST" "echo ok" &>/dev/null; then
    echo -e "${RED}✗ Cannot reach Mac Mini at $MINI_USER@$MINI_HOST${NC}"
    echo "  Is Tailscale connected? Is the Mini awake?"
    exit 1
fi

echo -e "${GREEN}✓ Mac Mini is reachable${NC}"

# ---- Count prompts ----
IFS=$'\n' read -ra PROMPT_ARRAY <<< "$(echo "$PROMPTS" | sed 's/|||/\n/g')"
# Filter empty entries from the split
PROMPT_COUNT=0
for p in "${PROMPT_ARRAY[@]}"; do
    p_trimmed=$(echo "$p" | xargs)
    if [ -n "$p_trimmed" ]; then
        ((PROMPT_COUNT++))
    fi
done

# ---- Generate job ID ----
JOB_ID="mini-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 4)"

echo -e "${BLUE}📋 Dispatching to Mac Mini${NC}"
echo "  Job ID:   $JOB_ID"
echo "  Repo:     $REPO_NAME ($BRANCH)"
echo "  Prompts:  $PROMPT_COUNT queued"
echo ""

# ---- Ensure latest commit is pushed ----
echo -e "${YELLOW}⬆️  Ensuring latest changes are pushed...${NC}"

# Check for uncommitted changes
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ You have uncommitted changes.${NC}"
    echo "  Claude Code auto-saves every 3 min. Wait for next auto-save, or:"
    echo "    git add -A && git commit -m 'pre-mini sync' && git push"
    echo ""
    read -p "  Continue anyway with last pushed commit? (y/n): " continue_anyway
    if [ "$continue_anyway" != "y" ] && [ "$continue_anyway" != "Y" ]; then
        echo "  Aborted. Push your changes first."
        exit 0
    fi
fi

# ---- Dispatch via SSH (detached) ----
REMOTE_SCRIPTS="$MINI_WORKSPACE/.mini-remote"
REMOTE_LOG="$MINI_WORKSPACE/.mini-remote/logs/$JOB_ID.log"

echo -e "${BLUE}🚀 Launching on Mac Mini...${NC}"

# Create log directory and launch executor in background via nohup
ssh "$MINI_USER@$MINI_HOST" bash -s << REMOTE_SCRIPT
    mkdir -p "$MINI_WORKSPACE/.mini-remote/logs"
    
    # Write job metadata
    cat > "$MINI_WORKSPACE/.mini-remote/jobs/$JOB_ID.json" 2>/dev/null || true
    mkdir -p "$MINI_WORKSPACE/.mini-remote/jobs"
    cat > "$MINI_WORKSPACE/.mini-remote/jobs/$JOB_ID.json" << JOBEOF
{
    "job_id": "$JOB_ID",
    "repo_url": "$REPO_URL",
    "branch": "$BRANCH",
    "repo_name": "$REPO_NAME",
    "prompts": "$PROMPTS",
    "status": "running",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "dispatched_from": "$(hostname)"
}
JOBEOF

    # Launch executor detached
    nohup bash "$REMOTE_SCRIPTS/executor.sh" \
        --job-id "$JOB_ID" \
        --repo "$REPO_URL" \
        --branch "$BRANCH" \
        --repo-name "$REPO_NAME" \
        --prompts "$PROMPTS" \
        > "$REMOTE_LOG" 2>&1 &
    
    EXECUTOR_PID=\$!
    echo \$EXECUTOR_PID > "$MINI_WORKSPACE/.mini-remote/jobs/$JOB_ID.pid"
    
    echo "EXECUTOR_PID=\$EXECUTOR_PID"
REMOTE_SCRIPT

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗"
echo "║  ✅ Dispatched successfully!                      ║"
echo "╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Job ID:    $JOB_ID"
echo "  Prompts:   $PROMPT_COUNT queued for sequential execution"
echo "  Repo:      $REPO_NAME @ $BRANCH"
echo "  Logs:      ssh $MINI_USER@$MINI_HOST 'tail -f $REMOTE_LOG'"
echo ""
echo -e "  ${BLUE}📱 You'll get a Slack notification when each task completes.${NC}"
echo -e "  ${BLUE}✈️  Safe to go offline now. The Mini's got this.${NC}"
echo ""
echo "  Check status anytime:"
echo "    /mini status"
echo "    ssh $MINI_USER@$MINI_HOST 'bash $REMOTE_SCRIPTS/status.sh'"
echo ""
