# ============================================================
# Claude Code - Plugin Export
# ============================================================
# Regenerates windows/plugins-manifest.json from the LIVE state
# in ~/.claude, so the manifest never goes stale.
#
# Reads:
#   ~/.claude/plugins/known_marketplaces.json  -> marketplaces
#   ~/.claude/settings.json (enabledPlugins)   -> plugin list
#   ~/.claude/plugins/installed_plugins.json   -> fallback plugin list
#
# Run this BEFORE `claude-sync push` to capture newly installed
# plugins.
#
# Usage:
#   .\windows\export-plugins.ps1
# ============================================================

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

Write-Log "Exporting live plugin state to manifest..."

$PluginsDir       = Join-Path $script:ClaudeDir "plugins"
$MarketplacesFile = Join-Path $PluginsDir "known_marketplaces.json"
$InstalledFile    = Join-Path $PluginsDir "installed_plugins.json"
$SettingsFile     = Join-Path $script:ClaudeDir "settings.json"
$ManifestFile     = Join-Path $PSScriptRoot "plugins-manifest.json"

# ── Marketplaces (strip machine-specific installLocation/lastUpdated) ──
$marketplaces = @()
if (Test-Path $MarketplacesFile) {
    $mk = Get-Content $MarketplacesFile -Raw | ConvertFrom-Json
    foreach ($prop in $mk.PSObject.Properties) {
        $name = $prop.Name
        $src  = $prop.Value.source
        $entry = [ordered]@{ name = $name; source = $src.source }
        if ($src.source -eq "github") {
            $entry.repo = $src.repo
        } elseif ($src.source -eq "git") {
            $entry.url = $src.url
        } else {
            # Unknown source type: keep repo/url if present
            if ($src.repo) { $entry.repo = $src.repo }
            if ($src.url)  { $entry.url  = $src.url }
        }
        $marketplaces += $entry
        Write-Info "marketplace: $name ($($src.source))"
    }
} else {
    Write-Warn "known_marketplaces.json not found - manifest will have no marketplaces"
}

# ── Plugins: prefer enabledPlugins from settings.json ────────────────
$plugins = @()
if (Test-Path $SettingsFile) {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
    if ($settings.enabledPlugins) {
        foreach ($prop in $settings.enabledPlugins.PSObject.Properties) {
            if ($prop.Value -eq $true) { $plugins += $prop.Name }
        }
    }
}

# Fallback: if no enabledPlugins, take everything from installed_plugins.json
if ($plugins.Count -eq 0 -and (Test-Path $InstalledFile)) {
    Write-Warn "No enabledPlugins in settings.json - falling back to installed_plugins.json"
    $installed = Get-Content $InstalledFile -Raw | ConvertFrom-Json
    if ($installed.plugins) {
        foreach ($prop in $installed.plugins.PSObject.Properties) {
            $plugins += $prop.Name
        }
    }
}

$plugins = $plugins | Sort-Object -Unique
Write-Log "Found $($plugins.Count) plugins across $($marketplaces.Count) marketplaces"

# ── Write manifest ───────────────────────────────────────────────────
$manifest = [ordered]@{
    description  = "Plugins/marketplaces a instalar em novas maquinas. Usado por setup-plugins.ps1. Gerado por export-plugins.ps1."
    marketplaces = $marketplaces
    plugins      = $plugins
}

$json = $manifest | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($ManifestFile, $json, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Log "Wrote $ManifestFile"
Write-Info "Review with: git diff windows/plugins-manifest.json"
Write-Info "Then: claude-sync push"
