# =====================================================================
# apply-remote.ps1 — orquestra o fix num alvo remoto via WinRM
# Uso:
#   .\apply-remote.ps1 -Target 10.250.0.6 -User 'DOMINIO\usuario' -Password '***'
#   .\apply-remote.ps1 -Target 10.250.0.6 -User '...' -Password '...' -Revert
#
# Faz: TrustedHosts -> backup -> aplica worker -> verifica (via .NET,
# igual ao ERP) -> cria tarefa de boot -> reverte sozinho se falhar.
# =====================================================================
param(
  [Parameter(Mandatory)][string]$Target,
  [Parameter(Mandatory)][string]$User,
  [Parameter(Mandatory)][string]$Password,
  [switch]$Revert,          # desfaz: volta Win32_BIOS pra dinamica e remove a tarefa
  [switch]$DiagnoseOnly      # so mostra o estado atual, nao altera
)
$ErrorActionPreference = "Stop"

# --- TrustedHosts (precisa admin local) ---
$th = (Get-Item WSMan:\localhost\Client\TrustedHosts -EA SilentlyContinue).Value
if ($th -notmatch [regex]::Escape($Target) -and $th -notmatch '\*') {
  $new = if ([string]::IsNullOrWhiteSpace($th)) { $Target } else { "$th,$Target" }
  Set-Item WSMan:\localhost\Client\TrustedHosts -Value $new -Force
  Write-Host "[i] TrustedHosts += $Target"
}

$sec  = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($User,$sec)

$worker = Get-Content (Join-Path $PSScriptRoot 'wmi-biosdate-fix.ps1') -Raw

Invoke-Command -ComputerName $Target -Credential $cred -Authentication Negotiate -ArgumentList $worker,$Revert.IsPresent,$DiagnoseOnly.IsPresent -ScriptBlock {
  param($workerSrc,$doRevert,$diagOnly)
  $ErrorActionPreference="Stop"; $scope="root\cimv2"
  $dir="C:\ProgramData\Fix-BiosDate"; New-Item -ItemType Directory -Force $dir | Out-Null

  if ($diagOnly) {
    $b=Get-WmiObject Win32_BIOS
    return [pscustomobject]@{Host=$env:COMPUTERNAME; OS=(Get-CimInstance Win32_OperatingSystem).Caption; ReleaseDate=$b.ReleaseDate; SMBIOSVer=$b.SMBIOSBIOSVersion; RegBIOSDate=(Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -EA SilentlyContinue).BIOSReleaseDate}
  }

  if ($doRevert) {
    Get-WmiObject Win32_BIOS 2>$null | ForEach-Object { $_.Delete() }
    $cr=New-Object System.Management.ManagementClass($scope,"Win32_BIOS",$null)
    if(-not @($cr.Qualifiers|?{$_.Name -eq "dynamic"}).Count){$cr.Qualifiers.Add("dynamic",$true)}
    if(-not @($cr.Qualifiers|?{$_.Name -eq "provider"}).Count){$cr.Qualifiers.Add("provider","CIMWin32")}
    $cr.Put()|Out-Null
    Unregister-ScheduledTask -TaskName 'Fix-Win32BIOS-ReleaseDate' -Confirm:$false -EA SilentlyContinue
    return [pscustomobject]@{Host=$env:COMPUTERNAME; Result='REVERTED'; ReleaseDate=(Get-WmiObject Win32_BIOS).ReleaseDate}
  }

  # salva worker no alvo
  Set-Content "$dir\wmi-biosdate-fix.ps1" $workerSrc -Encoding UTF8
  # backup
  $cls0=New-Object System.Management.ManagementClass($scope,"Win32_BIOS",$null)
  Set-Content "$dir\Win32_BIOS.class.mof.bak" ($cls0.GetText([System.Management.TextFormat]::Mof)) -Encoding UTF8
  (Get-WmiObject Win32_BIOS).Properties | ForEach-Object { "$($_.Name) = $($_.Value)" } | Set-Content "$dir\Win32_BIOS.values.bak.txt"

  # aplica
  $err=$null
  try { & powershell -ExecutionPolicy Bypass -File "$dir\wmi-biosdate-fix.ps1" } catch { $err=$_.Exception.Message }
  Start-Sleep 2

  # verifica via .NET (igual ERP)
  $got=$null;$parsed=$null
  try {
    $s=New-Object System.Management.ManagementObjectSearcher("SELECT ReleaseDate FROM Win32_BIOS")
    foreach($o in $s.Get()){ $got=$o['ReleaseDate'] }
    if($got){ $parsed=[System.Management.ManagementDateTimeConverter]::ToDateTime($got) }
  } catch { $err="$err | verify:$($_.Exception.Message)" }

  if ($got) {
    $a=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dir\wmi-biosdate-fix.ps1`""
    $t=New-ScheduledTaskTrigger -AtStartup; $t.Delay='PT60S'
    $pr=New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName 'Fix-Win32BIOS-ReleaseDate' -Action $a -Trigger $t -Principal $pr -Force | Out-Null
    [pscustomobject]@{Host=$env:COMPUTERNAME; Result='SUCCESS'; ReleaseDate=$got; Parsed=$parsed; TaskCreated=$true}
  } else {
    try {
      Get-WmiObject Win32_BIOS 2>$null | ForEach-Object { $_.Delete() }
      $cr=New-Object System.Management.ManagementClass($scope,"Win32_BIOS",$null)
      if(-not @($cr.Qualifiers|?{$_.Name -eq "dynamic"}).Count){$cr.Qualifiers.Add("dynamic",$true)}
      if(-not @($cr.Qualifiers|?{$_.Name -eq "provider"}).Count){$cr.Qualifiers.Add("provider","CIMWin32")}
      $cr.Put()|Out-Null; $rev="revertido"
    } catch { $rev="revert-FALHOU:$($_.Exception.Message)" }
    [pscustomobject]@{Host=$env:COMPUTERNAME; Result='FAILED'; ApplyErr=$err; Revert=$rev}
  }
} | Format-List
