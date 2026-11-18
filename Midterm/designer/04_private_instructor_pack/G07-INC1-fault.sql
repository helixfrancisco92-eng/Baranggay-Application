-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC1 (Fault Injection Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Target Roles: app_runtime_grp / campussafe_app
-- Affected Object: public.app_user
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

-- Prerequisites: Connected as PostgreSQL superuser (postgres) or database owner (campussafe_owner)
-- Verify target database before execution:
DO $$
BEGIN
    IF current_database() NOT LIKE '%disposable%' AND current_database() NOT LIKE '%test%' THEN
        RAISE NOTICE 'Executing on database: %. Ensure this is an isolated test environment.', current_database();
    END IF;
END $$;

BEGIN;

-- 1. Ensure table-wide UPDATE privilege is granted to app_runtime_grp (simulating flawed baseline)
GRANT UPDATE ON public.app_user TO app_runtime_grp;

-- 2. Simulate the privilege escalation symptom under runtime service credentials
-- A regular student/reporter account (user_id = 2) has their role escalated to Administrator (role_id = 1)
-- and an administrator account (user_id = 1) has their account status suspended
UPDATE public.app_user 
SET role_id = (SELECT role_id FROM public.role WHERE role_name ILIKE '%Admin%' ORDER BY role_id LIMIT 1)
WHERE user_id = 2;

UPDATE public.app_user 
SET account_status = 'suspended'
WHERE user_id = 1;

COMMIT;

-- Verification output of injected state
SELECT user_id, username, full_name, role_id, account_status 
FROM public.app_user 
WHERE user_id IN (1, 2)
ORDER BY user_id;
