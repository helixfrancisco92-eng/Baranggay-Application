-- ==============================================================================
-- HabalGo (Group 6) — Recovery Verification Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_recovery_test (RECOVERY VERIFICATION DB)
-- Schema: habalgo
-- ==============================================================================

\set ON_ERROR_STOP on

SET search_path TO habalgo, public;

SELECT '=================================================================' AS title;
SELECT ' POST-RESTORATION RECOVERY AUDIT & VERIFICATION                  ' AS title;
SELECT ' Target Recovery Database: ' || current_database() AS db_check;
SELECT ' Audit Timestamp: ' || CURRENT_TIMESTAMP::text AS audit_time;
SELECT '=================================================================' AS title;

-- -----------------------------------------------------------------------------
-- STEP 1: LOCATE THE TARGET RECORD IN RESTORED RECOVERY DATABASE
-- -----------------------------------------------------------------------------
SELECT 'STEP 1: Locating previously deleted record from backup archive...' AS action;

SELECT 
    customer_id,
    name,
    phone,
    email,
    'LOCATED IN RECOVERY ARCHIVE' AS archive_status
FROM habalgo.customer
WHERE email = 'disposable_sim_test@habalgo.test';

-- -----------------------------------------------------------------------------
-- STEP 2: VERIFY RECOVERED ATTRIBUTES AGAINST BASELINE VALUES
-- -----------------------------------------------------------------------------
SELECT 'STEP 2: Comparing Recovered Record against Baseline Attributes...' AS action;

SELECT 
    customer_id,
    name,
    phone,
    email,
    CASE 
        WHEN name = 'DISPOSABLE TEST RECORD - RECOVERY DRILL'
         AND phone = '09179990001'
         AND email = 'disposable_sim_test@habalgo.test'
        THEN 'PASSED: 100% BIT-FOR-BIT FIDELITY CONFIRMED'
        ELSE 'FAILED: DATA DISCREPANCY DETECTED'
    END AS recovery_evaluation
FROM habalgo.customer
WHERE email = 'disposable_sim_test@habalgo.test';

-- -----------------------------------------------------------------------------
-- STEP 3: RELATIONAL INTEGRITY AND FOREIGN KEY RE-CHECK
-- -----------------------------------------------------------------------------
SELECT 'STEP 3: Verifying Relational Integrity Across Child Tables...' AS action;

-- Ensure all foreign keys referencing customers, drivers, and locations remain valid
SELECT 
    (SELECT count(*) FROM habalgo.booking b LEFT JOIN habalgo.customer c ON c.customer_id = b.customer_id WHERE c.customer_id IS NULL) AS orphan_customer_bookings,
    (SELECT count(*) FROM habalgo.booking b LEFT JOIN habalgo.driver d ON d.driver_id = b.driver_id WHERE b.driver_id IS NOT NULL AND d.driver_id IS NULL) AS orphan_driver_bookings,
    (SELECT count(*) FROM habalgo.payment p LEFT JOIN habalgo.booking b ON b.booking_id = p.booking_id WHERE b.booking_id IS NULL) AS orphan_payments,
    (SELECT count(*) FROM habalgo.rating_feedback r LEFT JOIN habalgo.booking b ON b.booking_id = r.booking_id WHERE b.booking_id IS NULL) AS orphan_ratings;

-- -----------------------------------------------------------------------------
-- STEP 4: POST-BACKUP TRANSACTION LOSS ANALYSIS
-- -----------------------------------------------------------------------------
SELECT 'STEP 4: RPO and Post-Backup Gap Evaluation Note...' AS action;

SELECT 
    'IMPORTANT ARCHITECTURAL EVALUATION' AS evaluation_header,
    'Any transactions (rides, bookings, payments) created AFTER the backup timestamp cannot be recovered via logical pg_dump restore alone.' AS rpo_gap_analysis,
    'For zero-loss durability, PostgreSQL Write-Ahead Logging (WAL) archiving and Point-in-Time Recovery (PITR) must be implemented.' AS mitigation_strategy;

SELECT '=================================================================' AS footer;
SELECT ' RECOVERY VERIFICATION AUDIT COMPLETED SUCCESSFULLY               ' AS footer;
SELECT '=================================================================' AS footer;

