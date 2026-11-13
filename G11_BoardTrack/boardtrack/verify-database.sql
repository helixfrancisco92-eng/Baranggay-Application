-- ==============================================================================
-- Script: verify-database.sql
-- System: BoardTrack — Boarding House & Rental Management System
-- Purpose: Comprehensive Relational Schema, Object, and Data Integrity Audit
-- COMP 018 — Database Administration | Activity 6
-- ==============================================================================

\echo '===================================================================='
\echo '  BOARDTRACK DATABASE RESTORATION INTEGRITY AUDIT'
\echo '===================================================================='
\echo 'Target Database : ' :DBNAME
\echo 'Audit Timestamp : ' `date /t` `time /t`
\echo '===================================================================='

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [1] Installed PostgreSQL Extensions ---'
SELECT extname AS extension_name, extversion AS installed_version
FROM pg_extension
WHERE extname IN ('btree_gist', 'pgcrypto')
ORDER BY extname;

-- ------------------------------------------------------------------------------
-- 2. TABLE INVENTORY & RECORD COUNTS
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [2] Relational Tables Inventory & Baseline Record Counts ---'
SELECT 
  t.table_name,
  COALESCE(c.reltuples::bigint, 0) AS estimated_rows,
  pg_size_pretty(pg_total_relation_size(quote_ident(t.table_name))) AS total_size
FROM information_schema.tables t
LEFT JOIN pg_class c ON c.relname = t.table_name AND c.relnamespace = 'public'::regnamespace
WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name;

\echo ''
\echo '--- Exact Row Counts (Target Baseline Validation) ---'
SELECT 'property' AS table_name, COUNT(*) AS exact_count, 2 AS expected_baseline FROM property
UNION ALL
SELECT 'room', COUNT(*), 6 FROM room
UNION ALL
SELECT 'tenant', COUNT(*), 4 FROM tenant
UNION ALL
SELECT 'lease', COUNT(*), 4 FROM lease
UNION ALL
SELECT 'payment', COUNT(*), 6 FROM payment
UNION ALL
SELECT 'utility_bill', COUNT(*), 4 FROM utility_bill
UNION ALL
SELECT 'app_user', COUNT(*), 3 FROM app_user
UNION ALL
SELECT 'schema_migrations', COUNT(*), 1 FROM schema_migrations
ORDER BY table_name;

-- ------------------------------------------------------------------------------
-- 3. PRIMARY KEYS AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [3] Primary Key Constraints Audit ---'
SELECT 
  tc.table_name, 
  tc.constraint_name, 
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.ordinal_position;

-- ------------------------------------------------------------------------------
-- 4. FOREIGN KEYS & REFERENTIAL INTEGRITY AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [4] Foreign Key Constraints & Referential Targets ---'
SELECT
  tc.table_name AS child_table,
  kcu.column_name AS child_column,
  tc.constraint_name,
  ccu.table_name AS referenced_parent_table,
  ccu.column_name AS referenced_parent_column,
  rc.delete_rule,
  rc.update_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
JOIN information_schema.referential_constraints rc
  ON tc.constraint_name = rc.constraint_name AND tc.table_schema = rc.constraint_schema
JOIN information_schema.constraint_column_usage ccu
  ON rc.unique_constraint_name = ccu.constraint_name AND rc.unique_constraint_schema = ccu.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ------------------------------------------------------------------------------
-- 5. UNIQUE AND EXCLUSION CONSTRAINTS
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [5] Unique and Exclusion Constraints ---'
SELECT 
  conname AS constraint_name,
  relname AS table_name,
  CASE contype 
    WHEN 'u' THEN 'UNIQUE'
    WHEN 'x' THEN 'EXCLUSION (GiST)'
    WHEN 'c' THEN 'CHECK'
    ELSE contype::text
  END AS constraint_type,
  pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_class r ON r.oid = c.conrelid
JOIN pg_namespace n ON n.oid = r.relnamespace
WHERE n.nspname = 'public' AND contype IN ('u', 'x', 'c')
ORDER BY r.relname, c.conname;

-- ------------------------------------------------------------------------------
-- 6. SECONDARY INDEXES AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [6] Secondary Indexes Audit ---'
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND indexname NOT LIKE '%_pkey' AND indexname NOT LIKE 'uq_%'
ORDER BY tablename, indexname;

-- ------------------------------------------------------------------------------
-- 7. REPORTING VIEWS AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [7] Reporting Views Audit ---'
SELECT table_name, view_definition
FROM information_schema.views
WHERE table_schema = 'public';

\echo ''
\echo '--- View Query Test: v_lease_summary ---'
SELECT 
  lease_id,
  tenant,
  property_name,
  room_number,
  status,
  monthly_rent,
  total_paid,
  utilities_billed
FROM v_lease_summary
ORDER BY lease_id;

-- ------------------------------------------------------------------------------
-- 8. TRIGGERS AND STORED FUNCTIONS AUDIT
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [8] Trigger Functions and Operational Triggers ---'
SELECT 
  p.proname AS function_name,
  l.lanname AS language_name,
  pg_get_function_result(p.oid) AS return_type
FROM pg_proc p
JOIN pg_language l ON l.oid = p.prolang
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname IN ('sync_room_status', 'guard_room_status');

SELECT 
  event_object_table AS target_table,
  trigger_name,
  action_timing,
  event_manipulation AS event,
  action_orientation AS orientation,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ------------------------------------------------------------------------------
-- 9. DATA CONSISTENCY & INTEGRITY CROSS-CHECKS
-- ------------------------------------------------------------------------------
\echo ''
\echo '--- [9] Data Consistency & Business Rule Validation ---'

-- Check 1: Orphaned records
SELECT 'Orphaned Leases (Invalid Tenant)' AS audit_check, COUNT(*) AS violation_count
FROM lease l LEFT JOIN tenant t ON t.tenant_id = l.tenant_id WHERE t.tenant_id IS NULL
UNION ALL
SELECT 'Orphaned Leases (Invalid Room)', COUNT(*)
FROM lease l LEFT JOIN room r ON r.room_id = l.room_id WHERE r.room_id IS NULL
UNION ALL
SELECT 'Orphaned Payments (Invalid Lease)', COUNT(*)
FROM payment p LEFT JOIN lease l ON l.lease_id = p.lease_id WHERE l.lease_id IS NULL
UNION ALL
SELECT 'Orphaned Utility Bills (Invalid Lease)', COUNT(*)
FROM utility_bill u LEFT JOIN lease l ON l.lease_id = u.lease_id WHERE l.lease_id IS NULL
UNION ALL
SELECT 'Tenant Accounts Missing Tenant Link', COUNT(*)
FROM app_user WHERE role = 'tenant' AND tenant_id IS NULL
UNION ALL
SELECT 'Non-Tenant Accounts with Tenant Link', COUNT(*)
FROM app_user WHERE role <> 'tenant' AND tenant_id IS NOT NULL;

-- Check 2: Room occupancy consistency against active leases
\echo ''
\echo '--- Room Occupancy Status Verification ---'
SELECT 
  r.room_id,
  r.room_number,
  p.property_name,
  r.status AS current_room_status,
  CASE WHEN EXISTS (SELECT 1 FROM lease l WHERE l.room_id = r.room_id AND l.status = 'ACTIVE')
       THEN 'ACTIVE LEASE PRESENT' ELSE 'NO ACTIVE LEASE' END AS active_lease_status,
  CASE 
    WHEN r.status = 'OCCUPIED' AND NOT EXISTS (SELECT 1 FROM lease l WHERE l.room_id = r.room_id AND l.status = 'ACTIVE') THEN 'DISCREPANCY (Occupied without lease)'
    WHEN r.status = 'AVAILABLE' AND EXISTS (SELECT 1 FROM lease l WHERE l.room_id = r.room_id AND l.status = 'ACTIVE') THEN 'DISCREPANCY (Available with lease)'
    ELSE 'CONSISTENT'
  END AS sync_integrity
FROM room r
JOIN property p ON p.property_id = r.property_id
ORDER BY r.room_id;

\echo ''
\echo '===================================================================='
\echo '  END OF DATABASE RESTORATION AUDIT SUITE'
\echo '===================================================================='

