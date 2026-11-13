-- ==============================================================================
-- COMP 018 — Database Administration (Activity 6)
-- Target Project: PUP-SPOT (Group 5 - Lost and Found Management System)
-- Cluster Role Recreation Script (Activity 4 RBAC Specification)
-- Platform: PostgreSQL 18.0 / 16+
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. IDEMPOTENT CREATION OF GROUP ROLES (NOLOGIN)
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lf_admin') THEN
        CREATE ROLE lf_admin NOLOGIN;
        RAISE NOTICE 'Role lf_admin created.';
    ELSE
        RAISE NOTICE 'Role lf_admin already exists.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lf_staff') THEN
        CREATE ROLE lf_staff NOLOGIN;
        RAISE NOTICE 'Role lf_staff created.';
    ELSE
        RAISE NOTICE 'Role lf_staff already exists.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lf_viewer') THEN
        CREATE ROLE lf_viewer NOLOGIN;
        RAISE NOTICE 'Role lf_viewer created.';
    ELSE
        RAISE NOTICE 'Role lf_viewer already exists.';
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. IDEMPOTENT CREATION OF DATABASE LOGIN ACCOUNTS
-- Note: Replace placeholder passwords with institutional secret management keys.
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lf_admin_user') THEN
        CREATE USER lf_admin_user WITH PASSWORD 'AdminPassword123';
        RAISE NOTICE 'User lf_admin_user created.';
    ELSE
        RAISE NOTICE 'User lf_admin_user already exists.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lf_staff_user') THEN
        CREATE USER lf_staff_user WITH PASSWORD 'StaffPassword123';
        RAISE NOTICE 'User lf_staff_user created.';
    ELSE
        RAISE NOTICE 'User lf_staff_user already exists.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lf_viewer_user') THEN
        CREATE USER lf_viewer_user WITH PASSWORD 'ViewerPassword123';
        RAISE NOTICE 'User lf_viewer_user created.';
    ELSE
        RAISE NOTICE 'User lf_viewer_user already exists.';
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 3. ROLE MEMBERSHIP ASSIGNMENTS (RBAC HIERARCHY)
-- ------------------------------------------------------------------------------
GRANT lf_admin TO lf_admin_user;
GRANT lf_staff TO lf_staff_user;
GRANT lf_viewer TO lf_viewer_user;

-- ------------------------------------------------------------------------------
-- 4. SCHEMA USAGE PRIVILEGES
-- ------------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO lf_admin, lf_staff, lf_viewer;

-- ------------------------------------------------------------------------------
-- 5. OBJECT PRIVILEGE ASSIGNMENTS (TABLES AND SEQUENCES)
-- ------------------------------------------------------------------------------

-- Administrator: Full control over tables and sequences
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO lf_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO lf_admin;

-- Staff: View, Insert, and Update on tables (DELETE prohibited)
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO lf_staff;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lf_staff;
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM lf_staff;

-- Viewer: Strict Read-Only Access
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lf_viewer;
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM lf_viewer;

-- ------------------------------------------------------------------------------
-- 6. DEFAULT PRIVILEGES FOR FUTURE OBJECTS
-- Ensures newly restored or migrated tables automatically inherit privileges
-- ------------------------------------------------------------------------------
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO lf_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO lf_staff;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO lf_viewer;

SELECT 'Activity 4 roles and privileges recreated successfully.' AS status;

