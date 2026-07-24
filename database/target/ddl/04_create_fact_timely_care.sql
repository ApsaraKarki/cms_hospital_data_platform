-- Fact table: timely and effective care process measures
-- Source: staging.stg_timely_care
-- Grain: one row per hospital per condition per measure

CREATE TABLE IF NOT EXISTS target.fact_timely_care (
    timely_care_id       BIGSERIAL PRIMARY KEY,     -- surrogate key
    facility_id           VARCHAR(10) NOT NULL REFERENCES target.dim_hospital(facility_id),
    condition            VARCHAR(255),
    measure_id            VARCHAR(50),
    measure_name          VARCHAR(255),
    score                VARCHAR(50),               -- kept as text: CMS mixes numeric scores with values like "Not Available"
    sample               VARCHAR(50),
    footnote             VARCHAR(500),
    start_date            DATE,
    end_date              DATE,
    loaded_at             TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fact_timely_care_facility ON target.fact_timely_care(facility_id);