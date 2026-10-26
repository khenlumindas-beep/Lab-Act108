# SmartTrack Auto-Start — runs at Windows logon (no admin needed).
# - Backend: uvicorn on 127.0.0.1:5000
# - Frontend: python http.server on http://localhost:3000/ (mobile_app\build\web)
# Logs to %TEMP%\smarttrack_startup.log

$ErrorActionPreference = 'SilentlyContinue'
$log = Join-Path $env:TEMP 'smarttrack_startup.log'
function Log($msg) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Add-Content -Path $log }

Log '=== SmartTrack startup begin ==='

# --- Backend: uvicorn on 127.0.0.1:5000 ---
$conns = Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue
foreach ($c in $conns) {
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    Log "killed stale backend pid $($c.OwningProcess) on :5000"
}
Start-Sleep -Seconds 1

$backendDir = 'C:\xampp\htdocs\SmartTrack\backend'
$python    = Join-Path $backendDir 'venv\Scripts\python.exe'
if (Test-Path $python) {
    Start-Process -FilePath $python `
        -ArgumentList '-m','uvicorn','main:app','--host','127.0.0.1','--port','5000' `
        -WorkingDirectory $backendDir `
        -WindowStyle Hidden
    Log 'backend started (uvicorn :5000)'
} else {
    Log "ERROR: backend python not found: $python"
}

# --- Frontend: python http.server on :3000 (Hyper-V-safe port, already in CORS) ---
$conns = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
foreach ($c in $conns) {
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    Log "killed stale frontend pid $($c.OwningProcess) on :3000"
}
Start-Sleep -Seconds 1

$webDir = 'C:\xampp\htdocs\SmartTrack\mobile_app\build\web'
$py314  = 'C:\Python314\python.exe'
if ((Test-Path $webDir) -and (Test-Path $py314)) {
    Start-Process -FilePath $py314 `
        -ArgumentList '-m','http.server','3000','--directory',$webDir `
        -WindowStyle Hidden
    Log 'frontend started (http.server :3000)'
} else {
    Log "ERROR: webDir or python missing (webDir=$webDir py=$py314)"
}

Log 'open http://localhost:3000/ after login'
Log '=== SmartTrack startup end ==='
