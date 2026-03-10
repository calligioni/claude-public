#!/bin/bash
# ============================================================================
# Mini Remote — Executor
# Runs ON the Mac Mini. Pulls repo, runs Claude Code with each prompt
# sequentially, commits, pushes, and notifies via Slack.
# ============================================================================

set -euo pipefail

# Ensure Homebrew binaries are available in non-login SSH shells
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || true

# ---- Parse Arguments ----
JOB_ID=""
REPO_URL=""
BRANCH=""
REPO_NAME=""
PROMPTS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --job-id) JOB_ID="$2"; shift 2 ;;
        --repo) REPO_URL="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --repo-name) REPO_NAME="$2"; shift 2 ;;
        --prompts) PROMPTS="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

LOG_PREFIX="[$JOB_ID]"
WORKSPACE="${MINI_WORKSPACE:-$HOME/workspace}"
REPO_DIR="$WORKSPACE/$REPO_NAME"
JOBS_DIR="$WORKSPACE/.mini-remote/jobs"
START_TIME=$(date +%s)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_PREFIX $1"
}

update_job_status() {
    local status="$1"
    local detail="${2:-}"
    
    if [ -f "$JOBS_DIR/$JOB_ID.json" ]; then
        # Simple status update via temp file
        local tmp=$(mktemp)
        cat "$JOBS_DIR/$JOB_ID.json" | \
            sed "s/\"status\": \"[^\"]*\"/\"status\": \"$status\"/" > "$tmp"
        mv "$tmp" "$JOBS_DIR/$JOB_ID.json"
    fi
}

# ---- Split Prompts ----
IFS=$'\n' read -ra RAW_PROMPTS <<< "$(echo "$PROMPTS" | sed 's/|||/\n/g')"
PROMPT_LIST=()
for p in "${RAW_PROMPTS[@]}"; do
    trimmed=$(echo "$p" | xargs)
    if [ -n "$trimmed" ]; then
        PROMPT_LIST+=("$trimmed")
    fi
done

TOTAL_PROMPTS=${#PROMPT_LIST[@]}

log "Starting executor — $TOTAL_PROMPTS prompts queued"
log "Repo: $REPO_URL ($BRANCH)"

# ---- Clone or Update Repo ----
log "Syncing repository..."

if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    git fetch origin
    git checkout "$BRANCH"
    git reset --hard "origin/$BRANCH"
    git pull origin "$BRANCH"
    log "✓ Pulled latest from origin/$BRANCH"
else
    log "Cloning $REPO_URL..."
    git clone -b "$BRANCH" "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
    log "✓ Cloned successfully"
fi

# ---- Execute Each Prompt ----
COMPLETED=0
FAILED=0
TOTAL_ADDITIONS=0
TOTAL_DELETIONS=0
TOTAL_FILES_CHANGED=0
ALL_COMMITS=""

for i in "${!PROMPT_LIST[@]}"; do
    PROMPT="${PROMPT_LIST[$i]}"
    PROMPT_NUM=$((i + 1))
    PROMPT_START=$(date +%s)
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Executing prompt $PROMPT_NUM/$TOTAL_PROMPTS"
    log "Prompt: $PROMPT"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    update_job_status "running" "Prompt $PROMPT_NUM/$TOTAL_PROMPTS"
    
    # Pull latest before each prompt (in case previous prompt pushed changes)
    git pull origin "$BRANCH" 2>/dev/null || true
    
    # ---- Safety Check ----
    log "Running safety check..."
    if ! bash "$SCRIPT_DIR/safety_check.sh" "$PROMPT"; then
        log "✗ Safety check FAILED for prompt: $PROMPT"
        ((FAILED++))
        
        bash "$SCRIPT_DIR/notify.sh" \
            --status "blocked" \
            --repo "$REPO_NAME" \
            --branch "$BRANCH" \
            --prompt "$PROMPT" \
            --prompt-num "$PROMPT_NUM" \
            --total-prompts "$TOTAL_PROMPTS" \
            --message "Blocked by safety check — contains potentially destructive operations"
        
        continue
    fi
    log "✓ Safety check passed"
    
    # ---- Run Claude Code ----
    log "Launching Claude Code..."
    
    CLAUDE_OUTPUT_FILE=$(mktemp)
    CLAUDE_EXIT_CODE=0
    
    # Run Claude Code in print mode with the prompt
    # --dangerously-skip-permissions for fully autonomous execution
    timeout 3600 claude -p \
        --dangerously-skip-permissions \
        "$PROMPT" \
        > "$CLAUDE_OUTPUT_FILE" 2>&1 || CLAUDE_EXIT_CODE=$?
    
    PROMPT_END=$(date +%s)
    PROMPT_DURATION=$((PROMPT_END - PROMPT_START))
    DURATION_FORMATTED=$(printf '%dm %ds' $((PROMPT_DURATION/60)) $((PROMPT_DURATION%60)))
    
    if [ $CLAUDE_EXIT_CODE -ne 0 ] && [ $CLAUDE_EXIT_CODE -ne 124 ]; then
        log "✗ Claude Code exited with code $CLAUDE_EXIT_CODE"
        ((FAILED++))
        
        # Get last 20 lines of output for error context
        ERROR_CONTEXT=$(tail -20 "$CLAUDE_OUTPUT_FILE" | head -500)
        
        bash "$SCRIPT_DIR/notify.sh" \
            --status "failed" \
            --repo "$REPO_NAME" \
            --branch "$BRANCH" \
            --prompt "$PROMPT" \
            --prompt-num "$PROMPT_NUM" \
            --total-prompts "$TOTAL_PROMPTS" \
            --duration "$DURATION_FORMATTED" \
            --message "Claude Code failed (exit $CLAUDE_EXIT_CODE): $ERROR_CONTEXT"
        
        rm -f "$CLAUDE_OUTPUT_FILE"
        continue
    fi
    
    if [ $CLAUDE_EXIT_CODE -eq 124 ]; then
        log "⚠ Claude Code timed out after 60 minutes"
    fi
    
    log "✓ Claude Code completed in $DURATION_FORMATTED"
    
    # ---- Commit and Push ----
    log "Committing changes..."
    
    # Check if there are changes to commit
    if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
        log "No changes detected — nothing to commit"
        COMMIT_HASH="(no changes)"
        FILES_CHANGED=0
        ADDITIONS=0
        DELETIONS=0
    else
        git add -A
        
        # Create commit message with [remote-mini] tag
        COMMIT_MSG="[remote-mini] $PROMPT

Executed autonomously by Mini Remote
Job: $JOB_ID
Prompt: $PROMPT_NUM/$TOTAL_PROMPTS
Duration: $DURATION_FORMATTED"
        
        git commit -m "$COMMIT_MSG"
        
        # Get stats
        COMMIT_HASH=$(git rev-parse --short HEAD)
        DIFF_STAT=$(git diff --stat HEAD~1 2>/dev/null || echo "")
        FILES_CHANGED=$(git diff --numstat HEAD~1 2>/dev/null | wc -l | xargs)
        ADDITIONS=$(git diff --numstat HEAD~1 2>/dev/null | awk '{s+=$1}END{print s+0}')
        DELETIONS=$(git diff --numstat HEAD~1 2>/dev/null | awk '{s+=$2}END{print s+0}')
        
        ALL_COMMITS="$ALL_COMMITS $COMMIT_HASH"
        TOTAL_FILES_CHANGED=$((TOTAL_FILES_CHANGED + FILES_CHANGED))
        TOTAL_ADDITIONS=$((TOTAL_ADDITIONS + ADDITIONS))
        TOTAL_DELETIONS=$((TOTAL_DELETIONS + DELETIONS))
        
        # Push
        git push origin "$BRANCH"
        log "✓ Pushed commit $COMMIT_HASH"
    fi
    
    ((COMPLETED++))
    
    # ---- Notify Slack (per prompt) ----
    bash "$SCRIPT_DIR/notify.sh" \
        --status "completed" \
        --repo "$REPO_NAME" \
        --branch "$BRANCH" \
        --prompt "$PROMPT" \
        --prompt-num "$PROMPT_NUM" \
        --total-prompts "$TOTAL_PROMPTS" \
        --duration "$DURATION_FORMATTED" \
        --files-changed "$FILES_CHANGED" \
        --additions "$ADDITIONS" \
        --deletions "$DELETIONS" \
        --commit "$COMMIT_HASH" \
        --next-prompt "${PROMPT_LIST[$((i+1))]:-}"
    
    rm -f "$CLAUDE_OUTPUT_FILE"
    
    log "Prompt $PROMPT_NUM/$TOTAL_PROMPTS complete"
done

# ---- Final Summary ----
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
TOTAL_FORMATTED=$(printf '%dm %ds' $((TOTAL_DURATION/60)) $((TOTAL_DURATION%60)))

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "ALL TASKS COMPLETE"
log "  Completed: $COMPLETED / $TOTAL_PROMPTS"
log "  Failed:    $FAILED"
log "  Duration:  $TOTAL_FORMATTED"
log "  Changes:   $TOTAL_FILES_CHANGED files, +$TOTAL_ADDITIONS -$TOTAL_DELETIONS"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---- Final Slack Notification ----
if [ $TOTAL_PROMPTS -gt 1 ]; then
    bash "$SCRIPT_DIR/notify.sh" \
        --status "queue-complete" \
        --repo "$REPO_NAME" \
        --branch "$BRANCH" \
        --completed "$COMPLETED" \
        --failed "$FAILED" \
        --total-prompts "$TOTAL_PROMPTS" \
        --duration "$TOTAL_FORMATTED" \
        --total-files "$TOTAL_FILES_CHANGED" \
        --total-additions "$TOTAL_ADDITIONS" \
        --total-deletions "$TOTAL_DELETIONS"
fi

update_job_status "completed"

log "Executor finished. Pausing as requested."
