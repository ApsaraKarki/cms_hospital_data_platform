# postgres_fdw Setup — Command Log

## Purpose
Enables the target database (cms_hospital_quality) to query staging 
tables in a separate database (cms_hospital_quality_raw) directly, 
as if they were local tables — required since PostgreSQL does not 
support native cross-database queries.

## Why postgres_fdw over dblink
Chose postgres_fdw over the older dblink extension: FDW allows staging 
tables to be queried with normal SELECT/JOIN syntax (via foreign tables), 
rather than dblink's function-call style with embedded connection 
strings. FDW is also the modern, currently-recommended approach.

## Setup (in database/target/fdw/00_setup_fdw.sql)
1. `CREATE EXTENSION postgres_fdw`
2. `CREATE SERVER staging_server` — connection to cms_hospital_quality_raw
3. `CREATE USER MAPPING` — credentials passed as psql variables (-v), 
   sourced from .env — never hardcoded in the SQL file
4. `IMPORT FOREIGN SCHEMA staging INTO staging_link` — imports all 4 
   staging tables as foreign tables, queryable from the target database

## Issue: psql variable substitution failed inside DO $$ blocks
**Error:**
**Cause:** psql's `:'variable'` substitution does not work inside 
dollar-quoted (`DO $$ ... $$`) blocks, since dollar-quoting passes 
text through literally without substitution.

**Fix:** Moved `CREATE SERVER` and `CREATE USER MAPPING` out of `DO $$` 
blocks to the top level (where substitution works), and used 
`DROP SERVER IF EXISTS ... CASCADE` beforehand instead, to keep the 
script idempotent without relying on `IF NOT EXISTS` (which these two 
statements don't support natively).

## Result
Ran successfully via deploy_local.ps1. Verified with:
```sql
SELECT * FROM staging_link.stg_hospital_general LIMIT 5;

SELECT foreign_table_name FROM information_schema.foreign_tables WHERE foreign_table_schema = 'staging_link';
```
Confirmed staging tables are queryable from the target database.

## Integrated into deploy_local.ps1
Runs as Step 4, after both staging and target DDL — required since 
IMPORT FOREIGN SCHEMA needs the staging tables to already exist.