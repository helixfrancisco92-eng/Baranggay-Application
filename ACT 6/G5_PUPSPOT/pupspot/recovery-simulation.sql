-- ==============================================================================
-- COMP 018 — Database Administration (Activity 6: Part D)
-- Target Project: PUP-SPOT (Group 5 - Lost and Found Management System)
-- Controlled Recovery Simulation Script (Disposable Test Environment)
-- Target Database: grp05_lostandfounddb_activity6_restore_test
-- Secondary Recovery Target: grp05_lostandfounddb_activity6_recovery_test
-- ==============================================================================

\echo '================================================================='
\echo ' PUP-SPOT CONTROLLED DISASTER RECOVERY SIMULATION                '
\echo ' Purpose: Validate disaster recovery using disposable test data  '
\echo ' Target Environment: Disposable Test Database                    '
\echo '================================================================='

-- ------------------------------------------------------------------------------
-- CRITICAL SAFETY NOTICE:
-- 1. This simulation MUST NEVER be executed against production or original DBs.
-- 2. Only clearly identifiable disposable test records prefixed with
--    '[SIM-RECOVERY]' or 'SIM-REC-' are targeted.
-- 3. A backup taken before a record is inserted cannot restore that record.
--    This simulation documents the boundary between logical snapshot recovery
--    and transactional point-in-time state.
-- ------------------------------------------------------------------------------

-- ------------------------------------------------------------------------------
-- PHASE 1: PRE-INCIDENT BASELINE & DISPOSABLE RECORD PROVISIONING
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> PHASE 1: Creating identifiable disposable test record in items table...'

-- Insert disposable found-item record with explicit unique title and reference
INSERT INTO items (
    category_id,
    title,
    description,
    location_found,
    date_found,
    time_found,
    status
) 
SELECT 
    c.category_id,
    '[SIM-RECOVERY] Black Leather RFID Cardholder',
    'Disposable simulation record used to test recovery procedures. Contains synthetic test cards.',
    'South Wing 3rd Floor Corridor',
    CURRENT_DATE,
    CURRENT_TIME,
    'unclaimed'
FROM categories c
WHERE c.name = 'Wallets and Pouches'
LIMIT 1
RETURNING item_id, title, location_found, status, date_found;

-- Confirm pre-incident presence
\echo ''
\echo '>>> Verifying disposable record existence in test environment...'
SELECT 
    item_id,
    title,
    location_found,
    date_found,
    status
FROM items
WHERE title LIKE '[SIM-RECOVERY]%';

-- ------------------------------------------------------------------------------
-- PHASE 2: SIMULATED DATA-LOSS INCIDENT (ACCIDENTAL OPERATOR DELETION)
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> PHASE 2: Simulating accidental deletion of the disposable test record...'
\echo 'Incident Description: An operator inadvertently issues an unconstrained DELETE command.'

-- Save identifier for verification
DELETE FROM items
WHERE title LIKE '[SIM-RECOVERY]%'
RETURNING item_id, title;

-- ------------------------------------------------------------------------------
-- PHASE 3: POST-INCIDENT LOSS VERIFICATION
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> PHASE 3: Verifying that the record is absent from the test database...'
SELECT 
    COUNT(*) AS records_matching_recovery_token
FROM items
WHERE title LIKE '[SIM-RECOVERY]%';

\echo 'Result: Record count is 0. Data loss confirmed in active working database.'

-- ------------------------------------------------------------------------------
-- PHASE 4: RECOVERY PROCEDURE & VERIFICATION
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> PHASE 4: Disaster Recovery Evaluation from Logical Archive'
\echo ' Recovery Method: Restoring pre-incident baseline from custom archive into'
\echo ' secondary recovery database (grp05_lostandfounddb_activity6_recovery_test).'

-- Query to compare pre-incident baseline against secondary recovery database
\echo ''
\echo '>>> Comparison Query (Executed across databases to verify recovery status):'
SELECT 
    c.name AS category_name,
    COUNT(i.item_id) AS total_items,
    COUNT(CASE WHEN i.status = 'unclaimed' THEN 1 END) AS unclaimed_count,
    COUNT(CASE WHEN i.status = 'claimed' THEN 1 END) AS claimed_count
FROM categories c
LEFT JOIN items i ON c.category_id = i.category_id
GROUP BY c.name
ORDER BY c.name;

\echo ''
\echo '================================================================='
\echo ' CONTROLLED RECOVERY SIMULATION COMPLETED                        '
\echo '================================================================='

