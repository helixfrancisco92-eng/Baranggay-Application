-- ==============================================================================
-- COMP 018 — Database Administration (Activity 6)
-- Target Project: PUP-SPOT (Group 5 - Lost and Found Management System)
-- Privilege and Access Control Matrix Verification Script
-- Target Database: grp05_lostandfounddb
-- ==============================================================================

\echo '================================================================='
\echo ' PUP-SPOT ACCESS PERMISSION AUDIT MATRIX                         '
\echo '================================================================='

-- 1. Cluster Roles and Account Attributes
\echo ''
\echo '>>> 1. Database Accounts & System Attributes:'
SELECT 
    rolname,
    rolsuper AS superuser,
    rolcreaterole AS createrole,
    rolcreatedb AS createdb,
    rolcanlogin AS can_login
FROM pg_roles
WHERE rolname IN ('lf_admin', 'lf_staff', 'lf_viewer', 'lf_admin_user', 'lf_staff_user', 'lf_viewer_user')
ORDER BY rolcanlogin DESC, rolname;

-- 2. Role Memberships
\echo ''
\echo '>>> 2. Role Memberships & Inheritance:'
SELECT 
    m_user.rolname AS login_account,
    m_role.rolname AS group_role_inherited
FROM pg_auth_members pam
JOIN pg_roles m_user ON pam.member = m_user.oid
JOIN pg_roles m_role ON pam.roleid = m_role.oid
WHERE m_role.rolname IN ('lf_admin', 'lf_staff', 'lf_viewer');

-- 3. Schema Privileges
\echo ''
\echo '>>> 3. Schema Privileges on `public`:'
SELECT 
    r.rolname,
    has_schema_privilege(r.rolname, 'public', 'USAGE') AS usage_allowed,
    has_schema_privilege(r.rolname, 'public', 'CREATE') AS create_allowed
FROM pg_roles r
WHERE r.rolname IN ('lf_admin', 'lf_staff', 'lf_viewer', 'lf_admin_user', 'lf_staff_user', 'lf_viewer_user')
ORDER BY r.rolname;

-- 4. Table Privileges Audit
\echo ''
\echo '>>> 4. Table Privileges Audit Matrix:'
SELECT 
    table_name,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND grantee IN ('lf_admin', 'lf_staff', 'lf_viewer', 'public')
ORDER BY table_name, grantee, privilege_type;

\echo ''
\echo '================================================================='
\echo ' AUDIT COMPLETE                                                  '
\echo '================================================================='

