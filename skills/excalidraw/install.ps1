# excalidraw skill installer (Windows / PowerShell)
# Builds the MCP server and registers it with Claude Code.
# Idempotent: safe to re-run.

$ErrorActionPreference = "Stop"
$skillDir = Join-Path $env:USERPROFILE ".claude\skills\excalidraw"
$mcpDir = Join-Path $skillDir "mcp-server"
$serverPath = Join-Path $mcpDir "dist\index.js"

Write-Host "==> Checking prerequisites..." -ForegroundColor Cyan
foreach ($cmd in @("node", "npm", "claude")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: '$cmd' not found on PATH." -ForegroundColor Red
        if ($cmd -eq "claude") { Write-Host "       Install Claude Code from https://claude.com/claude-code" -ForegroundColor Yellow }
        elseif ($cmd -eq "node" -or $cmd -eq "npm") { Write-Host "       Install Node >= 18 from https://nodejs.org" -ForegroundColor Yellow }
        exit 1
    }
}
$nodeVer = (& node --version).TrimStart("v").Split(".")[0]
if ([int]$nodeVer -lt 18) {
    Write-Host "ERROR: Node $nodeVer detected. excalidraw MCP requires Node >= 18." -ForegroundColor Red
    exit 1
}
Write-Host "    Node $(node --version), npm $(npm --version), claude OK" -ForegroundColor Green

if (-not (Test-Path $mcpDir)) {
    Write-Host "ERROR: MCP server source not found at $mcpDir" -ForegroundColor Red
    Write-Host "       Make sure you copied the full skill folder (including mcp-server/)." -ForegroundColor Yellow
    exit 1
}

Write-Host "==> Installing MCP server dependencies (npm ci)..." -ForegroundColor Cyan
Push-Location $mcpDir
try {
    & npm ci
    if ($LASTEXITCODE -ne 0) { throw "npm ci failed" }

    Write-Host "==> Building MCP server (frontend + server)..." -ForegroundColor Cyan
    & npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build failed" }
} finally {
    Pop-Location
}

if (-not (Test-Path $serverPath)) {
    Write-Host "ERROR: Build artifact missing at $serverPath" -ForegroundColor Red
    exit 1
}

Write-Host "==> Registering MCP server with Claude Code..." -ForegroundColor Cyan
$existing = & claude mcp list 2>&1 | Select-String -Pattern "^excalidraw:"
if ($existing) {
    Write-Host "    Found existing 'excalidraw' MCP entry. Removing before re-adding..." -ForegroundColor Yellow
    & claude mcp remove excalidraw 2>&1 | Out-Null
}

& claude mcp add excalidraw --scope user `
    -e EXPRESS_SERVER_URL=http://127.0.0.1:3000 `
    -e ENABLE_CANVAS_SYNC=true `
    -- node "$serverPath"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: claude mcp add failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done. excalidraw MCP server registered." -ForegroundColor Green
Write-Host "Verify with: claude mcp list" -ForegroundColor Yellow
Write-Host ""
Write-Host "Optional - to enable canvas screenshot + real-time sync, run the canvas server:" -ForegroundColor Yellow
Write-Host "    cd `"$mcpDir`"" -ForegroundColor Yellow
Write-Host "    npm run canvas    # opens http://127.0.0.1:3000" -ForegroundColor Yellow
