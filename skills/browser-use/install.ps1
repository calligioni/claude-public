# browser-use skill installer (Windows / PowerShell)
# Installs Python deps + Chromium for Playwright.
# Idempotent: safe to re-run.

$ErrorActionPreference = "Stop"

Write-Host "==> Checking Python..." -ForegroundColor Cyan
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Host "ERROR: python not found on PATH. Install Python >= 3.11 from python.org." -ForegroundColor Red
    exit 1
}

$ver = (& python -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')").Trim()
$major, $minor = $ver.Split('.')
if ([int]$major -lt 3 -or ([int]$major -eq 3 -and [int]$minor -lt 11)) {
    Write-Host "ERROR: Python $ver detected. browser-use requires >= 3.11." -ForegroundColor Red
    exit 1
}
Write-Host "    Python $ver OK" -ForegroundColor Green

Write-Host "==> Installing browser-use + playwright..." -ForegroundColor Cyan
& python -m pip install --upgrade browser-use playwright
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: pip install failed." -ForegroundColor Red
    exit 1
}

Write-Host "==> Installing Chromium for Playwright (~170 MB)..." -ForegroundColor Cyan
& python -m playwright install chromium
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: playwright install failed." -ForegroundColor Red
    exit 1
}

Write-Host "==> Smoke test..." -ForegroundColor Cyan
& python -c "import browser_use, playwright; print('imports OK')"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: import test failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done. browser-use skill is ready." -ForegroundColor Green
Write-Host "Start the server when invoking the skill:" -ForegroundColor Yellow
Write-Host "    cd `$env:USERPROFILE\.claude\skills\browser-use" -ForegroundColor Yellow
Write-Host "    python server.py start" -ForegroundColor Yellow
