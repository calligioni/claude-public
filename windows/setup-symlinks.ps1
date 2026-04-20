# ============================================================
# Claude Code - Windows Symlink/Junction Setup
# ============================================================
# Creates NTFS junctions (directories) and symlinks/copies
# (files) from the repo to ~/.claude/
#
# Usage:
#   .\windows\setup-symlinks.ps1              # Create links
#   .\windows\setup-symlinks.ps1 -Restore     # Restore from backup
# ============================================================

param(
    [switch]$Restore,
    [string]$RepoDir
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

# Resolve repo directory (parent of windows/)
if (-not $RepoDir) {
    $RepoDir = Split-Path -Parent $PSScriptRoot
}

$ClaudeDir = $script:ClaudeDir
$BackupDir = Join-Path $env:USERPROFILE ".claude-backup-$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ── Restore Mode ─────────────────────────────────────────────
if ($Restore) {
    $latestBackup = Get-ChildItem -Path $env:USERPROFILE -Filter ".claude-backup-*" -Directory |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $latestBackup) {
        Write-Err "No backup found to restore"
        exit 1
    }

    Write-Log "Restoring from $($latestBackup.FullName)"

    foreach ($item in $script:SyncItems) {
        $dest = Join-Path $ClaudeDir $item
        $backupItem = Join-Path $latestBackup.FullName $item

        # Remove current link
        if (Test-Path $dest) {
            $fi = Get-Item $dest -Force
            if ($fi.LinkType) {
                $fi.Delete()
            } else {
                Remove-Item $dest -Recurse -Force
            }
        }

        # Restore from backup
        if (Test-Path $backupItem) {
            Copy-Item -Path $backupItem -Destination $dest -Recurse -Force
            Write-Log "Restored $item"
        }
    }

    Write-Log "Restore complete!"
    exit 0
}

# ── Create Mode ──────────────────────────────────────────────
Write-Log "Claude Config Symlink Setup"
Write-Log "Repo: $RepoDir"
Write-Log "Claude dir: $ClaudeDir"

# Ensure ~/.claude exists
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

# Backup existing config (only non-link items)
Write-Log "Backing up existing config to $BackupDir"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$hasBackup = $false

foreach ($item in $script:SyncItems) {
    $dest = Join-Path $ClaudeDir $item
    if ((Test-Path $dest) -and -not (Get-Item $dest -Force).LinkType) {
        Copy-Item -Path $dest -Destination $BackupDir -Recurse -Force
        Write-Log "Backed up $item"
        $hasBackup = $true
    }
}

if (-not $hasBackup) {
    Remove-Item $BackupDir -Force -ErrorAction SilentlyContinue
}

# Create links
Write-Log "Creating links..."

foreach ($item in $script:SyncItems) {
    $src = Join-Path $RepoDir $item
    $dest = Join-Path $ClaudeDir $item

    # Skip if source doesn't exist
    if (-not (Test-Path $src)) {
        Write-Warn "Source not found: $item (skipping)"
        continue
    }

    # Check if already correctly linked
    if (Test-Path $dest) {
        $fi = Get-Item $dest -Force
        if ($fi.LinkType) {
            $currentTarget = $fi.Target
            if ($currentTarget -eq $src) {
                Write-Log "$item already linked correctly"
                continue
            }
            # Wrong target, remove
            $fi.Delete()
        } else {
            # Regular file/dir, remove (already backed up)
            Remove-Item $dest -Recurse -Force
        }
    }

    # Use settings.json from windows/ instead of repo root
    if ($item -eq "settings.json") {
        $windowsSettings = Join-Path $PSScriptRoot "settings.json"
        if (Test-Path $windowsSettings) {
            $src = $windowsSettings
        }
    }

    New-ClaudeLink -Source $src -Destination $dest
}

# Create directories Claude Code expects
foreach ($dir in @("logs", "projects", "cache")) {
    $dirPath = Join-Path $ClaudeDir $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
    }
}

# ── Install claude-sync command ──────────────────────────────
$binDir = Join-Path $env:USERPROFILE ".local\bin"
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

$syncPs1 = Join-Path $binDir "claude-sync.ps1"
$syncContent = @"
#!/usr/bin/env pwsh
# Claude Config Sync - push/pull config changes
`$ErrorActionPreference = "Stop"
`$RepoDir = "$($RepoDir -replace '\\', '\\')"

Set-Location `$RepoDir

switch (`$args[0]) {
    "push" {
        Write-Host "[+] Pushing config changes..." -ForegroundColor Green
        git add -A
        git commit -m "sync: `$(`$env:COMPUTERNAME) `$(Get-Date -Format 'yyyy-MM-dd')" 2>`$null
        if (`$LASTEXITCODE -ne 0) { Write-Host "[+] Nothing to commit" -ForegroundColor Green }
        git push
        Write-Host "[+] Done!" -ForegroundColor Green
    }
    "pull" {
        Write-Host "[+] Pulling latest config..." -ForegroundColor Green
        git pull --rebase
        Write-Host "[+] Done!" -ForegroundColor Green
    }
    "pull-upstream" {
        Write-Host "[+] Pulling from upstream (local wins on conflicts)..." -ForegroundColor Green
        git fetch upstream 2>`$null
        if (`$LASTEXITCODE -ne 0) {
            Write-Host "[!] upstream remote not configured. Run:" -ForegroundColor Yellow
            Write-Host "  git remote add upstream https://github.com/escotilha/claude-public.git"
            exit 1
        }
        git merge upstream/main --strategy-option ours --no-edit
        Write-Host "[+] Done! New items from upstream merged, your files preserved." -ForegroundColor Green
    }
    "status" {
        git status --short
        git log --oneline -5
    }
    default {
        Write-Host "Usage: claude-sync [push|pull|pull-upstream|status]"
    }
}
"@

Set-Content -Path $syncPs1 -Value $syncContent -Encoding UTF8

# Create .cmd wrapper for CMD users
$syncCmd = Join-Path $binDir "claude-sync.cmd"
$cmdContent = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%USERPROFILE%\.local\bin\claude-sync.ps1`" %*"
Set-Content -Path $syncCmd -Value $cmdContent -Encoding ASCII

Write-Log "Installed: claude-sync command"

# Check PATH
if ($env:PATH -notlike "*$binDir*") {
    Write-Warn "Add to PATH: $binDir"
    Write-Info "This will be configured by install.ps1"
}

Write-Host ""
Write-Log "Symlink setup complete!"
Write-Host ""
Write-Host "Usage:"
Write-Host "  claude-sync status        - Show pending changes"
Write-Host "  claude-sync push          - Commit and push config"
Write-Host "  claude-sync pull          - Pull latest config"
Write-Host "  claude-sync pull-upstream - Merge upstream (local wins)"
