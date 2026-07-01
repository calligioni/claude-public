# ============================================================
# Claude Code - Plugin Setup (import)
# ============================================================
# Reconstructs plugin state from windows/plugins-manifest.json:
#   - known_marketplaces.json (one entry per marketplace)
#   - installed_plugins.json  (one entry per plugin, forged so
#     Claude Code re-downloads on next launch)
#   - settings.json enabledPlugins (enables each plugin)
#
# Machine-specific paths (installLocation / installPath) are
# recomputed locally and never come from the committed manifest.
#
# Supports multiple marketplaces and both source types:
#   github -> { source: "github", repo: "owner/name" }
#   git    -> { source: "git",    url:  "https://.../repo.git" }
#
# Usage:
#   .\windows\setup-plugins.ps1
# ============================================================

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

Write-Log "Setting up Claude Code plugins..."

$ManifestFile     = Join-Path $PSScriptRoot "plugins-manifest.json"
$PluginsDir       = Join-Path $script:ClaudeDir "plugins"
$InstalledFile    = Join-Path $PluginsDir "installed_plugins.json"
$MarketplacesFile = Join-Path $PluginsDir "known_marketplaces.json"
$SettingsFile     = Join-Path $script:ClaudeDir "settings.json"

# ── Read manifest ────────────────────────────────────────────
if (-not (Test-Path $ManifestFile)) {
    Write-Err "Manifest not found: $ManifestFile"
    exit 1
}

$manifest     = Get-Content $ManifestFile -Raw | ConvertFrom-Json
$marketplaces = $manifest.marketplaces
$plugins      = $manifest.plugins

if (-not $marketplaces -or $marketplaces.Count -eq 0) {
    Write-Err "Manifest has no marketplaces. Run export-plugins.ps1 first."
    exit 1
}

Write-Log "Manifest: $($plugins.Count) plugins across $($marketplaces.Count) marketplaces"

# ── Ensure plugins directory tree exists ─────────────────────
foreach ($subdir in @("", "cache", "data", "marketplaces", "repos")) {
    $dir = Join-Path $PluginsDir $subdir
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# ── Build known_marketplaces.json ────────────────────────────
$marketplacesHash = @{}
foreach ($mk in $marketplaces) {
    $name = $mk.name
    $installLocation = Join-Path $PluginsDir "marketplaces\$name"

    if ($mk.source -eq "github") {
        $sourceObj = @{ source = "github"; repo = $mk.repo }
    } elseif ($mk.source -eq "git") {
        $sourceObj = @{ source = "git"; url = $mk.url }
    } else {
        Write-Warn "Unknown source type '$($mk.source)' for '$name' - skipping"
        continue
    }

    $marketplacesHash[$name] = @{
        source          = $sourceObj
        installLocation = $installLocation
        lastUpdated     = $now
    }
    Write-Log "marketplace: $name ($($mk.source))"
}

$marketplacesJson = $marketplacesHash | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($MarketplacesFile, $marketplacesJson, (New-Object System.Text.UTF8Encoding $false))
Write-Log "Written known_marketplaces.json"

# ── Build installed_plugins.json ─────────────────────────────
$pluginsHash = @{}
foreach ($pluginId in $plugins) {
    # pluginId is "plugin@marketplace"
    $parts = $pluginId -split "@", 2
    if ($parts.Count -ne 2) {
        Write-Warn "Malformed plugin id '$pluginId' (expected plugin@marketplace) - skipping"
        continue
    }
    $pluginName  = $parts[0]
    $marketplace = $parts[1]
    $installPath = Join-Path $PluginsDir "cache\$marketplace\$pluginName\unknown"

    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }

    $pluginsHash[$pluginId] = @(
        @{
            scope        = "user"
            installPath  = $installPath
            version      = "unknown"
            installedAt  = $now
            lastUpdated  = $now
            gitCommitSha = ""
        }
    )
}

$installed = @{
    version = 2
    plugins = $pluginsHash
}

$installedJson = $installed | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($InstalledFile, $installedJson, (New-Object System.Text.UTF8Encoding $false))
Write-Log "Written installed_plugins.json ($($plugins.Count) plugins)"

# ── Ensure settings.json has enabledPlugins ──────────────────
if (Test-Path $SettingsFile) {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json

    $needsUpdate = $false
    if (-not $settings.enabledPlugins) {
        $settings | Add-Member -NotePropertyName "enabledPlugins" -NotePropertyValue ([PSCustomObject]@{}) -Force
        $needsUpdate = $true
    }

    foreach ($pluginId in $plugins) {
        if (-not $settings.enabledPlugins.$pluginId) {
            $settings.enabledPlugins | Add-Member -NotePropertyName $pluginId -NotePropertyValue $true -Force
            $needsUpdate = $true
        }
    }

    if ($needsUpdate) {
        $settingsJson = $settings | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($SettingsFile, $settingsJson, (New-Object System.Text.UTF8Encoding $false))
        Write-Log "Updated settings.json with enabledPlugins"
    } else {
        Write-Log "settings.json already has all plugins enabled"
    }
} else {
    Write-Warn "settings.json not found - plugins enabled in manifest only"
}

# ── Summary ──────────────────────────────────────────────────
Write-Host ""
Write-Log "Plugin setup complete!"
Write-Host ""
Write-Host "  Marketplaces:" -ForegroundColor Cyan
foreach ($mk in $marketplaces) {
    Write-Host "    - $($mk.name) ($($mk.source))" -ForegroundColor White
}
Write-Host "  Plugins registered: $($plugins.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Info "Claude Code will download plugin files on next launch."
Write-Info "If plugins don't appear, run: /plugin (inside Claude Code)"
