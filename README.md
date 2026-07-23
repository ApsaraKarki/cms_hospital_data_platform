# CMS Hospital Data Platform

An end-to-end data platform that ingests, cleans, and models publicly available 
U.S. hospital quality data from the Centers for Medicare & Medicaid Services (CMS), 
culminating in an interactive Power BI dashboard.

## Overview

This project follows a staging-to-warehouse ETL pattern commonly used in 
production data platforms:

1. **Extract** — Raw CSV files are downloaded from the CMS Provider Data Catalog, 
   covering four related hospital quality datasets.
2. **Load (Stage)** — Raw CSVs are loaded as-is into a PostgreSQL **staging** 
   database, preserving the original structure for traceability and reprocessing.
3. **Transform** — SQL functions clean, standardize, and validate the staged data 
   (handling data type mismatches, null values, duplicate records, and 
   inconsistent formatting — e.g., preserving leading zeros in CMS Certification 
   Numbers).
4. **Load (Target)** — Cleaned data is loaded into a **target/warehouse** 
   database, modeled as a star schema (fact and dimension tables) optimized for 
   analytical querying.
5. **Visualize** — Power BI connects directly to the warehouse to build an 
   interactive hospital quality dashboard.

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

## Tech Stack

- **PostgreSQL** — staging and warehouse databases
- **SQL** — data cleaning/transformation functions (staging → target)
- **PowerShell** — local deployment scripting
- **Power BI** — dashboard and analytics layer

## Roadmap

- [ ] Migrate repository to GitLab
- [ ] Build CI/CD pipeline for automated deployment
