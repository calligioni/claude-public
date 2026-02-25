#!/bin/bash
# Learning Capture Hook - Track code changes for pattern extraction
# Location: ~/.claude-setup/hooks/learning-capture.sh
#
# This hook captures file changes and test outcomes to build a learning log
# that the session analyzer can process for pattern extraction.

set -euo pipefail

MEMORY_DIR="$HOME/.claude-setup/memory"
LEARNING_LOG="$MEMORY_DIR/learning-log.jsonl"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Ensure directory exists
mkdir -p "$MEMORY_DIR"

# Parse input from Claude Code hook system
INPUT=$(cat 2>/dev/null || echo '{}')

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null || echo '{}')
TOOL_OUTPUT=$(echo "$INPUT" | jq -c '.tool_output // {}' 2>/dev/null || echo '{}')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | jq -r '.cwd // "'$(pwd)'"' 2>/dev/null || pwd)

# Detect project from path
detect_project() {
  local path="$1"
  if [[ "$path" == *"contably"* ]]; then echo "Contably"
  elif [[ "$path" == *"agentcreator"* ]] || [[ "$path" == *"AgentCreator"* ]]; then echo "AgentCreator"
  elif [[ "$path" == *"mna"* ]] || [[ "$path" == *"nuvini"* ]]; then echo "M&A Toolkit"
  elif [[ "$path" == *"claudia"* ]] || [[ "$path" == *"claude-setup"* ]]; then echo "Claude Setup"
  else echo "Unknown"
  fi
}

PROJECT=$(detect_project "$CWD")

# Extract file path from tool input
FILE_PATH=""
if [[ "$TOOL_NAME" == "Edit" ]] || [[ "$TOOL_NAME" == "Write" ]]; then
  FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""' 2>/dev/null || echo "")
fi

# Detect file type and language
detect_language() {
  local file="$1"
  case "${file##*.}" in
    ts|tsx) echo "TypeScript" ;;
    js|jsx) echo "JavaScript" ;;
    py) echo "Python" ;;
    go) echo "Go" ;;
    rs) echo "Rust" ;;
    sql) echo "SQL" ;;
    sh|bash) echo "Shell" ;;
    json) echo "JSON" ;;
    md) echo "Markdown" ;;
    css|scss|sass) echo "CSS" ;;
    html) echo "HTML" ;;
    *) echo "Other" ;;
  esac
}

LANGUAGE=""
if [[ -n "$FILE_PATH" ]]; then
  LANGUAGE=$(detect_language "$FILE_PATH")
fi

# Detect patterns in the code change
detect_patterns() {
  local tool_input="$1"
  local patterns=()

  # Check for common patterns in the change
  if echo "$tool_input" | grep -qi "early return\|return early\|guard clause"; then
    patterns+=("early-returns")
  fi
  if echo "$tool_input" | grep -qi "try.*catch\|error.*handling\|throw new"; then
    patterns+=("error-handling")
  fi
  if echo "$tool_input" | grep -qi "async.*await\|Promise\|\.then("; then
    patterns+=("async-patterns")
  fi
  if echo "$tool_input" | grep -qi "useState\|useEffect\|useCallback\|useMemo"; then
    patterns+=("react-hooks")
  fi
  if echo "$tool_input" | grep -qi "z\.object\|z\.string\|zod"; then
    patterns+=("zod-validation")
  fi
  if echo "$tool_input" | grep -qi "supabase\|createClient\|\.from("; then
    patterns+=("supabase")
  fi
  if echo "$tool_input" | grep -qi "prisma\|\.findMany\|\.create("; then
    patterns+=("prisma")
  fi
  if echo "$tool_input" | grep -qi "middleware\|NextResponse\|headers"; then
    patterns+=("middleware")
  fi
  if echo "$tool_input" | grep -qi "test\|describe\|it(\|expect("; then
    patterns+=("testing")
  fi

  # Output as JSON array
  printf '%s\n' "${patterns[@]}" | jq -R . | jq -s .
}

DETECTED_PATTERNS=$(detect_patterns "$TOOL_INPUT")

# Check if this was a successful operation
SUCCESS="true"
if echo "$TOOL_OUTPUT" | jq -e '.error' >/dev/null 2>&1; then
  SUCCESS="false"
fi

# Create learning entry
LEARNING_ENTRY=$(jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg date "$DATE" \
  --arg session_id "$SESSION_ID" \
  --arg project "$PROJECT" \
  --arg tool "$TOOL_NAME" \
  --arg file_path "$FILE_PATH" \
  --arg language "$LANGUAGE" \
  --arg success "$SUCCESS" \
  --argjson patterns "$DETECTED_PATTERNS" \
  --arg cwd "$CWD" \
  '{
    timestamp: $timestamp,
    date: $date,
    sessionId: $session_id,
    project: $project,
    tool: $tool,
    filePath: $file_path,
    language: $language,
    success: ($success == "true"),
    detectedPatterns: $patterns,
    cwd: $cwd,
    processed: false
  }'
)

# Append to learning log (JSONL format - one JSON object per line)
echo "$LEARNING_ENTRY" >> "$LEARNING_LOG"

# Output for hook chain (if needed)
echo '{"status": "captured"}'
