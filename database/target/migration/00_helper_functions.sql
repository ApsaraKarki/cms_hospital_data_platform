-- Reusable data-cleaning helper functions used across all migration functions.
-- Keeps CASE WHEN cleaning logic centralized instead of repeated in every function.

-- Safely converts a text value to NUMERIC, returning NULL for
-- known "missing data" placeholder strings or invalid values.
CREATE OR REPLACE FUNCTION target.safe_to_numeric(val TEXT)
RETURNS NUMERIC AS $$
BEGIN
    IF val IS NULL OR TRIM(val) IN ('', 'Not Available', 'N/A', 'NA') THEN
        RETURN NULL;
    END IF;
    RETURN TRIM(val)::NUMERIC;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;  -- any unexpected non-numeric text becomes NULL instead of failing the whole load
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Safely converts a text value to INTEGER, same missing-data handling as above.
CREATE OR REPLACE FUNCTION target.safe_to_integer(val TEXT)
RETURNS INTEGER AS $$
BEGIN
    IF val IS NULL OR TRIM(val) IN ('', 'Not Available', 'N/A', 'NA') THEN
        RETURN NULL;
    END IF;
    RETURN TRIM(val)::INTEGER;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Safely converts a text date (MM/DD/YYYY) to DATE.
CREATE OR REPLACE FUNCTION target.safe_to_date(val TEXT)
RETURNS DATE AS $$
BEGIN
    IF val IS NULL OR TRIM(val) IN ('', 'Not Available', 'N/A', 'NA') THEN
        RETURN NULL;
    END IF;
    RETURN TO_DATE(TRIM(val), 'MM/DD/YYYY');
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Converts common Yes/No/Y/N text values to BOOLEAN.
CREATE OR REPLACE FUNCTION target.safe_to_boolean(val TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF val IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN CASE TRIM(UPPER(val))
        WHEN 'YES' THEN TRUE
        WHEN 'Y' THEN TRUE
        WHEN 'NO' THEN FALSE
        WHEN 'N' THEN FALSE
        ELSE NULL
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Trims whitespace and converts empty strings to NULL for general text fields.
CREATE OR REPLACE FUNCTION target.clean_text(val TEXT)
RETURNS TEXT AS $$
BEGIN
    IF val IS NULL OR TRIM(val) = '' THEN
        RETURN NULL;
    END IF;
    RETURN TRIM(val);
END;
$$ LANGUAGE plpgsql IMMUTABLE;