#!/usr/bin/env bash
# excalidraw skill installer (Linux / macOS)
# Builds the MCP server and registers it with Claude Code.
# Idempotent: safe to re-run.

set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/excalidraw"
MCP_DIR="$SKILL_DIR/mcp-server"
SERVER_PATH="$MCP_DIR/dist/index.js"

echo "==> Checking prerequisites..."
for cmd in node npm claude; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: '$cmd' not found on PATH." >&2
        case "$cmd" in
            claude) echo "       Install Claude Code from https://claude.com/claude-code" >&2 ;;
            node|npm) echo "       Install Node >= 18 from https://nodejs.org" >&2 ;;
        esac
        exit 1
    fi
done

NODE_MAJOR="$(node --version | sed 's/^v//' | cut -d. -f1)"
if [ "$NODE_MAJOR" -lt 18 ]; then
    echo "ERROR: Node $NODE_MAJOR detected. excalidraw MCP requires Node >= 18." >&2
    exit 1
fi
echo "    Node $(node --version), npm $(npm --version), claude OK"

if [ ! -d "$MCP_DIR" ]; then
    echo "ERROR: MCP server source not found at $MCP_DIR" >&2
    echo "       Make sure you copied the full skill folder (including mcp-server/)." >&2
    exit 1
fi

echo "==> Installing MCP server dependencies (npm ci)..."
(cd "$MCP_DIR" && npm ci)

echo "==> Building MCP server (frontend + server)..."
(cd "$MCP_DIR" && npm run build)

if [ ! -f "$SERVER_PATH" ]; then
    echo "ERROR: Build artifact missing at $SERVER_PATH" >&2
    exit 1
fi

echo "==> Registering MCP server with Claude Code..."
if claude mcp list 2>&1 | grep -q "^excalidraw:"; then
    echo "    Found existing 'excalidraw' MCP entry. Removing before re-adding..."
    claude mcp remove excalidraw >/dev/null 2>&1 || true
fi

claude mcp add excalidraw --scope user \
    -e EXPRESS_SERVER_URL=http://127.0.0.1:3000 \
    -e ENABLE_CANVAS_SYNC=true \
    -- node "$SERVER_PATH"

echo ""
echo "Done. excalidraw MCP server registered."
echo "Verify with: claude mcp list"
echo ""
echo "Optional - to enable canvas screenshot + real-time sync, run the canvas server:"
echo "    cd \"$MCP_DIR\""
echo "    npm run canvas    # opens http://127.0.0.1:3000"
