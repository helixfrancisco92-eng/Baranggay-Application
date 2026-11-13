-- =============================================================================
-- CampusSafe (Group 7) — Controlled Data-Loss Simulation Script (09_simulate_data_loss.sql)
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test
-- 
-- STRICT SAFETY RULE: NEVER DELETE PRODUCTION OR SEED APPLICATION RECORDS!
-- This script creates an isolated disposable canary record and simulates data loss.
-- =============================================================================

\echo '================================================================='
\echo ' Controlled Canary Disaster Simulation — Part 1: Loss Induction  '
\echo ' Target: grp07_campussafedb_activity6_restore_test               '
\echo '================================================================='

-- Safety Check
SELECT current_database() AS connected_database;

\echo '--- 1. INSERTING ISOLATED DISPOSABLE CANARY RECORD ---'
-- Uses valid foreign keys: reporter (4 = Maria Santos), location (1 = Science Hall Room 304), category (1 = Electrical)
INSERT INTO hazard_report (
    reporter_user_id,
    location_id,
    category_id,
    description,
    priority,
    status,
    submitted_at
) VALUES (
    4,
    1,
    1,
    'CANARY-DRILL: Damaged emergency power shutoff switch sparking behind workbench 3.',
    'Critical',
    'Submitted',
    '2026-11-13 14:00:00'
) RETURNING report_id, reporter_user_id, location_id, category_id, priority, status, submitted_at, description;

\echo '--- 2. CAPTURING CANARY RECORD BASELINE STATE ---'
SELECT 
    report_id, 
    reporter_user_id, 
    location_id, 
    category_id, 
    priority, 
    status, 
    submitted_at, 
    description
FROM hazard_report
WHERE description LIKE 'CANARY-DRILL%';

\echo '--- 3. SIMULATING ACCIDENTAL DATA LOSS (DELETION OF CANARY RECORD) ---'
-- Controlled deletion targeting strictly the canary record
DELETE FROM hazard_report 
WHERE description LIKE 'CANARY-DRILL%';

\echo '--- 4. VERIFYING DATA LOSS (RECORD SHOULD RETURN 0 ROWS) ---'
SELECT 
    COUNT(*) AS canary_record_count,
    CASE WHEN COUNT(*) = 0 THEN 'CONFIRMED: Canary record is successfully deleted (Data Loss State Active)'
         ELSE 'ERROR: Record still present'
    END AS loss_verification
FROM hazard_report
WHERE description LIKE 'CANARY-DRILL%';

\echo '================================================================='
\echo ' Disaster loss simulation confirmed.                             '
\echo ' Next Step: Restore baseline snapshot to secondary recovery DB:  '
\echo '   pg_restore -d grp07_campussafedb_recovery_drill <dump_file>   '
\echo ' Then execute script: 10_verify_recovery.sql                     '
\echo '================================================================='

