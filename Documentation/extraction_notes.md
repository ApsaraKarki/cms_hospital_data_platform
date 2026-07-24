# CMS Data Extraction — Setup Notes & Troubleshooting Log

This document records the steps taken to set up the Python environment and 
build the CMS data extraction script, including issues encountered and how 
they were resolved. Kept for reference and to demonstrate the troubleshooting 
process for this stage of the pipeline.

---

# CMS Data Extraction — Command Log

## Environment Setup
```powershell
python --version                                          # Python 3.14.5
pip --version                                              # pip 26.1.1
git --version                                               # git 2.54.0
Get-ExecutionPolicy                                         # Restricted
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser          # fix: allow local scripts to run
```

## Virtual Environment
```powershell
cd C:\Users\apsar\Git\cms_hospital_data_platform\etl
python -m venv venv
.\venv\Scripts\Activate.ps1                                  # confirmed via (venv) prefix
```

## Package Install
```powershell
pip install requests pandas
```
**Error:** pandas DLL load failed (Application Control blocked file)
**Fix:**
```powershell
pip uninstall pandas -y
pip install pandas --only-binary :all:                       # resolved import error
python -c "import pandas; print(pandas.__version__)"         # verified OK
pip freeze > requirements.txt
```

## Extraction Script Fixes
**Error 1:** JSON API endpoint returned only 4 rows per dataset (bad response structure)
**Fix:** Switched to CSV export endpoint: `.../datastore/query/{dataset-id}/0/download?format=csv`

**Error 2:** CSVs saved to wrong folder (relative path resolved from terminal location, not script location)
**Fix:** Used `os.path.abspath(__file__)` to anchor output path in `config.py`

**Adjustment:** Read CSV with `dtype=str` to preserve leading zeros in Facility ID (CCN)

## Final Run
```powershell
python extract_cms_api.py
```

All saved to `data/raw/` — row counts verified against CMS website.


hospital_general_info : 5,432 rows
timely_effective_care : 138,173 rows
hcahps_survey : 325,856 rows
readmissions : 18,330 rows