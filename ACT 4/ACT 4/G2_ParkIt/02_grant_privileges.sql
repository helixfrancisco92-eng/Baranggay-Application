
-- PARK-IT: GRANT DATABASE PRIVILEGES

-- Allow roles to connect to the database
GRANT CONNECT ON DATABASE grp_parkitdb
TO parkit_admin_grp,
   parkit_runtime_grp,
   parkit_readonly_grp;

-- Allow access to the public schema
GRANT USAGE ON SCHEMA public
TO parkit_admin_grp,
   parkit_runtime_grp,
   parkit_readonly_grp;

-- ADMIN: Full access to existing tables
GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA public
TO parkit_admin_grp;

-- ADMIN: Full access to existing sequences
GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
TO parkit_admin_grp;

-- RUNTIME: Normal application operations
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO parkit_runtime_grp;

-- RUNTIME: Access to ID sequences
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO parkit_runtime_grp;

-- READ ONLY: View records only
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO parkit_readonly_grp;

-- FUTURE TABLES: Default privileges for postgres
ALTER DEFAULT PRIVILEGES
FOR ROLE postgres IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES
TO parkit_admin_grp;

ALTER DEFAULT PRIVILEGES
FOR ROLE postgres IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES
TO parkit_runtime_grp;

ALTER DEFAULT PRIVILEGES
FOR ROLE postgres IN SCHEMA public
GRANT SELECT ON TABLES
TO parkit_readonly_grp;

-- FUTURE SEQUENCES
ALTER DEFAULT PRIVILEGES
FOR ROLE postgres IN SCHEMA public
GRANT ALL PRIVILEGES ON SEQUENCES
TO parkit_admin_grp;

ALTER DEFAULT PRIVILEGES
FOR ROLE postgres IN SCHEMA public
GRANT USAGE, SELECT ON SEQUENCES
TO parkit_runtime_grp;
