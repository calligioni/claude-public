# ============================================================
# Claude Code - Windows Credential Manager Setup
# ============================================================
# Interactive setup for storing secrets in Windows Credential
# Manager. Run this on a new machine or to update secrets.
#
# Usage:
#   .\windows\setup-credentials.ps1           # Interactive setup
#   .\windows\setup-credentials.ps1 -Check    # Check status only
# ============================================================

param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

Write-Banner "Claude Code - Credential Setup"

$missingRequired = 0
$configured = 0
$total = $script:ClaudeSecrets.Count

# Check/setup required secrets
Write-Host "  Required:" -ForegroundColor White
foreach ($secret in ($script:ClaudeSecrets | Where-Object { $_.Required })) {
    if (Test-ClaudeSecret -Name $secret.Name) {
        Write-Log $secret.EnvVar
        $configured++
    } else {
        if ($Check) {
            Write-Warn "$($secret.EnvVar) (not set)"
            $missingRequired++
        } else {
            Write-Warn "$($secret.EnvVar) - not configured"
            $input = Read-Host "  Enter $($secret.Prompt) (or press Enter to skip)"
            if ($input -and $input.Trim().Length -gt 0) {
                if (Set-ClaudeSecret -Name $secret.Name -Value $input.Trim()) {
                    Write-Log "Saved $($secret.EnvVar)"
                    $configured++
                } else {
                    Write-Err "Failed to save $($secret.EnvVar)"
                    $missingRequired++
                }
            } else {
                $missingRequired++
            }
        }
    }
}

# Check/setup optional secrets
Write-Host ""
Write-Host "  Optional:" -ForegroundColor White
foreach ($secret in ($script:ClaudeSecrets | Where-Object { -not $_.Required })) {
    if (Test-ClaudeSecret -Name $secret.Name) {
        Write-Log $secret.EnvVar
        $configured++
    } else {
        if ($Check) {
            Write-Info "$($secret.EnvVar) (not set)"
        } else {
            $answer = Read-Host "  Set up $($secret.EnvVar)? (y/N)"
            if ($answer -eq 'y' -or $answer -eq 'Y') {
                $input = Read-Host "  Enter $($secret.Prompt)"
                if ($input -and $input.Trim().Length -gt 0) {
                    if (Set-ClaudeSecret -Name $secret.Name -Value $input.Trim()) {
                        Write-Log "Saved $($secret.EnvVar)"
                        $configured++
                    } else {
                        Write-Err "Failed to save $($secret.EnvVar)"
                    }
                }
            }
        }
    }
}

# Summary
Write-Host ""
Write-Host "  Configured: $configured / $total secrets" -ForegroundColor Cyan

if ($missingRequired -gt 0) {
    Write-Host ""
    Write-Warn "Missing required secrets. Run without -Check to configure:"
    Write-Host "  .\windows\setup-credentials.ps1"
}

Write-Host ""
Write-Info "To view stored credentials: cmdkey /list:claude-code-*"
Write-Info "To delete a credential: cmdkey /delete:claude-code-<name>"
