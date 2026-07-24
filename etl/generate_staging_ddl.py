"""
generate_staging_ddl.py

Reads the header row of each raw CSV and generates a CREATE TABLE
statement for the staging schema, with every column as TEXT.
Staging tables intentionally have no typed/constrained columns —
cleaning and typing happens later in the migration step.
"""

import pandas as pd
import os
import re
from config import OUTPUT_DIR

# Map: raw file prefix -> target staging table name
TABLE_MAP = {
    "hospital_general_info": "stg_hospital_general",
    "timely_effective_care": "stg_timely_care",
    "hcahps_survey": "stg_hcahps",
    "readmissions": "stg_readmissions",
}


def clean_column_name(col: str) -> str:
    """Convert a CSV header into a safe snake_case SQL column name."""
    col = col.strip().lower()
    col = re.sub(r"[^\w\s]", "", col)      # remove punctuation like / ( )
    col = re.sub(r"\s+", "_", col)         # spaces -> underscores
    return col


def generate_ddl_for_file(filepath: str, table_name: str) -> str:
    df = pd.read_csv(filepath, nrows=0)  # just read the header, not the data
    columns = [clean_column_name(c) for c in df.columns]

    col_lines = ",\n    ".join([f'{col} TEXT' for col in columns])

    ddl = f"""-- Auto-generated from {os.path.basename(filepath)}
CREATE TABLE IF NOT EXISTS staging.{table_name} (
    {col_lines}
);
"""
    return ddl


def main():
    raw_files = [f for f in os.listdir(OUTPUT_DIR) if f.endswith(".csv")]

    for prefix, table_name in TABLE_MAP.items():
        matching_file = next((f for f in raw_files if f.startswith(prefix)), None)
        if not matching_file:
            print(f"WARNING: no file found for '{prefix}', skipping.")
            continue

        filepath = os.path.join(OUTPUT_DIR, matching_file)
        ddl = generate_ddl_for_file(filepath, table_name)

        print(ddl)
        print("-" * 60)


if __name__ == "__main__":
    main()