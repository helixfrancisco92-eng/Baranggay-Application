-- ==========================================
-- BOARDTRACK - CREATE DATABASE ROLES
-- Activity 4
-- ==========================================

-- GROUP ROLES

CREATE ROLE boardtrack_admin_role NOLOGIN;
CREATE ROLE boardtrack_app_role NOLOGIN;
CREATE ROLE boardtrack_manager_role NOLOGIN;
CREATE ROLE boardtrack_member_role NOLOGIN;
CREATE ROLE boardtrack_readonly_role NOLOGIN;


-- LOGIN USERS

CREATE ROLE boardtrack_admin LOGIN;
CREATE ROLE boardtrack_app LOGIN;
CREATE ROLE boardtrack_manager LOGIN;
CREATE ROLE boardtrack_member LOGIN;
CREATE ROLE boardtrack_viewer LOGIN;


-- ASSIGN USERS TO GROUP ROLES

GRANT boardtrack_admin_role TO boardtrack_admin;
GRANT boardtrack_app_role TO boardtrack_app;
GRANT boardtrack_manager_role TO boardtrack_manager;
GRANT boardtrack_member_role TO boardtrack_member;
GRANT boardtrack_readonly_role TO boardtrack_viewer;


-- VERIFY ROLE CREATION

SELECT
    rolname,
    rolcanlogin
FROM pg_roles
WHERE rolname LIKE 'boardtrack%'
ORDER BY rolname;