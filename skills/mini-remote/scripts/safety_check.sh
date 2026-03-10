#!/bin/bash
# ============================================================================
# Mini Remote — Safety Check
# Validates prompts before execution to prevent destructive operations.
# Returns 0 if safe, 1 if blocked.
# ============================================================================

PROMPT="$1"
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

RED='\033[0;31m'
NC='\033[0m'

# ---- Destructive Database Operations ----
DB_PATTERNS=(
    "drop database"
    "drop table"
    "drop schema"
    "truncate table"
    "truncate "
    "delete from .* without"
    "delete all records"
    "delete everything"
    "db.dropdatabase"
    "db.drop"
    "destroy database"
    "wipe database"
    "wipe the database"
    "clear all data"
    "delete all data"
    "purge database"
    "reset database"
    "nuke"
)

# ---- Destructive File Operations ----
FILE_PATTERNS=(
    "rm -rf /"
    "rm -rf ~"
    "rm -rf \."
    "rm -rf \*"
    "delete everything"
    "delete all files"
    "wipe the disk"
    "format the drive"
    "mkfs"
    "dd if=/dev/zero"
    "shred"
    "> /dev/sda"
)

# ---- Git Dangerous Operations ----
GIT_PATTERNS=(
    "force push to main"
    "force push to master"
    "git push --force origin main"
    "git push --force origin master"
    "git push -f origin main"
    "git push -f origin master"
    "delete the repo"
    "delete repository"
    "git reset --hard.*main"
    "git reset --hard.*master"
)

# ---- Credential Exposure ----
CRED_PATTERNS=(
    "print.*api.key"
    "echo.*secret"
    "cat.*\.env"
    "display.*password"
    "show.*credentials"
    "expose.*token"
    "log.*api.key"
    "print.*password"
)

# ---- System Destructive ----
SYSTEM_PATTERNS=(
    "shutdown"
    "reboot"
    "halt"
    "poweroff"
    "init 0"
    "kill -9 -1"
    "killall"
    "launchctl unload"
    "disable sip"
    "csrutil disable"
)

check_patterns() {
    local category="$1"
    shift
    local patterns=("$@")
    
    for pattern in "${patterns[@]}"; do
        if echo "$PROMPT_LOWER" | grep -qiE "$pattern"; then
            echo -e "${RED}BLOCKED${NC} — $category"
            echo "  Matched pattern: $pattern"
            echo "  Prompt: $PROMPT"
            return 1
        fi
    done
    return 0
}

# Run all checks
check_patterns "Destructive database operation" "${DB_PATTERNS[@]}" || exit 1
check_patterns "Destructive file operation" "${FILE_PATTERNS[@]}" || exit 1
check_patterns "Dangerous git operation" "${GIT_PATTERNS[@]}" || exit 1
check_patterns "Credential exposure risk" "${CRED_PATTERNS[@]}" || exit 1
check_patterns "Destructive system operation" "${SYSTEM_PATTERNS[@]}" || exit 1

# All checks passed
exit 0
