-- Check current database user
SELECT CURRENT_USER;

-- Check table permissions
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'campussafe_admin_role',
    'campussafe_app_role',
    'campussafe_auditor_role'
)
ORDER BY grantee, table_name;