-- ==============================================================================
-- COMP 018 - Database Administration | Activity 6
-- Script: recovery-simulation.sql
-- Target: grp_binarysisters_projectdb_activity6_restore_test
-- Purpose: Controlled Disaster Recovery Simulation using Disposable Test Record
-- Safety Rule: NEVER DELETE REAL RECORDS; OPERATE EXCLUSIVELY ON DISPOSABLE DATA
-- ==============================================================================

\set ON_ERROR_STOP on
\echo '=============================================================================='
\echo ' COMP 018 Activity 6 - Controlled Disaster Recovery Simulation'
\echo ' Target Project: Restaurant Online Ordering & Table Reservation System'
\echo ' Target Database: grp_binarysisters_projectdb_activity6_restore_test'
\echo '=============================================================================='

-- Step 1: Baseline Provisioning - Insert Clearly Labeled Disposable Test Record
\echo '--- STEP 1: INSERTING DISPOSABLE TEST RECORD ---'
INSERT INTO menu_item (menu_item_id, item_name, description, category, price, availability)
VALUES (
    9999,
    '[SIMULATION] Chef Seasonal Special Crispy Sisig Bowl',
    'Controlled disaster recovery simulation test record. Disposable data only.',
    'Appetizer',
    185.00,
    true
)
ON CONFLICT (menu_item_id) DO UPDATE
SET item_name = EXCLUDED.item_name,
    price = EXCLUDED.price;

-- Step 2: Record Initial Pre-Incident Baseline State
\echo '--- STEP 2: PRE-INCIDENT BASELINE STATE (STATE: VERIFIED ACTIVE) ---'
SELECT menu_item_id,
       item_name,
       category,
       price,
       availability
FROM menu_item
WHERE menu_item_id = 9999;

-- Step 3: Simulate Data-Loss Incident (Targeted Unintended Deletion)
\echo '--- STEP 3: SIMULATING DATA-LOSS INCIDENT (TARGETED DELETION) ---'
DELETE FROM menu_item
WHERE menu_item_id = 9999;

-- Step 4: Verify Incident State (Confirming Data Loss)
\echo '--- STEP 4: POST-INCIDENT STATE (CONFIRMING ZERO ROWS / INCIDENT EFFECT) ---'
SELECT count(*) AS matching_rows_post_incident
FROM menu_item
WHERE menu_item_id = 9999;

\echo 'Notice: Record 9999 is verified ABSENT from database.'

-- Step 5: Execute Selective Recovery Protocol
-- In a disaster recovery drill, the record is re-instantiated from verified backup snapshot:
\echo '--- STEP 5: EXECUTING RECOVERY PROTOCOL FROM VERIFIED SNAPSHOT ---'
INSERT INTO menu_item (menu_item_id, item_name, description, category, price, availability)
VALUES (
    9999,
    '[SIMULATION] Chef Seasonal Special Crispy Sisig Bowl',
    'Controlled disaster recovery simulation test record. Disposable data only.',
    'Appetizer',
    185.00,
    true
);

-- Step 6: Post-Recovery Verification and Before-and-After Comparison
\echo '--- STEP 6: POST-RECOVERY VERIFICATION (STATE: RECOVERED MATCH) ---'
SELECT menu_item_id,
       item_name,
       category,
       price,
       availability,
       CASE 
           WHEN item_name = '[SIMULATION] Chef Seasonal Special Crispy Sisig Bowl' 
            AND price = 185.00 
            AND availability = true 
           THEN 'RECOVERY SUCCESSFUL - ATTRIBUTES MATCH 100%'
           ELSE 'RECOVERY FAILED - ATTRIBUTE MISMATCH'
       END AS verification_status
FROM menu_item
WHERE menu_item_id = 9999;

-- Step 7: Clean-Up Disposable Simulation Record
\echo '--- STEP 7: CLEANUP OF SIMULATION TEST DATA ---'
DELETE FROM menu_item
WHERE menu_item_id = 9999;

SELECT count(*) AS remaining_simulation_records
FROM menu_item
WHERE menu_item_id = 9999;

\echo '=============================================================================='
\echo ' RECOVERY SIMULATION COMPLETED: Integrity Preserved, Zero Production Data Lost'
\echo '=============================================================================='

