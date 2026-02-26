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

# Extract last assistant message (available since v2.1.47)
LAST_MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // ""' 2>/dev/null || echo "")

# Extract learnings from last message (look for patterns, decisions, fixes)
LEARNINGS="[]"
if [ -n "$LAST_MESSAGE" ] && [ "$LAST_MESSAGE" != "null" ]; then
  # Extract key phrases that indicate learnings
  LEARNINGS=$(echo "$LAST_MESSAGE" | python3 -c "
import sys, json, re

text = sys.stdin.read()
learnings = []

# Patterns that indicate a learning or decision
patterns = [
    (r'(?:fixed|resolved|solved)\s+(?:by|with)\s+(.{20,100})', 'fix'),
    (r'(?:the issue was|root cause|problem was)\s+(.{20,100})', 'diagnosis'),
    (r'(?:switched to|migrated to|upgraded to)\s+(.{20,80})', 'decision'),
    (r'(?:pattern|approach):\s+(.{20,100})', 'pattern'),
]

for pattern, category in patterns:
    matches = re.findall(pattern, text, re.IGNORECASE)
    for match in matches[:2]:  # Max 2 per category
        learnings.append({'type': category, 'content': match.strip()[:150]})

print(json.dumps(learnings[:5]))  # Max 5 learnings
" 2>/dev/null || echo "[]")
fi

# Detect project from working directory
PROJECT="unknown"
if [[ "$WORKING_DIR" == *"contably"* ]]; then
  PROJECT="Contably"
elif [[ "$WORKING_DIR" == *"agentcreator"* ]] || [[ "$WORKING_DIR" == *"AgentCreator"* ]]; then
  PROJECT="AgentCreator"
elif [[ "$WORKING_DIR" == *"mna"* ]] || [[ "$WORKING_DIR" == *"nuvini"* ]]; then
  PROJECT="M&A Toolkit"
fi

# Create session log with extracted learnings
SESSION_FILE="$SESSIONS_DIR/${DATE}-${TIME}-session.json"
cat > "$SESSION_FILE" << EOF
{
  "date": "$DATE",
  "time": "$(date +%H:%M:%S)",
  "sessionId": "$SESSION_ID",
  "project": "$PROJECT",
  "workingDirectory": "$WORKING_DIR",
  "learnings": $LEARNINGS,
  "memoriesApplied": [],
  "status": "pending_review"
}
EOF

# Auto-sync claude-setup if there are changes
SETUP_DIR="$HOME/.claude-setup"
if [ -d "$SETUP_DIR/.git" ]; then
  if ! git -C "$SETUP_DIR" diff --quiet 2>/dev/null || \
     ! git -C "$SETUP_DIR" diff --cached --quiet 2>/dev/null || \
     [ -n "$(git -C "$SETUP_DIR" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    git -C "$SETUP_DIR" add -A 2>/dev/null
    git -C "$SETUP_DIR" commit -m "auto: sync claude-setup" --quiet 2>/dev/null
    git -C "$SETUP_DIR" push origin master --quiet 2>/dev/null &
    echo "claude-setup synced to GitHub" >&2
  fi
fi

# Log reminder to stderr (stdout must be valid JSON for Claude Code hooks)
echo "Session logged: $SESSION_FILE" >&2

# Must output valid JSON to stdout for Claude Code hook validation
echo '{}'

exit 0
