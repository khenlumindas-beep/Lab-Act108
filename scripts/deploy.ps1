<#
.SYNOPSIS
  Full deployment pipeline for SmartTrack.
  1. Python venv + requirements   2. SQL migrations   3. Flutter web build+sync
.EXAMPLE
  .\scripts\deploy.ps1
  .\scripts\deploy.ps1 -SkipFlutter          # backend-only redeploy
  .\scripts\deploy.ps1 -SkipMigrations       # no DB changes
#>
param(
    [switch]$SkipFlutter,
    [switch]$SkipMigrations,
    [string]$Python = "py"
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$backend = Join-Path $root "backend"
$venvPython = Join-Path $backend "venv\Scripts\python.exe"

Write-Host "=== SmartTrack deploy ===" -ForegroundColor Cyan

# 1) Python environment
if (-not (Test-Path $venvPython)) {
    Write-Host "[1/3] Creating venv..." -ForegroundColor Cyan
    & $Python -m venv (Join-Path $backend "venv")
    if ($LASTEXITCODE -ne 0) { throw "venv creation failed" }
} else {
    Write-Host "[1/3] venv already exists" -ForegroundColor DarkGray
}
Write-Host "      Installing requirements..."
& $venvPython -m pip install --quiet --upgrade pip
& $venvPython -m pip install --quiet -r (Join-Path $backend "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }
if (-not (Test-Path (Join-Path $backend ".env")) -and (Test-Path (Join-Path $backend ".env.example"))) {
    Write-Warning "backend\.env is missing. Copy backend\.env.example to backend\.env and fill it in."
}

# 2) Migrations
if (-not $SkipMigrations) {
    Write-Host "[2/3] Applying database migrations..." -ForegroundColor Cyan
    & $venvPython (Join-Path $root "scripts\apply_migrations.py")
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Migration apply failed. If this database was migrated manually before tracking existed, run:"
        Write-Warning "  $venvPython $(Join-Path $root 'scripts\apply_migrations.py') --baseline"
        throw "migrations failed"
    }
} else {
    Write-Host "[2/3] Skipping migrations" -ForegroundColor DarkGray
}

# 3) Flutter web
if (-not $SkipFlutter) {
    Write-Host "[3/3] Building + syncing Flutter web..." -ForegroundColor Cyan
    & (Join-Path $root "scripts\sync_flutter_web.ps1")
    if ($LASTEXITCODE -ne 0) { throw "flutter sync failed" }
} else {
    Write-Host "[3/3] Skipping Flutter build" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=== Deploy complete ===" -ForegroundColor Green
Write-Host "Start API (dev):    cd backend; python -m uvicorn main:app --host 127.0.0.1 --port 5000"
Write-Host "Start API (prod):   cd backend; python -m uvicorn main:app --host 0.0.0.0 --port 5000 --workers 4"
Write-Host "Web UI:             http://<server>/SmartTrack/   (serves flutter-web\ via the web server)"
Write-Host "API docs:           http://<server>:5000/api/docs"
Write-Host "Health check:       http://<server>:5000/api/health"
Write-Host "Backup (scheduled): scripts\backup_db.ps1"
