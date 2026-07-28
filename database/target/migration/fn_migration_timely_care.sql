-- Migrates staging.stg_timely_care -> target.fact_timely_care
-- Note: 'score' kept as TEXT (matches target DDL) since CMS mixes
-- numeric percentages with text values like "Not Available" in this field
-- Upsert key: facility_id + measure_id

CREATE OR REPLACE FUNCTION target.fn_migration_timely_care()
RETURNS void AS $$
BEGIN
    INSERT INTO target.fact_timely_care (
        facility_id, condition, measure_id, measure_name,
        score, sample, footnote, start_date, end_date
    )
    SELECT
        target.clean_text(facility_id),
        target.clean_text(condition),
        target.clean_text(measure_id),
        target.clean_text(measure_name),
        target.clean_text(score),      -- kept as text, mixed numeric/"Not Available"
        target.clean_text(sample),
        target.clean_text(footnote),
        target.safe_to_date(start_date),
        target.safe_to_date(end_date)
    FROM staging_link.stg_timely_care
    WHERE facility_id IS NOT NULL
      AND EXISTS (
          SELECT 1 FROM target.dim_hospital d WHERE d.facility_id = stg_timely_care.facility_id
      )
    ON CONFLICT (facility_id, measure_id) DO UPDATE SET
        condition   = EXCLUDED.condition,
        measure_name = EXCLUDED.measure_name,
        score       = EXCLUDED.score,
        sample      = EXCLUDED.sample,
        footnote    = EXCLUDED.footnote,
        start_date  = EXCLUDED.start_date,
        end_date    = EXCLUDED.end_date,
        loaded_at   = NOW();
END;
$$ LANGUAGE plpgsql;