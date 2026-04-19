#!/bin/bash
# Claude Config Sync Setup
# Creates symlinks from ~/.claude to this repo for portable config files
# Usage: ./setup-symlinks.sh [--restore]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d_%H%M%S)"

# Portable directories/files to sync
SYNC_ITEMS=(
    "agents"
    "bin"
    "commands"
    "hooks"
    "rules"
    "skills"
    "settings.json"
)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# Restore from backup
if [[ "$1" == "--restore" ]]; then
    LATEST_BACKUP=$(ls -td "$HOME"/.claude-backup-* 2>/dev/null | head -1)
    if [[ -z "$LATEST_BACKUP" ]]; then
        error "No backup found to restore"
    fi
    log "Restoring from $LATEST_BACKUP"
    for item in "${SYNC_ITEMS[@]}"; do
        if [[ -L "$CLAUDE_DIR/$item" ]]; then
            rm "$CLAUDE_DIR/$item"
        fi
        if [[ -e "$LATEST_BACKUP/$item" ]]; then
            cp -R "$LATEST_BACKUP/$item" "$CLAUDE_DIR/$item"
            log "Restored $item"
        fi
    done
    log "Restore complete!"
    exit 0
fi

# Main setup
log "Claude Config Sync Setup"
log "Repo: $SCRIPT_DIR"
log "Claude dir: $CLAUDE_DIR"

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR"

# Backup existing config
log "Backing up existing config to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for item in "${SYNC_ITEMS[@]}"; do
    if [[ -e "$CLAUDE_DIR/$item" && ! -L "$CLAUDE_DIR/$item" ]]; then
        cp -R "$CLAUDE_DIR/$item" "$BACKUP_DIR/"
        log "Backed up $item"
    fi
done

# Create symlinks
log "Creating symlinks..."
for item in "${SYNC_ITEMS[@]}"; do
    src="$SCRIPT_DIR/$item"
    dest="$CLAUDE_DIR/$item"

    # Skip if source doesn't exist in repo
    if [[ ! -e "$src" ]]; then
        warn "Source not found: $src (skipping)"
        continue
    fi

    # Remove existing (file or symlink)
    if [[ -e "$dest" || -L "$dest" ]]; then
        rm -rf "$dest"
    fi

    # Create symlink
    ln -s "$src" "$dest"
    log "Linked: $item -> $src"
done

# Install claude-sync command
SYNC_CMD="$HOME/.local/bin/claude-sync"
mkdir -p "$HOME/.local/bin"

cat > "$SYNC_CMD" << 'SYNC_SCRIPT'
#!/bin/bash
# Claude Config Sync - push/pull config changes
set -e

REPO_DIR="REPO_PLACEHOLDER"
cd "$REPO_DIR"

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1"; }

case "${1:-status}" in
    push)
        log "Pushing config changes..."
        git add -A
        git commit -m "sync: $(hostname) $(date +%Y-%m-%d)" 2>/dev/null || log "Nothing to commit"
        git push
        log "Done!"
        ;;
    pull)
        log "Pulling latest config..."
        git pull --rebase
        log "Done!"
        ;;
    status)
        git status --short
        git log --oneline -3
        ;;
    *)
        echo "Usage: claude-sync [push|pull|status]"
        ;;
esac
SYNC_SCRIPT

# Replace placeholder with actual repo path
sed -i '' "s|REPO_PLACEHOLDER|$SCRIPT_DIR|g" "$SYNC_CMD"
chmod +x "$SYNC_CMD"

log "Installed: claude-sync command"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "Add to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
log "Setup complete!"
echo ""
echo "Usage:"
echo "  claude-sync status  - Show pending changes"
echo "  claude-sync push    - Commit and push config"
echo "  claude-sync pull    - Pull latest config"
echo ""
echo "On a new device:"
echo "  1. git clone https://github.com/escotilha/claude.git ~/.claude-setup"
echo "  2. cd ~/.claude-setup && ./setup-symlinks.sh"
echo "  3. cp ~/.claude-setup/launchd/com.claude.setup-sync.plist ~/Library/LaunchAgents/"
echo "  4. launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/com.claude.setup-sync.plist"
