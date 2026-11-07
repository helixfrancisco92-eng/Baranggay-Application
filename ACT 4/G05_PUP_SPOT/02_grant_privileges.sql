-- Allow access to public schema
GRANT USAGE ON SCHEMA public
TO lf_admin, lf_staff, lf_viewer;

-- ADMIN: Full table permissions
GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA public
TO lf_admin;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
TO lf_admin;

-- STAFF: View, insert, and update
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO lf_staff;

-- VIEWER: Read-only access
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO lf_viewer;