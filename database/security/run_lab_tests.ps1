<#
.SYNOPSIS
  SmartTrack - IT108 Activity 7 sandbox runner.

  Builds the SANDBOX database smarttrack_security_lab from the live schema
  (read-only on smarttrack_db), applies the GRANT/REVOKE script and the RLS
  policy, seeds safe test records, runs the allowed/blocked action tests and
  captures the output as lab evidence.

  LIVE DATABASE IS NEVER MODIFIED. The only cluster-wide side effects are the
  three NOLOGIN roles (smarttrack_super_admin, smarttrack_faculty,
  smarttrack_app), which are required deliverables of the activity.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File database\security\run_lab_tests.ps1
#>
param(
    [string]$Psql    = "C:\Program Files\PostgreSQL\18\bin\psql.exe",
    [string]$PgDump  = "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe",
    [string]$HostAddr = "127.0.0.1",
    [string]$LiveDb  = "smarttrack_db",
    [string]$LabDb   = "smarttrack_security_lab",
    [string]$EnvFile = (Join-Path $PSScriptRoot "..\..\backend\.env")
)

$ErrorActionPreference = "Stop"
$prevOutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8   # psql emits UTF-8
$secDir  = $PSScriptRoot
$outDir  = Join-Path $secDir "evidence"
$outFile = Join-Path $outDir "privilege_test_results.txt"
$schemaDump = Join-Path $env:TEMP "smarttrack_lab_schema.sql"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# --- 1. Credentials: load from backend/.env into the process environment.
#        Values are NEVER printed or written to the evidence file.
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^POSTGRES_USER=(.+)$')     { $env:PGUSER     = $Matches[1] }
        if ($_ -match '^POSTGRES_PASSWORD=(.+)$') { $env:PGPASSWORD = $Matches[1] }
    }
} else {
    Write-Warning "backend/.env not found - falling back to pgpass/trust auth."
}
$env:PGHOST = $HostAddr

$base = @("-U", "postgres", "-h", $HostAddr)

try {
    # --- 2. (Re)create the sandbox database
    Write-Host "[1/6] Creating sandbox database $LabDb ..." -ForegroundColor Cyan
    & $Psql @base -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $LabDb;"
    & $Psql @base -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $LabDb;"

    # --- 3. Copy the live schema (READ-ONLY on the live database)
    Write-Host "[2/6] Copying schema from $LiveDb (read-only) ..." -ForegroundColor Cyan
    & $PgDump -h $HostAddr -U postgres -d $LiveDb -n system_core --schema-only -f $schemaDump
    if ($LASTEXITCODE -ne 0) { throw "pg_dump failed" }
    & $Psql @base -d $LabDb -v ON_ERROR_STOP=1 -f $schemaDump
    if ($LASTEXITCODE -ne 0) { throw "schema restore failed" }

    # --- 4. Apply roles + GRANT/REVOKE, then the RLS policy (sandbox only)
    Write-Host "[3/6] Applying 01_roles_and_grants.sql ..." -ForegroundColor Cyan
    & $Psql @base -d $LabDb -v ON_ERROR_STOP=1 -f (Join-Path $secDir "01_roles_and_grants.sql")
    if ($LASTEXITCODE -ne 0) { throw "01_roles_and_grants.sql failed" }

    Write-Host "[4/6] Applying 02_rls_policy.sql ..." -ForegroundColor Cyan
    & $Psql @base -d $LabDb -v ON_ERROR_STOP=1 -f (Join-Path $secDir "02_rls_policy.sql")
    if ($LASTEXITCODE -ne 0) { throw "02_rls_policy.sql failed" }

    # --- 5. Seed safe test records
    Write-Host "[5/6] Seeding safe test records (03_sandbox_seed.sql) ..." -ForegroundColor Cyan
    & $Psql @base -d $LabDb -v ON_ERROR_STOP=1 -f (Join-Path $secDir "03_sandbox_seed.sql")
    if ($LASTEXITCODE -ne 0) { throw "03_sandbox_seed.sql failed" }

    # --- 6. Run allowed/blocked tests and capture evidence
    #        (ON_ERROR_STOP intentionally OFF: BLOCKED tests must fail on
    #         purpose and the script has to continue.)
    Write-Host "[6/6] Running 04_privilege_tests.sql ..." -ForegroundColor Cyan
    # BLOCKED tests intentionally write ERROR lines to stderr; tolerate them.
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $results = @(& $Psql @base -d $LabDb -v ON_ERROR_STOP=off -f (Join-Path $secDir "04_privilege_tests.sql") 2>&1 |
                 ForEach-Object { "$_" })
    $pgVersion = "$(& $Psql @base -d postgres -tAc 'SELECT version();' 2>&1)"
    $ErrorActionPreference = $prevEAP

    $header = @(
        "SmartTrack - IT108 Activity 7 - sandbox privilege test evidence",
        "Generated        : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Server           : $pgVersion",
        "Live database    : $LiveDb (READ-ONLY in this run)",
        "Sandbox database : $LabDb",
        "Scripts          : 01_roles_and_grants.sql, 02_rls_policy.sql,",
        "                   03_sandbox_seed.sql, 04_privilege_tests.sql",
        "Note             : ERROR lines under BLOCKED tests are EXPECTED.",
        ""
    )
    $header + $results | Set-Content -Path $outFile -Encoding UTF8
    Write-Host "Evidence written to: $outFile" -ForegroundColor Green
}
finally {
    Remove-Item -Path $schemaDump -ErrorAction SilentlyContinue
    $env:PGPASSWORD = $null
    $env:PGUSER     = $null
    $env:PGHOST     = $null
    [Console]::OutputEncoding = $prevOutputEncoding
}
