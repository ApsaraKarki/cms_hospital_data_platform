<#
deploy_local.ps1

Idempotent local database structure deployment.

Creates:
    1. Databases         (cms_hospital_quality_raw, cms_hospital_quality)
    2. Schemas + tables   (staging DDL, target/star-schema DDL)
    3. Cross-database link (postgres_fdw setup, staging -> target)

Safe to re-run — uses IF NOT EXISTS (or equivalent DROP/CREATE patterns
where IF NOT EXISTS isn't supported, e.g. CREATE SERVER) throughout, so
re-running won't destroy existing structure or data.

This script handles STRUCTURE only — it does not load or move data.
See extract_cms_api.py, load_staging.py, and the fn_migration_* SQL
functions for the actual data pipeline.
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

# --- Step 4: Set up postgres_fdw (run against target database) ---
Write-Host "`n=== Setting up postgres_fdw (staging -> target link) ===" -ForegroundColor Cyan

$fdwScript = Join-Path $PSScriptRoot "..\target\fdw\00_setup_fdw.sql"

psql -h $PGHOST -p $PGPORT -U $PGUSER -d cms_hospital_quality `
    -v staging_host="$PGHOST" `
    -v staging_port="$PGPORT" `
    -v staging_dbname="cms_hospital_quality_raw" `
    -v staging_user="$PGUSER" `
    -v staging_password="$PGPASSWORD" `
    -f $fdwScript

# --- Step 5: Deploy helper functions + migration functions (target database) ---
Write-Host "`n=== Deploying migration functions ===" -ForegroundColor Cyan

$migrationPath = Join-Path $PSScriptRoot "..\target\migration"
$migrationScripts = Get-ChildItem -Path $migrationPath -Filter "*.sql" | Sort-Object Name

foreach ($script in $migrationScripts) {
    Write-Host "  Running $($script.Name)..."
    psql -h $PGHOST -p $PGPORT -U $PGUSER -d cms_hospital_quality -f $script.FullName
}

Write-Host "`n=== Deployment complete ===" -ForegroundColor Cyan

Write-Host "`n=== Deployment complete ===" -ForegroundColor Cyan


<#
How to run:
    cd C:\Users\apsar\Git\cms_hospital_data_platform
    .\database\deploy\deploy_local.ps1

#>