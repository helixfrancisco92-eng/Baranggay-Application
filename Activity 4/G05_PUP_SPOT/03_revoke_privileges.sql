
-- ============================================
-- ACTIVITY 4: REVOKE PRIVILEGES
-- LOST AND FOUND MANAGEMENT SYSTEM
-- ============================================

-- STAFF: Remove DELETE privilege
REVOKE DELETE
ON ALL TABLES IN SCHEMA public
FROM lf_staff;

-- VIEWER: Remove INSERT, UPDATE, DELETE privileges
REVOKE INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
FROM lf_viewer;

-- VIEWER: Ensure read-only access
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO lf_viewer;

-- STAFF: Ensure required permissions
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO lf_staff;

-- ADMIN: Ensure full table permissions
GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA public
TO lf_admin;

-- Display completion message
SELECT 'Privilege revocation completed successfully!'
AS status;
