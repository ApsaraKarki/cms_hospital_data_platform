#cd etl
# python extract_cms_api.py
"""
extract_cms_api.py

Downloads CMS hospital quality datasets from the data.cms.gov API
and saves them as raw CSV files for loading into the staging database.
"""

import requests
import pandas as pd
import os
import logging
from datetime import datetime
from config import DATASETS, OUTPUT_DIR

# --- Set up logging so you can see what happened, and debug later ---
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)
logger = logging.getLogger(__name__)


def fetch_dataset(name: str, url: str) -> pd.DataFrame:
    """Fetch a single dataset from the CMS API and return it as a DataFrame."""
    logger.info(f"Requesting data for '{name}' from {url}")

    response = requests.get(url, timeout=60)

    # Raise an error if the request failed (bad URL, server error, etc.)
    response.raise_for_status()

    data = response.json()
    df = pd.DataFrame(data)

    logger.info(f"Retrieved {len(df)} rows and {len(df.columns)} columns for '{name}'")
    return df


def save_raw_csv(df: pd.DataFrame, name: str, output_dir: str) -> str:
    """Save the DataFrame as a CSV file with a timestamp in the filename."""
    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d")
    filepath = os.path.join(output_dir, f"{name}_{timestamp}.csv")

    df.to_csv(filepath, index=False)
    logger.info(f"Saved '{name}' to {filepath}")

    return filepath


def main():
    logger.info("=== Starting CMS data extraction ===")

    results = {}

    for name, url in DATASETS.items():
        try:
            df = fetch_dataset(name, url)
            filepath = save_raw_csv(df, name, OUTPUT_DIR)
            results[name] = {"status": "success", "rows": len(df), "file": filepath}
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch '{name}': {e}")
            results[name] = {"status": "failed", "error": str(e)}

    # --- Summary report at the end ---
    logger.info("=== Extraction Summary ===")
    for name, result in results.items():
        logger.info(f"{name}: {result}")


if __name__ == "__main__":
    main()