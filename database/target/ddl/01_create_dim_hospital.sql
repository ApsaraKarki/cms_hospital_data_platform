-- Dimension table: one row per hospital
-- Source: staging.stg_hospital_general

CREATE TABLE IF NOT EXISTS target.dim_hospital (
    facility_id                  VARCHAR(10) PRIMARY KEY,   -- CCN, keep as text to preserve leading zeros
    facility_name                VARCHAR(255) NOT NULL,
    address                      VARCHAR(255),
    city_town                    VARCHAR(100),
    state                        VARCHAR(2),
    zip_code                     VARCHAR(10),
    county_parish                VARCHAR(100),
    telephone_number              VARCHAR(20),
    hospital_type                VARCHAR(100),
    hospital_ownership           VARCHAR(100),
    emergency_services            BOOLEAN,
    birthing_friendly_designation BOOLEAN,
    hospital_overall_rating       SMALLINT,                  -- 1-5 star rating
    hospital_overall_rating_footnote VARCHAR(500),
    loaded_at                    TIMESTAMP DEFAULT NOW()      -- audit column: when this row was migrated
);