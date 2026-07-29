# Data Quality Investigation: Staging Tables

## Purpose
Before writing migration/cleaning logic, sampled distinct values in 
key fields likely to contain dirty or inconsistent data, to design 
cleaning functions based on actual data rather than assumptions.

## Method
Ran DISTINCT queries against staging tables for fields expected to 
have missing-value placeholders, mixed types, or inconsistent formatting.

```sql
SELECT DISTINCT hospital_overall_rating FROM staging.stg_hospital_general LIMIT 20;
SELECT DISTINCT emergency_services FROM staging.stg_hospital_general LIMIT 20;
SELECT DISTINCT score FROM staging.stg_timely_care LIMIT 20;
SELECT DISTINCT excess_readmission_ratio FROM staging.stg_readmissions LIMIT 20;
```

## Findings
- `hospital_overall_rating`: numeric values (1-5) mixed with the 
  literal string "Not Available"
- `emergency_services`: clean "Yes"/"No" text values
- `score` (timely_care): mostly numeric-looking text, but known (per 
  CMS documentation) to include "Not Available" for some measures — 
  kept as TEXT rather than casting, to avoid load failures
- `excess_readmission_ratio`: clean decimal text, safe to cast to NUMERIC

## Resulting Design Decision
Built reusable helper functions (`target.safe_to_numeric`, 
`safe_to_integer`, `safe_to_date`, `safe_to_boolean`, `clean_text`) 
rather than repeating CASE WHEN logic in every migration function. 
Each helper treats known placeholder values ("Not Available", "N/A", 
empty string) as NULL, and uses EXCEPTION WHEN OTHERS to fail safely 
(return NULL) rather than abort the entire migration on one bad value.

## Investigation: Readmissions Row Count Validation

### Purpose
After migration, validated that the row count in target.fact_readmissions 
matched expectations based on staging data and migration filtering logic.

### Queries used

```sql
-- Confirm no duplicate facility_id + measure_name combinations in staging
SELECT COUNT(*) FROM (
    SELECT DISTINCT facility_id, measure_name 
    FROM staging_link.stg_readmissions
) t;
-- Result: 18,330 (matches total row count, confirming no duplicates)

-- Identify hospitals present in readmissions data but missing from dim_hospital
SELECT DISTINCT r.facility_id 
FROM staging_link.stg_readmissions r
WHERE NOT EXISTS (
    SELECT 1 FROM target.dim_hospital d WHERE d.facility_id = r.facility_id
);
-- Result: 10 facility_ids

-- Confirm these facility_ids genuinely don't exist in dim_hospital
SELECT * FROM target.dim_hospital 
WHERE facility_id IN (
    '010008','010059','050589','070012','100047',
    '100092','390326','450143','450271','450411'
);
-- Result: 0 rows returned, confirming these hospitals were not loaded
-- into dim_hospital (likely absent from, or filtered out of, the
-- Hospital General Information source dataset)
```

### Findings
- staging.stg_readmissions: 18,330 rows, all distinct (facility_id, measure_name) pairs
- 10 hospitals present in the Readmissions dataset are not present in 
  dim_hospital, likely due to independent refresh timing or facility 
  status differences between CMS source files
- fn_migration_readmissions excludes rows for facilities not present in 
  dim_hospital, via a referential integrity check (EXISTS), to maintain 
  FK validity in the star schema
- Expected exclusion: 10 hospitals × 6 readmission measures each = 60 rows
- target.fact_readmissions: 18,270 rows — confirmed to match expected 
  count exactly (18,330 - 60)

### Conclusion
Row count difference is fully explained and expected. No data quality 
issue or migration bug — the referential integrity check is working as 
designed, correctly protecting foreign key integrity in the star schema.