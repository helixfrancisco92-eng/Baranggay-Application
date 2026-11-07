-- ==========================================
-- BOARDTRACK - TEST PRIVILEGES
-- Activity 4
-- ==========================================

-- TEST 1: CHECK ROLE MEMBERSHIPS

SELECT
    member.rolname AS login_user,
    granted.rolname AS group_role
FROM pg_auth_members m
JOIN pg_roles granted
    ON m.roleid = granted.oid
JOIN pg_roles member
    ON m.member = member.oid
WHERE granted.rolname LIKE 'boardtrack%'
ORDER BY login_user;


-- TEST 2: CHECK TABLE PERMISSIONS

SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee LIKE 'boardtrack%'
ORDER BY grantee, table_name, privilege_type;


-- TEST 3: CHECK SELECT PERMISSION

SELECT
    table_name,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'SELECT'
    ) AS can_select
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';


-- TEST 4: CHECK MEMBER RESTRICTIONS

SELECT
    table_name,
    has_table_privilege(
        'boardtrack_member',
        format('%I.%I', table_schema, table_name),
        'DELETE'
    ) AS can_delete
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';


-- TEST 5: CHECK VIEWER RESTRICTIONS

SELECT
    table_name,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'INSERT'
    ) AS can_insert,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'UPDATE'
    ) AS can_update,
    has_table_privilege(
        'boardtrack_viewer',
        format('%I.%I', table_schema, table_name),
        'DELETE'
    ) AS can_delete
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';


-- TEST 6: CHECK ADMIN ACCESS

SELECT
    table_name,
    has_table_privilege(
        'boardtrack_admin',
        format('%I.%I', table_schema, table_name),
        'SELECT'
    ) AS can_select,
    has_table_privilege(
        'boardtrack_admin',
        format('%I.%I', table_schema, table_name),
        'INSERT'
    ) AS can_insert,
    has_table_privilege(
        'boardtrack_admin',
        format('%I.%I', table_schema, table_name),
        'UPDATE'
    ) AS can_update,
    has_table_privilege(
        'boardtrack_admin',
        format('%I.%I', table_schema, table_name),
        'DELETE'
    ) AS can_delete
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';