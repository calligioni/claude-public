#!/bin/bash
# Claude Setup - Bootstrap installer for new Macs
# Usage:
#   gh repo clone escotilha/claude ~/.claude-setup && bash ~/.claude-setup/install.sh
#   or if already cloned:
#   bash ~/.claude-setup/install.sh

set -euo pipefail

REPO="https://github.com/escotilha/claude.git"
INSTALL_DIR="$HOME/.claude-setup"
PLIST_NAME="com.claude.setup-sync"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"

echo "=== Claude Setup Installer ==="
echo ""

# 1. Check prerequisites
echo "[1/6] Checking prerequisites..."
for cmd in git gh; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "  x $cmd not found. Install with: brew install $cmd"
    exit 1
  fi
done
echo "  ok git and gh found"

# 2. Authenticate with GitHub
echo "[2/6] Checking GitHub auth..."
if ! gh auth status &>/dev/null; then
  echo "  -> Logging in to GitHub..."
  gh auth login
fi
gh auth setup-git
echo "  ok GitHub authenticated"

# 3. Clone the repo (if not already present)
echo "[3/6] Cloning claude-setup..."
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "  -> Already cloned, pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only origin master
elif [ -L "$INSTALL_DIR" ] && [ -d "$(readlink "$INSTALL_DIR")/.git" ]; then
  REAL_DIR=$(readlink "$INSTALL_DIR")
  echo "  -> Symlink to $REAL_DIR, pulling latest..."
  git -C "$REAL_DIR" pull --ff-only origin master
else
  git clone "$REPO" "$INSTALL_DIR"
fi
echo "  ok Repo ready at $INSTALL_DIR"

# 4. Build MCP servers
echo "[4/6] Building MCP servers..."
if [ -f "$INSTALL_DIR/mcp-servers/build.sh" ]; then
  bash "$INSTALL_DIR/mcp-servers/build.sh"
  echo "  ok MCP servers built"
else
  echo "  -- No build script found, skipping"
fi

# 5. Link settings into Claude Code
echo "[5/6] Linking settings..."
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

if [ -L "$CLAUDE_DIR/settings.json" ]; then
  echo "  ok settings.json already linked"
elif [ -f "$CLAUDE_DIR/settings.json" ]; then
  BACKUP="$CLAUDE_DIR/settings.json.bak.$(date +%Y%m%d%H%M%S)"
  mv "$CLAUDE_DIR/settings.json" "$BACKUP"
  ln -s "$INSTALL_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "  ok Backed up existing to $BACKUP, linked new"
else
  ln -s "$INSTALL_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  echo "  ok Linked settings.json"
fi

# 6. Install launchd sync agent
echo "[6/6] Installing sync agent (every 3 minutes)..."
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
echo "  ok Sync agent installed and running"

echo ""
echo "=== Done ==="
echo ""
echo "Claude Code setup is now synced from GitHub."
echo "Changes sync bidirectionally every 3 minutes."
echo ""
echo "Verify:     launchctl list | grep claude.setup"
echo "Sync logs:  /tmp/claude-setup-sync.log"
echo "Errors:     /tmp/claude-setup-sync-error.log"
echo ""
echo "Note: Make sure your environment variables are set"
echo "(GITHUB_TOKEN, BRAVE_API_KEY, RESEND_API_KEY, etc.)"
echo "in your shell profile (~/.zshrc or ~/.zshenv)."
