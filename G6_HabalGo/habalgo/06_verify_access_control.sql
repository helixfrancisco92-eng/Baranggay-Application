-- ==============================================================================
-- HabalGo (Group 6) — Access Control & Role Verification Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test
-- Reference: Activity 4 Access Control Specification (03_roles_and_privileges.sql)
-- ==============================================================================

\set ON_ERROR_STOP off

SELECT '=================================================================' AS header;
SELECT ' ACTIVITY 4 ACCESS CONTROL RECOVERY & VALIDATION SUITE          ' AS header;
SELECT ' Target Database: ' || current_database() || ' | User: ' || current_user AS context;
SELECT '=================================================================' AS header;

-- -----------------------------------------------------------------------------
-- STEP 1: RECREATE ACTIVITY 4 GROUP AND LOGIN ROLES IF ABSENT
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    -- 1. Create Group Roles (NOLOGIN)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_runtime_grp') THEN
        CREATE ROLE app_runtime_grp NOLOGIN;
        RAISE NOTICE 'Created role app_runtime_grp';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_readonly_grp') THEN
        CREATE ROLE app_readonly_grp NOLOGIN;
        RAISE NOTICE 'Created role app_readonly_grp';
    END IF;

    -- 2. Create Application Login Accounts
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'habalgo_app_user') THEN
        CREATE ROLE habalgo_app_user WITH LOGIN PASSWORD 'HabalGoSecurePass2026!';
        RAISE NOTICE 'Created login user habalgo_app_user';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'habalgo_readonly_user') THEN
        CREATE ROLE habalgo_readonly_user WITH LOGIN PASSWORD 'HabalGoReadOnly2026!';
        RAISE NOTICE 'Created login user habalgo_readonly_user';
    END IF;

    -- 3. Assign Login Accounts to Group Roles
    GRANT app_runtime_grp TO habalgo_app_user;
    GRANT app_readonly_grp TO habalgo_readonly_user;

    -- 4. Grant Database Connection
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO app_runtime_grp, app_readonly_grp', current_database());

    -- 5. Grant Schema Usage
    GRANT USAGE ON SCHEMA habalgo TO app_runtime_grp, app_readonly_grp;

    -- 6. Grant Object-Level Privileges
    -- Runtime application account gets full CRUD
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA habalgo TO app_runtime_grp;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA habalgo TO app_runtime_grp;

    -- Read-only auditor account gets SELECT only
    GRANT SELECT ON ALL TABLES IN SCHEMA habalgo TO app_readonly_grp;

    -- 7. Ensure Default Privileges for Future Tables
    ALTER DEFAULT PRIVILEGES IN SCHEMA habalgo GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_runtime_grp;
    ALTER DEFAULT PRIVILEGES IN SCHEMA habalgo GRANT USAGE, SELECT ON SEQUENCES TO app_runtime_grp;
    ALTER DEFAULT PRIVILEGES IN SCHEMA habalgo GRANT SELECT ON TABLES TO app_readonly_grp;

    RAISE NOTICE 'Access control matrix successfully applied.';
END
$$;

-- -----------------------------------------------------------------------------
-- STEP 2: AUDIT ROLES AND MEMBERSHIPS IN CATALOG
-- -----------------------------------------------------------------------------
SELECT 'STEP 2: Auditing Cluster Roles and Membership Tree...' AS test_step;

SELECT 
    r.rolname AS role_name,
    r.rolcanlogin AS can_login,
    r.rolsuper AS is_superuser,
    r.rolcreaterole AS can_create_role,
    r.rolcreatedb AS can_create_db,
    ARRAY(
        SELECT b.rolname
        FROM pg_auth_members m
        JOIN pg_roles b ON (m.roleid = b.oid)
        WHERE m.member = r.oid
    ) AS granted_group_roles
FROM pg_roles r
WHERE r.rolname IN ('app_runtime_grp', 'app_readonly_grp', 'habalgo_app_user', 'habalgo_readonly_user')
ORDER BY r.rolcanlogin, r.rolname;

-- -----------------------------------------------------------------------------
-- STEP 3: AUDIT TABLE PRIVILEGES IN SCHEMA 'habalgo'
-- -----------------------------------------------------------------------------
SELECT 'STEP 3: Auditing Table-Level Permissions by Grantee...' AS test_step;

SELECT 
    table_schema,
    table_name,
    grantee,
    string_agg(privilege_type, ', ' ORDER BY privilege_type) AS granted_privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'habalgo'
  AND grantee IN ('app_runtime_grp', 'app_readonly_grp', 'habalgo_app_user', 'habalgo_readonly_user')
GROUP BY table_schema, table_name, grantee
ORDER BY table_name, grantee;

-- -----------------------------------------------------------------------------
-- STEP 4: PERMITTED OPERATION TEST (habalgo_app_user -> INSERT customer)
-- -----------------------------------------------------------------------------
SELECT 'STEP 4: Testing Permitted Operation (habalgo_app_user -> CRUD)...' AS test_step;

SET ROLE habalgo_app_user;
SELECT current_user AS active_session_role;

-- Execute permitted INSERT into habalgo.customer
INSERT INTO habalgo.customer (name, phone, email) 
VALUES ('Access Control Test User', '09170009999', 'acl_test_user@example.com')
RETURNING customer_id, name, phone, email;

-- Execute permitted UPDATE
UPDATE habalgo.customer 
SET phone = '09170008888' 
WHERE email = 'acl_test_user@example.com'
RETURNING customer_id, name, phone;

-- Execute permitted DELETE (Clean up)
DELETE FROM habalgo.customer 
WHERE email = 'acl_test_user@example.com';

RESET ROLE;
SELECT 'TEST 4 RESULT: PASSED (habalgo_app_user successfully performed CRUD operations)' AS status;

-- -----------------------------------------------------------------------------
-- STEP 5: PERMITTED OPERATION TEST (habalgo_readonly_user -> SELECT driver)
-- -----------------------------------------------------------------------------
SELECT 'STEP 5: Testing Permitted Operation (habalgo_readonly_user -> SELECT)...' AS test_step;

SET ROLE habalgo_readonly_user;
SELECT current_user AS active_session_role;

-- Permitted query
SELECT count(*) AS visible_drivers_count FROM habalgo.driver;

RESET ROLE;
SELECT 'TEST 5 RESULT: PASSED (habalgo_readonly_user successfully executed SELECT)' AS status;

-- -----------------------------------------------------------------------------
-- STEP 6: DENIED OPERATION TEST (habalgo_readonly_user -> INSERT INTO driver)
-- -----------------------------------------------------------------------------
SELECT 'STEP 6: Testing Denied Operation (habalgo_readonly_user -> INSERT [MUST FAIL])...' AS test_step;

SET ROLE habalgo_readonly_user;
SELECT current_user AS active_session_role;

-- This statement MUST fail with ERROR 42501 (permission denied for table driver)
INSERT INTO habalgo.driver (name, phone, license_no)
VALUES ('Unauthorized Driver Entry', '09179998877', 'N01-99-999999');

RESET ROLE;

-- -----------------------------------------------------------------------------
-- STEP 7: DENIED OPERATION TEST (habalgo_readonly_user -> DROP TABLE)
-- -----------------------------------------------------------------------------
SELECT 'STEP 7: Testing Denied Operation (habalgo_readonly_user -> DROP TABLE [MUST FAIL])...' AS test_step;

SET ROLE habalgo_readonly_user;
SELECT current_user AS active_session_role;

-- This statement MUST fail with ERROR 42501 (must be owner of table)
DROP TABLE habalgo.customer;

RESET ROLE;

SELECT '=================================================================' AS footer;
SELECT ' ACCESS CONTROL VERIFICATION SUITE EXECUTION COMPLETED           ' AS footer;
SELECT '=================================================================' AS footer;

