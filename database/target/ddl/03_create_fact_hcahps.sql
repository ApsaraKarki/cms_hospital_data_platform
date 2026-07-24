-- Fact table: patient experience survey results
-- Source: staging.stg_hcahps
-- Grain: one row per hospital per HCAHPS question/measure

CREATE TABLE IF NOT EXISTS target.fact_hcahps (
    hcahps_id                          BIGSERIAL PRIMARY KEY,   -- surrogate key
    facility_id                         VARCHAR(10) NOT NULL REFERENCES target.dim_hospital(facility_id),
    hcahps_measure_id                    VARCHAR(50),
    hcahps_question                     VARCHAR(255),
    hcahps_answer_description            VARCHAR(255),
    patient_survey_star_rating           SMALLINT,
    patient_survey_star_rating_footnote   VARCHAR(500),
    hcahps_answer_percent                NUMERIC(5,2),
    hcahps_answer_percent_footnote        VARCHAR(500),
    hcahps_linear_mean_value             NUMERIC(6,2),
    number_of_completed_surveys           INTEGER,
    number_of_completed_surveys_footnote   VARCHAR(500),
    survey_response_rate_percent          NUMERIC(5,2),
    survey_response_rate_percent_footnote  VARCHAR(500),
    start_date                          DATE,
    end_date                            DATE,
    loaded_at                           TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fact_hcahps_facility ON target.fact_hcahps(facility_id);