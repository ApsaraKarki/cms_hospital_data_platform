<#
run_pipeline.ps1

Repeatable data pipeline:
1. Extract raw data from CMS API
2. Load raw CSVs into staging tables

Run deploy_local.ps1 separately (manually, only when setting up fresh 
or when schema changes) — this script does NOT touch database structure.
#>

$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
Write-Host "=== CMS Data Pipeline: Starting ===" -ForegroundColor Cyan
$startTime = Get-Date

try {
    # --- Step 1: Activate venv ---
    Write-Host "`n[1/3] Activating virtual environment..." -ForegroundColor Yellow
    & "$ProjectRoot\etl\venv\Scripts\Activate.ps1"

    # --- Step 2: Extract from CMS API ---
    Write-Host "`n[2/3] Extracting data from CMS API..." -ForegroundColor Yellow
    Push-Location "$ProjectRoot\etl"
    python extract_cms_api.py
    if ($LASTEXITCODE -ne 0) { throw "Extraction step failed." }
    Pop-Location

    # --- Step 3: Load into staging ---
    Write-Host "`n[3/3] Loading data into staging tables..." -ForegroundColor Yellow
    python "$ProjectRoot\database\staging\load\load_staging.py"
    if ($LASTEXITCODE -ne 0) { throw "Staging load step failed." }

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