# CMS Hospital Data Platform

An end-to-end data platform that ingests, cleans, and models publicly available 
U.S. hospital quality data from the Centers for Medicare & Medicaid Services (CMS), 
culminating in an interactive Power BI dashboard.

## Overview

This project follows a staging-to-warehouse ETL pattern commonly used in 
production data platforms:

1. **Extract**  A Python script pulls raw data from the CMS Provider Data 
   Catalog API, covering four related hospital quality datasets.
2. **Load (Stage)**  Raw CSVs are bulk-loaded as-is into a PostgreSQL 
   **staging** database, preserving the original structure for traceability 
   and reprocessing. Staging is truncated and reloaded fresh on every run.
3. **Transform**  SQL functions clean, standardize, and validate the staged 
   data (handling data type mismatches, null values, and inconsistent 
   formatting  e.g., preserving leading zeros in CMS Certification Numbers).
4. **Load (Target)**  Cleaned data is migrated into a **target/warehouse** 
   database, modeled as a star schema (fact and dimension tables) optimized 
   for analytical querying.
5. **Visualize**  Power BI connects directly to the warehouse to build an 
   interactive hospital quality dashboard.

Database structure (schemas, tables, indexes) is deployed separately from 
the data pipeline. `deploy_local.ps1` is run manually, only during initial 
setup or when the schema changes. `run_pipeline.ps1` handles the repeatable 
extract → load cycle and does not modify schema.

## Data Sources

Four datasets from the [CMS Provider Data Catalog](https://data.cms.gov/provider-data), 
joined on **CMS Certification Number (CCN)**:

| Dataset | Description |
|---|---|
| Hospital General Information | Hospital identity, ownership, overall rating |
| Timely and Effective Care – Hospital | Process-of-care measures (ER wait times, etc.) |
| Patient Survey (HCAHPS) – Hospital | Patient experience survey scores |
| Hospital Readmissions Reduction Program | 30-day excess readmission ratios by condition |

## Architecture

```
CMS Provider Data Catalog (API)
        │
        ▼  Python (extract_cms_api.py)
  Raw CSV files (data/raw/)
        │
        ▼  Python + psycopg2 (load_staging.py)
  Staging Database — cms_hospital_quality_raw
   schema: staging
   - stg_hospital_general
   - stg_timely_care
   - stg_hcahps
   - stg_readmissions
        │
        ▼  postgres_fdw (staging_link foreign tables)
        │  SQL migration functions (staging → target, upsert)
        ▼
  Target Database / Warehouse — cms_hospital_quality
   schema: target
   - dim_hospital
   - fact_readmissions
   - fact_hcahps
   - fact_timely_care
        │
        ▼
     Power BI Dashboard
```

## Tech Stack

- **Python**  data extraction (CMS API), staging load (bulk `COPY` via psycopg2)
- **PostgreSQL**  staging and target/warehouse databases, connected 
  via postgres_fdw for cross-database migration
- **SQL**  schema DDL, data cleaning/transformation and migration functions
- **PowerShell**  idempotent local deployment of database structure, pipeline orchestration
- **Power BI**  dashboard and analytics layer


```
cms_hospital_data_platform/
├── .gitignore
├── .env.example
├── LICENSE
├── README.md
├── requirements.txt
├── run_pipeline.ps1              # Orchestrates: extract -> load staging
├── etl/
│   ├── venv/                     (gitignored)
│   ├── extract_cms_api.py        # Pulls data from CMS API, saves as CSV
│   └── config.py                 # Dataset API endpoints, output paths
├── database/
│   ├── staging/
│   │   ├── ddl/                  # Schema + table creation (staging)
│   │   └── load/
│   │       └── load_staging.py   # Bulk-loads CSVs into staging tables
│   ├── target/
│   │   ├── ddl/                  # Schema + table creation (star schema)
│   │   ├── fdw/                  # postgres_fdw setup (staging -> target link)
│   │   │   └── 00_setup_fdw.sql
│   │   └── migration/            # Cleaning/transformation/migration SQL functions
│   └── deploy/
│       └── deploy_local.ps1      # Idempotent structure deployment (DDL + FDW setup)
├── powerbi/                      # Power BI (.pbix) dashboard
├── documentation/                # Setup notes and troubleshooting logs
└── data/
    └── raw/                      # Extracted CSVs (gitignored)
```

## Getting Started

### Prerequisites
- Python 3.9+
- PostgreSQL (with `psql` available in PATH)
- Git

### 1. Clone the repository
```bash
git clone https://github.com/<your-username>/cms_hospital_data_platform.git
cd cms_hospital_data_platform
```

### 2. Set up the Python environment
```powershell
cd etl
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
cd ..
```

### 3. Configure environment variables
Copy `.env.example` to `.env` in the project root and fill in your PostgreSQL credentials:
```
PGHOST=localhost
PGPORT=5432
PGDATABASE=cms_hospital_quality_raw
PGUSER=postgres
PGPASSWORD=your_password_here
```

### 4. Deploy database structure
Creates both databases, schemas, tables, the postgres_fdw cross-database link, 
and migration function definitions. Idempotent — safe to re-run. Run once, 
or whenever the structure changes.
```powershell
.\database\deploy\deploy_local.ps1
```

### 5. Run the data pipeline
Extracts the latest data from the CMS API, loads it into staging tables, and 
migrates it into the target warehouse (cleaning, type casting, upsert).
```powershell
.\run_pipeline.ps1
```

### 6. Open the Power BI dashboard
Open `powerbi/cms_hospital_quality.pbix`, connect to the `cms_hospital_quality` 
database, and refresh.
```Coming soon
```

## Key Challenges & Solutions

A few notable issues encountered and resolved during development (full logs 
in `documentation/`):

- **API pagination/response format**  initial JSON API endpoint returned 
  only partial data per dataset. Resolved by switching to the CMS CSV 
  export endpoint, which returns the complete dataset in one request.
- **Leading zeros in CCN (Facility ID)**  CSV data read with explicit 
  `dtype=str` to prevent pandas/Postgres from silently stripping leading 
  zeros from hospital identifiers.
- **Silent pipeline failure**  the staging loader originally caught errors 
  per-table but always exited with a success code, causing the orchestration 
  script to report success even when every table failed to load. Fixed by 
  explicitly exiting with a non-zero code when any table fails.
- **Windows Application Control blocking pandas**  a native pandas 
  dependency was blocked by Windows Smart App Control; resolved by 
  reinstalling with a forced prebuilt binary wheel.
- **Cross-database querying**  staging and target live in separate 
  PostgreSQL databases, which Postgres doesn't support querying across 
  natively. Solved using `postgres_fdw`, exposing staging tables to the 
  target database as foreign tables. Connection credentials are passed 
  as parameterized `psql` variables, sourced from `.env`  never 
  hardcoded in SQL.
## Data Quality & Cleaning

Before building migration logic, staging data was sampled to identify 
inconsistent values (e.g., `"Not Available"` mixed into numeric fields, 
text-based Yes/No flags). Rather than repeating cleaning logic across 
each migration function, reusable SQL helper functions were built for 
safe type casting (`safe_to_numeric`, `safe_to_integer`, `safe_to_date`, 
`safe_to_boolean`) and text cleanup (`clean_text`)  each designed to 
degrade gracefully to `NULL` on unexpected values rather than fail the 
entire load.

See [`documentation/data_quality_notes.md`](./documentation/data_quality_notes.md) 
for the full investigation and findings.

## Roadmap

- [x] CMS data extraction (Python + API, with CSV export + leading-zero handling)
- [x] Staging database setup and bulk load
- [x] Idempotent local deployment script (PowerShell)
- [x] Pipeline orchestration script (extract + load)
- [x] Staging → target migration (cleaning/transformation, upsert logic)
- [ ] Power BI dashboard
- [ ] Migrate repository to GitLab
- [ ] CI/CD pipeline for automated deployment to VM

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
