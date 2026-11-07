-- ==========================================
-- BOARDTRACK - GRANT PRIVILEGES
-- Activity 4
-- ==========================================

-- DATABASE ACCESS

DO $$
BEGIN
    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO boardtrack_admin_role,
         boardtrack_app_role, boardtrack_manager_role,
         boardtrack_member_role, boardtrack_readonly_role',
        current_database()
    );
END
$$;


-- SCHEMA ACCESS

GRANT USAGE ON SCHEMA public TO
    boardtrack_admin_role,
    boardtrack_app_role,
    boardtrack_manager_role,
    boardtrack_member_role,
    boardtrack_readonly_role;

GRANT CREATE ON SCHEMA public TO boardtrack_admin_role;


-- ADMIN: FULL ACCESS TO EXISTING TABLES

GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA public
TO boardtrack_admin_role;


-- APPLICATION: CRUD ACCESS

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO boardtrack_app_role;


-- MANAGER: CRUD ACCESS

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO boardtrack_manager_role;


-- MEMBER: SELECT, INSERT, UPDATE

GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO boardtrack_member_role;


-- VIEWER: READ-ONLY ACCESS

GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO boardtrack_readonly_role;


-- SEQUENCE PRIVILEGES

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
TO boardtrack_admin_role;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO boardtrack_app_role,
   boardtrack_manager_role,
   boardtrack_member_role;


-- FUTURE TABLE PRIVILEGES
-- These apply to objects created by the user
-- executing this script.

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLES TO boardtrack_app_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLES TO boardtrack_manager_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE
ON TABLES TO boardtrack_member_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT
ON TABLES TO boardtrack_readonly_role;


-- VERIFY TABLE PRIVILEGES

SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee LIKE 'boardtrack%'
ORDER BY grantee, table_name, privilege_type;