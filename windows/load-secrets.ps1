# ============================================================
# Claude Code - Load Secrets from Windows Credential Manager
# ============================================================
# This script is dot-sourced from the PowerShell profile.
# It loads secrets into environment variables silently.
#
# Usage (added to $PROFILE automatically by install.ps1):
#   . "$env:USERPROFILE\.claude-setup\windows\load-secrets.ps1"
# ============================================================

# Load helpers (for CredManager type and secrets table)
. "$PSScriptRoot\helpers.ps1"

foreach ($secret in $script:ClaudeSecrets) {
    $value = Get-ClaudeSecret -Name $secret.Name
    if ($null -ne $value -and $value.Length -gt 0) {
        [System.Environment]::SetEnvironmentVariable($secret.EnvVar, $value, "Process")
    }
}
