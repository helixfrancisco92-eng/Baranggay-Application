-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC4 (Fault Injection Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Target Roles: app_backup_grp / campussafe_backup
-- Affected Process: Automated Logical Backup (pg_dump) & Recovery Protocol
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Ensure the backup group does not have pre-defined global read roles
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_data') THEN
        EXECUTE 'REVOKE pg_read_all_data FROM app_backup_grp;';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pg_read_all_settings') THEN
        EXECUTE 'REVOKE pg_read_all_settings FROM app_backup_grp;';
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- 2. Simulate permission revocation on an operational table (e.g. following a table restructure)
-- This causes non-superuser pg_dump to abort when extracting this table's data
REVOKE SELECT ON public.report_status_history FROM app_backup_grp;
REVOKE SELECT ON public.attachment FROM app_backup_grp;

COMMIT;

-- Verification of degraded backup privileges
SELECT grantee, table_name, privilege_type 
FROM information_schema.table_privileges 
WHERE grantee = 'app_backup_grp' AND table_name IN ('report_status_history', 'attachment');
