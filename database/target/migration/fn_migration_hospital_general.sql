-- Migrates staging.stg_hospital_general -> target.dim_hospital
-- Cleans: "Not Available" ratings, Yes/No -> boolean, whitespace trimming
-- Upsert: re-running updates existing hospitals rather than duplicating

CREATE OR REPLACE FUNCTION target.fn_migration_hospital_general()
RETURNS void AS $$
BEGIN
    INSERT INTO target.dim_hospital (
        facility_id, facility_name, address, city_town, state, zip_code,
        county_parish, telephone_number, hospital_type, hospital_ownership,
        emergency_services, birthing_friendly_designation,
        hospital_overall_rating, hospital_overall_rating_footnote
    )
    SELECT
        target.clean_text(facility_id),
        target.clean_text(facility_name),
        target.clean_text(address),
        target.clean_text(citytown),
        target.clean_text(state),
        target.clean_text(zip_code),
        target.clean_text(countyparish),
        target.clean_text(telephone_number),
        target.clean_text(hospital_type),
        target.clean_text(hospital_ownership),
        target.safe_to_boolean(emergency_services),
        target.safe_to_boolean(meets_criteria_for_birthing_friendly_designation),
        target.safe_to_integer(hospital_overall_rating),
        target.clean_text(hospital_overall_rating_footnote)
    FROM staging_link.stg_hospital_general
    WHERE facility_id IS NOT NULL          -- primary key can't be null
    ON CONFLICT (facility_id) DO UPDATE SET
        facility_name                    = EXCLUDED.facility_name,
        address                          = EXCLUDED.address,
        city_town                        = EXCLUDED.city_town,
        state                            = EXCLUDED.state,
        zip_code                         = EXCLUDED.zip_code,
        county_parish                    = EXCLUDED.county_parish,
        telephone_number                 = EXCLUDED.telephone_number,
        hospital_type                    = EXCLUDED.hospital_type,
        hospital_ownership               = EXCLUDED.hospital_ownership,
        emergency_services                = EXCLUDED.emergency_services,
        birthing_friendly_designation     = EXCLUDED.birthing_friendly_designation,
        hospital_overall_rating           = EXCLUDED.hospital_overall_rating,
        hospital_overall_rating_footnote  = EXCLUDED.hospital_overall_rating_footnote,
        loaded_at                        = NOW();
END;
$$ LANGUAGE plpgsql;