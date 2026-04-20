# ============================================================
# Claude Code - Full Setup for Windows
# ============================================================
# Replicates the entire Claude Code environment on Windows.
# Configures both Claude CLI (~/.claude/) and Claude Desktop.
#
# Usage (new machine):
#   winget install GitHub.cli jqlang.jq OpenJS.NodeJS
#   gh auth login
#   gh repo clone <your-fork> $env:USERPROFILE\.claude-setup
#   .\windows\install.ps1
#
# Usage (existing machine - update):
#   .\windows\install.ps1
# ============================================================

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

$RepoDir = Split-Path -Parent $PSScriptRoot
$Repo = "https://github.com/escotilha/claude.git"
$UpstreamRepo = "https://github.com/escotilha/claude-public.git"
$TotalSteps = 10

Write-Banner "Claude Code - Full Environment Setup (Windows)"

# ── 1. Prerequisites ─────────────────────────────────────────
Write-Step 1 $TotalSteps "Checking prerequisites..."

# Check execution policy
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted" -or $policy -eq "Undefined") {
    Write-Warn "PowerShell execution policy is '$policy'"
    Write-Host "  Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Write-Host "  Then re-run this script."
    exit 1
}

$missing = @()
$commands = @{
    "git"  = "Git.Git"
    "gh"   = "GitHub.cli"
    "node" = "OpenJS.NodeJS"
    "npm"  = "OpenJS.NodeJS"
    "jq"   = "jqlang.jq"
}

foreach ($entry in $commands.GetEnumerator()) {
    if (Get-Command $entry.Key -ErrorAction SilentlyContinue) {
        Write-Log "$($entry.Key) found"
    } else {
        $missing += $entry.Value
        Write-Err "$($entry.Key) not found"
    }
}

if ($missing.Count -gt 0) {
    $unique = $missing | Sort-Object -Unique
    Write-Host ""
    Write-Warn "Install missing tools:"
    Write-Host "  winget install $($unique -join ' ')"
    exit 1
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Warn "npx not found, installing..."
    npm install -g npx
}

# ── 2. GitHub Auth ───────────────────────────────────────────
Write-Step 2 $TotalSteps "GitHub authentication..."

$ghStatus = gh auth status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "GitHub authenticated"
} else {
    Write-Warn "Not authenticated. Running gh auth login..."
    gh auth login
}
gh auth setup-git 2>$null

# ── 3. Clone / Update Repo ──────────────────────────────────
Write-Step 3 $TotalSteps "Repository..."

$InstallDir = $script:InstallDir

if (Test-Path (Join-Path $InstallDir ".git")) {
    Write-Log "Repo exists, pulling latest..."
    git -C $InstallDir pull --ff-only origin master 2>$null
    if ($LASTEXITCODE -ne 0) {
        git -C $InstallDir pull --ff-only origin main 2>$null
    }
} elseif ($InstallDir -ne $RepoDir) {
    Write-Log "Cloning from GitHub..."
    git clone $Repo $InstallDir
}

# Configure upstream remote for syncing from original repo
Set-Location $InstallDir
$remotes = git remote 2>$null
if ($remotes -notcontains "upstream") {
    git remote add upstream $UpstreamRepo 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Added upstream remote: $UpstreamRepo"
    }
} else {
    Write-Log "Upstream remote already configured"
}

Write-Log "Repo ready at $InstallDir"

# ── 4. Create Symlinks (Claude CLI) ─────────────────────────
Write-Step 4 $TotalSteps "Creating symlinks (Claude CLI)..."

& "$PSScriptRoot\setup-symlinks.ps1" -RepoDir $RepoDir

# ── 5. Build MCP Servers ────────────────────────────────────
Write-Step 5 $TotalSteps "Building MCP servers..."

& "$PSScriptRoot\setup-mcp-servers.ps1"

# ── 6. Credentials ──────────────────────────────────────────
Write-Step 6 $TotalSteps "Checking credentials..."

& "$PSScriptRoot\setup-credentials.ps1" -Check

# ── 7. Shell Profile ────────────────────────────────────────
Write-Step 7 $TotalSteps "Shell profile..."

# Determine PowerShell profile path
$profilePath = $PROFILE
if (-not $profilePath) {
    $profilePath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
}

# Ensure profile directory exists
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Ensure profile file exists
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if (-not $profileContent) { $profileContent = "" }

$changed = $false

# Add load-secrets
$loadSecretsLine = '. "$env:USERPROFILE\.claude-setup\windows\load-secrets.ps1"'
if ($profileContent -notlike "*load-secrets.ps1*") {
    Add-Content -Path $profilePath -Value "`n# Claude Code - load secrets from Credential Manager`n$loadSecretsLine"
    $changed = $true
}

# Add bin to PATH
$pathLine = '$env:PATH = "$env:USERPROFILE\.claude\bin;$env:USERPROFILE\.local\bin;$env:PATH"'
if ($profileContent -notlike "*\.claude\bin*") {
    Add-Content -Path $profilePath -Value "`n# Claude Code - bin in PATH`n$pathLine"
    $changed = $true
}

if ($changed) {
    Write-Log "Updated $profilePath"
} else {
    Write-Log "Profile already configured"
}

# ── 8. Task Scheduler (Auto-Sync) ───────────────────────────
Write-Step 8 $TotalSteps "Auto-sync agent..."

& "$PSScriptRoot\setup-task-scheduler.ps1"

# ── 9. Plugins ───────────────────────────────────────────────
Write-Step 9 $TotalSteps "Plugins..."

& "$PSScriptRoot\setup-plugins.ps1"

# ── 10. Claude Desktop ──────────────────────────────────────
Write-Step 10 $TotalSteps "Claude Desktop configuration..."

& "$PSScriptRoot\setup-desktop.ps1"

# ── Summary ──────────────────────────────────────────────────
Write-Banner "Setup Complete!"

Write-Host "Configured for both Claude CLI and Claude Desktop:"
Write-Host ""
Write-Host "  Claude CLI (~/.claude/):"
Write-Host "    settings.json  - Permissions, plugins, env vars"
Write-Host "    agents/        - Custom agent definitions"
Write-Host "    skills/        - Custom skills"
Write-Host "    mcp-servers/   - MCP server scripts"
Write-Host ""
Write-Host "  Claude Desktop (%APPDATA%\Claude\):"
Write-Host "    claude_desktop_config.json - MCP servers with credentials"
Write-Host ""
Write-Host "  Auto-sync: every 3 min via Task Scheduler"
Write-Host "  Upstream:  claude-sync pull-upstream (manual)"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Restart terminal (or: . `$PROFILE)"
Write-Host "  2. Restart Claude Desktop (if running)"

$hasRequired = $true
foreach ($s in ($script:ClaudeSecrets | Where-Object { $_.Required })) {
    if (-not (Test-ClaudeSecret -Name $s.Name)) { $hasRequired = $false; break }
}

if (-not $hasRequired) {
    Write-Host "  3. Set up missing secrets: .\windows\setup-credentials.ps1"
    Write-Host "  4. Re-run desktop config:  .\windows\setup-desktop.ps1"
    Write-Host "  5. Run: claude"
} else {
    Write-Host "  3. Run: claude"
}

Write-Host ""
Write-Host "Verify:" -ForegroundColor DarkGray
Write-Host "  Get-ScheduledTask -TaskName 'ClaudeSetupSync'" -ForegroundColor DarkGray
Write-Host "  Get-Content `$env:TEMP\claude-setup-sync.log" -ForegroundColor DarkGray
Write-Host "  cmdkey /list:claude-code-*" -ForegroundColor DarkGray
