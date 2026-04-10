#!/bin/bash
#
# Claude Code Setup Script
# Run this on any Mac to set up Claude Code with git-synced skills, agents, and commands.
#
# Usage:
#   curl -sL "file://$HOME/.claude-setup/setup-mac.sh" | bash
#   OR
#   bash "/Users/$(whoami)/.claude-setup/setup-mac.sh"
#

set -e

SETUP_DIR="$HOME/.claude-setup"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Git-Synced Setup ==="
echo ""

# Check if git repo exists
if [ ! -d "$SETUP_DIR" ]; then
    echo "ERROR: claude-setup repo not found at:"
    echo "  $SETUP_DIR"
    echo ""
    echo "Clone it first:"
    echo "  git clone https://github.com/escotilha/claude.git ~/.claude-setup"
    exit 1
fi

echo "Found claude-setup repo at: $SETUP_DIR"
echo ""

# Create ~/.claude if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating $CLAUDE_DIR..."
    mkdir -p "$CLAUDE_DIR"
fi

# Function to create symlink safely
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ]; then
        # Already a symlink - check if it points to the right place
        current=$(readlink "$target")
        if [ "$current" = "$source" ]; then
            echo "✓ $name already linked correctly"
            return
        else
            echo "  Updating $name symlink..."
            rm "$target"
        fi
    elif [ -e "$target" ]; then
        # Exists but not a symlink - back it up
        echo "  Backing up existing $name to ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    ln -s "$source" "$target"
    echo "✓ Linked $name"
}

echo "Setting up symlinks..."
echo ""

# Core symlinks - all synced via git
create_symlink "$SETUP_DIR/skills" "$CLAUDE_DIR/skills" "skills"
create_symlink "$SETUP_DIR/agents" "$CLAUDE_DIR/agents" "agents"
create_symlink "$SETUP_DIR/commands" "$CLAUDE_DIR/commands" "commands"
create_symlink "$SETUP_DIR/hooks" "$CLAUDE_DIR/hooks" "hooks"

# Copy settings.json (not symlinked - may have machine-specific paths)
if [ -f "$SETUP_DIR/settings.json" ]; then
    if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
        echo "Copying settings.json from repo..."
        cp "$SETUP_DIR/settings.json" "$CLAUDE_DIR/settings.json"
        echo "✓ Settings copied"
    else
        echo "✓ settings.json already exists (not overwritten)"
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your Claude Code is now configured with:"
echo "  Skills:   $(ls -1 "$CLAUDE_DIR/skills" 2>/dev/null | wc -l | tr -d ' ') items"
echo "  Agents:   $(ls -1 "$CLAUDE_DIR/agents" 2>/dev/null | wc -l | tr -d ' ') items"
echo "  Commands: $(ls -1 "$CLAUDE_DIR/commands" 2>/dev/null | wc -l | tr -d ' ') items"
echo "  Hooks:    $(ls -1 "$CLAUDE_DIR/hooks" 2>/dev/null | wc -l | tr -d ' ') items"
echo ""
echo "All changes sync automatically via git (run /cs or git pull)."
echo ""

# Verify Claude Code is installed
if command -v claude &> /dev/null; then
    echo "Claude Code CLI: $(claude --version 2>/dev/null || echo 'installed')"
else
    echo "NOTE: Claude Code CLI not found. Install with:"
    echo "  npm install -g @anthropic-ai/claude-code"
fi
