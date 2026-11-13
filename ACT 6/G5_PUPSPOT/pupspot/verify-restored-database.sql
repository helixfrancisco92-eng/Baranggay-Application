-- ==============================================================================
-- COMP 018 — Database Administration (Activity 6: Part C)
-- Target Project: PUP-SPOT (Group 5 - Lost and Found Management System)
-- Database Restoration Verification Suite
-- Target Database: grp05_lostandfounddb_activity6_restore_test
-- ==============================================================================

\echo '================================================================='
\echo ' PUP-SPOT DATABASE RESTORATION INTEGRITY VERIFICATION SUITE       '
\echo ' Target Database: grp05_lostandfounddb_activity6_restore_test     '
\echo '================================================================='

-- ------------------------------------------------------------------------------
-- 1. SCHEMA VERIFICATION
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 1. Verifying Schema Existence...'
SELECT 
    schema_name,
    schema_owner
FROM information_schema.schemata
WHERE schema_name = 'public';

-- ------------------------------------------------------------------------------
-- 2. TABLE EXISTENCE VERIFICATION (8 Expected Normalized Tables)
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 2. Verifying Table Existence (8 Core Tables)...'
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'categories',
      'items',
      'lost_reports',
      'claims',
      'potential_matches',
      'item_images',
      'lost_report_images',
      'claim_images'
  )
ORDER BY table_name;

-- ------------------------------------------------------------------------------
-- 3. SEQUENCE GENERATOR VERIFICATION
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 3. Verifying Auto-Increment Sequence Generators...'
SELECT 
    sequence_name,
    data_type,
    start_value,
    minimum_value,
    maximum_value
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

-- ------------------------------------------------------------------------------
-- 4. PRIMARY KEY CONSTRAINT VERIFICATION
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 4. Verifying Primary Key Constraints across all Tables...'
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name 
   AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY' 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- ------------------------------------------------------------------------------
-- 5. FOREIGN KEY REFERENTIAL INTEGRITY VERIFICATION
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 5. Verifying Foreign Key Referential Relationships...'
SELECT 
    tc.table_name AS foreign_table,
    kcu.column_name AS foreign_column,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.referential_constraints rc 
    ON tc.constraint_name = rc.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON rc.unique_constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ------------------------------------------------------------------------------
-- 6. CHECK CONSTRAINTS & UNIQUE CONSTRAINTS
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 6. Verifying Check Constraints and Domain Integrity...'
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.constraint_type IN ('CHECK', 'UNIQUE')
  AND tc.constraint_name NOT LIKE '%_not_null'
ORDER BY tc.table_name, tc.constraint_name;

-- ------------------------------------------------------------------------------
-- 7. RECORD COUNT AUDIT ACROSS ALL BASE TABLES
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 7. Record Counts Audit in Restored Database...'
SELECT 
    'categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL
SELECT 'items', COUNT(*) FROM items
UNION ALL
SELECT 'lost_reports', COUNT(*) FROM lost_reports
UNION ALL
SELECT 'claims', COUNT(*) FROM claims
UNION ALL
SELECT 'potential_matches', COUNT(*) FROM potential_matches
UNION ALL
SELECT 'item_images', COUNT(*) FROM item_images
UNION ALL
SELECT 'lost_report_images', COUNT(*) FROM lost_report_images
UNION ALL
SELECT 'claim_images', COUNT(*) FROM claim_images
ORDER BY table_name;

-- ------------------------------------------------------------------------------
-- 8. REPRESENTATIVE MULTI-TABLE SELECT QUERIES
-- ------------------------------------------------------------------------------
\echo ''
\echo '>>> 8.1 Representative Query: Found Items with Category Classifications'
SELECT 
    i.item_id,
    c.name AS category_name,
    i.title,
    i.location_found,
    i.date_found,
    i.status
FROM items i
LEFT JOIN categories c ON i.category_id = c.category_id
ORDER BY i.item_id
LIMIT 5;

\echo ''
\echo '>>> 8.2 Representative Query: Lost Reports with Contact Preferences'
SELECT 
    lr.report_id,
    lr.report_code,
    c.name AS category_name,
    lr.title,
    lr.location_lost,
    lr.contact_preference,
    lr.status,
    lr.created_at
FROM lost_reports lr
LEFT JOIN categories c ON lr.category_id = c.category_id
ORDER BY lr.report_id
LIMIT 5;

\echo ''
\echo '>>> 8.3 Representative Query: Claims Linked to Physical Found Items'
SELECT 
    clm.claim_id,
    clm.claim_code,
    i.title AS claimed_item_title,
    clm.contact_preference,
    clm.status AS claim_status,
    clm.created_at
FROM claims clm
JOIN items i ON clm.item_id = i.item_id
ORDER BY clm.claim_id
LIMIT 5;

\echo ''
\echo '>>> 8.4 Representative Query: Potential Candidate Matches'
SELECT 
    pm.match_id,
    lr.report_code,
    lr.title AS lost_item_title,
    i.title AS found_item_title,
    pm.similarity_score,
    pm.created_at
FROM potential_matches pm
JOIN lost_reports lr ON pm.report_id = lr.report_id
JOIN items i ON pm.item_id = i.item_id
ORDER BY pm.similarity_score DESC
LIMIT 5;

\echo ''
\echo '================================================================='
\echo ' RESTORATION INTEGRITY VERIFICATION COMPLETE                     '
\echo '================================================================='

