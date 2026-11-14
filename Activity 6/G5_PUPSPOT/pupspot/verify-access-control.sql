-- ==============================================================================
-- COMP 018 — Database Administration (Activity 6: Part D)
-- Target Project: PUP-SPOT (Group 5 - Lost and Found Management System)
-- Access Control and Role Privilege Verification Suite
-- Target Database: grp05_lostandfounddb_activity6_restore_test
-- Baseline Reference: Activity 4 Access Control Plan (RBAC)
-- ==============================================================================

\echo '================================================================='
\echo ' PUP-SPOT POST-RESTORATION ACCESS CONTROL & PERMISSION AUDIT      '
\echo '================================================================='

-- ------------------------------------------------------------------------------
-- 1. VERIFY GROUP ROLES AND LOGIN ACCOUNTS EXISTENCE
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 1. Verifying Activity 4 Roles in Cluster Catalog (pg_roles)...'
SELECT 
    rolname,
    rolsuper AS is_superuser,
    rolcreaterole AS can_create_role,
    rolcreatedb AS can_create_db,
    rolcanlogin AS can_login
FROM pg_roles
WHERE rolname IN (
    'lf_admin',
    'lf_staff',
    'lf_viewer',
    'lf_admin_user',
    'lf_staff_user',
    'lf_viewer_user'
)
ORDER BY rolcanlogin DESC, rolname;

-- ------------------------------------------------------------------------------
-- 2. VERIFY ROLE MEMBERSHIPS (RBAC INHERITANCE)
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 2. Verifying Role Memberships (Inheritance Binding)...'
SELECT 
    r_member.rolname AS login_user,
    r_group.rolname AS assigned_group_role
FROM pg_auth_members m
JOIN pg_roles r_member ON m.member = r_member.oid
JOIN pg_roles r_group ON m.roleid = r_group.oid
WHERE r_group.rolname IN ('lf_admin', 'lf_staff', 'lf_viewer')
ORDER BY r_group.rolname;

-- ------------------------------------------------------------------------------
-- 3. SCHEMA USAGE PRIVILEGES
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 3. Verifying Schema USAGE Privileges on Schema `public`...'
SELECT 
    r.rolname,
    has_schema_privilege(r.rolname, 'public', 'USAGE') AS has_usage,
    has_schema_privilege(r.rolname, 'public', 'CREATE') AS has_create
FROM pg_roles r
WHERE r.rolname IN ('lf_admin', 'lf_staff', 'lf_viewer', 'lf_admin_user', 'lf_staff_user', 'lf_viewer_user')
ORDER BY r.rolname;

-- ------------------------------------------------------------------------------
-- 4. TABLE PERMISSION MATRIX (has_table_privilege)
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 4. Verifying Table Privilege Matrix across System Tables...'
SELECT 
    t.tablename,
    has_table_privilege('lf_admin', 'public.' || t.tablename, 'SELECT') AS admin_select,
    has_table_privilege('lf_admin', 'public.' || t.tablename, 'INSERT') AS admin_insert,
    has_table_privilege('lf_admin', 'public.' || t.tablename, 'UPDATE') AS admin_update,
    has_table_privilege('lf_admin', 'public.' || t.tablename, 'DELETE') AS admin_delete,
    has_table_privilege('lf_staff', 'public.' || t.tablename, 'SELECT') AS staff_select,
    has_table_privilege('lf_staff', 'public.' || t.tablename, 'INSERT') AS staff_insert,
    has_table_privilege('lf_staff', 'public.' || t.tablename, 'UPDATE') AS staff_update,
    has_table_privilege('lf_staff', 'public.' || t.tablename, 'DELETE') AS staff_delete,
    has_table_privilege('lf_viewer', 'public.' || t.tablename, 'SELECT') AS viewer_select,
    has_table_privilege('lf_viewer', 'public.' || t.tablename, 'INSERT') AS viewer_insert,
    has_table_privilege('lf_viewer', 'public.' || t.tablename, 'UPDATE') AS viewer_update,
    has_table_privilege('lf_viewer', 'public.' || t.tablename, 'DELETE') AS viewer_delete
FROM pg_tables t
WHERE t.schemaname = 'public'
ORDER BY t.tablename;

-- ------------------------------------------------------------------------------
-- 5. FUNCTIONAL PRIVILEGE EVALUATION (CATALOG-BASED PERMISSION AUDIT)
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 5. Evaluating Activity 4 Permission Compliance...'
SELECT 
    'lf_admin' AS role_name,
    'ALL (SELECT, INSERT, UPDATE, DELETE)' AS expected_permissions,
    'Full administrative table and sequence privileges in schema public' AS description
UNION ALL
SELECT 
    'lf_staff',
    'SELECT, INSERT, UPDATE (DELETE revoked)',
    'Can record found items and claims; restricted from deleting records'
UNION ALL
SELECT 
    'lf_viewer',
    'SELECT only (INSERT, UPDATE, DELETE revoked)',
    'Public lookup and item status tracking; strictly read-only';

\echo ''
\echo '>>> 5.1 Direct Connection Test Guidelines:'
\echo ' To verify permissions under active sessions, connect directly as each login user:'
\echo '   1. Viewer Allowed SELECT : psql -U lf_viewer_user -d <test_db> -c "SELECT * FROM categories;"'
\echo '   2. Viewer Denied INSERT  : psql -U lf_viewer_user -d <test_db> -c "INSERT INTO categories(name) VALUES(''Test'');"'
\echo '   3. Staff Denied DELETE   : psql -U lf_staff_user -d <test_db> -c "DELETE FROM items WHERE item_id = 1;"'

\echo ''
\echo '================================================================='
\echo ' ACCESS CONTROL & SECURITY VERIFICATION COMPLETE                 '
\echo '================================================================='
