-- Check table privileges
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'brewpos_runtime_grp',
    'brewpos_cashier_grp',
    'brewpos_readonly_grp'
)
ORDER BY grantee, table_name, privilege_type;

------- check role membership

SELECT
    member.rolname AS login_account,
    granted.rolname AS group_role
FROM pg_auth_members m
JOIN pg_roles member
    ON member.oid = m.member
JOIN pg_roles granted
    ON granted.oid = m.roleid;