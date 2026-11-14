
-- ============================================
-- ACTIVITY 4: CREATE DATABASE ROLES AND USERS
-- ============================================

-- GROUP ROLES

CREATE ROLE canteen_admin_role NOLOGIN;
CREATE ROLE canteen_app_role NOLOGIN;
CREATE ROLE canteen_cashier_role NOLOGIN;
CREATE ROLE canteen_readonly_role NOLOGIN;

-- LOGIN USERS
-- Replace the example passwords before execution.
-- Never commit real passwords to GitHub.

CREATE ROLE canteen_admin
LOGIN PASSWORD 'ChangeThisAdminPassword';

CREATE ROLE canteen_app
LOGIN PASSWORD 'ChangeThisAppPassword';

CREATE ROLE canteen_cashier
LOGIN PASSWORD 'ChangeThisCashierPassword';

CREATE ROLE canteen_viewer
LOGIN PASSWORD 'ChangeThisViewerPassword';

-- ASSIGN USERS TO GROUP ROLES

GRANT canteen_admin_role TO canteen_admin;
GRANT canteen_app_role TO canteen_app;
GRANT canteen_cashier_role TO canteen_cashier;
GRANT canteen_readonly_role TO canteen_viewer;

-- VERIFY CREATED ROLES

SELECT
    rolname,
    rolcanlogin,
    rolsuper,
    rolcreatedb,
    rolcreaterole
FROM pg_roles
WHERE rolname LIKE 'canteen_%'
ORDER BY rolname;
