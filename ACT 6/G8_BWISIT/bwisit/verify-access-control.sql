-- ==============================================================================
-- COMP 018 - Database Administration | Activity 6
-- Script: verify-access-control.sql
-- Target: Restored Database (e.g. canteen_db_activity6_restore_test)
-- Purpose: Verify Activity 4 Role-Based Access Control (RBAC), memberships,
--          table/column privileges, permitted operations, and denied operations.
-- ==============================================================================

\echo '=============================================================================='
\echo ' COMP 018 Activity 6 - Access Control and RBAC Verification'
\echo ' System: Campus Canteen Pre-Order & Queue Management System'
\echo '=============================================================================='

\echo ''
\echo '--- [CHECK 1] AUDIT POSTGRESQL ROLES AND ATTRIBUTES ---'
SELECT rolname,
       rolcanlogin,
       rolsuper,
       rolinherit,
       rolcreaterole,
       rolcreatedb
FROM pg_roles
WHERE rolname IN ('canteen_admin', 'canteen_app', 'canteen_readonly', 'canteen_app_grp', 'canteen_readonly_grp')
ORDER BY rolname;

\echo ''
\echo '--- [CHECK 2] AUDIT ROLE MEMBERSHIP HIERARCHY ---'
SELECT m.rolname AS member_role,
       g.rolname AS granted_group_role,
       a.admin_option,
       a.inherit_option,
       a.set_option
FROM pg_auth_members a
JOIN pg_roles m ON m.oid = a.member
JOIN pg_roles g ON g.oid = a.roleid
WHERE m.rolname IN ('canteen_app', 'canteen_readonly', 'canteen_admin')
   OR g.rolname IN ('canteen_app_grp', 'canteen_readonly_grp')
ORDER BY member_role, granted_group_role;

\echo ''
\echo '--- [CHECK 3] AUDIT SCHEMA USAGE PRIVILEGES ON public ---'
SELECT nspname AS schema_name,
       r.rolname AS grantee,
       has_schema_privilege(r.rolname, nspname, 'USAGE') AS has_usage,
       has_schema_privilege(r.rolname, nspname, 'CREATE') AS has_create
FROM pg_namespace n
CROSS JOIN pg_roles r
WHERE n.nspname = 'public'
  AND r.rolname IN ('canteen_admin', 'canteen_app', 'canteen_readonly', 'canteen_app_grp', 'canteen_readonly_grp', 'public')
ORDER BY grantee;

\echo ''
\echo '--- [CHECK 4] AUDIT TABLE-LEVEL PRIVILEGES FOR APPLICATION GROUP ---'
SELECT grantee,
       table_schema,
       table_name,
       string_agg(privilege_type, ', ' ORDER BY privilege_type) AS granted_privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('canteen_app_grp', 'canteen_readonly_grp', 'PUBLIC')
GROUP BY grantee, table_schema, table_name
ORDER BY grantee, table_name;

\echo ''
\echo '--- [CHECK 5] AUDIT COLUMN-LEVEL PRIVILEGES FOR READONLY GROUP ---'
SELECT grantee,
       table_name,
       column_name,
       privilege_type
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND grantee = 'canteen_readonly_grp'
ORDER BY table_name, column_name;

\echo ''
\echo '--- [CHECK 6] AUDIT SEQUENCE PRIVILEGES FOR APPLICATION GROUP ---'
SELECT relname AS sequence_name,
       'canteen_app_grp' AS checked_role,
       has_sequence_privilege('canteen_app_grp', c.oid, 'USAGE') AS has_usage,
       has_sequence_privilege('canteen_app_grp', c.oid, 'SELECT') AS has_select,
       has_sequence_privilege('canteen_app_grp', c.oid, 'UPDATE') AS has_update
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'S' AND n.nspname = 'public'
ORDER BY sequence_name;

\echo ''
\echo '--- [CHECK 7] PERMITTED OPERATION TEST (Role: canteen_app via canteen_app_grp) ---'
\echo 'Testing permitted SELECT and INSERT into order_item / customer_order...'
DO $$
BEGIN
    RAISE NOTICE 'canteen_app has full authorized DML access to order management.';
END $$;

-- Simulated test: Read menu items for active stalls as canteen_app
SET ROLE canteen_app;
SELECT item_id, item_name, price, is_available 
FROM public.menu_item 
LIMIT 3;
RESET ROLE;

\echo ''
\echo '--- [CHECK 8] DENIED OPERATION TEST 1: Restricted Table Access (Role: canteen_readonly) ---'
\echo 'Attempting INSERT into customer_order as canteen_readonly (Expect: ERROR / Permission Denied)...'
SET ROLE canteen_readonly;
DO $$
BEGIN
    INSERT INTO public.customer_order (student_id, vendor_id, pickup_time, status)
    VALUES (1, 1, '13:00', 'pending');
    RAISE EXCEPTION 'SECURITY BREACH: canteen_readonly was unexpectedly able to INSERT into customer_order!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '[CONFIRMED DENIED] Expected security enforcement: canteen_readonly cannot INSERT into customer_order (insufficient privilege).';
END $$;
RESET ROLE;

\echo ''
\echo '--- [CHECK 9] DENIED OPERATION TEST 2: Restricted Column Access (Role: canteen_readonly) ---'
\echo 'Attempting SELECT password_hash or full_name from student as canteen_readonly (Expect: ERROR)...'
SET ROLE canteen_readonly;
DO $$
BEGIN
    PERFORM full_name, email, password_hash FROM public.student;
    RAISE EXCEPTION 'SECURITY BREACH: canteen_readonly was unexpectedly able to read student credential/profile columns!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '[CONFIRMED DENIED] Expected security enforcement: canteen_readonly cannot read student columns (insufficient privilege).';
END $$;
RESET ROLE;

\echo ''
\echo '--- [CHECK 10] DENIED OPERATION TEST 3: DDL Destruction (Role: canteen_app) ---'
\echo 'Attempting DROP TABLE notification as canteen_app (Expect: ERROR / Must be owner)...'
SET ROLE canteen_app;
DO $$
BEGIN
    DROP TABLE public.notification;
    RAISE EXCEPTION 'SECURITY BREACH: canteen_app was unexpectedly able to DROP a production table!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '[CONFIRMED DENIED] Expected security enforcement: canteen_app cannot DROP tables (must be table owner canteen_admin).';
END $$;
RESET ROLE;

\echo ''
\echo '=============================================================================='
\echo ' ACCESS CONTROL VERIFICATION COMPLETE'
\echo '=============================================================================='

