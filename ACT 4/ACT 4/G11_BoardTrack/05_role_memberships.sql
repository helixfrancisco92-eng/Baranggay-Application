-- =========================================
-- TEST 1: ROLE MEMBERSHIPS
-- =========================================

SELECT
    member.rolname AS username,
    role.rolname AS assigned_role
FROM pg_auth_members AS memberships
JOIN pg_roles AS role
    ON memberships.roleid = role.oid
JOIN pg_roles AS member
    ON memberships.member = member.oid
WHERE role.rolname IN (
    'boardtrack_admin_role',
    'boardtrack_app_role',
    'boardtrack_manager_role',
    'boardtrack_member_role',
    'boardtrack_readonly_role'
)
ORDER BY assigned_role, username;