-- =========================================
-- GRANT DATABASE PRIVILEGES
-- =========================================

-- Database connection
GRANT CONNECT ON DATABASE campussafe_db
TO campussafe_admin_role,
   campussafe_app_role,
   campussafe_auditor_role;

-- Schema access
GRANT USAGE, CREATE ON SCHEMA public
TO campussafe_admin_role;

GRANT USAGE ON SCHEMA public
TO campussafe_app_role,
   campussafe_auditor_role;

-- Admin permissions
GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA public
TO campussafe_admin_role;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
TO campussafe_admin_role;

-- Application permissions
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO campussafe_app_role;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO campussafe_app_role;

-- Auditor permissions
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO campussafe_auditor_role;