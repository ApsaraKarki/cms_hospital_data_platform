-- Sets up postgres_fdw so the target database can query staging tables
-- directly, as if they were local. Required before any migration function runs.

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Drop and recreate for idempotency (CREATE SERVER has no IF NOT EXISTS).
-- CASCADE also removes any dependent user mapping automatically.
DROP SERVER IF EXISTS staging_server CASCADE;

CREATE SERVER staging_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host :'staging_host', port :'staging_port', dbname :'staging_dbname');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER staging_server
    OPTIONS (user :'staging_user', password :'staging_password');

-- Schema to hold the foreign (remote-looking) tables
CREATE SCHEMA IF NOT EXISTS staging_link;

-- Import all staging tables so they're queryable like local tables
-- (only if not already imported, since IMPORT FOREIGN SCHEMA has no IF NOT EXISTS)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'staging_link'
    ) THEN
        EXECUTE 'IMPORT FOREIGN SCHEMA staging FROM SERVER staging_server INTO staging_link';
    END IF;
END
$$;