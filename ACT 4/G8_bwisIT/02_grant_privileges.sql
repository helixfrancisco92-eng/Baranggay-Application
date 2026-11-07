
-- ============================================
-- ACTIVITY 4: GRANT DATABASE PRIVILEGES
-- Project: Campus Canteen Pre-Order and Queue
-- Database: grp08_bwisITdb
-- Schema: public
-- ============================================

-- 1. GRANT DATABASE CONNECTION
GRANT CONNECT ON DATABASE grp08_bwisITdb
TO canteen_admin_role,
   canteen_app_role,
   canteen_cashier_role,
   canteen_readonly_role;

-- 2. GRANT SCHEMA ACCESS
GRANT USAGE ON SCHEMA public
TO canteen_admin_role,
   canteen_app_role,
   canteen_cashier_role,
   canteen_readonly_role;

-- 3. ADMIN PRIVILEGES
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
TO canteen_admin_role;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public
TO canteen_admin_role;

-- 4. APPLICATION PRIVILEGES
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO canteen_app_role;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO canteen_app_role;

-- 5. CASHIER PRIVILEGES
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO canteen_cashier_role;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO canteen_cashier_role;

-- 6. VIEWER PRIVILEGES
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO canteen_readonly_role;

-- 7. VERIFY TABLE PRIVILEGES
SELECT
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee LIKE 'canteen_%'
ORDER BY grantee, table_name, privilege_type;

-- 8. VERIFY SEQUENCE PRIVILEGES
SELECT
    grantee,
    object_schema,
    object_name,
    privilege_type
FROM information_schema.usage_privileges
WHERE grantee LIKE 'canteen_%'
ORDER BY grantee, object_name;
    