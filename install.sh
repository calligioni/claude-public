#!/bin/bash
# ============================================================
# Claude Code - Full Setup for New Macs
# ============================================================
# Replicates the entire Claude Code environment from GitHub.
#
# Usage (new machine):
#   brew install gh jq node
#   gh auth login
#   gh repo clone escotilha/claude ~/.claude-setup
#   bash ~/.claude-setup/install.sh
#
# Usage (existing machine - update):
#   bash ~/.claude-setup/install.sh
# ============================================================

set -euo pipefail

REPO="https://github.com/escotilha/claude.git"
INSTALL_DIR="$HOME/.claude-setup"
CLAUDE_DIR="$HOME/.claude"
PLIST_NAME="com.claude.setup-sync"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }
info() { echo -e "${DIM}    $1${NC}"; }

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Claude Code - Full Environment Setup              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── 1. Prerequisites ──────────────────────────────────────────
echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

MISSING=()
for cmd in git gh node npm jq; do
  if command -v "$cmd" &>/dev/null; then
    log "$cmd found"
  else
    MISSING+=("$cmd")
    err "$cmd not found"
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  warn "Install missing tools:"
  echo "  brew install ${MISSING[*]}"
  exit 1
fi

if ! command -v npx &>/dev/null; then
  warn "npx not found, installing..."
  npm install -g npx
fi

# ── 2. GitHub Auth ────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/8] GitHub authentication...${NC}"
if gh auth status &>/dev/null 2>&1; then
  log "GitHub authenticated"
else
  warn "Not authenticated. Running gh auth login..."
  gh auth login
fi
gh auth setup-git 2>/dev/null || true

# ── 3. Clone / Update Repo ───────────────────────────────────
echo ""
echo -e "${YELLOW}[3/8] Repository...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
  log "Repo exists, pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only origin master 2>/dev/null || true
elif [ -L "$INSTALL_DIR" ] && [ -d "$(readlink "$INSTALL_DIR")/.git" ]; then
  REAL_DIR=$(readlink "$INSTALL_DIR")
  log "Symlink to $REAL_DIR, pulling latest..."
  git -C "$REAL_DIR" pull --ff-only origin master 2>/dev/null || true
else
  log "Cloning from GitHub..."
  git clone "$REPO" "$INSTALL_DIR"
fi
log "Repo ready at $INSTALL_DIR"

# ── 4. Create Symlinks ───────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/8] Creating symlinks...${NC}"
mkdir -p "$CLAUDE_DIR"

SYNC_ITEMS=(
  "settings.json"
  "agents"
  "bin"
  "commands"
  "hooks"
  "rules"
  "skills"
)

for item in "${SYNC_ITEMS[@]}"; do
  src="$INSTALL_DIR/$item"
  dest="$CLAUDE_DIR/$item"

  if [ ! -e "$src" ]; then
    warn "Source not found: $src (skipping)"
    continue
  fi

  if [ -L "$dest" ]; then
    current=$(readlink "$dest")
    if [ "$current" = "$src" ]; then
      log "$item already linked"
      continue
    else
      rm "$dest"
    fi
  elif [ -e "$dest" ]; then
    BACKUP="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$BACKUP"
    warn "Backed up existing $item to $BACKUP"
  fi

  ln -s "$src" "$dest"
  log "Linked $item"
done

# Create directories Claude Code expects
mkdir -p "$CLAUDE_DIR/logs"
mkdir -p "$CLAUDE_DIR/projects"
mkdir -p "$CLAUDE_DIR/cache"

# ── 5. Build MCP Servers ─────────────────────────────────────
echo ""
echo -e "${YELLOW}[5/8] Building MCP servers...${NC}"

MEMORY_MCP="$INSTALL_DIR/mcp-servers/memory-turso"
if [ -f "$MEMORY_MCP/package.json" ]; then
  if [ ! -d "$MEMORY_MCP/dist" ] || [ "$MEMORY_MCP/src/index.ts" -nt "$MEMORY_MCP/dist/index.js" ] 2>/dev/null; then
    log "Building memory-turso MCP server..."
    (cd "$MEMORY_MCP" && npm install --silent 2>/dev/null && npm run build --silent 2>/dev/null)
    log "memory-turso built"
  else
    log "memory-turso already built"
  fi
else
  warn "memory-turso package.json not found"
fi

if [ -f "$INSTALL_DIR/mcp-servers/build.sh" ]; then
  bash "$INSTALL_DIR/mcp-servers/build.sh" 2>/dev/null || true
fi

# ── 6. Keychain Secrets ──────────────────────────────────────
echo ""
echo -e "${YELLOW}[6/8] Checking secrets...${NC}"
info "Secrets load from macOS Keychain (local per machine) + settings.json env block"

check_secret() {
  local name="$1"
  local env_var="$2"
  local service="claude-code-${name}"
  if security find-generic-password -a "$USER" -s "$service" -w &>/dev/null; then
    log "$env_var"
    return 0
  else
    warn "$env_var (not set)"
    return 1
  fi
}

SECRETS_MISSING=0
echo "  Required:"
check_secret "github-token" "GITHUB_TOKEN" || SECRETS_MISSING=1
check_secret "brave-api-key" "BRAVE_API_KEY" || SECRETS_MISSING=1

echo "  Optional:"
check_secret "anthropic-api-key" "ANTHROPIC_API_KEY" || true
check_secret "slack-bot-token" "SLACK_BOT_TOKEN" || true
check_secret "slack-team-id" "SLACK_TEAM_ID" || true
check_secret "notion-api-key" "NOTION_API_KEY" || true
check_secret "resend-api-key" "RESEND_API_KEY" || true
check_secret "digitalocean-token" "DIGITALOCEAN_TOKEN" || true
check_secret "firecrawl-api-key" "FIRECRAWL_API_KEY" || true

if [ $SECRETS_MISSING -eq 1 ]; then
  echo ""
  warn "Missing required secrets. Add them with:"
  echo "  security add-generic-password -a \"\$USER\" -s \"claude-code-github-token\" -w \"ghp_...\""
  echo "  security add-generic-password -a \"\$USER\" -s \"claude-code-brave-api-key\" -w \"BSA...\""
  echo ""
  info "Or run: bash ~/.claude-setup/hooks/setup-keychain.sh"
  info "For other machines, run setup-keychain.sh or use the settings.json env block."
fi

# ── 7. Shell Profile ─────────────────────────────────────────
echo ""
echo -e "${YELLOW}[7/8] Shell profile...${NC}"

LOAD_LINE='eval "$(~/.claude-setup/hooks/load-secrets.sh 2>/dev/null)"'
PATH_LINE='export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"'

setup_profile() {
  local profile="$1"
  local changed=false

  [ ! -f "$profile" ] && touch "$profile"

  if ! grep -q "load-secrets.sh" "$profile"; then
    printf '\n# Claude Code - load secrets from Keychain\n%s\n' "$LOAD_LINE" >> "$profile"
    changed=true
  fi

  if ! grep -q '\.claude/bin' "$profile"; then
    printf '\n# Claude Code - bin in PATH\n%s\n' "$PATH_LINE" >> "$profile"
    changed=true
  fi

  if $changed; then
    log "Updated $profile"
  else
    log "$profile already configured"
  fi
}

if [ "$SHELL" = "/bin/zsh" ] || [ -n "${ZSH_VERSION:-}" ]; then
  setup_profile "$HOME/.zshrc"
else
  setup_profile "$HOME/.bashrc"
  setup_profile "$HOME/.bash_profile"
fi

# ── 8. Launchd Sync Agent ────────────────────────────────────
echo ""
echo -e "${YELLOW}[8/8] Auto-sync agent...${NC}"
mkdir -p "$(dirname "$PLIST_PATH")"

cat > "$PLIST_PATH" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.claude.setup-sync</string>
    <key>Comment</key>
    <string>Bidirectional claude-setup sync with GitHub every 3 minutes</string>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>-c</string>
      <string>
cd "$HOME/.claude-setup" || exit 1
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
  git add -A
  git commit -m "auto: sync claude-setup" --quiet 2>/dev/null
fi
git pull --rebase --quiet origin master 2>/dev/null || true
git push --quiet origin master 2>/dev/null || true
      </string>
    </array>
    <key>StartInterval</key>
    <integer>180</integer>
    <key>StandardOutPath</key>
    <string>/tmp/claude-setup-sync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-setup-sync-error.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key>
      <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
  </dict>
</plist>
PLIST

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"
log "Sync agent installed (every 3 minutes)"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Synced from GitHub:"
echo "  settings.json  - MCP servers, hooks, statusline, permissions"
echo "  agents/        - Custom agent definitions (9 agents)"
echo "  skills/        - Custom skills (~40 skills)"
echo "  hooks/         - Session hooks, formatters, statusline"
echo "  rules/         - Coding standards, memory strategy"
echo "  commands/      - Custom slash commands"
echo "  bin/           - CLI utilities (claude-sync, etc.)"
echo "  memory/        - Turso-backed knowledge graph (cloud-synced)"
echo ""
echo "Auto-sync: every 3 min, bidirectional via launchd"
echo ""
echo "Next steps:"
echo "  1. Restart terminal (or: source ~/.zshrc)"
if [ $SECRETS_MISSING -eq 1 ]; then
  echo "  2. Set up missing secrets: bash ~/.claude-setup/hooks/setup-keychain.sh"
  echo "  3. Run: claude"
else
  echo "  2. Run: claude"
fi
echo ""
echo "Verify:"
echo "  launchctl list | grep claude.setup"
echo "  cat /tmp/claude-setup-sync.log"
