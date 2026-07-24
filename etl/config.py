# config.py
import os

# CSV download endpoints for each CMS dataset (data.cms.gov Provider Data Catalog API)
DATASETS = {
    "hospital_general_info": "https://data.cms.gov/provider-data/api/1/datastore/query/xubh-q36u/0/download?format=csv",
    "timely_effective_care": "https://data.cms.gov/provider-data/api/1/datastore/query/yv7e-xc69/0/download?format=csv",
    "hcahps_survey": "https://data.cms.gov/provider-data/api/1/datastore/query/dgck-syfz/0/download?format=csv",
    "readmissions": "https://data.cms.gov/provider-data/api/1/datastore/query/9n3s-kdb3/0/download?format=csv",
}

# Absolute path, built relative to THIS file's location (config.py),
# not relative to wherever the script happens to be run from.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, "..", "data", "raw")