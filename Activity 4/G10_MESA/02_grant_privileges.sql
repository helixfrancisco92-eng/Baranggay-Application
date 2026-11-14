
-- 02_grant_privileges.sql

-- Allow roles to access the public schema
GRANT USAGE ON SCHEMA public TO
    restaurant_admin,
    restaurant_manager,
    restaurant_staff,
    restaurant_customer,
    restaurant_readonly;

-- ADMIN: Full access to existing tables
GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA public
TO restaurant_admin;

-- ADMIN: Sequence access
GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
TO restaurant_admin;

-- MANAGER: Read access to existing tables
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO restaurant_manager;

-- STAFF: Read access to existing tables
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO restaurant_staff;

-- CUSTOMER: Read access to existing tables
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO restaurant_customer;

-- READ-ONLY: View existing tables
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO restaurant_readonly;

-- Verify table permissions
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'restaurant_admin',
    'restaurant_manager',
    'restaurant_staff',
    'restaurant_customer',
    'restaurant_readonly'
)
ORDER BY grantee, table_name, privilege_type;
