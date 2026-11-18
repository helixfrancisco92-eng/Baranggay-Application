-- =============================================================================
-- PostgreSQL DBA Diagnostic Toolkit: 03_access_control_and_roles.sql
-- Purpose: Inspect database roles, memberships, table grants, and column privileges
-- Execution: psql -U <user> -d <database> -f 03_access_control_and_roles.sql
-- =============================================================================

\echo '================================================================='
\echo ' 1. ROLES, LOGIN STATUS & SUPERUSER PRIVILEGES                   '
\echo '================================================================='
SELECT rolname,
       rolcanlogin AS can_login,
       rolsuper AS is_superuser,
       rolcreaterole AS can_create_role,
       rolcreatedb AS can_create_db,
       rolconnlimit AS conn_limit,
       ARRAY(
           SELECT b.rolname 
           FROM pg_auth_members m 
           JOIN pg_roles b ON (m.roleid = b.oid) 
           WHERE m.member = r.oid
       ) AS member_of_roles
FROM pg_roles r
WHERE rolname NOT LIKE 'pg_%'
ORDER BY rolcanlogin DESC, rolname;

\echo ''
\echo '================================================================='
\echo ' 2. TABLE-LEVEL PRIVILEGES IN PUBLIC SCHEMA                      '
\echo '================================================================='
SELECT grantee,
       table_name,
       privilege_type,
       is_grantable
FROM information_schema.table_privileges
WHERE table_schema = 'public' 
  AND grantee NOT IN ('postgres', 'PUBLIC')
ORDER BY table_name, grantee, privilege_type;

\echo ''
\echo '================================================================='
\echo ' 3. PUBLIC ROLE PRIVILEGES (LEAK CHECK)                          '
\echo '================================================================='
SELECT table_name,
       privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public' AND grantee = 'PUBLIC'
ORDER BY table_name, privilege_type;

\echo ''
\echo '================================================================='
\echo ' 4. COLUMN-LEVEL PRIVILEGE RESTRICTIONS                          '
\echo '================================================================='
SELECT grantee,
       table_name,
       column_name,
       privilege_type
FROM information_schema.column_privileges
WHERE table_schema = 'public'
ORDER BY table_name, column_name, grantee;
