# ============================================================
# Claude Code - Auto Sync Script
# ============================================================
# Executed by Task Scheduler every 3 minutes.
# Bidirectional git sync: commit local changes, pull, push.
# ============================================================

$LogFile = Join-Path $env:TEMP "claude-setup-sync.log"
Start-Transcript -Path $LogFile -Force | Out-Null

try {
    $InstallDir = Join-Path $env:USERPROFILE ".claude-setup"

    if (-not (Test-Path (Join-Path $InstallDir ".git"))) {
        Write-Output "Not a git repo: $InstallDir"
        Stop-Transcript | Out-Null
        exit 1
    }

    Set-Location $InstallDir

    # Ensure git is in PATH (common install locations)
    $gitPaths = @(
        "C:\Program Files\Git\cmd"
        "C:\Program Files (x86)\Git\cmd"
        "$env:LOCALAPPDATA\Programs\Git\cmd"
        "$env:ProgramFiles\Git\cmd"
    )
    foreach ($gp in $gitPaths) {
        if ((Test-Path $gp) -and ($env:PATH -notlike "*$gp*")) {
            $env:PATH = "$gp;$env:PATH"
            break
        }
    }

    # Check for local changes
    $diffExit = 0
    git diff --quiet 2>$null
    if ($LASTEXITCODE -ne 0) { $diffExit = 1 }

    git diff --cached --quiet 2>$null
    if ($LASTEXITCODE -ne 0) { $diffExit = 1 }

    $untracked = git ls-files --others --exclude-standard 2>$null
    if ($untracked) { $diffExit = 1 }

    # Commit local changes if any
    if ($diffExit -ne 0) {
        git add -A
        git commit -m "auto: sync claude-setup" --quiet 2>$null
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Committed local changes"
    }

    # Pull with rebase
    git pull --rebase --quiet origin master 2>$null
    if ($LASTEXITCODE -ne 0) {
        git pull --rebase --quiet origin main 2>$null
    }

    # Push
    git push --quiet origin master 2>$null
    if ($LASTEXITCODE -ne 0) {
        git push --quiet origin main 2>$null
    }

    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Sync complete"

} catch {
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - ERROR: $_"
} finally {
    Stop-Transcript | Out-Null
}
