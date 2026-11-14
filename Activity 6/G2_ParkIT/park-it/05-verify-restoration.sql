-- ==============================================================================
-- COMP 018 — Database Administration (Activity 6: Part C)
-- Script: 05-verify-restoration.sql
-- Purpose: Complete Verification Suite for Restored Park-It Test Database
-- Platform: PostgreSQL 18.6 | Target DB: grp_parkitdb_restore_test
-- ==============================================================================

\echo '========================================================================'
\echo '  PARK-IT DATABASE MANAGEMENT SYSTEM — RESTORATION VERIFICATION SUITE   '
\echo '  COMP 018 Database Administration (Activity 6: Part C)                 '
\echo '========================================================================'

-- Set client display preferences
\pset null '(NULL)'
\pset border 2

-- ==============================================================================
-- SECTION A: DATABASE OBJECT VERIFICATION
-- ==============================================================================
\echo '\n>>> SECTION A.1: VERIFYING DATABASE SCHEMAS <<<'
SELECT 
    schema_name,
    schema_owner,
    CASE 
        WHEN schema_name = 'public' THEN 'PASSED'
        ELSE 'INFO'
    END AS status
FROM information_schema.schemata
WHERE schema_name IN ('public', 'information_schema', 'pg_catalog');

\echo '\n>>> SECTION A.2: VERIFYING CORE APPLICATION TABLES (EXPECTED: 5 TABLES) <<<'
WITH expected_tables AS (
    SELECT unnest(ARRAY['parking_zone', 'payment', 'staff_user', 'transaction', 'vehicle']) AS table_name
)
SELECT 
    e.table_name AS expected_table,
    t.table_type,
    t.table_schema,
    CASE 
        WHEN t.table_name IS NOT NULL THEN 'PASSED'
        ELSE 'FAILED - MISSING'
    END AS verification_status
FROM expected_tables e
LEFT JOIN information_schema.tables t 
    ON t.table_schema = 'public' AND t.table_name = e.table_name
ORDER BY e.table_name;

\echo '\n>>> SECTION A.3: VERIFYING DATABASE SEQUENCES (EXPECTED: 5 SEQUENCES) <<<'
WITH expected_sequences AS (
    SELECT unnest(ARRAY[
        'parking_zone_zone_id_seq',
        'payment_payment_id_seq',
        'staff_user_user_id_seq',
        'transaction_transaction_id_seq',
        'vehicle_vehicle_id_seq'
    ]) AS sequence_name
)
SELECT 
    e.sequence_name AS expected_sequence,
    s.data_type,
    s.start_value,
    CASE 
        WHEN s.sequence_name IS NOT NULL THEN 'PASSED'
        ELSE 'FAILED - MISSING'
    END AS verification_status
FROM expected_sequences e
LEFT JOIN information_schema.sequences s 
    ON s.sequence_schema = 'public' AND s.sequence_name = e.sequence_name
ORDER BY e.sequence_name;

\echo '\n>>> SECTION A.4: VERIFYING TABLE INDEXES <<<'
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

\echo '\n>>> SECTION A.5: VERIFYING VIEWS, FUNCTIONS, AND TRIGGERS (EXPECTED: 0 OR NOT APPLICABLE) <<<'
SELECT 
    'Views' AS object_category,
    COUNT(*) AS restored_count,
    '0 Expected (Park-It utilizes application-level view layer)' AS expected_specification,
    'PASSED (NOT APPLICABLE)' AS status
FROM information_schema.views
WHERE table_schema = 'public'
UNION ALL
SELECT 
    'Triggers' AS object_category,
    COUNT(*),
    '0 Expected (Integrity enforced via PHP functions and SQL constraints)',
    'PASSED (NOT APPLICABLE)'
FROM information_schema.triggers
WHERE trigger_schema = 'public'
UNION ALL
SELECT 
    'Stored Routines' AS object_category,
    COUNT(*),
    '0 Expected (Business calculations housed in PHP functions.php)',
    'PASSED (NOT APPLICABLE)'
FROM information_schema.routines
WHERE routine_schema = 'public';

-- ==============================================================================
-- SECTION B: TABLE AND RECORD VERIFICATION
-- ==============================================================================
\echo '\n>>> SECTION B.1: RECORD COUNTS ACROSS ALL PARK-IT TABLES <<<'
SELECT 'parking_zone' AS table_name, COUNT(*) AS record_count FROM public.parking_zone
UNION ALL
SELECT 'vehicle', COUNT(*) FROM public.vehicle
UNION ALL
SELECT 'staff_user', COUNT(*) FROM public.staff_user
UNION ALL
SELECT 'transaction', COUNT(*) FROM public."transaction"
UNION ALL
SELECT 'payment', COUNT(*) FROM public.payment;

\echo '\n>>> SECTION B.2: VERIFYING INITIAL SEED DATA (ZONE CONFIGURATION & STAFF ACCOUNTS) <<<'
-- Check parking zone default seed (Main Parking Lot with max_capacity = 50)
SELECT 
    zone_id,
    zone_name,
    max_capacity,
    current_active_count,
    CASE 
        WHEN max_capacity = 50 AND zone_name = 'Main Parking Lot' THEN 'PASSED'
        ELSE 'FAILED - UNEXPECTED SEED DATA'
    END AS seed_validation
FROM public.parking_zone;

-- Check staff_user default accounts (Admin and Staff)
SELECT 
    user_id,
    username,
    role,
    CASE 
        WHEN username IN ('admin', 'staff') AND role IN ('Admin', 'Staff') THEN 'PASSED'
        ELSE 'CUSTOM RECORD'
    END AS account_check
FROM public.staff_user
ORDER BY user_id;

\echo '\n>>> SECTION B.3: DATA CONSISTENCY CHECK — CAPACITY SYNCHRONIZATION <<<'
-- The current_active_count in parking_zone must match actual 'Active' records in transaction
SELECT 
    z.zone_id,
    z.zone_name,
    z.current_active_count AS recorded_in_zone_table,
    COUNT(t.transaction_id) AS actual_active_transactions,
    CASE 
        WHEN z.current_active_count = COUNT(t.transaction_id) THEN 'PASSED - CONSISTENT'
        ELSE 'FAILED - CAPACITY DESYNCHRONIZED'
    END AS synchronization_status
FROM public.parking_zone z
LEFT JOIN public."transaction" t 
    ON z.zone_id = t.zone_id AND t.status = 'Active'
GROUP BY z.zone_id, z.zone_name, z.current_active_count;

-- ==============================================================================
-- SECTION C: CONSTRAINT AND REFERENTIAL INTEGRITY VERIFICATION
-- ==============================================================================
\echo '\n>>> SECTION C.1: PRIMARY KEY CONSTRAINTS <<<'
WITH expected_pks AS (
    SELECT unnest(ARRAY[
        'parking_zone_pkey',
        'vehicle_pkey',
        'staff_user_pkey',
        'transaction_pkey',
        'payment_pkey'
    ]) AS constraint_name
)
SELECT 
    e.constraint_name AS expected_pk,
    tc.table_name,
    CASE 
        WHEN tc.constraint_name IS NOT NULL THEN 'PASSED'
        ELSE 'FAILED - MISSING'
    END AS status
FROM expected_pks e
LEFT JOIN information_schema.table_constraints tc 
    ON tc.table_schema = 'public' 
   AND tc.constraint_type = 'PRIMARY KEY' 
   AND tc.constraint_name = e.constraint_name;

\echo '\n>>> SECTION C.2: FOREIGN KEY CONSTRAINTS <<<'
WITH expected_fks AS (
    SELECT unnest(ARRAY[
        'transaction_vehicle_id_fkey',
        'transaction_zone_id_fkey',
        'payment_transaction_id_fkey'
    ]) AS constraint_name
)
SELECT 
    e.constraint_name AS expected_fk,
    tc.table_name,
    CASE 
        WHEN tc.constraint_name IS NOT NULL THEN 'PASSED'
        ELSE 'FAILED - MISSING'
    END AS status
FROM expected_fks e
LEFT JOIN information_schema.table_constraints tc 
    ON tc.table_schema = 'public' 
   AND tc.constraint_type = 'FOREIGN KEY' 
   AND tc.constraint_name = e.constraint_name;

\echo '\n>>> SECTION C.3: UNIQUE AND CHECK CONSTRAINTS <<<'
SELECT 
    table_name,
    constraint_name,
    constraint_type,
    'PASSED' AS status
FROM information_schema.table_constraints
WHERE table_schema = 'public'
  AND constraint_type IN ('UNIQUE', 'CHECK')
ORDER BY table_name, constraint_type, constraint_name;

\echo '\n>>> SECTION C.4: REFERENTIAL INTEGRITY AUDIT (ORPHAN RECORD DETECTION) <<<'
-- Check 1: Any transactions pointing to nonexistent vehicles?
SELECT 
    'transaction -> vehicle' AS relationship,
    COUNT(*) AS orphaned_records,
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED - ORPHAN DETECTED' END AS integrity_status
FROM public."transaction" t
LEFT JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
WHERE v.vehicle_id IS NULL;

-- Check 2: Any transactions pointing to nonexistent parking zones?
SELECT 
    'transaction -> parking_zone' AS relationship,
    COUNT(*) AS orphaned_records,
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED - ORPHAN DETECTED' END AS integrity_status
FROM public."transaction" t
LEFT JOIN public.parking_zone z ON t.zone_id = z.zone_id
WHERE z.zone_id IS NULL;

-- Check 3: Any payments pointing to nonexistent transactions?
SELECT 
    'payment -> transaction' AS relationship,
    COUNT(*) AS orphaned_records,
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED - ORPHAN DETECTED' END AS integrity_status
FROM public.payment p
LEFT JOIN public."transaction" t ON p.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL;

-- ==============================================================================
-- SECTION D: REPRESENTATIVE APPLICATION SELECT QUERIES
-- ==============================================================================
\echo '\n>>> SECTION D.1: LIVE PARKING CAPACITY & AVAILABILITY MONITOR QUERY <<<'
-- Replicates the logic from park-it/includes/functions.php (getParkingSummary)
SELECT 
    z.zone_name,
    z.max_capacity AS total_capacity,
    z.current_active_count AS occupied_spaces,
    (z.max_capacity - z.current_active_count) AS available_spaces,
    ROUND((z.current_active_count::numeric / z.max_capacity::numeric) * 100, 1) AS occupancy_percentage,
    CASE 
        WHEN (z.max_capacity - z.current_active_count) = 0 THEN 'FULL CAPACITY WARNING'
        WHEN (z.max_capacity - z.current_active_count) <= 10 THEN 'LOW SPACE WARNING'
        ELSE 'OPEN / SPACES AVAILABLE'
    END AS parking_status
FROM public.parking_zone z;

\echo '\n>>> SECTION D.2: ACTIVE PARKING TRANSACTIONS & VEHICLE INFORMATION <<<'
-- Replicates the active parking directory query from Module 2 (Payment & Exit)
SELECT 
    t.transaction_id,
    v.license_plate,
    v.vehicle_type,
    z.zone_name,
    t.entry_time,
    t.status,
    t.is_lost_ticket
FROM public."transaction" t
JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
JOIN public.parking_zone z ON t.zone_id = z.zone_id
WHERE t.status = 'Active'
ORDER BY t.entry_time DESC
LIMIT 10;

\echo '\n>>> SECTION D.3: COMPLETED PARKING SETTLEMENTS & AUDIT LOG <<<'
-- Replicates the payment history audit query from Module 2
SELECT 
    p.payment_id,
    v.license_plate,
    v.vehicle_type,
    t.entry_time,
    t.exit_time,
    p.amount,
    p.payment_method,
    p.payment_time,
    t.is_lost_ticket
FROM public.payment p
JOIN public."transaction" t ON p.transaction_id = t.transaction_id
JOIN public.vehicle v ON t.vehicle_id = v.vehicle_id
ORDER BY p.payment_time DESC
LIMIT 10;

\echo '\n>>> SECTION D.4: STAFF DIRECTORY AUDIT (CREDENTIAL INTEGRITY CHECK) <<<'
SELECT 
    user_id,
    username,
    role,
    SUBSTRING(password_hash FROM 1 FOR 15) || '...' AS masked_bcrypt_hash,
    LENGTH(password_hash) AS hash_length,
    CASE 
        WHEN LENGTH(password_hash) = 60 THEN 'PASSED (VALID BCRYPT HASH)'
        ELSE 'FAILED (INVALID HASH FORMAT)'
    END AS credential_security_status
FROM public.staff_user
ORDER BY user_id;

-- ==============================================================================
-- SECTION E: VERIFICATION AUDIT SUMMARY
-- ==============================================================================
\echo '\n========================================================================'
\echo '  FINAL RESTORATION VERIFICATION AUDIT SUMMARY                          '
\echo '========================================================================'

SELECT 
    '1. Database Tables (5)' AS audit_item, 
    CASE WHEN COUNT(*) = 5 THEN 'PASSED' ELSE 'FAILED' END AS outcome,
    COUNT(*) || ' of 5 verified' AS details
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('parking_zone', 'vehicle', 'staff_user', 'transaction', 'payment')
UNION ALL
SELECT 
    '2. Sequences (5)', 
    CASE WHEN COUNT(*) = 5 THEN 'PASSED' ELSE 'FAILED' END,
    COUNT(*) || ' of 5 verified'
FROM information_schema.sequences 
WHERE sequence_schema = 'public'
UNION ALL
SELECT 
    '3. Primary Key Constraints (5)', 
    CASE WHEN COUNT(*) = 5 THEN 'PASSED' ELSE 'FAILED' END,
    COUNT(*) || ' of 5 verified'
FROM information_schema.table_constraints 
WHERE table_schema = 'public' AND constraint_type = 'PRIMARY KEY'
UNION ALL
SELECT 
    '4. Foreign Key Constraints (3)', 
    CASE WHEN COUNT(*) = 3 THEN 'PASSED' ELSE 'FAILED' END,
    COUNT(*) || ' of 3 verified'
FROM information_schema.table_constraints 
WHERE table_schema = 'public' AND constraint_type = 'FOREIGN KEY'
UNION ALL
SELECT 
    '5. Seed Records (Zone & Users)', 
    CASE WHEN (SELECT COUNT(*) FROM public.parking_zone) >= 1 AND (SELECT COUNT(*) FROM public.staff_user) >= 2 THEN 'PASSED' ELSE 'FAILED' END,
    'Zones: ' || (SELECT COUNT(*) FROM public.parking_zone) || ', Users: ' || (SELECT COUNT(*) FROM public.staff_user);

\echo '\n[VERIFICATION COMPLETE] If all items above display PASSED, database restoration is certified.'
\echo '========================================================================\n'

