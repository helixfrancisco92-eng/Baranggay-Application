
-- PARK-IT: VERIFY ROLE PERMISSIONS
-- Database: grp_parkitdb

-- 1. CHECK CREATED ROLES

SELECT
    rolname,
    rolcanlogin
FROM pg_roles
WHERE rolname IN (
    'parkit_admin_grp',
    'parkit_runtime_grp',
    'parkit_readonly_grp'
)
ORDER BY rolname;


-- 2. CHECK TABLE PRIVILEGES

SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'parkit_admin_grp',
    'parkit_runtime_grp',
    'parkit_readonly_grp'
)
ORDER BY grantee, table_name, privilege_type;


-- 3. TEST PERMISSIONS ON ALL EXISTING TABLES

SELECT
    c.relname AS table_name,

    has_table_privilege(
        'parkit_admin_grp',
        c.oid,
        'DELETE'
    ) AS admin_can_delete,

    has_table_privilege(
        'parkit_runtime_grp',
        c.oid,
        'INSERT'
    ) AS runtime_can_insert,

    has_table_privilege(
        'parkit_readonly_grp',
        c.oid,
        'SELECT'
    ) AS readonly_can_select,

    has_table_privilege(
        'parkit_readonly_grp',
        c.oid,
        'INSERT'
    ) AS readonly_can_insert

FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace

WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')

ORDER BY c.relname;


-- 4. VERIFY SCHEMA ACCESS

SELECT
    has_schema_privilege(
        'parkit_admin_grp',
        'public',
        'USAGE'
    ) AS admin_schema_access,

    has_schema_privilege(
        'parkit_runtime_grp',
        'public',
        'USAGE'
    ) AS runtime_schema_access,

    has_schema_privilege(
        'parkit_readonly_grp',
        'public',
        'USAGE'
    ) AS readonly_schema_access;
