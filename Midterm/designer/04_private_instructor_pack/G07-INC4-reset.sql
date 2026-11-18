-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC4 (Reset & Remediation Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Target Roles: app_backup_grp / campussafe_backup
-- Affected Process: Automated Logical Backup (pg_dump) & Recovery Protocol
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Restore comprehensive SELECT privileges on all public schema tables and sequences
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_backup_grp;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO app_backup_grp;

-- 2. Configure default privileges to prevent future privilege regressions
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_backup_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO app_backup_grp;

-- 3. Hardening: Grant PostgreSQL 14+ pre-defined read-all data role if available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_data') THEN
        EXECUTE 'GRANT pg_read_all_data TO app_backup_grp;';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_settings') THEN
        EXECUTE 'GRANT pg_read_all_settings TO app_backup_grp;';
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

COMMIT;

-- Verification:
-- 1. Inspect table privileges for backup group
SELECT grantee, table_name, privilege_type 
FROM information_schema.table_privileges 
WHERE grantee = 'app_backup_grp' AND table_name IN ('report_status_history', 'attachment')
ORDER BY table_name;

-- 2. Verify role memberships
SELECT r.rolname,
       ARRAY(SELECT b.rolname FROM pg_auth_members m JOIN pg_roles b ON (m.roleid = b.oid) WHERE m.member = r.oid) as memberships
FROM pg_roles r 
WHERE r.rolname = 'campussafe_backup';
