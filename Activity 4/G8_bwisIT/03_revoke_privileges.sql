
-- ============================================
-- ACTIVITY 4: REVOKE UNNECESSARY PRIVILEGES
-- ============================================

-- VIEWERS MUST NOT MODIFY RECORDS
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
ON ALL TABLES IN SCHEMA public
FROM canteen_readonly_role;

-- APPLICATION USERS MUST NOT DELETE RECORDS
REVOKE DELETE, TRUNCATE
ON ALL TABLES IN SCHEMA public
FROM canteen_app_role;

-- CASHIERS MUST NOT DELETE OR MODIFY DATABASE STRUCTURE
REVOKE DELETE, TRUNCATE, REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public
FROM canteen_cashier_role;

-- USERS MUST NOT CREATE OBJECTS IN PUBLIC SCHEMA
REVOKE CREATE ON SCHEMA public
FROM canteen_app_role,
     canteen_cashier_role,
     canteen_readonly_role;

-- VERIFY PRIVILEGES
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee IN (
    'canteen_app_role',
    'canteen_cashier_role',
    'canteen_readonly_role'
)
ORDER BY grantee, table_name, privilege_type;
