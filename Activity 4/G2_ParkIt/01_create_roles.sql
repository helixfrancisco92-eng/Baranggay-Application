
-- PARK-IT: CREATE DATABASE ROLES

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'parkit_admin_grp'
    ) THEN
        CREATE ROLE parkit_admin_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'parkit_runtime_grp'
    ) THEN
        CREATE ROLE parkit_runtime_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'parkit_readonly_grp'
    ) THEN
        CREATE ROLE parkit_readonly_grp NOLOGIN;
    END IF;
END
$$;

-- Display created roles
SELECT rolname
FROM pg_roles
WHERE rolname IN (
    'parkit_admin_grp',
    'parkit_runtime_grp',
    'parkit_readonly_grp'
)
ORDER BY rolname;
