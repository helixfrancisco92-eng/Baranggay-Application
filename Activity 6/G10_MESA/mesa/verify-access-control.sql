-- ==============================================================================
-- COMP 018 - Database Administration | Activity 6
-- Script: verify-access-control.sql
-- Target: grp_binarysisters_projectdb_activity6_restore_test
-- Purpose: Audit Activity 4 Roles, Privileges, Permitted & Denied Security Tests
-- ==============================================================================

\set ON_ERROR_STOP off
\echo '=============================================================================='
\echo ' COMP 018 Activity 6 - Access-Control and Least Privilege Verification'
\echo ' Target Project: Restaurant Online Ordering & Table Reservation System'
\echo '=============================================================================='

-- 1. Cluster-Wide Roles Inventory Audit
\echo '--- 1. ROLES AND MEMBERSHIPS INVENTORY ---'
SELECT r.rolname AS role_name,
       r.rolcanlogin AS can_login,
       r.rolconnlimit AS conn_limit,
       ARRAY(
           SELECT b.rolname
           FROM pg_auth_members m
           JOIN pg_roles b ON m.roleid = b.oid
           WHERE m.member = r.oid
       ) AS member_of,
       r.rolconfig AS custom_settings
FROM pg_roles r
WHERE r.rolname IN (
    'rors_runtime_grp', 'rors_readonly_grp', 'rors_maint_grp', 'rors_backup_grp', 'rors_admin_grp',
    'rors_app', 'rors_report', 'rors_maint', 'rors_backup', 'rors_dba'
)
ORDER BY r.rolcanlogin DESC, r.rolname;

-- 2. Schema-Level Privileges
\echo '--- 2. SCHEMA PUBLIC USAGE AND CREATE PRIVILEGES ---'
SELECT nspname AS schema_name,
       r.rolname AS grantee,
       has_schema_privilege(r.rolname, n.nspname, 'USAGE') AS has_usage,
       has_schema_privilege(r.rolname, n.nspname, 'CREATE') AS has_create
FROM pg_namespace n
CROSS JOIN (
    SELECT rolname FROM pg_roles WHERE rolname IN ('rors_app', 'rors_report', 'rors_maint', 'rors_backup', 'rors_dba')
) r
WHERE n.nspname = 'public'
ORDER BY r.rolname;

-- 3. Table-Level Privilege Matrix Audit
\echo '--- 3. TABLE PRIVILEGE MATRIX FOR APPLICATION & REPORTING ROLES ---'
SELECT grantee,
       table_name,
       string_agg(privilege_type, ', ' ORDER BY privilege_type) AS granted_privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('rors_runtime_grp', 'rors_readonly_grp', 'rors_maint_grp', 'rors_backup_grp', 'rors_admin_grp')
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

-- 4. Sequence Privilege Matrix
\echo '--- 4. SEQUENCE PRIVILEGES (SERIAL COLUMNS) ---'
SELECT grantee,
       routine_name AS sequence_name,
       string_agg(privilege_type, ', ') AS privileges
FROM (
    SELECT grantee, table_name AS routine_name, privilege_type
    FROM information_schema.role_usage_grants
    WHERE object_schema = 'public' AND grantee LIKE 'rors_%'
    UNION ALL
    SELECT grantee, table_name AS routine_name, privilege_type
    FROM information_schema.role_table_grants
    WHERE table_schema = 'public' AND table_name LIKE '%_seq' AND grantee LIKE 'rors_%'
) s
GROUP BY grantee, sequence_name
ORDER BY grantee, sequence_name;

-- ==============================================================================
-- 5. FUNCTIONAL SECURITY TESTS (Permitted vs. Denied Boundaries)
-- ==============================================================================

\echo '--- 5. PERMITTED TEST: rors_app querying active menu items ---'
SET ROLE rors_app;
SELECT current_user AS active_role;
SELECT menu_item_id, item_name, category, price, availability
FROM menu_item
WHERE availability = true
LIMIT 3;
RESET ROLE;

\echo '--- 6. DENIED TEST 1: rors_report attempting INSERT into orders ---'
\echo 'EXPECTED RESULT: Permission Denied (SQLSTATE 42501)'
SET ROLE rors_report;
SELECT current_user AS active_role;
INSERT INTO orders (customer_id, order_status, total_amount)
VALUES (1, 'pending', 150.00);
RESET ROLE;

\echo '--- 7. DENIED TEST 2: rors_report attempting SELECT on customer password hashes ---'
\echo 'EXPECTED RESULT: Permission Denied on customer table (SQLSTATE 42501)'
SET ROLE rors_report;
SELECT current_user AS active_role;
SELECT customer_id, email, password FROM customer LIMIT 1;
RESET ROLE;

\echo '--- 8. PERMITTED TEST 2: rors_report viewing sanitized customer directory view ---'
\echo 'EXPECTED RESULT: Permitted SELECT without password hashes'
SET ROLE rors_report;
SELECT current_user AS active_role;
SELECT customer_id, first_name, last_name, email, phone
FROM v_customer_directory
LIMIT 3;
RESET ROLE;

\echo '--- 9. DENIED TEST 3: rors_app attempting DDL DROP TABLE ---'
\echo 'EXPECTED RESULT: Must be owner of table (SQLSTATE 42501)'
SET ROLE rors_app;
SELECT current_user AS active_role;
DROP TABLE restaurant_table;
RESET ROLE;

\echo '--- 10. DENIED TEST 4: rors_maint attempting SELECT on customer orders ---'
\echo 'EXPECTED RESULT: Permission Denied (SQLSTATE 42501)'
SET ROLE rors_maint;
SELECT current_user AS active_role;
SELECT * FROM orders LIMIT 1;
RESET ROLE;

\echo '=============================================================================='
\echo ' ACCESS-CONTROL AUDIT COMPLETE: Least-Privilege Boundaries Confirmed'
\echo '=============================================================================='

