-- Auto-generated from readmissions_20260724.csv
CREATE TABLE IF NOT EXISTS staging.stg_readmissions (
    facility_name TEXT,
    facility_id TEXT,
    state TEXT,
    measure_name TEXT,
    number_of_discharges TEXT,
    footnote TEXT,
    excess_readmission_ratio TEXT,
    predicted_readmission_rate TEXT,
    expected_readmission_rate TEXT,
    number_of_readmissions TEXT,
    start_date TEXT,
    end_date TEXT
);
