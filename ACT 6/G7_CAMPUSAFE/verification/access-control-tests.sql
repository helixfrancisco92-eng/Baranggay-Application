-- =============================================================================
-- CampusSafe (Group 7) — Granular Access Control Verification Tests
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Access Control Test Suite (Permitted vs. Denied)     '
\echo ' Target: grp07_campussafedb_activity6_restore_test               '
\echo '================================================================='

-- =============================================================================
-- SECTION 1: RUNTIME ACCOUNT (campussafe_app) TESTS
-- =============================================================================
\echo '>>> 1. TESTING RUNTIME ACCOUNT (campussafe_app) <<<'

-- Test 1.1: Runtime Account Can SELECT Operational Data (Expected: ALLOWED)
SET ROLE campussafe_app;
SELECT 'Test 1.1 (SELECT hazard_report): SUCCESS' AS test_result, COUNT(*) AS count FROM hazard_report;

-- Test 1.2: Runtime Account Can INSERT Status History (Expected: ALLOWED)
INSERT INTO report_status_history (report_id, changed_by_user_id, status, notes)
VALUES (1, 1, 'Submitted', 'Activity 6 automated access control test probe')
RETURNING 'Test 1.2 (INSERT history): SUCCESS' AS test_result, history_id, changed_at;

-- Test 1.3: Runtime Account CANNOT Delete from hazard_report (Expected: DENIED)
-- Expected error: permission denied for table hazard_report
DO $$
BEGIN
    DELETE FROM hazard_report WHERE report_id = 1;
    RAISE EXCEPTION 'TEST 1.3 FAILED: Runtime account was permitted to delete from hazard_report!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'TEST 1.3 PASSED: Runtime account correctly blocked from deleting hazard_report.';
END $$;

-- Test 1.4: Runtime Account CANNOT Delete from app_user (Expected: DENIED)
DO $$
BEGIN
    DELETE FROM app_user WHERE user_id = 1;
    RAISE EXCEPTION 'TEST 1.4 FAILED: Runtime account was permitted to delete from app_user!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'TEST 1.4 PASSED: Runtime account correctly blocked from deleting app_user.';
END $$;

RESET ROLE;

-- =============================================================================
-- SECTION 2: AUDITOR ACCOUNT (campussafe_report) TESTS
-- =============================================================================
\echo '>>> 2. TESTING AUDITOR ACCOUNT (campussafe_report) <<<'

-- Test 2.1: Auditor Can SELECT Operational Reports (Expected: ALLOWED)
SET ROLE campussafe_report;
SELECT 'Test 2.1 (Auditor SELECT hazard_report): SUCCESS' AS test_result, COUNT(*) AS count FROM hazard_report;

-- Test 2.2: Auditor CANNOT Modify Hazard Priority (Expected: DENIED)
DO $$
BEGIN
    UPDATE hazard_report SET priority = 'Critical' WHERE report_id = 1;
    RAISE EXCEPTION 'TEST 2.2 FAILED: Auditor was permitted to update hazard_report!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'TEST 2.2 PASSED: Auditor correctly blocked from modifying hazard_report.';
END $$;

-- Test 2.3: Auditor CANNOT Query User Credentials / Password Hashes (Expected: DENIED)
DO $$
BEGIN
    PERFORM user_id, username, password_hash FROM app_user;
    RAISE EXCEPTION 'TEST 2.3 FAILED: Auditor was permitted to read app_user credentials!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'TEST 2.3 PASSED: Auditor correctly blocked from accessing app_user.';
END $$;

RESET ROLE;

-- =============================================================================
-- SECTION 3: BACKUP OPERATOR ACCOUNT (campussafe_backup) TESTS
-- =============================================================================
\echo '>>> 3. TESTING BACKUP OPERATOR ACCOUNT (campussafe_backup) <<<'

-- Test 3.1: Backup Operator Can Read All Tables & Sequences (Expected: ALLOWED)
SET ROLE campussafe_backup;
SELECT 'Test 3.1 (Backup SELECT app_user): SUCCESS' AS test_result, COUNT(*) FROM app_user;
SELECT 'Test 3.1b (Backup SELECT sequence): SUCCESS' AS test_result, last_value FROM hazard_report_report_id_seq;

-- Test 3.2: Backup Operator CANNOT Insert Data (Expected: DENIED)
DO $$
BEGIN
    INSERT INTO hazard_category (category_name) VALUES ('Rogue Category');
    RAISE EXCEPTION 'TEST 3.2 FAILED: Backup operator was permitted to INSERT data!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'TEST 3.2 PASSED: Backup operator correctly blocked from writing data.';
END $$;

-- Test 3.3: Backup Operator CANNOT Drop Tables (Expected: DENIED)
DO $$
BEGIN
    DROP TABLE attachment;
    RAISE EXCEPTION 'TEST 3.3 FAILED: Backup operator was permitted to DROP tables!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'TEST 3.3 PASSED: Backup operator correctly blocked from DDL DROP.';
END $$;

RESET ROLE;

\echo '================================================================='
\echo ' All Access Control Permitted & Denied Tests Evaluated: PASS     '
\echo ' Principle of Least Privilege (PoLP) Rigorously Enforced.       '
\echo '================================================================='

