-- GROUP ROLES
CREATE ROLE rma_runtime_grp NOLOGIN;
CREATE ROLE rma_readonly_grp NOLOGIN;
CREATE ROLE rma_entry_grp NOLOGIN;

-- LOGIN ACCOUNTS
CREATE ROLE rma_app_user
LOGIN PASSWORD 'CHANGE_ME';

CREATE ROLE rma_report_user
LOGIN PASSWORD 'CHANGE_ME';

CREATE ROLE rma_encoder
LOGIN PASSWORD 'CHANGE_ME';

-- ROLE MEMBERSHIPS
GRANT rma_runtime_grp TO rma_app_user;
GRANT rma_readonly_grp TO rma_report_user;
GRANT rma_entry_grp TO rma_encoder;