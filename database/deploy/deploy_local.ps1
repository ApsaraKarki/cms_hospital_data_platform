<#
deploy_local.ps1

One-time (idempotent) setup script: creates the two project databases,
their schemas, and all staging/target tables.

Safe to re-run — uses IF NOT EXISTS everywhere, so re-running won't
destroy existing structure or data. This script handles STRUCTURE only;
it does not load or move data (see extract_cms_api.py, load_staging.py,
and the migration scripts for the data pipeline).
#>

# --- Load environment variables from .env ---
$envFile = Join-Path $PSScriptRoot "..\..\.env"

if (-not (Test-Path $envFile)) {
    Write-Error "Could not find .env file at $envFile"
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

$PGHOST = $env:PGHOST
$PGPORT = $env:PGPORT
$PGUSER = $env:PGUSER
$PGPASSWORD = $env:PGPASSWORD

# psql reads PGPASSWORD from the environment automatically — no need to pass it as an argument
$env:PGPASSWORD = $PGPASSWORD

Write-Host "=== Starting local database deployment ===" -ForegroundColor Cyan

# --- Step 1: Create databases (connect to default 'postgres' db to run CREATE DATABASE) ---
$databases = @("cms_hospital_quality_raw", "cms_hospital_quality")

foreach ($db in $databases) {
    Write-Host "Checking database: $db"

    $exists = psql -h $PGHOST -p $PGPORT -U $PGUSER -d postgres -tAc `
        "SELECT 1 FROM pg_database WHERE datname='$db';"

    if ($exists -eq "1") {
        Write-Host "  Database '$db' already exists, skipping creation." -ForegroundColor Yellow
    } else {
        Write-Host "  Creating database '$db'..." -ForegroundColor Green
        psql -h $PGHOST -p $PGPORT -U $PGUSER -d postgres -c "CREATE DATABASE $db;"
    }
}

# --- Step 2: Run staging DDL against cms_hospital_quality_raw ---
Write-Host "`n=== Deploying staging schema + tables ===" -ForegroundColor Cyan

$stagingDdlPath = Join-Path $PSScriptRoot "..\staging\ddl"
$stagingScripts = Get-ChildItem -Path $stagingDdlPath -Filter "*.sql" | Sort-Object Name

foreach ($script in $stagingScripts) {
    Write-Host "  Running $($script.Name)..."
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d cms_hospital_quality_raw -f $script.FullName
}

# --- Step 3: Run target DDL against cms_hospital_quality ---
Write-Host "`n=== Deploying target schema + tables ===" -ForegroundColor Cyan

$targetDdlPath = Join-Path $PSScriptRoot "..\target\ddl"
$targetScripts = Get-ChildItem -Path $targetDdlPath -Filter "*.sql" | Sort-Object Name

foreach ($script in $targetScripts) {
    Write-Host "  Running $($script.Name)..."
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d cms_hospital_quality -f $script.FullName
}

Write-Host "`n=== Deployment complete ===" -ForegroundColor Cyan


<#
=========================================================
DEPLOYMENT NOTES
=========================================================

Purpose:
One-time (idempotent) setup script that creates both databases, schemas,
and all staging/target tables via psql. Safe to re-run — uses
IF NOT EXISTS everywhere, so re-running won't destroy existing data.

Setup required before running:
- psql must be available in PATH
  (installed at C:\Program Files\PostgreSQL\18\bin)
- Issue encountered: psql not recognized in new terminals even after
  using [System.Environment]::SetEnvironmentVariable — resolved by a
  full machine restart (environment variable cache issue)

How to run:
    cd C:\Users\apsar\Git\cms_hospital_data_platform
    .\database\deploy\deploy_local.ps1

Result of last successful run:
Ran against already-existing databases/tables (created manually via
pgAdmin). All statements returned "already exists, skipping" notices —
confirms script is idempotent and safe to re-run without data loss.

=========================================================
#>