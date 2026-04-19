#!/bin/bash
# Build local MCP servers that require compilation
# Run this after cloning the repo or when MCP servers are updated

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

log "Building local MCP servers..."

# Build memory-turso
if [ -d "$SCRIPT_DIR/mcp-servers/memory-turso" ]; then
    log "Building memory-turso..."
    cd "$SCRIPT_DIR/mcp-servers/memory-turso"
    npm install
    npm run build
    log "✓ memory-turso built successfully"
else
    warn "memory-turso not found, skipping"
fi

# Add more MCP servers here as needed
# if [ -d "$SCRIPT_DIR/mcp-servers/other-server" ]; then
#     log "Building other-server..."
#     cd "$SCRIPT_DIR/mcp-servers/other-server"
#     npm install
#     npm run build
# fi

log "MCP server build complete!"
