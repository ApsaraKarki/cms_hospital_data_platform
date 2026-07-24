# CMS Staging Load — Command Log

## 1. Install Additional Packages
```powershell
cd C:\Users\apsar\Git\cms_hospital_data_platform\etl
.\venv\Scripts\Activate.ps1
pip install psycopg2-binary python-dotenv          # psycopg2 = Postgres driver, dotenv = load .env credentials
pip freeze > requirements.txt
```

## 2. Create `.env` File (repo root)

Confirmed `.env` already covered by root `.gitignore` — never committed to Git.

**Note:** VS Code showed a notice — "environment file configured but terminal 
env injection is disabled." Not an error; script loads `.env` itself via 
`python-dotenv`, so no VS Code setting change needed. Ignored.

## 3. Database Setup (done manually via pgAdmin)
- Created `cms_hospital_quality_raw` database
- Created `staging` schema
- Ran DDL for 4 staging tables:
  `stg_hospital_general`, `stg_timely_care`, `stg_hcahps`, `stg_readmissions`
- Created `cms_hospital_quality` database
- Created `target` schema
- Ran DDL for `dim_hospital` + 3 fact tables

## 4. Build Staging Load Script
Created `database/staging/load/load_staging.py`:
- Reads `.env` for DB credentials
- Maps each raw CSV (by filename prefix) to its staging table
- Uses `TRUNCATE` + `COPY ... FROM STDIN` for fast bulk load 
  (chosen over row-by-row INSERT for performance on large files)
- `NULL ''` option in COPY — treats empty CSV fields as `NULL`
- Per-table `try/except` with `rollback()` — one failed table doesn't 
  break the full run
- Logs progress + summary via Python `logging`

## 5. Run
```powershell
cd C:\Users\apsar\Git\cms_hospital_data_platform
python database\staging\load\load_staging.py
```

## 6. Result

All row counts matched extraction output exactly. No errors, no rollbacks.

## 7. Verification (pgAdmin)
```sql
SELECT * FROM staging.stg_hospital_general LIMIT 5;
```
Confirmed `facility_id` retained leading zeros; column values aligned 
correctly with CSV headers.

---
## Next Step
Migrate data from staging → target (cleaning, type casting, star schema load)
via `database/target/migration/fn_migration_*.sql`.

---
stg_hospital_general : 5,432 rows
stg_timely_care       : 138,173 rows
stg_hcahps             : 325,856 rows
stg_readmissions       : 18,330 rows