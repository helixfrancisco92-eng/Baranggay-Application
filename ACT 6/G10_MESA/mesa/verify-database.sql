-- ==============================================================================
-- COMP 018 - Database Administration | Activity 6
-- Script: verify-database.sql
-- Target: grp_binarysisters_projectdb_activity6_restore_test
-- Purpose: Structural, Relational, Constraint, and Data Verification of Restored DB
-- ==============================================================================

\set ON_ERROR_STOP off
\echo '=============================================================================='
\echo ' COMP 018 Activity 6 - Restored Database Verification Suite'
\echo ' Target Database: Restaurant Online Ordering & Table Reservation System'
\echo '=============================================================================='

-- 1. Database Environment Identity
\echo '--- 1. DATABASE ENVIRONMENT IDENTITY ---'
SELECT current_database() AS connected_database,
       current_user AS session_user,
       version() AS postgresql_version;

-- 2. Schema and Extensions Check
\echo '--- 2. EXTENSIONS AUDIT ---'
SELECT extname, extversion, extnamespace::regnamespace AS schema
FROM pg_extension
WHERE extname IN ('btree_gist', 'pgcrypto', 'plpgsql')
ORDER BY extname;

-- 3. Core Table Inventory Audit
\echo '--- 3. TABLE INVENTORY AUDIT (Expected: 8 Tables) ---'
SELECT table_name,
       table_type,
       is_insertable_into
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 4. Detailed Column Definitions
\echo '--- 4. COLUMN INVENTORY AND DATATYPES ---'
SELECT table_name,
       ordinal_position,
       column_name,
       data_type,
       character_maximum_length,
       numeric_precision,
       numeric_scale,
       is_nullable,
       column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('customer', 'menu_item', 'restaurant_table', 'staff', 'orders', 'order_item', 'reservation', 'payment')
ORDER BY table_name, ordinal_position;

-- 5. Primary Key Constraints Audit
\echo '--- 5. PRIMARY KEY CONSTRAINTS AUDIT ---'
SELECT tc.table_name,
       tc.constraint_name,
       string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS pk_columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
GROUP BY tc.table_name, tc.constraint_name
ORDER BY tc.table_name;

-- 6. Foreign Key Constraints & Referential Action Audit
\echo '--- 6. FOREIGN KEY CONSTRAINTS AUDIT (Expected: 6 FKs) ---'
SELECT tc.constraint_name,
       tc.table_name AS child_table,
       kcu.column_name AS child_column,
       ccu.table_name AS parent_table,
       ccu.column_name AS parent_column,
       rc.update_rule,
       rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- 7. Unique Constraints Audit
\echo '--- 7. UNIQUE CONSTRAINTS AUDIT ---'
SELECT tc.table_name,
       tc.constraint_name,
       kcu.column_name AS unique_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'UNIQUE'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- 8. Domain Check Constraints Audit
\echo '--- 8. CHECK CONSTRAINTS AUDIT ---'
SELECT conname AS check_constraint_name,
       conrelid::regclass AS target_table,
       pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE contype = 'c'
  AND n.nspname = 'public'
ORDER BY target_table, check_constraint_name;

-- 9. Exclusion Constraints Audit (Double-Booking Protection)
\echo '--- 9. EXCLUSION CONSTRAINTS AUDIT (btree_gist) ---'
SELECT conname AS exclusion_constraint_name,
       conrelid::regclass AS target_table,
       pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE contype = 'x'
  AND n.nspname = 'public';

-- 10. Secondary Indexes Audit
\echo '--- 10. SECONDARY PERFORMANCE INDEXES AUDIT ---'
SELECT tablename,
       indexname,
       indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname NOT LIKE '%_pkey'
  AND indexname NOT LIKE 'uq_%'
ORDER BY tablename, indexname;

-- 11. Reporting Views Audit
\echo '--- 11. REPORTING VIEWS AUDIT ---'
SELECT table_name AS view_name,
       view_definition
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- 12. Trigger Functions and Triggers Audit
\echo '--- 12. TRIGGERS AND BUSINESS INTEGRITY FUNCTIONS AUDIT ---'
SELECT event_object_table AS target_table,
       trigger_name,
       event_manipulation AS event,
       action_timing AS timing,
       action_orientation AS orientation,
       action_statement AS routine
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY target_table, trigger_name;

-- 13. Baseline Data Row Counts vs Expected Seed Values
\echo '--- 13. DATA ROW COUNTS AUDIT (Expected Baseline Comparison) ---'
SELECT 'customer'         AS table_name, count(*) AS restored_count, 51  AS expected_seed, CASE WHEN count(*) = 51  THEN 'PASS' ELSE 'MISMATCH' END AS status FROM customer
UNION ALL
SELECT 'staff'            AS table_name, count(*) AS restored_count, 10  AS expected_seed, CASE WHEN count(*) = 10  THEN 'PASS' ELSE 'MISMATCH' END AS status FROM staff
UNION ALL
SELECT 'menu_item'        AS table_name, count(*) AS restored_count, 50  AS expected_seed, CASE WHEN count(*) = 50  THEN 'PASS' ELSE 'MISMATCH' END AS status FROM menu_item
UNION ALL
SELECT 'restaurant_table' AS table_name, count(*) AS restored_count, 20  AS expected_seed, CASE WHEN count(*) = 20  THEN 'PASS' ELSE 'MISMATCH' END AS status FROM restaurant_table
UNION ALL
SELECT 'orders'           AS table_name, count(*) AS restored_count, 60  AS expected_seed, CASE WHEN count(*) = 60  THEN 'PASS' ELSE 'MISMATCH' END AS status FROM orders
UNION ALL
SELECT 'order_item'       AS table_name, count(*) AS restored_count, 167 AS expected_seed, CASE WHEN count(*) = 167 THEN 'PASS' ELSE 'MISMATCH' END AS status FROM order_item
UNION ALL
SELECT 'payment'          AS table_name, count(*) AS restored_count, 56  AS expected_seed, CASE WHEN count(*) = 56  THEN 'PASS' ELSE 'MISMATCH' END AS status FROM payment
UNION ALL
SELECT 'reservation'      AS table_name, count(*) AS restored_count, 50  AS expected_seed, CASE WHEN count(*) = 50  THEN 'PASS' ELSE 'MISMATCH' END AS status FROM reservation
ORDER BY table_name;

-- 14. Data Integrity & Business Rule Consistency Cross-Check
\echo '--- 14. DATA INTEGRITY CROSS-CHECKS ---'
-- BR: Order total must match sum of item subtotals
SELECT count(*) AS order_total_discrepancies
FROM orders o
JOIN (
    SELECT order_id, sum(subtotal) AS computed_total
    FROM order_item
    GROUP BY order_id
) oi ON o.order_id = oi.order_id
WHERE o.total_amount <> oi.computed_total;

-- BR: Payment amount must equal order total
SELECT count(*) AS payment_amount_discrepancies
FROM payment p
JOIN orders o ON p.order_id = o.order_id
WHERE p.amount <> o.total_amount;

-- BR: No orphaned order items without an order
SELECT count(*) AS orphaned_order_items
FROM order_item oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- BR: No reservation exceeding table capacity
SELECT count(*) AS overbooked_capacity_reservations
FROM reservation r
JOIN restaurant_table t ON r.table_id = t.table_id
WHERE r.number_of_guests > t.capacity;

-- 15. Representative Application Read Queries
\echo '--- 15. REPRESENTATIVE APPLICATION QUERIES ---'
-- A. Active Menu Items by Category
SELECT category,
       count(*) AS item_count,
       min(price) AS min_price,
       avg(price)::numeric(10,2) AS avg_price,
       max(price) AS max_price
FROM menu_item
WHERE availability = true
GROUP BY category
ORDER BY category;

-- B. Sample Order Summaries via View
SELECT order_id,
       customer_name,
       order_date,
       order_status,
       total_amount,
       line_items,
       payment_method,
       payment_status
FROM v_order_summary
ORDER BY order_id
LIMIT 5;

-- C. Sample Reservation Schedule via View
SELECT reservation_id,
       reservation_date,
       reservation_time,
       customer_name,
       table_number,
       capacity,
       number_of_guests,
       reservation_status
FROM v_reservation_schedule
ORDER BY reservation_date, reservation_time
LIMIT 5;

\echo '=============================================================================='
\echo ' VERIFICATION COMPLETE: Restored Database Relational Audit Certified'
\echo '=============================================================================='

