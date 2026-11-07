GRANT CONNECT ON DATABASE rma_db
TO rma_runtime_grp,
   rma_readonly_grp,
   rma_entry_grp;

   GRANT USAGE ON SCHEMA public
TO rma_runtime_grp,
   rma_readonly_grp,
   rma_entry_grp;

   GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO rma_runtime_grp;

GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO rma_readonly_grp;

GRANT SELECT, INSERT
ON ALL TABLES IN SCHEMA public
TO rma_entry_grp;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO rma_runtime_grp,
   rma_entry_grp;

ALTER ROLE rma_app_user NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE rma_report_user NOSUPERUSER NOCREATEDB NOCREATEROLE;
ALTER ROLE rma_encoder NOSUPERUSER NOCREATEDB NOCREATEROLE;