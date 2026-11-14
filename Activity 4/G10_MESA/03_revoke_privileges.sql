
-- 03_revoke_privileges.sql

-- STAFF cannot delete records
REVOKE DELETE
ON ALL TABLES IN SCHEMA public
FROM restaurant_staff;

-- CUSTOMER cannot modify database records directly
REVOKE INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
FROM restaurant_customer;

-- READ-ONLY cannot modify records
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
ON ALL TABLES IN SCHEMA public
FROM restaurant_readonly;

-- READ-ONLY cannot modify sequences
REVOKE USAGE, UPDATE
ON ALL SEQUENCES IN SCHEMA public
FROM restaurant_readonly;

-- Verify remaining permissions
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
