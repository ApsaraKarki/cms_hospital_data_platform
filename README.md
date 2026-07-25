# CMS Hospital Data Platform

An end-to-end data platform that ingests, cleans, and models publicly available 
U.S. hospital quality data from the Centers for Medicare & Medicaid Services (CMS), 
culminating in an interactive Power BI dashboard.

## Overview

This project follows a staging-to-warehouse ETL pattern commonly used in 
production data platforms:

1. **Extract** — A Python script pulls raw data from the CMS Provider Data 
   Catalog API, covering four related hospital quality datasets.
2. **Load (Stage)** — Raw CSVs are bulk-loaded as-is into a PostgreSQL 
   **staging** database, preserving the original structure for traceability 
   and reprocessing.
3. **Transform** — SQL functions clean, standardize, and validate the staged 
   data (handling data type mismatches, null values, duplicate records, and 
   inconsistent formatting — e.g., preserving leading zeros in CMS 
   Certification Numbers).
4. **Load (Target)** — Cleaned data is migrated into a **target/warehouse** 
   database, modeled as a star schema (fact and dimension tables) optimized 
   for analytical querying.
5. **Visualize** — Power BI connects directly to the warehouse to build an 
   interactive hospital quality dashboard.

Database structure (schemas, tables, indexes) is deployed once via a 
PowerShell script and is idempotent — safe to re-run without affecting 
existing data. The extraction → staging → migration pipeline is designed 
to be re-run on demand to refresh data, independent of the underlying schema.

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

CMS Provider Data Catalog (API)
│
▼ Python (extract_cms_api.py)
Raw CSV files (data/raw/)
│
▼ Python + psycopg2 (load_staging.py)
Staging Database — cms_hospital_quality_raw
schema: staging
• stg_hospital_general
• stg_timely_care
• stg_hcahps
• stg_readmissions
│
▼ SQL migration functions (staging → target)
Target Database / Warehouse — cms_hospital_quality
schema: target
• dim_hospital
• fact_readmissions
• fact_hcahps
• fact_timely_care
│
▼
Power BI Dashboard

## Tech Stack

- **Python** — data extraction (CMS API), staging load (bulk `COPY` via psycopg2)
- **PostgreSQL** — staging and target/warehouse databases
- **SQL** — schema DDL, data cleaning/transformation and migration functions
- **PowerShell** — idempotent local deployment of database structure
- **Power BI** — dashboard and analytics layer

## Repository Structure

cms_hospital_data_platform/
├── .gitignore
├── .env.example
├── README.md
├── etl/
│ ├── extract_cms_api.py # Pulls data from CMS API, saves as CSV
│ └── config.py # Dataset API endpoints, output paths
├── database/
│ ├── staging/
│ │ ├── ddl/ # Schema + table creation (staging)
│ │ └── load/
│ │ └── load_staging.py # Bulk-loads CSVs into staging tables
│ ├── target/
│ │ ├── ddl/ # Schema + table creation (star schema)
│ │ └── migration/ # Cleaning/transformation SQL functions
│ └── deploy/
│ └── deploy_local.ps1 # One-time idempotent structure deployment
├── powerbi/ # Power BI (.pbix) dashboard
├── documentation/ # Setup notes and troubleshooting logs
└── data/
└── raw/ # Extracted CSVs (gitignored)

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
```

### 3. Configure environment variables
Copy `.env.example` to `.env` in the project root and fill in your PostgreSQL credentials:
PGHOST=localhost
PGPORT=5432
PGDATABASE=cms_hospital_quality_raw
PGUSER=postgres
PGPASSWORD=your_password_here

### 4. Deploy database structure
Creates both databases, schemas, and all tables. Safe to re-run.
```powershell
.\database\deploy\deploy_local.ps1
```

### 5. Extract data from CMS
```powershell
cd etl
python extract_cms_api.py
```

### 6. Load data into staging
```powershell
cd ..
python database\staging\load\load_staging.py
```

### 7. Migrate staging → target *(in progress)*
```powershell
# Coming soon
```

### 8. Open the Power BI dashboard
Open `powerbi/cms_hospital_quality.pbix`, connect to the `cms_hospital_quality` 
database, and refresh.

## Roadmap

- [x] CMS data extraction (Python + API, with pagination/CSV export handling)
- [x] Staging database setup and bulk load
- [x] Idempotent local deployment script (PowerShell)
- [ ] Staging → target migration (cleaning/transformation)
- [ ] Power BI dashboard
- [ ] Migrate repository to GitLab
- [ ] CI/CD pipeline for automated deployment