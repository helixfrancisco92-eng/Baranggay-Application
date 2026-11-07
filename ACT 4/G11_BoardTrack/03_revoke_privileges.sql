-- ==========================================
-- BOARDTRACK - REVOKE PRIVILEGES
-- Activity 4
-- ==========================================

-- MEMBER CANNOT DELETE RECORDS

REVOKE DELETE, TRUNCATE
ON ALL TABLES IN SCHEMA public
FROM boardtrack_member_role;


-- VIEWER IS STRICTLY READ-ONLY

REVOKE INSERT, UPDATE, DELETE, TRUNCATE,
       REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public
FROM boardtrack_readonly_role;

REVOKE ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
FROM boardtrack_readonly_role;


-- APPLICATION CANNOT TRUNCATE TABLES

REVOKE TRUNCATE, REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public
FROM boardtrack_app_role;


-- MANAGER CANNOT TRUNCATE TABLES

REVOKE TRUNCATE, REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public
FROM boardtrack_manager_role;


-- MEMBER CANNOT TRUNCATE TABLES

REVOKE TRUNCATE, REFERENCES, TRIGGER
ON ALL TABLES IN SCHEMA public
FROM boardtrack_member_role;


-- VERIFY REVOKED PRIVILEGES

SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee LIKE 'boardtrack%'
ORDER BY grantee, table_name, privilege_type;