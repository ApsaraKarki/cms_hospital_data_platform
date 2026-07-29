<#
run_pipeline.ps1

Repeatable data pipeline:
1. Extract raw data from CMS API
2. Load raw CSVs into staging tables
3. Migrate staging -> target (cleaning, casting, upsert)

Run deploy_local.ps1 separately (manually, only when setting up fresh 
or when schema/function definitions change) — this script does NOT 
create or modify database structure or function definitions.
#>

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

# --- Load .env ---
$envFile = Join-Path $ProjectRoot ".env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
    }
}
$PGHOST = $env:PGHOST
$PGPORT = $env:PGPORT
$PGUSER = $env:PGUSER
$env:PGPASSWORD = $env:PGPASSWORD

Write-Host "=== CMS Data Pipeline: Starting ===" -ForegroundColor Cyan
$startTime = Get-Date

try {
    # --- Step 1: Activate venv ---
    Write-Host "`n[1/4] Activating virtual environment..." -ForegroundColor Yellow
    & "$ProjectRoot\etl\venv\Scripts\Activate.ps1"

    # --- Step 2: Extract from CMS API ---
    Write-Host "`n[2/4] Extracting data from CMS API..." -ForegroundColor Yellow
    Push-Location "$ProjectRoot\etl"
    python extract_cms_api.py
    if ($LASTEXITCODE -ne 0) { throw "Extraction step failed." }
    Pop-Location

    # --- Step 3: Load into staging ---
    Write-Host "`n[3/4] Loading data into staging tables..." -ForegroundColor Yellow
    python "$ProjectRoot\database\staging\load\load_staging.py"
    if ($LASTEXITCODE -ne 0) { throw "Staging load step failed." }

    # --- Step 4: Migrate staging -> target ---
    Write-Host "`n[4/4] Migrating data to target warehouse..." -ForegroundColor Yellow

    $migrationCalls = @(
        "SELECT target.fn_migration_hospital_general();",
        "SELECT target.fn_migration_readmissions();",
        "SELECT target.fn_migration_hcahps();",
        "SELECT target.fn_migration_timely_care();"
    )

    foreach ($call in $migrationCalls) {
        psql -h $PGHOST -p $PGPORT -U $PGUSER -d cms_hospital_quality -c $call
        if ($LASTEXITCODE -ne 0) { throw "Migration step failed: $call" }
    }

    $duration = (Get-Date) - $startTime
    Write-Host "`n=== Pipeline completed successfully in $($duration.TotalSeconds) seconds ===" -ForegroundColor Green
}
catch {
    Write-Host "`n=== Pipeline FAILED: $_ ===" -ForegroundColor Red
    exit 1
}

<#

HOW TO RUN:


Prerequisite (run once, or whenever database schema changes):

    cd C:\Users\apsar\Git\cms_hospital_data_platform
    .\database\deploy\deploy_local.ps1

Then, to run the data pipeline (extract + load staging):

    cd C:\Users\apsar\Git\cms_hospital_data_platform
    .\run_pipeline.ps1

Note: run_pipeline.ps1 does NOT create databases, schemas, or tables.
It assumes deploy_local.ps1 has already been run successfully.

#>