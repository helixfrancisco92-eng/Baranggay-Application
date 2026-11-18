-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC1 (Reset & Remediation Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Target Roles: app_runtime_grp / campussafe_app
-- Affected Object: public.app_user
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

-- Prerequisites: Connected as PostgreSQL superuser (postgres) or database owner
BEGIN;

-- 1. Restore baseline user roles and account statuses
-- Revert user_id = 2 back to regular campus reporter / student role (role_id = 4 or non-admin)
UPDATE public.app_user 
SET role_id = (SELECT role_id FROM public.role WHERE role_name ILIKE '%Reporter%' OR role_name ILIKE '%User%' ORDER BY role_id DESC LIMIT 1),
    account_status = 'active'
WHERE user_id = 2;

-- Revert administrator (user_id = 1) back to active status
UPDATE public.app_user 
SET account_status = 'active'
WHERE user_id = 1;

-- 2. Revoke whole-table UPDATE privilege from app_runtime_grp
REVOKE UPDATE ON public.app_user FROM app_runtime_grp;

-- 3. Enforce Least Privilege: Grant column-level UPDATE on safe profile fields ONLY
GRANT UPDATE (full_name, email, password_hash) ON public.app_user TO app_runtime_grp;

COMMIT;

-- Verification of reset state
-- 1. Verify user attributes are restored
SELECT user_id, username, full_name, role_id, account_status 
FROM public.app_user 
WHERE user_id IN (1, 2)
ORDER BY user_id;

-- 2. Verify column-level privileges in catalog
SELECT grantee, table_name, column_name, privilege_type 
FROM information_schema.column_privileges 
WHERE table_name = 'app_user' AND grantee = 'app_runtime_grp'
ORDER BY column_name;
