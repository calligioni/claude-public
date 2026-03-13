#!/bin/bash
# Skill Execution Logger — PostToolUse hook for Skill tool
# Logs which skill was invoked, when, from which project, and outcome.
# Consumed by /claude-setup-optimizer to detect skill drift and propose amendments.

set -euo pipefail

LOG_FILE="$HOME/.claude-setup/memory/skill-executions.jsonl"
mkdir -p "$(dirname "$LOG_FILE")"

INPUT=$(cat 2>/dev/null || echo '{}')

SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // "unknown"' 2>/dev/null || echo "unknown")
SKILL_ARGS=$(echo "$INPUT" | jq -r '.tool_input.args // ""' 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(pwd 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DATE=$(date +%Y-%m-%d)

# Detect project from cwd
case "$CWD" in
  *contably*) PROJECT="Contably" ;;
  *Sourcerank*|*sourcerank*) PROJECT="SourceRank" ;;
  *agentcreator*|*AgentCreator*) PROJECT="AgentCreator" ;;
  *mna*|*nuvini*) PROJECT="M&A Toolkit" ;;
  *claude-setup*) PROJECT="Claude Setup" ;;
  *stonegeo*|*StoneGEO*) PROJECT="StoneGEO" ;;
  *) PROJECT="Unknown" ;;
esac

# Check for error in tool output
HAS_ERROR="false"
if echo "$INPUT" | jq -e '.tool_output.error // empty' >/dev/null 2>&1; then
  HAS_ERROR="true"
fi

# Write log entry
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg date "$DATE" \
  --arg skill "$SKILL_NAME" \
  --arg args "$SKILL_ARGS" \
  --arg session "$SESSION_ID" \
  --arg project "$PROJECT" \
  --arg cwd "$CWD" \
  --arg error "$HAS_ERROR" \
  '{
    timestamp: $ts,
    date: $date,
    skill: $skill,
    args: $args,
    sessionId: $session,
    project: $project,
    cwd: $cwd,
    hadError: ($error == "true")
  }' >> "$LOG_FILE"

exit 0
