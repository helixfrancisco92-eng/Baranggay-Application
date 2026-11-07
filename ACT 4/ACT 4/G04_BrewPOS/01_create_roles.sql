-- GROUP ROLES
CREATE ROLE brewpos_admin_grp NOLOGIN;
CREATE ROLE brewpos_runtime_grp NOLOGIN;
CREATE ROLE brewpos_cashier_grp NOLOGIN;
CREATE ROLE brewpos_readonly_grp NOLOGIN;

-- LOGIN ACCOUNTS
CREATE ROLE brewpos_admin LOGIN PASSWORD 'CHANGE_ME';
CREATE ROLE brewpos_app LOGIN PASSWORD 'CHANGE_ME';
CREATE ROLE brewpos_cashier LOGIN PASSWORD 'CHANGE_ME';
CREATE ROLE brewpos_auditor LOGIN PASSWORD 'CHANGE_ME';

-- ROLE MEMBERSHIP
GRANT brewpos_admin_grp TO brewpos_admin;
GRANT brewpos_runtime_grp TO brewpos_app;
GRANT brewpos_cashier_grp TO brewpos_cashier;
GRANT brewpos_readonly_grp TO brewpos_auditor;