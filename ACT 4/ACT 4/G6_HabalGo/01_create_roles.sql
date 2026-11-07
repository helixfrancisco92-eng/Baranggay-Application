
-- ============================================
-- HABALGO - ACTIVITY 4
-- 01_create_roles.sql
-- ============================================

-- 1. Create group roles

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'habalgo_admin_role'
    ) THEN
        CREATE ROLE habalgo_admin_role NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'habalgo_app_role'
    ) THEN
        CREATE ROLE habalgo_app_role NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'habalgo_auditor_role'
    ) THEN
        CREATE ROLE habalgo_auditor_role NOLOGIN;
    END IF;
END
$$;

-- 2. Create login accounts

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'habalgo_admin_user'
    ) THEN
        CREATE ROLE habalgo_admin_user LOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'habalgo_app_user'
    ) THEN
        CREATE ROLE habalgo_app_user LOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'habalgo_auditor_user'
    ) THEN
        CREATE ROLE habalgo_auditor_user LOGIN;
    END IF;
END
$$;

-- 3. Assign group roles to login accounts

GRANT habalgo_admin_role TO habalgo_admin_user;
GRANT habalgo_app_role TO habalgo_app_user;
GRANT habalgo_auditor_role TO habalgo_auditor_user;

-- 4. Verify created roles

SELECT
    rolname,
    rolcanlogin
FROM pg_roles
WHERE rolname LIKE 'habalgo_%'
ORDER BY rolname;
