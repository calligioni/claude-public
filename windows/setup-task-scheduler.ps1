# ============================================================
# Claude Code - Task Scheduler Setup (Auto-Sync)
# ============================================================
# Registers a Windows Task Scheduler job that runs
# claude-auto-sync.ps1 every 3 minutes.
#
# Usage:
#   .\windows\setup-task-scheduler.ps1            # Install
#   .\windows\setup-task-scheduler.ps1 -Remove    # Uninstall
# ============================================================

param(
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

$TaskName = "ClaudeSetupSync"
$SyncScript = Join-Path $PSScriptRoot "claude-auto-sync.ps1"

# ── Remove Mode ──────────────────────────────────────────────
if ($Remove) {
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Log "Removed scheduled task: $TaskName"
    } catch {
        Write-Warn "Task '$TaskName' not found or already removed"
    }
    exit 0
}

# ── Install Mode ─────────────────────────────────────────────
Write-Log "Setting up auto-sync scheduled task..."

# Remove existing if present
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Resolve PowerShell path
$psExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
if (-not $psExe) {
    $psExe = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
}
if (-not $psExe) {
    $psExe = "powershell.exe"
}

# Create the task
$action = New-ScheduledTaskAction `
    -Execute $psExe `
    -Argument "-NoProfile -NoLogo -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$SyncScript`""

$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 3) `
    -RepetitionDuration ([TimeSpan]::MaxValue)

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Bidirectional claude-setup sync with GitHub every 3 minutes" `
    | Out-Null

Write-Log "Scheduled task '$TaskName' registered (every 3 minutes)"
Write-Info "Log: $env:TEMP\claude-setup-sync.log"
Write-Info "Verify: Get-ScheduledTask -TaskName '$TaskName'"
Write-Info "Remove: .\setup-task-scheduler.ps1 -Remove"
