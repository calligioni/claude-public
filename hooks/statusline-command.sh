#!/bin/bash
input=$(cat)

# Account
ACCOUNT=$(whoami)

# Model
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')

# Context
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
PCT=${PCT:-0}

# Progress bar (20 chars wide)
FILLED=$((PCT * 20 / 100))
EMPTY=$((20 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

# Color based on context usage
if [ "$PCT" -ge 90 ]; then
  CLR='\033[31m'  # red
elif [ "$PCT" -ge 70 ]; then
  CLR='\033[33m'  # yellow
else
  CLR='\033[32m'  # green
fi
RST='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[36m'
MAGENTA='\033[35m'
BLUE='\033[34m'

# Cost
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_FMT=$(printf '$%.2f' "$COST")

# Duration
DUR_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
MINS=$((DUR_MS / 60000))
SECS=$(((DUR_MS % 60000) / 1000))
if [ "$MINS" -gt 0 ]; then
  DUR_FMT="${MINS}m${SECS}s"
else
  DUR_FMT="${SECS}s"
fi

# Tokens (cumulative session totals)
IN_TOK=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUT_TOK=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
TOTAL_TOK=$((IN_TOK + OUT_TOK))
if [ "$TOTAL_TOK" -ge 1000000 ]; then
  TOK_FMT=$(printf '%.1fM' "$(echo "$TOTAL_TOK / 1000000" | bc -l)")
elif [ "$TOTAL_TOK" -ge 1000 ]; then
  TOK_FMT=$(printf '%.1fK' "$(echo "$TOTAL_TOK / 1000" | bc -l)")
else
  TOK_FMT="${TOTAL_TOK}"
fi

# Lines changed
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Git info
BRANCH=""
DIRTY=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  if [ -n "$(git status --porcelain 2>/dev/null | head -1)" ]; then
    DIRTY="*"
  fi
fi

# Working directory (shortened)
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "?"')
DIR=${DIR##*/}

# Added dirs (from /add-dir command, available since v2.1.47)
ADDED_DIRS=$(echo "$input" | jq -r '(.workspace.added_dirs // []) | map(. | split("/") | last) | join(",")' 2>/dev/null)
ADDED_DIRS_FMT=""
if [ -n "$ADDED_DIRS" ]; then
  ADDED_DIRS_FMT=" ${DIM}+dirs:${RST}${DIM}${ADDED_DIRS}${RST}"
fi

# Build output
echo -e "${DIM}${ACCOUNT}${RST} ${DIM}|${RST} ${BOLD}${CYAN}${MODEL}${RST} ${DIM}|${RST} ${CLR}${BAR}${RST} ${PCT}% ${DIM}|${RST} ${MAGENTA}${COST_FMT}${RST} ${DIM}|${RST} ${DIM}${TOK_FMT}tok${RST} ${DIM}|${RST} ${DUR_FMT} ${DIM}|${RST} ${BLUE}${BRANCH}${DIRTY}${RST} ${DIM}|${RST} ${DIR}${ADDED_DIRS_FMT} ${DIM}|${RST} ${DIM}+${ADDED} -${REMOVED}${RST}"
