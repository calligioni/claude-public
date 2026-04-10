# ============================================================
# Claude Code - Build Local MCP Servers
# ============================================================
# Installs dependencies and builds MCP servers that require
# compilation. Run after cloning or when servers are updated.
#
# Usage:
#   .\windows\setup-mcp-servers.ps1
# ============================================================

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

$RepoDir = Split-Path -Parent $PSScriptRoot

Write-Log "Building local MCP servers..."

# ── memory-turso ─────────────────────────────────────────────
$memoryMcp = Join-Path $RepoDir "mcp-servers\memory-turso"
$packageJson = Join-Path $memoryMcp "package.json"

if (Test-Path $packageJson) {
    $distDir = Join-Path $memoryMcp "dist"
    $srcIndex = Join-Path $memoryMcp "src\index.ts"
    $distIndex = Join-Path $memoryMcp "dist\index.js"

    $needsBuild = (-not (Test-Path $distDir))
    if (-not $needsBuild -and (Test-Path $srcIndex) -and (Test-Path $distIndex)) {
        $srcTime = (Get-Item $srcIndex).LastWriteTime
        $distTime = (Get-Item $distIndex).LastWriteTime
        $needsBuild = $srcTime -gt $distTime
    }

    if ($needsBuild) {
        Write-Log "Building memory-turso..."
        Push-Location $memoryMcp
        try {
            npm install --silent 2>$null
            npm run build --silent 2>$null
            Write-Log "memory-turso built successfully"
        } catch {
            Write-Warn "memory-turso build failed: $_"
        } finally {
            Pop-Location
        }
    } else {
        Write-Log "memory-turso already built"
    }
} else {
    Write-Info "memory-turso not found (skipping)"
}

# ── deskmanager-mcp ──────────────────────────────────────────
$deskMcp = Join-Path $RepoDir "mcp-servers"
$deskPackage = Join-Path $deskMcp "package.json"

if (Test-Path $deskPackage) {
    $nodeModules = Join-Path $deskMcp "node_modules"
    if (-not (Test-Path $nodeModules)) {
        Write-Log "Installing deskmanager-mcp dependencies..."
        Push-Location $deskMcp
        try {
            npm install --silent 2>$null
            Write-Log "deskmanager-mcp dependencies installed"
        } catch {
            Write-Warn "deskmanager-mcp install failed: $_"
        } finally {
            Pop-Location
        }
    } else {
        Write-Log "deskmanager-mcp dependencies already installed"
    }
}

# ── Additional MCP servers ───────────────────────────────────
$buildScript = Join-Path $RepoDir "mcp-servers\build.ps1"
if (Test-Path $buildScript) {
    & $buildScript
}

Write-Log "MCP server build complete!"
