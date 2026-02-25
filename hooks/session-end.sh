#!/bin/bash
# Session End Hook - Capture learnings for memory system
# Location: ~/.claude-setup/hooks/session-end.sh

set -euo pipefail

MEMORY_DIR="$HOME/.claude-setup/memory"
SESSIONS_DIR="$MEMORY_DIR/sessions"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H%M%S)

# Create directories if needed
mkdir -p "$SESSIONS_DIR"

# Parse input from Claude Code (if available)
INPUT=$(cat 2>/dev/null || echo '{}')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
WORKING_DIR=$(echo "$INPUT" | jq -r '.cwd // "unknown"' 2>/dev/null || echo "unknown")

# Detect project from working directory
PROJECT="unknown"
if [[ "$WORKING_DIR" == *"contably"* ]]; then
  PROJECT="Contably"
elif [[ "$WORKING_DIR" == *"agentcreator"* ]] || [[ "$WORKING_DIR" == *"AgentCreator"* ]]; then
  PROJECT="AgentCreator"
elif [[ "$WORKING_DIR" == *"mna"* ]] || [[ "$WORKING_DIR" == *"nuvini"* ]]; then
  PROJECT="M&A Toolkit"
fi

# Create session log
SESSION_FILE="$SESSIONS_DIR/${DATE}-${TIME}-session.json"
cat > "$SESSION_FILE" << EOF
{
  "date": "$DATE",
  "time": "$(date +%H:%M:%S)",
  "sessionId": "$SESSION_ID",
  "project": "$PROJECT",
  "workingDirectory": "$WORKING_DIR",
  "learnings": [],
  "memoriesApplied": [],
  "status": "pending_review"
}
EOF

# Log reminder to stderr (stdout must be valid JSON for Claude Code hooks)
echo "Session logged: $SESSION_FILE" >&2

# Must output valid JSON to stdout for Claude Code hook validation
echo '{}'

exit 0
