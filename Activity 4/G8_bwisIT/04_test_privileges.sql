
-- ============================================
-- ACTIVITY 4: TEST DATABASE PRIVILEGES
-- ============================================

-- CHECK CURRENT DATABASE USER
SELECT CURRENT_USER;

-- CHECK CURRENT ROLE
SELECT CURRENT_ROLE;

-- CHECK TABLE PERMISSIONS
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee LIKE 'canteen_%'
ORDER BY grantee, table_name;

-- CHECK SEQUENCE PERMISSIONS
SELECT
    grantee,
    object_name,
    privilege_type
FROM information_schema.usage_privileges
WHERE grantee LIKE 'canteen_%'
ORDER BY grantee, object_name;
