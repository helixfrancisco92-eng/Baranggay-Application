-- =============================================================================
-- CampusSafe (Group 7) — Relational Constraint & Negative Test Suite
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test (or grp07_campussafedb)
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Constraint Validation & Negative Testing Suite       '
\echo '================================================================='

\echo '--- 1. ACTIVE PRIMARY KEY CATALOG ---'
SELECT 
    conrelid::regclass AS table_name,
    conname AS pk_constraint_name,
    pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE c.contype = 'p' AND n.nspname = 'public'
ORDER BY table_name;

\echo '--- 2. ACTIVE FOREIGN KEY CATALOG WITH CASCADE RULES ---'
SELECT 
    conrelid::regclass AS child_table,
    conname AS fk_constraint_name,
    confrelid::regclass AS referenced_parent_table,
    pg_get_constraintdef(c.oid) AS constraint_definition,
    c.confdeltype AS delete_action_code
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE c.contype = 'f' AND n.nspname = 'public'
ORDER BY child_table, fk_constraint_name;

\echo '--- 3. UNIQUE CONSTRAINTS CATALOG ---'
SELECT 
    conrelid::regclass AS table_name,
    conname AS unique_constraint_name,
    pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE c.contype = 'u' AND n.nspname = 'public'
ORDER BY table_name;

\echo '--- 4. DOMAIN CHECK CONSTRAINTS CATALOG ---'
SELECT 
    conrelid::regclass AS table_name,
    conname AS check_constraint_name,
    pg_get_constraintdef(c.oid) AS check_expression
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE c.contype = 'c' AND n.nspname = 'public'
ORDER BY table_name, check_constraint_name;

\echo '--- 5. NEGATIVE CONSTRAINT TESTS (TRANSACTION ROLLBACK DRILLS) ---'

-- Negative Test A: Violating chk_verified_pair (Verifier provided without timestamp)
-- Expected: ERROR 23514 (check_violation)
DO $$
BEGIN
    INSERT INTO hazard_report (reporter_user_id, location_id, category_id, description, status, verified_by_user_id, verified_at)
    VALUES (4, 1, 1, 'Constraint Probe: Invalid Verifier Pair', 'Verified', 1, NULL);
    RAISE EXCEPTION 'TEST FAILED: chk_verified_pair did not block incomplete verification pair!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST A PASSED: chk_verified_pair successfully rejected incomplete verification pair.';
END $$;

-- Negative Test B: Violating chk_resolved_has_date (Status Resolved without resolved_at)
-- Expected: ERROR 23514 (check_violation)
DO $$
BEGIN
    INSERT INTO hazard_report (reporter_user_id, location_id, category_id, description, status, resolved_at)
    VALUES (4, 1, 1, 'Constraint Probe: Missing Resolution Date', 'Resolved', NULL);
    RAISE EXCEPTION 'TEST FAILED: chk_resolved_has_date did not block missing resolution date!';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'TEST B PASSED: chk_resolved_has_date successfully rejected Resolved status with NULL timestamp.';
END $$;

-- Negative Test C: Violating assignment UNIQUE (report_id, maintenance_user_id)
-- Expected: ERROR 23505 (unique_violation)
DO $$
BEGIN
    -- Report 5 is already assigned to User 2 (Alex Davis)
    INSERT INTO assignment (report_id, maintenance_user_id, assigned_by_user_id, assignment_status)
    VALUES (5, 2, 1, 'Assigned');
    RAISE EXCEPTION 'TEST FAILED: Duplicate technician assignment was permitted!';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'TEST C PASSED: Unique constraint successfully blocked duplicate technician assignment.';
END $$;

-- Negative Test D: Violating role_name UNIQUE constraint
-- Expected: ERROR 23505 (unique_violation)
DO $$
BEGIN
    INSERT INTO role (role_name, description) VALUES ('Administrator', 'Duplicate admin role attempt');
    RAISE EXCEPTION 'TEST FAILED: Duplicate role_name was permitted!';
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'TEST D PASSED: Unique constraint successfully blocked duplicate role name.';
END $$;

\echo '================================================================='
\echo ' All Negative Constraint Tests Successfully Blocked Violations   '
\echo '================================================================='

