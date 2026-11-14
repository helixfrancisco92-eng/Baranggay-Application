
-- ============================================
-- HABALGO - ACTIVITY 4
-- 02_grant_privileges.sql
-- ============================================

-- 1. Grant database connection

DO $$
BEGIN
    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO habalgo_admin_role',
        current_database()
    );

    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO habalgo_app_role',
        current_database()
    );

    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO habalgo_auditor_role',
        current_database()
    );
END
$$;

-- 2. Grant schema access

GRANT USAGE, CREATE ON SCHEMA public
TO habalgo_admin_role;

GRANT USAGE ON SCHEMA public
TO habalgo_app_role;

GRANT USAGE ON SCHEMA public
TO habalgo_auditor_role;

-- 3. Administrator permissions

GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA public
TO habalgo_admin_role;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
TO habalgo_admin_role;

GRANT EXECUTE
ON ALL FUNCTIONS IN SCHEMA public
TO habalgo_admin_role;

-- 4. Application permissions

GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO habalgo_app_role;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO habalgo_app_role;

-- 5. Auditor permissions

GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO habalgo_auditor_role;

-- 6. Default privileges for future tables

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE
ON TABLES TO habalgo_app_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT
ON TABLES TO habalgo_auditor_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES
ON TABLES TO habalgo_admin_role;

-- 7. Default sequence privileges

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT
ON SEQUENCES TO habalgo_app_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES
ON SEQUENCES TO habalgo_admin_role;
