-- Migrates staging.stg_hcahps -> target.fact_hcahps
-- Cleans: numeric/date casting, whitespace
-- Upsert key: facility_id + hcahps_measure_id

CREATE OR REPLACE FUNCTION target.fn_migration_hcahps()
RETURNS void AS $$
BEGIN
    INSERT INTO target.fact_hcahps (
        facility_id, hcahps_measure_id, hcahps_question, hcahps_answer_description,
        patient_survey_star_rating, patient_survey_star_rating_footnote,
        hcahps_answer_percent, hcahps_answer_percent_footnote,
        hcahps_linear_mean_value, number_of_completed_surveys,
        number_of_completed_surveys_footnote, survey_response_rate_percent,
        survey_response_rate_percent_footnote, start_date, end_date
    )
    SELECT
        target.clean_text(facility_id),
        target.clean_text(hcahps_measure_id),
        target.clean_text(hcahps_question),
        target.clean_text(hcahps_answer_description),
        target.safe_to_integer(patient_survey_star_rating),
        target.clean_text(patient_survey_star_rating_footnote),
        target.safe_to_numeric(hcahps_answer_percent),
        target.clean_text(hcahps_answer_percent_footnote),
        target.safe_to_numeric(hcahps_linear_mean_value),
        target.safe_to_integer(number_of_completed_surveys),
        target.clean_text(number_of_completed_surveys_footnote),
        target.safe_to_numeric(survey_response_rate_percent),
        target.clean_text(survey_response_rate_percent_footnote),
        target.safe_to_date(start_date),
        target.safe_to_date(end_date)
    FROM staging_link.stg_hcahps
    WHERE facility_id IS NOT NULL
      AND EXISTS (
          SELECT 1 FROM target.dim_hospital d WHERE d.facility_id = stg_hcahps.facility_id
      )
    ON CONFLICT (facility_id, hcahps_measure_id) DO UPDATE SET
        hcahps_question                       = EXCLUDED.hcahps_question,
        hcahps_answer_description              = EXCLUDED.hcahps_answer_description,
        patient_survey_star_rating             = EXCLUDED.patient_survey_star_rating,
        patient_survey_star_rating_footnote     = EXCLUDED.patient_survey_star_rating_footnote,
        hcahps_answer_percent                  = EXCLUDED.hcahps_answer_percent,
        hcahps_answer_percent_footnote          = EXCLUDED.hcahps_answer_percent_footnote,
        hcahps_linear_mean_value                = EXCLUDED.hcahps_linear_mean_value,
        number_of_completed_surveys              = EXCLUDED.number_of_completed_surveys,
        number_of_completed_surveys_footnote     = EXCLUDED.number_of_completed_surveys_footnote,
        survey_response_rate_percent            = EXCLUDED.survey_response_rate_percent,
        survey_response_rate_percent_footnote    = EXCLUDED.survey_response_rate_percent_footnote,
        start_date                             = EXCLUDED.start_date,
        end_date                               = EXCLUDED.end_date,
        loaded_at                              = NOW();
END;
$$ LANGUAGE plpgsql;