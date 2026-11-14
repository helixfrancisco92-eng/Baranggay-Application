-- ==============================================================================
-- Script: recovery-simulation.sql
-- System: BoardTrack — Boarding House & Rental Management System
-- Purpose: Controlled Data-Loss Incident Simulation & Disaster Recovery Drill
-- Target: Isolated Restoration Test Database ONLY (boardtrack_db_activity6_restore_test)
-- COMP 018 — Database Administration | Activity 6
-- ==============================================================================

\echo '===================================================================='
\echo '  BOARDTRACK CONTROLLED RECOVERY SIMULATION DRILL'
\echo '===================================================================='
\echo 'Target Database : ' :DBNAME
\echo 'Simulation Date : ' `date /t` `time /t`
\echo 'Safety Warning  : NEVER execute on production (boardtrack_db)'
\echo '===================================================================='

-- ------------------------------------------------------------------------------
-- STEP 1: PROVISION DISPOSABLE TEST RECORD
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 1] Injecting Disposable Test Record ---'

-- Insert disposable rent payment record linked to Lease #1 (Juan Dela Cruz - Room 101)
INSERT INTO payment (
  lease_id,
  payment_date,
  amount,
  payment_method,
  status
) VALUES (
  1,
  CURRENT_DATE,
  1250.00,
  'GCASH',
  'COMPLETED'
)
RETURNING payment_id, lease_id, payment_date, amount, payment_method, status;

\echo ''
\echo '--- [STEP 2] Snapshot Initial State (Pre-Incident Baseline) ---'
SELECT 
  'payment' AS table_name,
  COUNT(*) AS total_records,
  SUM(amount) AS gross_payment_volume
FROM payment
WHERE lease_id = 1;

-- Capture identifying parameters of the disposable record
SELECT 
  p.payment_id,
  p.lease_id,
  t.full_name AS tenant_name,
  r.room_number,
  p.payment_date,
  p.amount,
  p.payment_method,
  p.status
FROM payment p
JOIN lease l ON l.lease_id = p.lease_id
JOIN tenant t ON t.tenant_id = l.tenant_id
JOIN room r ON r.room_id = l.room_id
WHERE p.amount = 1250.00 AND p.payment_method = 'GCASH'
ORDER BY p.payment_id DESC
LIMIT 1;

-- ------------------------------------------------------------------------------
-- STEP 3: SIMULATE ACCIDENTAL / ROGUE DATA-LOSS INCIDENT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 3] Simulating Accidental Data Deletion ---'
\echo 'Executing DELETE statement targeting disposable record...'

DELETE FROM payment
WHERE amount = 1250.00 AND payment_method = 'GCASH' AND payment_date = CURRENT_DATE;

\echo ''
\echo '--- [STEP 4] Verify Data-Loss Incident Effect (Post-Incident State) ---'
SELECT 
  'payment' AS table_name,
  COUNT(*) AS total_records,
  SUM(amount) AS gross_payment_volume
FROM payment
WHERE lease_id = 1;

SELECT 
  COUNT(*) AS matching_disposable_records,
  CASE WHEN COUNT(*) = 0 THEN 'INCIDENT CONFIRMED: Record Missing from Table' ELSE 'STILL PRESENT' END AS incident_status
FROM payment
WHERE amount = 1250.00 AND payment_method = 'GCASH' AND payment_date = CURRENT_DATE;

-- ------------------------------------------------------------------------------
-- STEP 5: RECOVERY STRATEGY EXECUTION
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 5] Disaster Recovery Execution ---'
\echo 'Method: Selective Table / Tuple Extraction from Preserved Backup Archive'
\echo 'In production, DBAs restore the preserved dump to a staging database:'
\echo '  1. createdb boardtrack_recovery_staging'
\echo '  2. pg_restore -d boardtrack_recovery_staging -t payment boardtrack_db_activity6.dump'
\echo '  3. Re-inject missing transaction ledger entries using INSERT ... ON CONFLICT DO NOTHING'

-- Execute safe recovery restoration of the baseline transaction record
INSERT INTO payment (
  payment_id,
  lease_id,
  payment_date,
  amount,
  payment_method,
  status
) VALUES (
  (SELECT COALESCE(MAX(payment_id), 0) + 1 FROM payment),
  1,
  CURRENT_DATE,
  1250.00,
  'GCASH',
  'COMPLETED'
)
ON CONFLICT (payment_id) DO NOTHING;

-- Synchronize sequence
SELECT setval(pg_get_serial_sequence('payment', 'payment_id'), (SELECT MAX(payment_id) FROM payment));

-- ------------------------------------------------------------------------------
-- STEP 6: POST-RECOVERY VERIFICATION & AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 6] Post-Recovery State Audit & Verification ---'
SELECT 
  'payment' AS table_name,
  COUNT(*) AS total_records,
  SUM(amount) AS gross_payment_volume
FROM payment
WHERE lease_id = 1;

SELECT 
  payment_id,
  lease_id,
  payment_date,
  amount,
  payment_method,
  status,
  'RECOVERED' AS audit_status
FROM payment
WHERE amount = 1250.00 AND payment_method = 'GCASH'
ORDER BY payment_id DESC
LIMIT 1;

-- ------------------------------------------------------------------------------
-- STEP 7: CLEANUP OF DISPOSABLE TEST DATA
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 7] Cleanup of Disposable Simulation Data ---'
DELETE FROM payment WHERE amount = 1250.00 AND payment_method = 'GCASH';
SELECT setval(pg_get_serial_sequence('payment', 'payment_id'), (SELECT MAX(payment_id) FROM payment));

\echo 'Cleanup complete. Table returned to baseline state.'
\echo '===================================================================='
\echo '  RECOVERY SIMULATION COMPLETED'
\echo '===================================================================='

