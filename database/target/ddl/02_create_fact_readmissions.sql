-- Fact table: hospital readmission ratios by condition/measure
-- Source: staging.stg_readmissions
-- Grain: one row per hospital per measure

CREATE TABLE IF NOT EXISTS target.fact_readmissions (
    readmission_id             BIGSERIAL PRIMARY KEY,        -- surrogate key
    facility_id                 VARCHAR(10) NOT NULL REFERENCES target.dim_hospital(facility_id),
    measure_name                VARCHAR(255),
    number_of_discharges         INTEGER,
    footnote                    VARCHAR(500),
    excess_readmission_ratio     NUMERIC(6,4),
    predicted_readmission_rate   NUMERIC(6,4),
    expected_readmission_rate    NUMERIC(6,4),
    number_of_readmissions       INTEGER,
    start_date                  DATE,
    end_date                    DATE,
    loaded_at                   TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fact_readmissions_facility ON target.fact_readmissions(facility_id);