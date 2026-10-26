<#
.SYNOPSIS
  Backup the SmartTrack PostgreSQL database to backups\smarttrack_<timestamp>.sql
.EXAMPLE
  .\scripts\backup_db.ps1
  .\scripts\backup_db.ps1 -PgDump "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" -Keep 14
#>
param(
    [string]$PgDump = "pg_dump",
    [string]$EnvFile = "$PSScriptRoot\..\backend\.env",
    [string]$OutDir  = "$PSScriptRoot\..\backups",
    [int]$Keep = 30
)

$ErrorActionPreference = "Stop"

# --- read connection info from backend\.env ---
$env = @{}
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $i = $line.IndexOf("=")
        $env[$line.Substring(0, $i).Trim()] = $line.Substring($i + 1).Trim().Trim('"').Trim("'")
    }
}
$dbUrl = $env["DATABASE_URL"]
if ($dbUrl -notmatch 'postgresql://([^:@/]+)(?::([^@/]*))?@([^:/]+):(\d+)/(\w+)') {
    throw "Cannot parse DATABASE_URL from $EnvFile"
}
$user = $Matches[1]; $pass = $Matches[2]; $dbHost = $Matches[3]; $port = $Matches[4]; $db = $Matches[5]

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outFile = Join-Path $OutDir "smarttrack_$stamp.sql"

# --- run pg_dump ---
$env:PGPASSWORD = $pass
& $PgDump -h $dbHost -p $port -U $user -d $db -f $outFile --no-owner --no-privileges
if ($LASTEXITCODE -ne 0) { throw "pg_dump failed with exit code $LASTEXITCODE" }
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

$size = [math]::Round((Get-Item $outFile).Length / 1KB, 1)
Write-Host "Backup written: $outFile ($size KB)"

# --- prune old backups ---
$old = Get-ChildItem $OutDir -Filter "smarttrack_*.sql" | Sort-Object Name -Descending | Select-Object -Skip $Keep
foreach ($f in $old) {
    Remove-Item $f.FullName -Force
    Write-Host "Pruned old backup: $($f.Name)"
}
Write-Host "Done. Keeping newest $Keep backups."
