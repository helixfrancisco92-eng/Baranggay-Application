
-- ============================================
-- HABALGO - ACTIVITY 4
-- 03_revoke_privileges.sql
-- ============================================

-- 1. Remove DELETE permission from application role

REVOKE DELETE
ON ALL TABLES IN SCHEMA public
FROM habalgo_app_role;

-- 2. Remove unnecessary permissions from auditor

REVOKE INSERT, UPDATE, DELETE, TRUNCATE,
       REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public
FROM habalgo_auditor_role;

-- 3. Remove CREATE permission from application

REVOKE CREATE ON SCHEMA public
FROM habalgo_app_role;

-- 4. Remove CREATE permission from auditor

REVOKE CREATE ON SCHEMA public
FROM habalgo_auditor_role;

-- 5. Verify revoked permissions

SELECT
    rolname,
    has_schema_privilege(
        rolname,
        'public',
        'CREATE'
    ) AS can_create
FROM pg_roles
WHERE rolname IN (
    'habalgo_admin_role',
    'habalgo_app_role',
    'habalgo_auditor_role'
);
