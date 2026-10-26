@echo off
title SmartTrack - Auto Run (Apache + Backend)
cd /d C:\xampp\htdocs\SmartTrack

REM =========================================================================
REM  SmartTrack launcher (new flow)
REM
REM  Frontend : http://localhost/SmartTrack/flutter-web/   (Apache, port 80)
REM             -> C:\xampp\htdocs\SmartTrack\flutter-web  (release build)
REM  Backend  : http://localhost:5000/api                 (FastAPI + uvicorn)
REM
REM  To refresh the frontend after editing mobile_app\lib\**.dart, run:
REM       powershell -NoProfile -ExecutionPolicy Bypass -File scripts\sync_flutter_web.ps1
REM =========================================================================

echo [1/3] Checking backend on :5000 ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue) { Write-Output 'backend: already running' } else { Start-Process -FilePath 'C:\xampp\htdocs\SmartTrack\backend\venv\Scripts\python.exe' -ArgumentList '-m','uvicorn','main:app','--host','0.0.0.0','--port','5000' -WorkingDirectory 'C:\xampp\htdocs\SmartTrack\backend' -WindowStyle Hidden; $t=0; while ($t -lt 40 -and -not (Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue)) { Start-Sleep -Milliseconds 500; $t++ }; Write-Output 'backend: started' }"

echo [2/3] Checking Apache on :80 (XAMPP) ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue) { Write-Output 'apache: already running' } else { Start-Process -FilePath 'C:\xampp\apache\bin\httpd.exe' -WorkingDirectory 'C:\xampp\apache\bin' -WindowStyle Hidden; $t=0; while ($t -lt 20 -and -not (Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue)) { Start-Sleep -Milliseconds 500; $t++ }; Write-Output 'apache: started' }"

echo [3/3] Opening SmartTrack in the browser ...
start "" "http://localhost/SmartTrack/flutter-web/"

echo.
echo SmartTrack is running:
echo   Frontend  http://localhost/SmartTrack/flutter-web/
echo   Backend   http://localhost:5000/api
echo.
echo Press any key to close this window...
pause >nul
