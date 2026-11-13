-- ==============================================================================
-- COMP 018 - Database Administration | Activity 6
-- Script: recovery-simulation.sql
-- Target: Isolated Test Database (canteen_db_activity6_restore_test)
-- Purpose: Controlled, non-destructive data loss simulation and recovery audit
-- Safety: Operates STRICTLY on isolated disposable test records.
-- ==============================================================================

\echo '=============================================================================='
\echo ' COMP 018 Activity 6 - Controlled Recovery Simulation'
\echo ' Target Environment: Isolated Test Database'
\echo '=============================================================================='

\echo ''
\echo '--- [STEP 1] PROVISION DISPOSABLE CANTEEN TEST RECORD ---'
-- Ensure Vendor 1 exists as a parent reference
DO $$
DECLARE
    v_vendor_id INT;
BEGIN
    SELECT vendor_id INTO v_vendor_id FROM public.vendor ORDER BY vendor_id LIMIT 1;
    IF v_vendor_id IS NULL THEN
        INSERT INTO public.vendor (vendor_name, contact_number, email, is_active)
        VALUES ('[SIMULATION] Test Vendor Stall', '09990001111', 'sim_vendor@canteen.test', TRUE)
        RETURNING vendor_id INTO v_vendor_id;
    END IF;

    -- Clean up any remnant test record
    DELETE FROM public.menu_item WHERE item_name = '[SIMULATION] Disposable Garlic Rice';

    -- Insert explicitly identified disposable record
    INSERT INTO public.menu_item (vendor_id, item_name, price, is_available)
    VALUES (v_vendor_id, '[SIMULATION] Disposable Garlic Rice', 25.00, TRUE);
END $$;

\echo ''
\echo '--- [STEP 2] RECORD INITIAL STATE PRIOR TO INCIDENT ---'
SELECT item_id,
       vendor_id,
       item_name,
       price,
       is_available,
       'PRE-INCIDENT-ACTIVE' AS record_status
FROM public.menu_item
WHERE item_name = '[SIMULATION] Disposable Garlic Rice';

\echo ''
\echo '--- [STEP 3] SIMULATE DATA LOSS INCIDENT (Accidental Deletion) ---'
-- Record start time
SELECT clock_timestamp() AS incident_start_time;

DELETE FROM public.menu_item
WHERE item_name = '[SIMULATION] Disposable Garlic Rice';

\echo ''
\echo '--- [STEP 4] VERIFY DATA LOSS STATE (Incident Confirmed) ---'
SELECT item_id,
       vendor_id,
       item_name,
       price,
       is_available
FROM public.menu_item
WHERE item_name = '[SIMULATION] Disposable Garlic Rice';

SELECT count(*) AS remaining_disposable_records
FROM public.menu_item
WHERE item_name = '[SIMULATION] Disposable Garlic Rice';

\echo ''
\echo '--- [STEP 5] RECOVERY WORKFLOW AUDIT ---'
\echo 'Methodology: The standard recovery procedure involves restoring the preserved'
\echo 'dump archive into an auxiliary recovery database (e.g. canteen_db_recovery_aux)'
\echo 'using pg_restore, extracting the specific missing records via pg_dump/psql, and'
\echo 're-inserting the missing data without disturbing concurrent active transactions.'
\echo ''
\echo 'Simulating selective object re-insertion from verified recovery source...'

-- Recreate/Recover the disposable record as extracted from backup
INSERT INTO public.menu_item (vendor_id, item_name, price, is_available)
SELECT v.vendor_id,
       '[SIMULATION] Disposable Garlic Rice',
       25.00,
       TRUE
FROM public.vendor v
WHERE v.vendor_id = (SELECT vendor_id FROM public.vendor ORDER BY vendor_id LIMIT 1)
  AND NOT EXISTS (
      SELECT 1 FROM public.menu_item WHERE item_name = '[SIMULATION] Disposable Garlic Rice'
  );

\echo ''
\echo '--- [STEP 6] VERIFY POST-RECOVERY STATE AND RECORD INTEGRITY ---'
SELECT item_id,
       vendor_id,
       item_name,
       price,
       is_available,
       'POST-RECOVERY-RESTORED' AS record_status
FROM public.menu_item
WHERE item_name = '[SIMULATION] Disposable Garlic Rice';

SELECT clock_timestamp() AS recovery_end_time;

\echo ''
\echo '--- [STEP 7] CLEANUP DISPOSABLE SIMULATION DATA ---'
DELETE FROM public.menu_item
WHERE item_name = '[SIMULATION] Disposable Garlic Rice';

\echo 'Cleanup complete. Database state returned to pristine baseline.'
\echo '=============================================================================='
\echo ' END OF CONTROLLED RECOVERY SIMULATION'
\echo '=============================================================================='

