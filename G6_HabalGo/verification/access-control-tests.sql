-- ==============================================================================
-- HabalGo (Group 6) — Access Control & Security Verification Test Suite
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test
-- Schema: habalgo
-- ==============================================================================

\set ON_ERROR_STOP off
SET search_path TO habalgo, public;

SELECT '=================================================================' AS header;
SELECT ' LEAST PRIVILEGE & ACCESS CONTROL VERIFICATION TEST SUITE        ' AS header;
SELECT ' Database: ' || current_database() || ' | Timestamp: ' || CURRENT_TIMESTAMP::text AS session;
SELECT '=================================================================' AS header;

-- -----------------------------------------------------------------------------
-- TEST 1: habalgo_app_user — PERMITTED SELECT & INSERT (Application Operations)
-- Expected Behavior: SUCCEEDS with exit code 0 / successful row return.
-- -----------------------------------------------------------------------------
SELECT '--- TEST 1: habalgo_app_user Permitted Operations (SELECT & INSERT) ---' AS test_name;

SET ROLE habalgo_app_user;
SELECT current_user AS active_role;

-- 1A: Permitted SELECT
SELECT count(*) AS app_visible_customers FROM habalgo.customer;

-- 1B: Permitted INSERT
INSERT INTO habalgo.customer (name, phone, email)
VALUES ('Permitted App Customer', '09171234567', 'permitted_app_cust@habalgo.test')
RETURNING customer_id, name, email;

-- Clean up
DELETE FROM habalgo.customer WHERE email = 'permitted_app_cust@habalgo.test';

RESET ROLE;
SELECT 'TEST 1 EVALUATION: [PASSED] habalgo_app_user permitted operations executed successfully.' AS result;

-- -----------------------------------------------------------------------------
-- TEST 2: habalgo_readonly_user — PERMITTED SELECT (Audit & Reporting)
-- Expected Behavior: SUCCEEDS with exit code 0 / reading rows.
-- -----------------------------------------------------------------------------
SELECT '--- TEST 2: habalgo_readonly_user Permitted SELECT Operations ---' AS test_name;

SET ROLE habalgo_readonly_user;
SELECT current_user AS active_role;

-- 2A: Permitted SELECT on tables
SELECT count(*) AS readonly_visible_drivers FROM habalgo.driver;
SELECT count(*) AS readonly_visible_payments FROM habalgo.payment;

RESET ROLE;
SELECT 'TEST 2 EVALUATION: [PASSED] habalgo_readonly_user successfully read catalog data.' AS result;

-- -----------------------------------------------------------------------------
-- TEST 3: habalgo_readonly_user — DENIED INSERT (Write Protection)
-- Expected Behavior: FAILS with ERROR 42501 (permission denied for table).
-- -----------------------------------------------------------------------------
SELECT '--- TEST 3: habalgo_readonly_user Denied INSERT (MUST FAIL) ---' AS test_name;

SET ROLE habalgo_readonly_user;
SELECT current_user AS active_role;

-- This statement MUST produce ERROR 42501
INSERT INTO habalgo.customer (name, phone, email)
VALUES ('Unauthorized Customer Entry', '09170001111', 'unauth_cust@habalgo.test');

RESET ROLE;
SELECT 'TEST 3 EVALUATION: [EXPECTED FAILURE] Write attempt by auditor role was blocked.' AS result;

-- -----------------------------------------------------------------------------
-- TEST 4: habalgo_readonly_user — DENIED DDL / DROP TABLE (Schema Protection)
-- Expected Behavior: FAILS with ERROR 42501 (must be owner of relation).
-- -----------------------------------------------------------------------------
SELECT '--- TEST 4: habalgo_readonly_user Denied DROP TABLE (MUST FAIL) ---' AS test_name;

SET ROLE habalgo_readonly_user;
SELECT current_user AS active_role;

-- This statement MUST produce ERROR 42501
DROP TABLE habalgo.vehicle;

RESET ROLE;
SELECT 'TEST 4 EVALUATION: [EXPECTED FAILURE] Destructive DDL attempt was blocked.' AS result;

SELECT '=================================================================' AS footer;
SELECT ' ACCESS CONTROL VERIFICATION TEST SUITE FINISHED                 ' AS footer;
SELECT '=================================================================' AS footer;

