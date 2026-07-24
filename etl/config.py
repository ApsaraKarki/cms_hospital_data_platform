# config.py
# API endpoints for each CMS dataset (get these from the "API" tab on each dataset page)

DATASETS = {
    "hospital_general_info": "https://data.cms.gov/data-api/v1/dataset/xubh-q36u/data",
    "timely_effective_care": "https://data.cms.gov/data-api/v1/dataset/yv7e-xc69/data",
    "hcahps_survey": "https://data.cms.gov/data-api/v1/dataset/dgck-syfz/data",
    "readmissions": "https://data.cms.gov/data-api/v1/dataset/9n3s-kdb3/data",
}

OUTPUT_DIR = "../data/raw"  # where CSVs will be saved

# replace these 4 URLs with the exact ones from each dataset's API tab on data.cms.gov (browser URL ≠ API endpoint, as we covered earlier)