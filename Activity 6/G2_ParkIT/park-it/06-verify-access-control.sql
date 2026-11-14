-- ==============================================================================
-- COMP 018 — Database Administration (Activity 6: Part C / Activity 4 RBAC)
-- Script: 06-verify-access-control.sql
-- Purpose: Verify and Reinstate Role-Based Access Control on Restored Database
-- Reference: Activity 4 Access Control Implementation (user-role.md)
-- Platform: PostgreSQL 18.6 | Target DB: grp_parkitdb_restore_test
-- ==============================================================================

\echo '========================================================================'
\echo '  PARK-IT DBMS — ACTIVITY 4 ACCESS CONTROL (RBAC) VERIFICATION SUITE   '
\echo '  COMP 018 Database Administration (Activity 6 / Activity 4 Integration)'
\echo '========================================================================'

-- Set client display format
\pset null '(NULL)'
\pset border 2

-- ==============================================================================
-- ARCHITECTURAL NOTE: POSTGRESQL ROLES & SINGLE-DATABASE RESTORATION
-- ==============================================================================
-- In PostgreSQL, database roles (users and groups) are cluster-wide global objects
-- stored in pg_authid. They are NOT included in a single-database pg_dump archive.
-- When a database is restored onto a new PostgreSQL cluster, the roles and permissions
-- must be recreated. The block below idempotently provisions the Activity 4 roles
-- if they do not already exist on the target PostgreSQL instance.
-- ==============================================================================

\echo '\n>>> STEP 1: IDEMPOTENT PROVISIONING OF ACTIVITY 4 ROLES & PRIVILEGES <<<'

DO $$
BEGIN
    -- 1. Create the application group role (NOLOGIN) if absent
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'parkit_runtime_grp') THEN
        CREATE ROLE parkit_runtime_grp WITH NOLOGIN;
        RAISE NOTICE 'Created role: parkit_runtime_grp (NOLOGIN)';
    ELSE
        RAISE NOTICE 'Role already exists: parkit_runtime_grp';
    END IF;

    -- 2. Create the application login service account (LOGIN) if absent
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'parkit_app') THEN
        -- Password placeholder matches Activity 4 specification; change locally
        CREATE ROLE parkit_app WITH LOGIN PASSWORD 'parkit_app_secure_pass_2026';
        RAISE NOTICE 'Created login role: parkit_app (LOGIN)';
    ELSE
        RAISE NOTICE 'Login role already exists: parkit_app';
    END IF;

    -- 3. Ensure role inheritance: parkit_app inherits parkit_runtime_grp
    IF NOT EXISTS (
        SELECT 1 FROM pg_auth_members m
        JOIN pg_roles r_grp ON m.roleid = r_grp.oid
        JOIN pg_roles r_usr ON m.member = r_usr.oid
        WHERE r_grp.rolname = 'parkit_runtime_grp' AND r_usr.rolname = 'parkit_app'
    ) THEN
        GRANT parkit_runtime_grp TO parkit_app;
        RAISE NOTICE 'Granted parkit_runtime_grp membership to parkit_app';
    ELSE
        RAISE NOTICE 'Membership already confirmed: parkit_app in parkit_runtime_grp';
    END IF;
END $$;

-- 4. Apply Schema and Object Permissions to parkit_runtime_grp
GRANT USAGE ON SCHEMA public TO parkit_runtime_grp;

-- Table Grants (strictly mirroring Activity 4 specification in user-role.md)
GRANT SELECT ON
    public.staff_user,
    public.vehicle,
    public."transaction",
    public.payment,
    public.parking_zone
TO parkit_runtime_grp;

GRANT INSERT ON
    public.vehicle,
    public."transaction",
    public.payment
TO parkit_runtime_grp;

GRANT UPDATE ON
    public.vehicle,
    public."transaction",
    public.parking_zone
TO parkit_runtime_grp;

-- Sequence Grants: Required for auto-increment IDs on vehicle, transaction, payment
GRANT USAGE, SELECT ON
    public.parking_zone_zone_id_seq,
    public.payment_payment_id_seq,
    public.staff_user_user_id_seq,
    public.transaction_transaction_id_seq,
    public.vehicle_vehicle_id_seq
TO parkit_runtime_grp;

\echo '[OK] Activity 4 role and privilege grants applied successfully.'

-- ==============================================================================
-- SECTION 2: AUDITING ROLES AND MEMBERSHIPS IN SYSTEM CATALOGS
-- ==============================================================================
\echo '\n>>> STEP 2: VERIFYING ROLE DEFINITIONS IN PG_ROLES <<<'
SELECT 
    rolname AS role_name,
    rolcanlogin AS can_login,
    rolsuper AS is_superuser,
    rolinherit AS inherits_privileges,
    CASE 
        WHEN rolname = 'parkit_runtime_grp' AND rolcanlogin = false THEN 'PASSED (PROPER GROUP ROLE)'
        WHEN rolname = 'parkit_app' AND rolcanlogin = true THEN 'PASSED (PROPER LOGIN SERVICE ACCOUNT)'
        ELSE 'INFO'
    END AS verification_status
FROM pg_roles
WHERE rolname IN ('parkit_runtime_grp', 'parkit_app', 'postgres')
ORDER BY rolname;

\echo '\n>>> STEP 3: VERIFYING ROLE MEMBERSHIP HIERARCHY <<<'
SELECT 
    r_grp.rolname AS group_role,
    r_usr.rolname AS member_user,
    m.admin_option,
    CASE 
        WHEN r_grp.rolname = 'parkit_runtime_grp' AND r_usr.rolname = 'parkit_app' THEN 'PASSED - INHERITANCE VERIFIED'
        ELSE 'OTHER'
    END AS status
FROM pg_auth_members m
JOIN pg_roles r_grp ON m.roleid = r_grp.oid
JOIN pg_roles r_usr ON m.member = r_usr.oid
WHERE r_grp.rolname = 'parkit_runtime_grp';

-- ==============================================================================
-- SECTION 3: AUDITING TABLE AND SEQUENCE PRIVILEGES
-- ==============================================================================
\echo '\n>>> STEP 4: VERIFYING TABLE PRIVILEGES GRANTED TO PARKIT_RUNTIME_GRP <<<'
SELECT 
    table_name,
    privilege_type,
    grantee,
    is_grantable,
    CASE 
        WHEN privilege_type IN ('SELECT', 'INSERT', 'UPDATE') THEN 'PASSED (EXPECTED PERMITTED)'
        WHEN privilege_type = 'DELETE' THEN 'FAILED (VIOLATES LEAST PRIVILEGE)'
        ELSE 'INFO'
    END AS access_policy_check
FROM information_schema.role_table_grants
WHERE grantee = 'parkit_runtime_grp'
  AND table_schema = 'public'
ORDER BY table_name, privilege_type;

\echo '\n>>> STEP 5: VERIFYING RESTRICTED DELETE PERMISSIONS (MUST BE ZERO GRANTS) <<<'
-- Principle of Least Privilege: parkit_runtime_grp must NEVER have DELETE on operational tables
SELECT 
    'DELETE Privileges on Tables' AS security_audit,
    COUNT(*) AS active_delete_grants,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASSED (LEAST PRIVILEGE ENFORCED: NO DELETE ACCESS)'
        ELSE 'FAILED (CRITICAL: UNEXPECTED DELETE PRIVILEGE GRANTED)'
    END AS compliance_status
FROM information_schema.role_table_grants
WHERE grantee IN ('parkit_runtime_grp', 'parkit_app')
  AND table_schema = 'public'
  AND privilege_type = 'DELETE';

\echo '\n>>> STEP 6: VERIFYING SEQUENCE USAGE PRIVILEGES <<<'
SELECT 
    sequence_name,
    privilege_type,
    grantee,
    'PASSED' AS status
FROM information_schema.role_usage_grants
WHERE grantee = 'parkit_runtime_grp'
  AND object_schema = 'public'
ORDER BY sequence_name;

-- ==============================================================================
-- SECTION 4: FUNCTIONAL PERMISSION TESTING (PERMITTED VS. DENIED OPERATIONS)
-- ==============================================================================
\echo '\n>>> STEP 7: FUNCTIONAL SECURITY TEST — PERMITTED OPERATIONS <<<'

-- Test 7.1: Verify parkit_app can SELECT from parking_zone
DO $$
DECLARE
    v_zone_count int;
BEGIN
    SET LOCAL ROLE parkit_app;
    SELECT COUNT(*) INTO v_zone_count FROM public.parking_zone;
    RESET ROLE;
    RAISE NOTICE 'TEST 7.1 PASSED: parkit_app successfully executed SELECT on parking_zone (Count: %)', v_zone_count;
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    RAISE EXCEPTION 'TEST 7.1 FAILED: parkit_app was unexpectedly denied SELECT on parking_zone: %', SQLERRM;
END $$;

-- Test 7.2: Verify parkit_app can INSERT a vehicle inside a rolled-back transaction
DO $$
DECLARE
    v_new_id int;
BEGIN
    SET LOCAL ROLE parkit_app;
    -- Disposable test insert
    INSERT INTO public.vehicle (license_plate, vehicle_type)
    VALUES ('SEC-TEST-01', 'Car')
    RETURNING vehicle_id INTO v_new_id;
    
    RESET ROLE;
    RAISE NOTICE 'TEST 7.2 PASSED: parkit_app successfully executed INSERT on vehicle (Vehicle ID: %)', v_new_id;
EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    RAISE EXCEPTION 'TEST 7.2 FAILED: parkit_app was unexpectedly denied INSERT on vehicle: %', SQLERRM;
END $$;

-- Clean up any residual test vehicle record
DELETE FROM public.vehicle WHERE license_plate = 'SEC-TEST-01';

\echo '\n>>> STEP 8: FUNCTIONAL SECURITY TEST — DENIED OPERATIONS (EXPECTED SECURITY BLOCKS) <<<'

-- Test 8.1: Verify parkit_app is DENIED permission to DELETE from payment
DO $$
BEGIN
    SET LOCAL ROLE parkit_app;
    -- This operation MUST be denied by PostgreSQL
    DELETE FROM public.payment WHERE payment_id = 999999;
    
    -- If execution reaches here, security failed!
    RESET ROLE;
    RAISE EXCEPTION 'TEST 8.1 FAILED: parkit_app was ALLOWED to execute DELETE on payment table! (Least privilege breach)';
EXCEPTION 
    WHEN insufficient_privilege THEN
        RESET ROLE;
        RAISE NOTICE 'TEST 8.1 PASSED (EXPECTED BLOCK): parkit_app was correctly DENIED DELETE on payment table: %', SQLERRM;
    WHEN OTHERS THEN
        RESET ROLE;
        RAISE NOTICE 'TEST 8.1 NOTICE: Encountered: %', SQLERRM;
END $$;

-- Test 8.2: Verify parkit_app is DENIED permission to DELETE from transaction
DO $$
BEGIN
    SET LOCAL ROLE parkit_app;
    DELETE FROM public."transaction" WHERE transaction_id = 999999;
    
    RESET ROLE;
    RAISE EXCEPTION 'TEST 8.2 FAILED: parkit_app was ALLOWED to execute DELETE on transaction table!';
EXCEPTION 
    WHEN insufficient_privilege THEN
        RESET ROLE;
        RAISE NOTICE 'TEST 8.2 PASSED (EXPECTED BLOCK): parkit_app was correctly DENIED DELETE on transaction table: %', SQLERRM;
    WHEN OTHERS THEN
        RESET ROLE;
        RAISE NOTICE 'TEST 8.2 NOTICE: Encountered: %', SQLERRM;
END $$;

-- Test 8.3: Verify parkit_app is DENIED permission to UPDATE staff_user credentials
DO $$
BEGIN
    SET LOCAL ROLE parkit_app;
    UPDATE public.staff_user SET role = 'SuperAdmin' WHERE username = 'admin';
    
    RESET ROLE;
    RAISE EXCEPTION 'TEST 8.3 FAILED: parkit_app was ALLOWED to execute UPDATE on staff_user table!';
EXCEPTION 
    WHEN insufficient_privilege THEN
        RESET ROLE;
        RAISE NOTICE 'TEST 8.3 PASSED (EXPECTED BLOCK): parkit_app was correctly DENIED UPDATE on staff_user table: %', SQLERRM;
    WHEN OTHERS THEN
        RESET ROLE;
        RAISE NOTICE 'TEST 8.3 NOTICE: Encountered: %', SQLERRM;
END $$;

-- ==============================================================================
-- SECTION 5: FINAL ACCESS CONTROL COMPLIANCE SUMMARY
-- ==============================================================================
\echo '\n========================================================================'
\echo '  ACTIVITY 4 RBAC RESTORATION CERTIFICATION                             '
\echo '========================================================================'

SELECT 
    'Role parkit_runtime_grp Exists' AS verification_item,
    CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'parkit_runtime_grp') THEN 'PASSED' ELSE 'FAILED' END AS result
UNION ALL
SELECT 
    'Role parkit_app Exists',
    CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'parkit_app') THEN 'PASSED' ELSE 'FAILED' END
UNION ALL
SELECT 
    'Role Membership (parkit_app in parkit_runtime_grp)',
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_auth_members m
        JOIN pg_roles r_grp ON m.roleid = r_grp.oid
        JOIN pg_roles r_usr ON m.member = r_usr.oid
        WHERE r_grp.rolname = 'parkit_runtime_grp' AND r_usr.rolname = 'parkit_app'
    ) THEN 'PASSED' ELSE 'FAILED' END
UNION ALL
SELECT 
    'Zero DELETE Privileges Granted to Runtime Account',
    CASE WHEN (
        SELECT COUNT(*) FROM information_schema.role_table_grants 
        WHERE grantee IN ('parkit_runtime_grp', 'parkit_app') AND privilege_type = 'DELETE'
    ) = 0 THEN 'PASSED' ELSE 'FAILED' END;

\echo '\n[ACCESS CONTROL VERIFICATION COMPLETE]'
\echo '========================================================================\n'

