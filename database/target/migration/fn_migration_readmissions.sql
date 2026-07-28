-- Migrates staging.stg_readmissions -> target.fact_readmissions
-- Cleans: numeric/date casting, whitespace
-- Upsert key: facility_id + measure_name (natural composite key for this grain)

CREATE OR REPLACE FUNCTION target.fn_migration_readmissions()
RETURNS void AS $$
BEGIN
    INSERT INTO target.fact_readmissions (
        facility_id, measure_name, number_of_discharges, footnote,
        excess_readmission_ratio, predicted_readmission_rate,
        expected_readmission_rate, number_of_readmissions,
        start_date, end_date
    )
    SELECT
        target.clean_text(facility_id),
        target.clean_text(measure_name),
        target.safe_to_integer(number_of_discharges),
        target.clean_text(footnote),
        target.safe_to_numeric(excess_readmission_ratio),
        target.safe_to_numeric(predicted_readmission_rate),
        target.safe_to_numeric(expected_readmission_rate),
        target.safe_to_integer(number_of_readmissions),
        target.safe_to_date(start_date),
        target.safe_to_date(end_date)
    FROM staging_link.stg_readmissions
    WHERE facility_id IS NOT NULL
      AND EXISTS (                          -- avoid FK violation if a hospital wasn't loaded
          SELECT 1 FROM target.dim_hospital d WHERE d.facility_id = stg_readmissions.facility_id
      )
    ON CONFLICT (facility_id, measure_name) DO UPDATE SET
        number_of_discharges       = EXCLUDED.number_of_discharges,
        footnote                   = EXCLUDED.footnote,
        excess_readmission_ratio    = EXCLUDED.excess_readmission_ratio,
        predicted_readmission_rate  = EXCLUDED.predicted_readmission_rate,
        expected_readmission_rate   = EXCLUDED.expected_readmission_rate,
        number_of_readmissions      = EXCLUDED.number_of_readmissions,
        start_date                 = EXCLUDED.start_date,
        end_date                   = EXCLUDED.end_date,
        loaded_at                  = NOW();
END;
$$ LANGUAGE plpgsql;