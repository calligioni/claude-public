# ============================================================
# Claude Code Windows Setup - Shared Helpers
# ============================================================
# Dot-source this file from all other scripts:
#   . "$PSScriptRoot\helpers.ps1"
# ============================================================

# ── Constants ────────────────────────────────────────────────
$script:ClaudeDir  = Join-Path $env:USERPROFILE ".claude"
$script:InstallDir = Join-Path $env:USERPROFILE ".claude-setup"
$script:DesktopConfigDir = Join-Path $env:APPDATA "Claude"

$script:SyncItems = @(
    "settings.json"
    "agents"
    "skills"
    "commands"
    "hooks"
    "rules"
    "mcp-servers"
)

# ── Logging ──────────────────────────────────────────────────
function Write-Log  { param([string]$Msg) Write-Host "[+] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "[!] $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "[x] $Msg" -ForegroundColor Red }
function Write-Info { param([string]$Msg) Write-Host "    $Msg" -ForegroundColor DarkGray }

function Write-Banner {
    param([string]$Title)
    Write-Host ""
    Write-Host "===========================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "===========================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([int]$Num, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Num/$Total] $Title" -ForegroundColor Yellow
}

# ── Windows Credential Manager (P/Invoke) ────────────────────
# Uses CredRead/CredWrite from advapi32.dll to access Windows
# Credential Manager without external modules.

if (-not ([System.Management.Automation.PSTypeName]'ClaudeCredManager').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class ClaudeCredManager {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool CredRead(string target, int type, int flags, out IntPtr credential);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool CredWrite(ref CREDENTIAL credential, int flags);

    [DllImport("advapi32.dll")]
    private static extern void CredFree(IntPtr credential);

    private const int CRED_TYPE_GENERIC = 1;
    private const int CRED_PERSIST_LOCAL_MACHINE = 2;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public long LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string Read(string target) {
        IntPtr credPtr;
        if (!CredRead(target, CRED_TYPE_GENERIC, 0, out credPtr))
            return null;
        try {
            var cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            if (cred.CredentialBlobSize <= 0)
                return null;
            return Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
        } finally {
            CredFree(credPtr);
        }
    }

    public static bool Write(string target, string secret, string username) {
        byte[] byteArray = Encoding.Unicode.GetBytes(secret);
        CREDENTIAL cred = new CREDENTIAL();
        cred.Type = CRED_TYPE_GENERIC;
        cred.TargetName = target;
        cred.CredentialBlobSize = byteArray.Length;
        cred.CredentialBlob = Marshal.AllocHGlobal(byteArray.Length);
        cred.Persist = CRED_PERSIST_LOCAL_MACHINE;
        cred.UserName = username;
        try {
            Marshal.Copy(byteArray, 0, cred.CredentialBlob, byteArray.Length);
            return CredWrite(ref cred, 0);
        } finally {
            Marshal.FreeHGlobal(cred.CredentialBlob);
        }
    }
}
"@ -ErrorAction SilentlyContinue
}

function Get-ClaudeSecret {
    param([string]$Name)
    return [ClaudeCredManager]::Read("claude-code-$Name")
}

function Set-ClaudeSecret {
    param([string]$Name, [string]$Value)
    return [ClaudeCredManager]::Write("claude-code-$Name", $Value, "claude")
}

function Test-ClaudeSecret {
    param([string]$Name)
    $val = Get-ClaudeSecret -Name $Name
    return ($null -ne $val -and $val.Length -gt 0)
}

# ── Secrets Table ────────────────────────────────────────────
$script:ClaudeSecrets = @(
    @{ Name = "github-token";          EnvVar = "GITHUB_TOKEN";          Required = $true;  Prompt = "GitHub Personal Access Token (ghp_...)" }
    @{ Name = "brave-api-key";         EnvVar = "BRAVE_API_KEY";         Required = $true;  Prompt = "Brave Search API Key (BSA...)" }
    @{ Name = "anthropic-api-key";     EnvVar = "ANTHROPIC_API_KEY";     Required = $false; Prompt = "Anthropic API Key" }
    @{ Name = "slack-bot-token";       EnvVar = "SLACK_BOT_TOKEN";       Required = $false; Prompt = "Slack Bot Token (xoxb-...)" }
    @{ Name = "slack-team-id";         EnvVar = "SLACK_TEAM_ID";         Required = $false; Prompt = "Slack Team ID (T...)" }
    @{ Name = "notion-api-key";        EnvVar = "NOTION_API_KEY";        Required = $false; Prompt = "Notion API Key" }
    @{ Name = "resend-api-key";        EnvVar = "RESEND_API_KEY";        Required = $false; Prompt = "Resend API Key" }
    @{ Name = "digitalocean-token";    EnvVar = "DIGITALOCEAN_TOKEN";    Required = $false; Prompt = "DigitalOcean Token" }
    @{ Name = "firecrawl-api-key";     EnvVar = "FIRECRAWL_API_KEY";     Required = $false; Prompt = "Firecrawl API Key" }
    @{ Name = "azure-devops-pat";      EnvVar = "AZURE_DEVOPS_PAT";      Required = $false; Prompt = "Azure DevOps Personal Access Token" }
    @{ Name = "deskmanager-api-key";   EnvVar = "DESKMANAGER_API_KEY";   Required = $false; Prompt = "Deskmanager API Key" }
    @{ Name = "deskmanager-public-key";EnvVar = "DESKMANAGER_PUBLIC_KEY";Required = $false; Prompt = "Deskmanager Public Key" }
    @{ Name = "sqlserver-host";        EnvVar = "SQLSERVER_HOST";        Required = $false; Prompt = "SQL Server Host" }
    @{ Name = "sqlserver-user";        EnvVar = "SQLSERVER_USER";        Required = $false; Prompt = "SQL Server Username" }
    @{ Name = "sqlserver-password";    EnvVar = "SQLSERVER_PASSWORD";    Required = $false; Prompt = "SQL Server Password" }
    @{ Name = "sqlserver-database";    EnvVar = "SQLSERVER_DATABASE";    Required = $false; Prompt = "SQL Server Database Name" }
    @{ Name = "obsidian-api-key";      EnvVar = "OBSIDIAN_API_KEY";      Required = $false; Prompt = "Obsidian API Key" }
)

# ── Symlink / Junction Helpers ───────────────────────────────
function Test-DeveloperMode {
    try {
        $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        $val = Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction Stop
        return $val.AllowDevelopmentWithoutDevLicense -eq 1
    } catch {
        return $false
    }
}

function New-ClaudeLink {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path $Source -PathType Container) {
        # Directory: use NTFS Junction (no admin needed)
        New-Item -ItemType Junction -Path $Destination -Target $Source -Force | Out-Null
        Write-Log "Linked (junction): $(Split-Path $Destination -Leaf)"
    } else {
        # File: try symlink, fall back to copy
        if (Test-DeveloperMode) {
            try {
                New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force -ErrorAction Stop | Out-Null
                Write-Log "Linked (symlink): $(Split-Path $Destination -Leaf)"
                return
            } catch {
                # Fall through to copy
            }
        }
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Warn "Copied (enable Developer Mode for symlinks): $(Split-Path $Destination -Leaf)"
    }
}

# ── Notification Helper ──────────────────────────────────────
function Send-ClaudeNotification {
    param(
        [string]$Title = "Claude Code",
        [string]$Message
    )
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.Visible = $true
        $notify.BalloonTipTitle = $Title
        $notify.BalloonTipText = $Message
        $notify.ShowBalloonTip(5000)
        Start-Sleep -Seconds 1
        $notify.Dispose()
    } catch {
        # Silently ignore if notifications aren't available
    }
}
