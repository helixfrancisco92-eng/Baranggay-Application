
-- 04_test_privileges.sql

-- Check role membership
SELECT
    member.rolname AS user_name,
    role.rolname AS assigned_role
FROM pg_auth_members m
JOIN pg_roles role
    ON role.oid = m.roleid
JOIN pg_roles member
    ON member.oid = m.member
ORDER BY member.rolname;

-- Check SELECT permissions
SELECT
    table_name,
    has_table_privilege(
        'restaurant_admin',
        'public.' || quote_ident(table_name),
        'SELECT'
    ) AS admin_can_select,
    has_table_privilege(
        'restaurant_staff',
        'public.' || quote_ident(table_name),
        'SELECT'
    ) AS staff_can_select,
    has_table_privilege(
        'restaurant_readonly',
        'public.' || quote_ident(table_name),
        'SELECT'
    ) AS readonly_can_select
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Check restricted permissions
SELECT
    has_table_privilege(
        'restaurant_staff',
        'public.' || quote_ident(table_name),
        'DELETE'
    ) AS staff_can_delete,
    has_table_privilege(
        'restaurant_customer',
        'public.' || quote_ident(table_name),
        'INSERT'
    ) AS customer_can_insert,
    has_table_privilege(
        'restaurant_readonly',
        'public.' || quote_ident(table_name),
        'UPDATE'
    ) AS readonly_can_update
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
