
-- ============================================
-- HABALGO - ACTIVITY 4
-- 04_test_privileges.sql
-- ============================================

-- 1. Display privileges for every public table

SELECT
    t.table_schema,
    t.table_name,

    has_table_privilege(
        'habalgo_admin_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'SELECT'
    ) AS admin_can_select,

    has_table_privilege(
        'habalgo_app_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'SELECT'
    ) AS app_can_select,

    has_table_privilege(
        'habalgo_app_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'INSERT'
    ) AS app_can_insert,

    has_table_privilege(
        'habalgo_app_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'UPDATE'
    ) AS app_can_update,

    has_table_privilege(
        'habalgo_app_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'DELETE'
    ) AS app_can_delete,

    has_table_privilege(
        'habalgo_auditor_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'SELECT'
    ) AS auditor_can_select,

    has_table_privilege(
        'habalgo_auditor_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'INSERT'
    ) AS auditor_can_insert,

    has_table_privilege(
        'habalgo_auditor_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'UPDATE'
    ) AS auditor_can_update,

    has_table_privilege(
        'habalgo_auditor_role',
        quote_ident(t.table_schema) || '.' ||
        quote_ident(t.table_name),
        'DELETE'
    ) AS auditor_can_delete

FROM information_schema.tables t

WHERE t.table_schema = 'public'
AND t.table_type IN ('BASE TABLE', 'VIEW')

ORDER BY t.table_name;

-- 2. Check schema creation permissions

SELECT
    rolname,
    has_schema_privilege(
        rolname,
        'public',
        'CREATE'
    ) AS can_create_in_public
FROM pg_roles
WHERE rolname IN (
    'habalgo_admin_role',
    'habalgo_app_role',
    'habalgo_auditor_role'
);

-- 3. Verify role memberships

SELECT
    member.rolname AS login_account,
    granted.rolname AS assigned_role
FROM pg_auth_members m
JOIN pg_roles granted
    ON granted.oid = m.roleid
JOIN pg_roles member
    ON member.oid = m.member
WHERE granted.rolname LIKE 'habalgo_%'
ORDER BY member.rolname;
