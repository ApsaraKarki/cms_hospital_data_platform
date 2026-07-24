"""
load_staging.py

Loads raw CMS CSV files into staging tables in PostgreSQL
(cms_hospital_quality_raw.staging schema).

Uses TRUNCATE + bulk COPY pattern: staging tables are wiped and
reloaded fresh each run, since staging is meant to always reflect
the latest raw extract, not accumulate history.
"""

import os
import sys
import logging
import psycopg2
from dotenv import load_dotenv

# --- Path setup: find project root regardless of where script is run from ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
DATA_RAW_DIR = os.path.join(PROJECT_ROOT, "data", "raw")

load_dotenv(os.path.join(PROJECT_ROOT, ".env"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)
logger = logging.getLogger(__name__)

# Map: raw CSV filename prefix -> staging table name
TABLE_MAP = {
    "hospital_general_info": "stg_hospital_general",
    "timely_effective_care": "stg_timely_care",
    "hcahps_survey": "stg_hcahps",
    "readmissions": "stg_readmissions",
}


def get_connection():
    """Open a connection to the staging (raw) database using .env credentials."""
    return psycopg2.connect(
        host=os.getenv("PGHOST"),
        port=os.getenv("PGPORT"),
        dbname=os.getenv("PGDATABASE"),
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD"),
    )


def find_latest_file(prefix: str) -> str:
    """Find the most recent CSV file for a given dataset prefix (by filename)."""
    matches = [f for f in os.listdir(DATA_RAW_DIR) if f.startswith(prefix) and f.endswith(".csv")]
    if not matches:
        raise FileNotFoundError(f"No CSV found for prefix '{prefix}' in {DATA_RAW_DIR}")
    # Filenames include a date stamp, so sorting descending gives the latest
    matches.sort(reverse=True)
    return os.path.join(DATA_RAW_DIR, matches[0])


def load_table(conn, prefix: str, table_name: str):
    """Truncate the staging table, then bulk-load the CSV using COPY."""
    filepath = find_latest_file(prefix)
    logger.info(f"Loading '{table_name}' from {filepath}")

    with conn.cursor() as cur:
        # Clear existing data — staging always reflects the latest extract only
        cur.execute(f"TRUNCATE TABLE staging.{table_name};")

        with open(filepath, "r", encoding="utf-8") as f:
            cur.copy_expert(
                sql=f"""
                    COPY staging.{table_name}
                    FROM STDIN
                    WITH (FORMAT csv, HEADER true, NULL '')
                """,
                file=f,
            )

        cur.execute(f"SELECT COUNT(*) FROM staging.{table_name};")
        row_count = cur.fetchone()[0]

    conn.commit()
    logger.info(f"Loaded '{table_name}': {row_count} rows")
    return row_count


def main():
    logger.info("=== Starting staging load ===")

    conn = get_connection()
    results = {}

    try:
        for prefix, table_name in TABLE_MAP.items():
            try:
                row_count = load_table(conn, prefix, table_name)
                results[table_name] = {"status": "success", "rows": row_count}
            except Exception as e:
                conn.rollback()
                logger.error(f"Failed to load '{table_name}': {e}")
                results[table_name] = {"status": "failed", "error": str(e)}
    finally:
        conn.close()

    logger.info("=== Staging Load Summary ===")
    for table, result in results.items():
        logger.info(f"{table}: {result}")


if __name__ == "__main__":
    main()