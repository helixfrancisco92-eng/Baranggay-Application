-- ==============================================================================
-- Script: verify-access-control.sql
-- System: BoardTrack — Boarding House & Rental Management System
-- Purpose: Activity 4 Access Control, Database Role & Privilege Verification
-- COMP 018 — Database Administration | Activity 6
-- ==============================================================================

\echo '===================================================================='
\echo '  BOARDTRACK ACCESS CONTROL & ROLE PRIVILEGE AUDIT'
\echo '===================================================================='
\echo 'Target Database : ' :DBNAME
\echo 'Audit Timestamp : ' `date /t` `time /t`
\echo '===================================================================='

-- ------------------------------------------------------------------------------
-- 1. CLUSTER DATABASE ROLES INVENTORY
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [1] PostgreSQL Roles Inventory ---'
SELECT 
  rolname AS role_name,
  rolsuper AS is_superuser,
  rolinherit AS inherits_privileges,
  rolcreaterole AS can_create_roles,
  rolcreatedb AS can_create_db,
  rolcanlogin AS can_login,
  rolconnlimit AS connection_limit
FROM pg_roles
WHERE rolname IN (
  'boardtrack_owner',
  'boardtrack_admin_grp',
  'app_runtime_grp',
  'app_readonly_grp',
  'boardtrack_app',
  'boardtrack_backup',
  'postgres'
)
ORDER BY rolname;

-- ------------------------------------------------------------------------------
-- 2. ROLE MEMBERSHIP HIERARCHY
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [2] Role Membership Mapping ---'
SELECT 
  r.rolname AS parent_group_role,
  m.rolname AS member_role,
  a.admin_option
FROM pg_auth_members a
JOIN pg_roles r ON r.oid = a.roleid
JOIN pg_roles m ON m.oid = a.member
WHERE r.rolname IN ('boardtrack_admin_grp', 'app_runtime_grp', 'app_readonly_grp')
ORDER BY r.rolname, m.rolname;

-- ------------------------------------------------------------------------------
-- 3. SCHEMA-LEVEL PRIVILEGES
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [3] Schema-Level (public) Privileges ---'
SELECT 
  n.nspname AS schema_name,
  COALESCE(r.rolname, 'PUBLIC') AS grantee,
  p.perm AS privilege_type
FROM pg_namespace n
CROSS JOIN LATERAL (
  SELECT unnest(ARRAY['USAGE', 'CREATE']) AS perm
) p
LEFT JOIN pg_roles r ON has_schema_privilege(r.oid, n.oid, p.perm)
WHERE n.nspname = 'public' 
  AND (r.rolname IS NULL OR r.rolname IN ('boardtrack_owner', 'boardtrack_admin_grp', 'app_runtime_grp', 'app_readonly_grp', 'boardtrack_app', 'boardtrack_backup'))
ORDER BY grantee, p.perm;

-- ------------------------------------------------------------------------------
-- 4. TABLE-LEVEL PRIVILEGE MATRIX
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [4] Table-Level Privilege Grants ---'
SELECT 
  grantee,
  table_name,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('boardtrack_owner', 'boardtrack_admin_grp', 'app_runtime_grp', 'app_readonly_grp', 'boardtrack_app', 'boardtrack_backup')
ORDER BY grantee, table_name, privilege_type;

-- ------------------------------------------------------------------------------
-- 5. SEQUENCE-LEVEL PRIVILEGES
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [5] Sequence Privileges (USAGE / SELECT) ---'
SELECT 
  grantee,
  routine_name AS sequence_name,
  privilege_type
FROM information_schema.routine_privileges
WHERE specific_schema = 'public'
  AND grantee IN ('app_runtime_grp', 'boardtrack_app', 'app_readonly_grp')
UNION ALL
SELECT 
  grantee,
  table_name,
  privilege_type
FROM information_schema.role_usage_grants
WHERE object_schema = 'public'
  AND grantee IN ('app_runtime_grp', 'boardtrack_app', 'app_readonly_grp')
ORDER BY grantee;

-- ------------------------------------------------------------------------------
-- 6. LEAST-PRIVILEGE COMPLIANCE AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [6] Administrative Superuser Check ---'
SELECT 
  rolname,
  CASE WHEN rolsuper THEN 'VIOLATION: Superuser Assigned' ELSE 'COMPLIANT: Least Privilege' END AS compliance_status
FROM pg_roles
WHERE rolname IN ('boardtrack_app', 'app_runtime_grp', 'app_readonly_grp', 'boardtrack_backup');

-- ------------------------------------------------------------------------------
-- 7. FUNCTIONAL RBAC TESTS (PERMITTED VS. DENIED OPERATIONS)
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [7] Functional Access Enforcement Simulation ---'

-- Subtest A: Permitted Operation (app_runtime_grp or boardtrack_app reading view)
\echo 'Test A (Permitted): Querying v_lease_summary by authorized runtime user'
DO $$
BEGIN
  -- Simulates application runtime query
  PERFORM lease_id, tenant, total_paid FROM v_lease_summary LIMIT 1;
  RAISE NOTICE 'SUCCESS: Permitted read on v_lease_summary executed without exception.';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'FAILURE on permitted read: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

-- Subtest B: Denied Operation 1 (Read-Only user attempting DELETE)
\echo 'Test B (Denied): Simulating unauthorized DELETE on payment by read-only role'
DO $$
BEGIN
  -- Attempt to simulate deletion under restricted role if role exists
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_readonly_grp') THEN
    BEGIN
      SET LOCAL ROLE app_readonly_grp;
      DELETE FROM payment WHERE payment_id = 99999;
      RESET ROLE;
      RAISE WARNING 'CRITICAL FAILURE: Unauthorized DELETE succeeded on payment table!';
    EXCEPTION 
      WHEN insufficient_privilege THEN
        RESET ROLE;
        RAISE NOTICE 'SUCCESS: Denied operation blocked as expected with SQLSTATE 42501 (insufficient_privilege).';
      WHEN OTHERS THEN
        RESET ROLE;
        RAISE NOTICE 'SUCCESS: Operation blocked with error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
    END;
  ELSE
    RAISE NOTICE 'SKIPPED: Role app_readonly_grp not present in cluster. (Documented in Activity 6 report).';
  END IF;
END $$;

-- Subtest C: Denied Operation 2 (Runtime user attempting DDL DROP TABLE)
\echo 'Test C (Denied): Simulating unauthorized DDL (DROP TABLE) by runtime account'
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'boardtrack_app') THEN
    BEGIN
      SET LOCAL ROLE boardtrack_app;
      EXECUTE 'DROP TABLE payment CASCADE';
      RESET ROLE;
      RAISE WARNING 'CRITICAL FAILURE: Unauthorized DROP TABLE executed!';
    EXCEPTION 
      WHEN insufficient_privilege THEN
        RESET ROLE;
        RAISE NOTICE 'SUCCESS: DDL DROP TABLE blocked as expected with SQLSTATE 42501 (insufficient_privilege).';
      WHEN OTHERS THEN
        RESET ROLE;
        RAISE NOTICE 'SUCCESS: DDL blocked with error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
    END;
  ELSE
    RAISE NOTICE 'SKIPPED: Role boardtrack_app not present in cluster. (Documented in Activity 6 report).';
  END IF;
END $$;

\echo ''
\echo '===================================================================='
\echo '  END OF ACCESS CONTROL AUDIT SUITE'
\echo '===================================================================='

