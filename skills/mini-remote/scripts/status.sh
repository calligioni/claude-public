#!/bin/bash
# ============================================================================
# Mini Remote — Status Checker
# Shows running and completed jobs on the Mac Mini.
# Can be run locally (SSHs in) or directly on the Mini.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || true

WORKSPACE="${MINI_WORKSPACE:-$HOME/workspace}"
JOBS_DIR="$WORKSPACE/.mini-remote/jobs"
LOGS_DIR="$WORKSPACE/.mini-remote/logs"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║     🤖 Mini Remote — Job Status          ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

if [ ! -d "$JOBS_DIR" ]; then
    echo "  No jobs found."
    exit 0
fi

# Find running jobs (have a PID file with active process)
RUNNING=0
COMPLETED=0

for pid_file in "$JOBS_DIR"/*.pid; do
    [ -f "$pid_file" ] || continue
    
    JOB_ID=$(basename "$pid_file" .pid)
    PID=$(cat "$pid_file")
    
    if kill -0 "$PID" 2>/dev/null; then
        ((RUNNING++))
        echo -e "  ${GREEN}● RUNNING${NC} — $JOB_ID (PID: $PID)"
        
        # Show last few lines of log
        LOG_FILE="$LOGS_DIR/$JOB_ID.log"
        if [ -f "$LOG_FILE" ]; then
            echo -e "    ${DIM}Last activity:${NC}"
            tail -3 "$LOG_FILE" | sed 's/^/    /'
        fi
        echo ""
    else
        ((COMPLETED++))
        echo -e "  ${DIM}○ FINISHED${NC} — $JOB_ID"
        
        # Show completion info
        LOG_FILE="$LOGS_DIR/$JOB_ID.log"
        if [ -f "$LOG_FILE" ]; then
            LAST_LINE=$(tail -1 "$LOG_FILE")
            echo -e "    ${DIM}$LAST_LINE${NC}"
        fi
        echo ""
    fi
done

if [ $RUNNING -eq 0 ] && [ $COMPLETED -eq 0 ]; then
    echo "  No jobs found."
fi

echo -e "  ${BLUE}Summary: $RUNNING running, $COMPLETED finished${NC}"
echo ""

# Show recent logs option
if [ $RUNNING -gt 0 ]; then
    echo -e "  ${YELLOW}Tail a running log:${NC}"
    for pid_file in "$JOBS_DIR"/*.pid; do
        [ -f "$pid_file" ] || continue
        JOB_ID=$(basename "$pid_file" .pid)
        PID=$(cat "$pid_file")
        if kill -0 "$PID" 2>/dev/null; then
            echo "    tail -f $LOGS_DIR/$JOB_ID.log"
        fi
    done
    echo ""
fi
