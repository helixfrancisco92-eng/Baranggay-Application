-- ==============================================================================
-- HabalGo (Group 6) — Controlled Data-Loss Simulation Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test (TEST DATABASE ONLY)
-- Schema: habalgo
-- ==============================================================================
-- CRITICAL SAFETY RULES:
-- 1. NEVER execute this script against the production database (grp00_habalgodb).
-- 2. Never delete real application customer, driver, or booking records.
-- 3. This simulation creates an isolated DISPOSABLE test record, records its state,
--    and executes a controlled deletion exclusively on that record.
-- ==============================================================================

\set ON_ERROR_STOP on

SET search_path TO habalgo, public;

SELECT '=================================================================' AS title;
SELECT ' CONTROLLED DATA-LOSS SIMULATION (TEST DATABASE ONLY)            ' AS title;
SELECT ' Target Database: ' || current_database() AS db_check;
SELECT ' Timestamp: ' || CURRENT_TIMESTAMP::text AS timestamp;
SELECT '=================================================================' AS title;

-- SAFETY PRE-CHECK: Abort if accidentally connected to production
DO $$
BEGIN
    IF current_database() = 'grp00_habalgodb' THEN
        RAISE EXCEPTION '[SAFETY HALT] Detected connection to original database grp00_habalgodb. This simulation is strictly restricted to test environments!';
    END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- STEP 1: CREATE OR VERIFY AN ISOLATED DISPOSABLE TEST RECORD
-- -----------------------------------------------------------------------------
SELECT 'STEP 1: Inserting isolated disposable test record into habalgo.customer...' AS action;

-- Insert a clearly marked synthetic test record
INSERT INTO habalgo.customer (name, phone, email)
VALUES ('DISPOSABLE TEST RECORD - RECOVERY DRILL', '09179990001', 'disposable_sim_test@habalgo.test')
ON CONFLICT (email) DO UPDATE 
SET name = 'DISPOSABLE TEST RECORD - RECOVERY DRILL', phone = '09179990001'
RETURNING customer_id, name, phone, email;

-- -----------------------------------------------------------------------------
-- STEP 2: RECORD AND DISPLAY BASELINE PRE-INCIDENT STATE
-- -----------------------------------------------------------------------------
SELECT 'STEP 2: Recording Baseline Pre-Incident State...' AS action;

SELECT 
    customer_id AS incident_target_id,
    name AS pre_loss_name,
    phone AS pre_loss_phone,
    email AS pre_loss_email,
    'BASELINE RECORDED SAFELY' AS audit_note
FROM habalgo.customer
WHERE email = 'disposable_sim_test@habalgo.test';

-- -----------------------------------------------------------------------------
-- STEP 3: SIMULATE ACCIDENTAL / CONTROLLED DATA LOSS
-- -----------------------------------------------------------------------------
SELECT 'STEP 3: Simulating Accidental Data Loss (DELETE targeting disposable record)...' AS action;

-- Targeted deletion restricted strictly to the disposable test record
DELETE FROM habalgo.customer
WHERE email = 'disposable_sim_test@habalgo.test'
RETURNING customer_id, name, email, 'DELETED IN CONTROLLED DRILL' AS simulation_status;

-- -----------------------------------------------------------------------------
-- STEP 4: VERIFY AND CONFIRM TARGET RECORD IS MISSING
-- -----------------------------------------------------------------------------
SELECT 'STEP 4: Confirming Record Absence in Active Database...' AS action;

SELECT 
    count(*) AS matching_records_found,
    CASE 
        WHEN count(*) = 0 THEN 'DATA LOSS SIMULATION CONFIRMED: Record is completely absent.'
        ELSE 'ERROR: Record still exists!'
    END AS loss_verification_result
FROM habalgo.customer
WHERE email = 'disposable_sim_test@habalgo.test';

SELECT '=================================================================' AS footer;
SELECT ' DATA LOSS SIMULATION COMPLETED — PROCEED TO RECOVERY PHASE      ' AS footer;
SELECT '=================================================================' AS footer;

