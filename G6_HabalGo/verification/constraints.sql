-- ==============================================================================
-- HabalGo (Group 6) — Relational Constraints Verification Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test
-- Schema: habalgo
-- ==============================================================================

\set ON_ERROR_STOP off
SET search_path TO habalgo, public;

SELECT '=================================================================' AS header;
SELECT ' AUDIT: PRIMARY, FOREIGN, UNIQUE, AND CHECK CONSTRAINTS          ' AS header;
SELECT ' Target Database: ' || current_database() AS context;
SELECT '=================================================================' AS header;

-- 1. Inventory of All Active Constraints in Schema 'habalgo'
SELECT 
    conrelid::regclass::text AS target_table,
    conname AS constraint_name,
    CASE contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE KEY'
        WHEN 'c' THEN 'CHECK CONSTRAINT'
        ELSE contype::text
    END AS constraint_type,
    pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'habalgo'
ORDER BY conrelid::regclass::text, contype, conname;

-- 2. Audit Foreign Key Referential Integrity and Cascading Actions
SELECT 
    tc.table_name AS referencing_table,
    kcu.column_name AS foreign_key_column,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_primary_key,
    rc.update_rule AS on_update_action,
    rc.delete_rule AS on_delete_action
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.referential_constraints rc
    ON tc.constraint_name = rc.constraint_name
    AND tc.table_schema = rc.constraint_schema
JOIN information_schema.constraint_column_usage ccu
    ON rc.unique_constraint_name = ccu.constraint_name
    AND rc.unique_constraint_schema = ccu.constraint_schema
WHERE tc.table_schema = 'habalgo'
ORDER BY tc.table_name, kcu.column_name;

-- 3. Audit NOT NULL Constraints
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'habalgo'
  AND is_nullable = 'NO'
ORDER BY table_name, ordinal_position;

-- -----------------------------------------------------------------------------
-- SECTION 4: NEGATIVE CONSTRAINT TESTS (VALIDATING ENFORCEMENT)
-- -----------------------------------------------------------------------------
SELECT 'SECTION 4: Testing Constraint Enforcement with Negative Tests...' AS section;

-- Negative Test 1: Check Constraint on Payment Amount (Must be > 0)
SELECT '--- Negative Test 1: Inserting Negative Payment Amount (MUST FAIL) ---' AS test_name;
DO $$
BEGIN
    INSERT INTO habalgo.payment (booking_id, amount, method, status)
    VALUES (1, -50.00, 'Cash', 'Pending');
    RAISE EXCEPTION 'Constraint failure: Negative payment amount was accepted!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASSED: Check constraint payment_amount_check successfully rejected negative amount.';
END
$$;

-- Negative Test 2: Check Constraint on Rating Range (Must be 1 to 5)
SELECT '--- Negative Test 2: Inserting Out-of-Range Rating Value (MUST FAIL) ---' AS test_name;
DO $$
BEGIN
    INSERT INTO habalgo.rating_feedback (booking_id, customer_id, rating, feedback)
    VALUES (1, 1, 6, 'Exceeded maximum rating 5');
    RAISE EXCEPTION 'Constraint failure: Rating value of 6 was accepted!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASSED: Check constraint rating_check successfully rejected out-of-bounds score.';
END
$$;

-- Negative Test 3: Check Constraint on Booking Status
SELECT '--- Negative Test 3: Inserting Invalid Booking Status (MUST FAIL) ---' AS test_name;
DO $$
BEGIN
    INSERT INTO habalgo.booking (customer_id, pickup_location_id, dropoff_location_id, booking_status)
    VALUES (1, 1, 2, 'InvalidStatusXYZ');
    RAISE EXCEPTION 'Constraint failure: Invalid booking status was accepted!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASSED: Check constraint ck_booking_status successfully rejected illegal status value.';
END
$$;

-- Negative Test 4: Driver-Vehicle Assignment Date Logic
SELECT '--- Negative Test 4: Inserting End Date Earlier Than Start Date (MUST FAIL) ---' AS test_name;
DO $$
BEGIN
    INSERT INTO habalgo.driver_vehicle (driver_id, vehicle_id, assigned_from, assigned_to)
    VALUES (1, 1, '2026-11-10 10:00:00', '2026-11-09 10:00:00');
    RAISE EXCEPTION 'Constraint failure: Inverted assignment dates were accepted!';
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASSED: Check constraint ck_assignment_dates successfully rejected invalid timeline.';
END
$$;

SELECT '=================================================================' AS footer;
SELECT ' CONSTRAINT ENFORCEMENT AUDIT COMPLETED                          ' AS footer;
SELECT '=================================================================' AS footer;

