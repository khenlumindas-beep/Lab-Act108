<#
.SYNOPSIS
  Build the canonical Flutter web app (mobile_app) and sync it into flutter-web\
  (the directory served by the web server).
.EXAMPLE
  .\scripts\sync_flutter_web.ps1
#>
param(
    [string]$AppDir   = "$PSScriptRoot\..\mobile_app",
    [string]$TargetDir = "$PSScriptRoot\..\flutter-web",
    [string]$BaseHref = "/SmartTrack/flutter-web/",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

if (-not $SkipBuild) {
    Write-Host "Building Flutter web (release)..."
    Push-Location $AppDir
    flutter build web --release
    if ($LASTEXITCODE -ne 0) { Pop-Location; throw "flutter build failed" }
    Pop-Location
}

$src = Join-Path $AppDir "build\web"
if (-not (Test-Path (Join-Path $src "main.dart.js"))) {
    throw "Build output not found: $src\main.dart.js"
}

# --- Stale-cache fix: disable the Flutter service worker (localhost demo) ---
# The SW caches main.dart.js/flutter_bootstrap.js cache-first, so browsers keep
# serving an OLD build after a rebuild (stale design / blank pages). Passing a
# null serviceWorkerSettings makes flutter.js skip SW registration entirely,
# and the snippet in index.html unregisters any SW + clears caches once.
$boot = Join-Path $src "flutter_bootstrap.js"
$bootText = [System.IO.File]::ReadAllText($boot)
$newBoot = [regex]::Replace($bootText, 'serviceWorkerSettings:\s*\{[^}]*\}', 'serviceWorkerSettings: null')
if ($newBoot -eq $bootText -and $bootText -match 'serviceWorkerSettings:\s*\{') {
    throw "flutter_bootstrap.js: found serviceWorkerSettings but regex failed to patch it"
}
[System.IO.File]::WriteAllText($boot, $newBoot)
Write-Host "Patched flutter_bootstrap.js (serviceWorkerSettings: null -> no service worker)."

$idx = Join-Path $src "index.html"
$idxText = [System.IO.File]::ReadAllText($idx)
if ($idxText -notmatch 'getRegistrations') {
    $cleanup = @'
    <script>
      // One-time cleanup: remove stale Flutter service workers + caches
      // (older builds registered a cache-first SW that served old assets).
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function (rs) { rs.forEach(function (r) { r.unregister(); }); });
      }
      if (window.caches) {
        caches.keys().then(function (ks) { ks.forEach(function (k) { caches.delete(k); }); });
      }
    </script>
'@
    if ($idxText -match '(?s)<script src="flutter_bootstrap\.js"') {
        $idxText = $idxText -replace '(<script src="flutter_bootstrap\.js")', ($cleanup + "`n    " + '$1')
        [System.IO.File]::WriteAllText($idx, $idxText)
        Write-Host "Patched index.html (service-worker/cache cleanup snippet injected)."
    } else {
        throw "index.html: flutter_bootstrap.js <script> tag not found for cleanup injection"
    }
} else {
    Write-Host "index.html: cleanup snippet already present."
}


Write-Host "Syncing $src -> $TargetDir"
robocopy $src $TargetDir /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with code $LASTEXITCODE" }
# robocopy exit codes 0-7 are success-ish
$global:LASTEXITCODE = 0

# The build output uses <base href="/"> (correct for :8080 serving the root).
# The mirrored flutter-web\ copy is served from a subpath by XAMPP, so give it
# its own base href — otherwise assets resolve against / and the page is blank.
$targetIdx = Join-Path $TargetDir "index.html"
$tText = [System.IO.File]::ReadAllText($targetIdx)
if ($tText -match '<base href="/">') {
    $tText = $tText -replace '<base href="/">', ('<base href="' + $BaseHref + '">')
    [System.IO.File]::WriteAllText($targetIdx, $tText)
    Write-Host "Patched flutter-web\index.html base href -> $BaseHref"
}

Write-Host "flutter-web\ is now in sync with mobile_app build."
