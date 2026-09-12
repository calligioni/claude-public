# =====================================================================
# wmi-biosdate-fix.ps1  (worker — roda NO servidor alvo, como admin/SYSTEM)
# Preenche Win32_BIOS.ReleaseDate quando o firmware entrega a data num
# formato que o WMI nao parseia (comum em VMs Oracle Cloud / QEMU-KVM).
#
# Idempotente: se ReleaseDate ja tiver valor, sai sem fazer nada.
# Detecta a data real de: SMBIOSBIOSVersion (YYYYMMDD) -> registro
# HARDWARE\...\BIOSReleaseDate -> fallback data de hoje.
# Converte a classe Win32_BIOS de dinamica para estatica e injeta uma
# instancia com TODOS os campos originais + ReleaseDate preenchido
# (CIM datetime com offset LOCAL, pra nao deslocar o dia por fuso).
# =====================================================================
$ErrorActionPreference = "Stop"
$scope = "root\cimv2"

$live = Get-WmiObject Win32_BIOS
if ($live.ReleaseDate) { exit 0 }   # ja resolvido — nada a fazer

function Get-BiosDate($live) {
  # 1) SMBIOSBIOSVersion no formato YYYYMMDD (ex.: 20260522)
  $v = "$($live.SMBIOSBIOSVersion)".Trim()
  if ($v -match "^\d{8}$") {
    $y=[int]$v.Substring(0,4); $mo=[int]$v.Substring(4,2); $d=[int]$v.Substring(6,2)
    if ($mo -ge 1 -and $mo -le 12 -and $d -ge 1 -and $d -le 31) {
      return [datetime]::new($y,$mo,$d,0,0,0,[DateTimeKind]::Local)
    }
  }
  # 2) HKLM\HARDWARE\DESCRIPTION\System\BIOS\BIOSReleaseDate (ex.: "May-22-2026")
  $rk = (Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -EA SilentlyContinue).BIOSReleaseDate
  if ($rk) {
    $dt = [datetime]::MinValue
    foreach ($f in @("MMM-dd-yyyy","MM/dd/yyyy","yyyy-MM-dd","M/d/yyyy","dd/MM/yyyy")) {
      if ([datetime]::TryParseExact($rk,$f,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$dt)) {
        return [datetime]::new($dt.Year,$dt.Month,$dt.Day,0,0,0,[DateTimeKind]::Local)
      }
    }
    if ([datetime]::TryParse($rk,[ref]$dt)) {
      return [datetime]::new($dt.Year,$dt.Month,$dt.Day,0,0,0,[DateTimeKind]::Local)
    }
  }
  # 3) fallback: hoje
  return (Get-Date).Date
}

$rd = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime((Get-BiosDate $live))

# captura todos os campos atuais
$vals = @{}; foreach ($p in $live.Properties) { $vals[$p.Name] = $p.Value }

# converte a classe de dinamica -> estatica
$cls = New-Object System.Management.ManagementClass($scope,"Win32_BIOS",$null)
if (@($cls.Qualifiers | ?{$_.Name -eq "dynamic"}).Count)  { $cls.Qualifiers.Remove("dynamic") }
if (@($cls.Qualifiers | ?{$_.Name -eq "provider"}).Count) { $cls.Qualifiers.Remove("provider") }
$cls.Put() | Out-Null

# injeta instancia estatica com todos os valores + ReleaseDate
$c2 = New-Object System.Management.ManagementClass($scope,"Win32_BIOS",$null)
$i  = $c2.CreateInstance()
foreach ($k in $vals.Keys) { if ($k -eq "ReleaseDate") { continue }; try { $i[$k] = $vals[$k] } catch {} }
$i["ReleaseDate"] = $rd
$i.Put() | Out-Null
