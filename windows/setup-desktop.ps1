# ============================================================
# Claude Code - Claude Desktop Configuration
# ============================================================
# Generates claude_desktop_config.json from template,
# replacing {{PLACEHOLDERS}} with values from Credential
# Manager and detected paths.
#
# Usage:
#   .\windows\setup-desktop.ps1
# ============================================================

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

$RepoDir = Split-Path -Parent $PSScriptRoot
$DesktopDir = $script:DesktopConfigDir
$ConfigFile = Join-Path $DesktopDir "claude_desktop_config.json"
$TemplateFile = Join-Path $PSScriptRoot "claude_desktop_config.template.json"

Write-Log "Configuring Claude Desktop..."

# ── Check template exists ────────────────────────────────────
if (-not (Test-Path $TemplateFile)) {
    Write-Err "Template not found: $TemplateFile"
    exit 1
}

# ── Check Claude Desktop directory ───────────────────────────
if (-not (Test-Path $DesktopDir)) {
    Write-Warn "Claude Desktop directory not found: $DesktopDir"
    Write-Info "Install Claude Desktop first, then re-run this script"
    exit 0
}

# ── Read template ────────────────────────────────────────────
$config = Get-Content $TemplateFile -Raw -Encoding UTF8

# ── Resolve paths ────────────────────────────────────────────
# Install dir (for deskmanager-mcp.js path)
$installDir = $script:InstallDir
if (-not (Test-Path $installDir)) {
    $installDir = $RepoDir
}
$config = $config -replace '\{\{INSTALL_DIR\}\}', ($installDir -replace '\\', '\\')

# UVX path (Python uvx for mcp-obsidian)
$uvxPath = ""
$uvxCandidates = @(
    "$env:APPDATA\Python\Python312\Scripts\uvx.exe"
    "$env:APPDATA\Python\Python311\Scripts\uvx.exe"
    "$env:APPDATA\Python\Python310\Scripts\uvx.exe"
    "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts\uvx.exe"
    "$env:LOCALAPPDATA\Programs\Python\Python311\Scripts\uvx.exe"
)

foreach ($candidate in $uvxCandidates) {
    if (Test-Path $candidate) {
        $uvxPath = $candidate
        break
    }
}

# Also try which/where
if (-not $uvxPath) {
    try {
        $uvxPath = (Get-Command uvx -ErrorAction Stop).Source
    } catch {
        $uvxPath = "uvx"
    }
}

$config = $config -replace '\{\{UVX_PATH\}\}', ($uvxPath -replace '\\', '\\')

# ── Replace secret placeholders ──────────────────────────────
$placeholders = @{
    "SQLSERVER_HOST"        = "sqlserver-host"
    "SQLSERVER_USER"        = "sqlserver-user"
    "SQLSERVER_PASSWORD"    = "sqlserver-password"
    "SQLSERVER_DATABASE"    = "sqlserver-database"
    "DESKMANAGER_API_KEY"   = "deskmanager-api-key"
    "DESKMANAGER_PUBLIC_KEY"= "deskmanager-public-key"
    "OBSIDIAN_API_KEY"      = "obsidian-api-key"
}

$missingSecrets = @()

foreach ($entry in $placeholders.GetEnumerator()) {
    $placeholder = "{{$($entry.Key)}}"
    $credName = $entry.Value
    $value = Get-ClaudeSecret -Name $credName

    if ($null -ne $value -and $value.Length -gt 0) {
        $config = $config -replace [regex]::Escape($placeholder), $value
        Write-Log "  $($entry.Key): set from Credential Manager"
    } else {
        $missingSecrets += $entry.Key
        Write-Warn "  $($entry.Key): not found in Credential Manager (placeholder kept)"
    }
}

# ── Backup existing config ───────────────────────────────────
if (Test-Path $ConfigFile) {
    $backupName = "claude_desktop_config.json.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    $backupPath = Join-Path $DesktopDir $backupName
    Copy-Item $ConfigFile $backupPath
    Write-Log "Backed up existing config to $backupName"
}

# ── Write new config (UTF-8 WITHOUT BOM — required for Claude Desktop) ──
[System.IO.File]::WriteAllText($ConfigFile, $config, (New-Object System.Text.UTF8Encoding $false))
Write-Log "Claude Desktop config written to $ConfigFile"

# ── Summary ──────────────────────────────────────────────────
if ($missingSecrets.Count -gt 0) {
    Write-Host ""
    Write-Warn "Some MCP servers have missing credentials."
    Write-Warn "Run setup-credentials.ps1 to configure, then re-run this script:"
    Write-Host "  .\windows\setup-credentials.ps1"
    Write-Host "  .\windows\setup-desktop.ps1"
}

Write-Host ""
Write-Info "Restart Claude Desktop to apply changes."
