"""
extract_cms_api.py

Downloads CMS hospital quality datasets from the data.cms.gov API
(CSV export endpoint) and saves them as raw CSV files for loading
into the staging database.
"""

import requests
import pandas as pd
import os
import logging
from datetime import datetime
from io import StringIO
from config import DATASETS, OUTPUT_DIR

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)
logger = logging.getLogger(__name__)


def fetch_dataset(name: str, url: str) -> pd.DataFrame:
    """Fetch the full dataset as CSV from the CMS download endpoint."""
    logger.info(f"Requesting data for '{name}' from {url}")

    response = requests.get(url, timeout=120)
    response.raise_for_status()

    # Parse the CSV text directly into a DataFrame
    df = pd.read_csv(StringIO(response.text), dtype=str)  # dtype=str preserves leading zeros in CCN

    logger.info(f"Completed '{name}': {len(df)} rows, {len(df.columns)} columns")
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

    logger.info("=== Extraction Summary ===")
    for name, result in results.items():
        logger.info(f"{name}: {result}")


if __name__ == "__main__":
    main()