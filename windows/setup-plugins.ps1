# ============================================================
# Claude Code - Plugin Setup
# ============================================================
# Installs plugins listed in plugins-manifest.json by
# reconstructing the installed_plugins.json and letting
# Claude Code re-download them on next launch.
#
# Also ensures settings.json has the plugins enabled.
#
# Usage:
#   .\windows\setup-plugins.ps1
# ============================================================

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

Write-Log "Setting up Claude Code plugins..."

$ManifestFile = Join-Path $PSScriptRoot "plugins-manifest.json"
$PluginsDir = Join-Path $script:ClaudeDir "plugins"
$InstalledFile = Join-Path $PluginsDir "installed_plugins.json"
$MarketplacesFile = Join-Path $PluginsDir "known_marketplaces.json"
$SettingsFile = Join-Path $script:ClaudeDir "settings.json"

# ── Read manifest ────────────────────────────────────────────
if (-not (Test-Path $ManifestFile)) {
    Write-Err "Manifest not found: $ManifestFile"
    exit 1
}

$manifest = Get-Content $ManifestFile -Raw | ConvertFrom-Json
$marketplace = $manifest.marketplace
$marketplaceRepo = $manifest.marketplaceRepo
$plugins = $manifest.plugins

Write-Log "Found $($plugins.Count) plugins in manifest: $($plugins -join ', ')"

# ── Ensure plugins directory exists ──────────────────────────
foreach ($subdir in @("", "cache", "data", "marketplaces", "repos")) {
    $dir = Join-Path $PluginsDir $subdir
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ── Create known_marketplaces.json ───────────────────────────
$marketplacePath = Join-Path $PluginsDir "marketplaces\$marketplace"
$marketplaces = @{
    $marketplace = @{
        source = @{
            source = "github"
            repo = $marketplaceRepo
        }
        installLocation = $marketplacePath
        lastUpdated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
}

$marketplacesJson = $marketplaces | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($MarketplacesFile, $marketplacesJson, (New-Object System.Text.UTF8Encoding $false))
Write-Log "Written known_marketplaces.json"

# ── Create installed_plugins.json ────────────────────────────
$pluginsHash = @{}
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

foreach ($plugin in $plugins) {
    $pluginId = "$plugin@$marketplace"
    $installPath = Join-Path $PluginsDir "cache\$marketplace\$plugin\unknown"

    # Create cache directory
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }

    $pluginsHash[$pluginId] = @(
        @{
            scope = "user"
            installPath = $installPath
            version = "unknown"
            installedAt = $now
            lastUpdated = $now
            gitCommitSha = ""
        }
    )
}

$installed = @{
    version = 2
    plugins = $pluginsHash
}

$installedJson = $installed | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($InstalledFile, $installedJson, (New-Object System.Text.UTF8Encoding $false))
Write-Log "Written installed_plugins.json ($($plugins.Count) plugins)"

# ── Ensure settings.json has enabledPlugins ──────────────────
if (Test-Path $SettingsFile) {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json

    $needsUpdate = $false
    if (-not $settings.enabledPlugins) {
        $settings | Add-Member -NotePropertyName "enabledPlugins" -NotePropertyValue @{} -Force
        $needsUpdate = $true
    }

    foreach ($plugin in $plugins) {
        $pluginId = "$plugin@$marketplace"
        if (-not $settings.enabledPlugins.$pluginId) {
            $settings.enabledPlugins | Add-Member -NotePropertyName $pluginId -NotePropertyValue $true -Force
            $needsUpdate = $true
        }
    }

    if ($needsUpdate) {
        $settingsJson = $settings | ConvertTo-Json -Depth 5
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
Write-Host "  Plugins registered:" -ForegroundColor Cyan
foreach ($plugin in $plugins) {
    Write-Host "    - $plugin" -ForegroundColor White
}
Write-Host ""
Write-Info "Claude Code will download plugin files on next launch."
Write-Info "If plugins don't appear, run: /plugin (inside Claude Code)"
