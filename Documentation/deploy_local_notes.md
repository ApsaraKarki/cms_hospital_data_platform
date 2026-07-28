# Local Deployment Script: deploy_local.ps1

## Purpose
One-time (idempotent) setup script that creates both databases, schemas, 
and all staging/target tables via psql. Safe to re-run. 
IF NOT EXISTS everywhere.

## Setup required
- psql added to PATH (installed at C:\Program Files\PostgreSQL\18\bin)
  - Issue: psql not recognized in new terminals even after 
    SetEnvironmentVariable resolved by full machine restart 
    (environment variable cache issue)

## Run
```powershell
cd C:\Users\apsar\Git\cms_hospital_data_platform
.\database\deploy\deploy_local.ps1
```

## Result
Ran successfully against existing databases/tables (created manually 
earlier via pgAdmin). All statements returned "already exists, skipping" 
notices confirms script is idempotent and safe to re-run without data loss.