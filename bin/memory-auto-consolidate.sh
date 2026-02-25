#!/bin/bash
# Memory Auto-Consolidation - Automated triggers for memory maintenance
# Location: ~/.claude-setup/bin/memory-auto-consolidate.sh
#
# This script checks if consolidation is needed and triggers it.
# Run via cron or launchd for automated maintenance.
#
# Usage:
#   ./memory-auto-consolidate.sh          # Check and consolidate if needed
#   ./memory-auto-consolidate.sh --force  # Force consolidation
#   ./memory-auto-consolidate.sh --check  # Check only, don't consolidate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_DIR="$HOME/.claude-setup/memory"
CORE_MEMORY="$MEMORY_DIR/core-memory.json"
LOG_FILE="$MEMORY_DIR/consolidation.log"

# Configuration thresholds
MAX_DAYS_SINCE_CONSOLIDATION=7
MAX_MEMORY_COUNT=200
MAX_UNPROCESSED_ENTRIES=50

# Parse arguments
FORCE=false
CHECK_ONLY=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --force) FORCE=true; shift ;;
    --check) CHECK_ONLY=true; shift ;;
    *) shift ;;
  esac
done

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$msg"
  echo "$msg" >> "$LOG_FILE"
}

# Get last consolidation date from core memory
get_last_consolidation() {
  if [[ -f "$CORE_MEMORY" ]]; then
    jq -r '.lastConsolidation // "null"' "$CORE_MEMORY" 2>/dev/null || echo "null"
  else
    echo "null"
  fi
}

# Calculate days since last consolidation
days_since_consolidation() {
  local last=$(get_last_consolidation)
  if [[ "$last" == "null" ]]; then
    echo "999"  # Never consolidated
    return
  fi

  # Parse ISO date and calculate difference
  local last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last%Z}" "+%s" 2>/dev/null || echo "0")
  local now_epoch=$(date "+%s")
  local diff_seconds=$((now_epoch - last_epoch))
  local diff_days=$((diff_seconds / 86400))
  echo "$diff_days"
}

# Count unprocessed learning log entries
count_unprocessed() {
  local learning_log="$MEMORY_DIR/learning-log.jsonl"
  if [[ -f "$learning_log" ]]; then
    grep -c '"processed": false' "$learning_log" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

# Count pending extractions
count_pending_extractions() {
  local extracted_dir="$MEMORY_DIR/extracted"
  if [[ -d "$extracted_dir" ]]; then
    find "$extracted_dir" -name "*.json" -type f 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

# Check if consolidation is needed
check_consolidation_needed() {
  local days=$(days_since_consolidation)
  local unprocessed=$(count_unprocessed)
  local pending=$(count_pending_extractions)

  local reasons=()

  if [[ "$days" -ge "$MAX_DAYS_SINCE_CONSOLIDATION" ]]; then
    reasons+=("$days days since last consolidation (threshold: $MAX_DAYS_SINCE_CONSOLIDATION)")
  fi

  if [[ "$unprocessed" -ge "$MAX_UNPROCESSED_ENTRIES" ]]; then
    reasons+=("$unprocessed unprocessed entries (threshold: $MAX_UNPROCESSED_ENTRIES)")
  fi

  if [[ "$pending" -gt 0 ]]; then
    reasons+=("$pending pending extractions to import")
  fi

  if [[ ${#reasons[@]} -gt 0 ]]; then
    echo "NEEDED"
    for reason in "${reasons[@]}"; do
      echo "  - $reason"
    done
  else
    echo "NOT_NEEDED"
    echo "  - Last consolidation: $(get_last_consolidation)"
    echo "  - Unprocessed entries: $unprocessed"
    echo "  - Pending extractions: $pending"
  fi
}

# Run the consolidation pipeline
run_consolidation() {
  log "Starting auto-consolidation pipeline..."

  # Step 1: Run session analyzer
  log "Step 1: Analyzing sessions..."
  if [[ -f "$SCRIPT_DIR/session-analyzer.py" ]]; then
    python3 "$SCRIPT_DIR/session-analyzer.py" --quiet 2>&1 | tee -a "$LOG_FILE" || true
  fi

  # Step 2: Run git pattern extractor on all projects
  log "Step 2: Extracting git patterns..."
  if [[ -f "$SCRIPT_DIR/git-pattern-extractor.py" ]]; then
    python3 "$SCRIPT_DIR/git-pattern-extractor.py" --all-projects --quiet 2>&1 | tee -a "$LOG_FILE" || true
  fi

  # Step 3: Run memory importer
  log "Step 3: Preparing memory imports..."
  if [[ -f "$SCRIPT_DIR/memory-importer.py" ]]; then
    python3 "$SCRIPT_DIR/memory-importer.py" --quiet 2>&1 | tee -a "$LOG_FILE" || true
  fi

  # Step 4: Update last consolidation timestamp
  log "Step 4: Updating consolidation timestamp..."
  local now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  if [[ -f "$CORE_MEMORY" ]]; then
    local tmp=$(mktemp)
    jq --arg now "$now" '.lastConsolidation = $now | .lastUpdated = ($now | split("T")[0])' "$CORE_MEMORY" > "$tmp"
    mv "$tmp" "$CORE_MEMORY"
  fi

  log "Auto-consolidation complete!"

  # Generate summary
  echo ""
  echo "=========================================="
  echo "CONSOLIDATION SUMMARY"
  echo "=========================================="
  echo "Completed at: $now"
  echo ""
  echo "Next steps:"
  echo "  1. Review pending imports in $MEMORY_DIR/extracted/"
  echo "  2. Run /consolidate in Claude to import memories"
  echo "  3. Or run: python3 $SCRIPT_DIR/memory-importer.py"
  echo "=========================================="
}

# Main
main() {
  log "Memory auto-consolidation check started"

  local status=$(check_consolidation_needed | head -1)

  echo ""
  echo "Consolidation Check Results:"
  check_consolidation_needed
  echo ""

  if [[ "$FORCE" == "true" ]]; then
    log "Forced consolidation requested"
    if [[ "$CHECK_ONLY" == "true" ]]; then
      echo "CHECK_ONLY mode - would run consolidation"
    else
      run_consolidation
    fi
  elif [[ "$status" == "NEEDED" ]]; then
    if [[ "$CHECK_ONLY" == "true" ]]; then
      echo "CHECK_ONLY mode - consolidation needed but not running"
    else
      run_consolidation
    fi
  else
    log "No consolidation needed at this time"
  fi
}

main
