-- =============================================================================
-- CampusSafe (Group 7) — Database Object Verification Script (05_verify_objects.sql)
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Restored Database Object Verification (Phase 6 - A)  '
\echo ' Target: grp07_campussafedb_activity6_restore_test               '
\echo '================================================================='

-- Safety Check: Confirm connected database is the test database
SELECT current_database() AS connected_database, current_user AS connected_user;

\echo '--- 1. USER BASE TABLES AUDIT (Expected: Exactly 9 tables) ---'
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Assertion Check: Exactly 9 tables
SELECT 
    COUNT(*) AS total_restored_tables,
    CASE WHEN COUNT(*) = 9 THEN 'PASS (9/9 Tables Present)' ELSE 'FAIL (Expected 9 Tables)' END AS evaluation
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

\echo '--- 2. AUTO-INCREMENT SEQUENCES AUDIT (Expected: Exactly 9 sequences) ---'
SELECT 
    sequence_name,
    data_type,
    start_value,
    minimum_value,
    maximum_value
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

-- Assertion Check: Exactly 9 sequences
SELECT 
    COUNT(*) AS total_restored_sequences,
    CASE WHEN COUNT(*) = 9 THEN 'PASS (9/9 Sequences Present)' ELSE 'FAIL (Expected 9 Sequences)' END AS evaluation
FROM information_schema.sequences
WHERE sequence_schema = 'public';

\echo '--- 3. PERFORMANCE B-TREE INDEXES AUDIT (Expected: Exactly 10 explicit indexes) ---'
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public' 
  AND indexname NOT LIKE '%_pkey' 
  AND indexname NOT LIKE '%_key'
ORDER BY tablename, indexname;

-- Assertion Check: Exactly 10 explicit indexes
SELECT 
    COUNT(*) AS total_explicit_indexes,
    CASE WHEN COUNT(*) = 10 THEN 'PASS (10/10 Explicit Indexes Active)' ELSE 'FAIL (Expected 10 Indexes)' END AS evaluation
FROM pg_indexes
WHERE schemaname = 'public' 
  AND indexname NOT LIKE '%_pkey' 
  AND indexname NOT LIKE '%_key';

\echo '--- 4. DETAILED COLUMN DEFINITION & NULLABILITY AUDIT ---'
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

