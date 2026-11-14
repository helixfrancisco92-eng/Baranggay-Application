-- =========================================
-- REVOKE UNNECESSARY PRIVILEGES
-- =========================================

-- Auditor must not modify records
REVOKE INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
FROM campussafe_auditor_role;

-- Auditor cannot create database objects
REVOKE CREATE ON SCHEMA public
FROM campussafe_auditor_role;

-- Application role cannot create database objects
REVOKE CREATE ON SCHEMA public
FROM campussafe_app_role;