-- DATABASE ACCESS
GRANT CONNECT ON DATABASE brewpos_db
TO brewpos_admin_grp,
   brewpos_runtime_grp,
   brewpos_cashier_grp,
   brewpos_readonly_grp;

-- SCHEMA ACCESS
GRANT USAGE ON SCHEMA public
TO brewpos_runtime_grp,
   brewpos_cashier_grp,
   brewpos_readonly_grp;

-- APPLICATION RUNTIME ACCESS
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO brewpos_runtime_grp;

-- CASHIER ACCESS
GRANT SELECT, INSERT
ON ALL TABLES IN SCHEMA public
TO brewpos_cashier_grp;

-- READ ONLY ACCESS
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO brewpos_readonly_grp;

-- SEQUENCE ACCESS
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO brewpos_runtime_grp,
   brewpos_cashier_grp;