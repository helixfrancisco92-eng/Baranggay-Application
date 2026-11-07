-- =========================================
-- CAMPUSSAFE DATABASE ACCESS CONTROL
-- CREATE ROLES AND USERS
-- =========================================

-- Group roles
CREATE ROLE campussafe_admin_role NOLOGIN;
CREATE ROLE campussafe_app_role NOLOGIN;
CREATE ROLE campussafe_auditor_role NOLOGIN;

-- Login accounts
CREATE ROLE campussafe_admin
LOGIN PASSWORD 'CHANGE_THIS_PASSWORD';

CREATE ROLE campussafe_app
LOGIN PASSWORD 'CHANGE_THIS_PASSWORD';

CREATE ROLE campussafe_auditor
LOGIN PASSWORD 'CHANGE_THIS_PASSWORD';

-- Assign group roles
GRANT campussafe_admin_role TO campussafe_admin;
GRANT campussafe_app_role TO campussafe_app;
GRANT campussafe_auditor_role TO campussafe_auditor;