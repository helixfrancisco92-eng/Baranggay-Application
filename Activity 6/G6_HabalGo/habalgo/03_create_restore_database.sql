-- ==============================================================================
-- HabalGo (Group 6) — Test Database Creation Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Object: grp00_habalgodb_activity6_restore_test
-- ==============================================================================
-- IMPORTANT SAFETY NOTICE:
-- This script creates a completely isolated, standalone test database.
-- It NEVER modifies, overwrites, or drops the original production database (grp00_habalgodb).
-- ==============================================================================

-- 1. Ensure connected as an administrative role (e.g., postgres) to cluster maintenance DB
-- Check if database already exists before creating
SELECT 'Creating separate restore test database: grp00_habalgodb_activity6_restore_test' AS status;

-- In psql, run from administrative shell:
-- CREATE DATABASE grp00_habalgodb_activity6_restore_test WITH OWNER postgres ENCODING 'UTF8';

-- Verification Query: Ensure the test database was created and is strictly separate
SELECT 
    datname AS database_name,
    pg_get_userbyid(datdba) AS owner,
    pg_encoding_to_char(encoding) AS encoding,
    datcollate AS collation,
    datctype AS ctype,
    datistemplate AS is_template
FROM pg_database
WHERE datname IN ('grp00_habalgodb', 'grp00_habalgodb_activity6_restore_test')
ORDER BY datname;

