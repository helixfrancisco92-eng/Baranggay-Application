-- ==============================================================================
-- COMP 018 - Database Administration | Activity 6
-- Script: verify-restore.sql
-- Target: Restored Database (e.g. canteen_db_activity6_restore_test)
-- Purpose: Exhaustive validation of database objects, schema, constraints,
--          indexes, sequences, row counts, and representative business queries.
-- ==============================================================================

\echo '=============================================================================='
\echo ' COMP 018 Activity 6 - Database Restoration Verification'
\echo ' Target Environment: Campus Canteen Pre-Order & Queue Management System'
\echo '=============================================================================='

\echo ''
\echo '--- [CHECK 1] DATABASE AND SCHEMA METADATA ---'
SELECT current_database() AS current_database,
       current_user AS connected_user,
       version() AS postgresql_version;

\echo ''
\echo '--- [CHECK 2] AUDIT CORE RELATIONAL TABLES (Expected: 7 tables) ---'
SELECT table_schema,
       table_name,
       table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

\echo ''
\echo '--- [CHECK 3] AUDIT PRIMARY KEY CONSTRAINTS (Expected: 7 PKs) ---'
SELECT tc.table_name,
       tc.constraint_name,
       kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;

\echo ''
\echo '--- [CHECK 4] AUDIT FOREIGN KEY CONSTRAINTS (Expected: 7 FKs) ---'
SELECT tc.table_name AS child_table,
       kcu.column_name AS child_column,
       tc.constraint_name,
       ccu.table_name AS referenced_table,
       ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

\echo ''
\echo '--- [CHECK 5] AUDIT UNIQUE CONSTRAINTS (Expected: 5 Unique Constraints) ---'
SELECT tc.table_name,
       tc.constraint_name,
       kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'UNIQUE'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

\echo ''
\echo '--- [CHECK 6] AUDIT CHECK CONSTRAINTS ---'
SELECT tc.table_name,
       tc.constraint_name,
       cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc
  ON tc.constraint_name = cc.constraint_name
WHERE tc.constraint_type = 'CHECK'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

\echo ''
\echo '--- [CHECK 7] AUDIT PERFORMANCE AND RELATIONSHIP INDEXES ---'
SELECT tablename,
       indexname,
       indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

\echo ''
\echo '--- [CHECK 8] AUDIT SEQUENCES AND CURRENT VALUES ---'
SELECT sequence_schema,
       sequence_name,
       data_type,
       start_value,
       minimum_value,
       maximum_value
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

\echo ''
\echo '--- [CHECK 9] ROW COUNTS FOR ALL CANTEEN CORE TABLES ---'
SELECT 'student' AS table_name, count(*) AS total_rows FROM public.student
UNION ALL
SELECT 'vendor', count(*) FROM public.vendor
UNION ALL
SELECT 'menu_item', count(*) FROM public.menu_item
UNION ALL
SELECT 'customer_order', count(*) FROM public.customer_order
UNION ALL
SELECT 'order_item', count(*) FROM public.order_item
UNION ALL
SELECT 'queue_entry', count(*) FROM public.queue_entry
UNION ALL
SELECT 'notification', count(*) FROM public.notification
ORDER BY table_name;

\echo ''
\echo '--- [CHECK 10] REPRESENTATIVE BUSINESS QUERY 1: Active Stalls and Menu Offerings ---'
SELECT v.vendor_id,
       v.vendor_name,
       v.contact_number,
       v.email,
       v.is_active,
       COUNT(m.item_id) AS total_menu_items
FROM public.vendor v
LEFT JOIN public.menu_item m ON v.vendor_id = m.vendor_id
GROUP BY v.vendor_id, v.vendor_name, v.contact_number, v.email, v.is_active
ORDER BY v.vendor_id;

\echo ''
\echo '--- [CHECK 11] REPRESENTATIVE BUSINESS QUERY 2: Orders, Queue Status, and Items ---'
SELECT co.order_id,
       s.full_name AS student_name,
       v.vendor_name,
       co.pickup_time,
       co.status AS order_status,
       qe.queue_number,
       qe.status AS queue_status,
       SUM(oi.quantity * oi.price_at_order) AS total_order_amount
FROM public.customer_order co
JOIN public.student s ON co.student_id = s.student_id
JOIN public.vendor v ON co.vendor_id = v.vendor_id
LEFT JOIN public.queue_entry qe ON co.order_id = qe.order_id
LEFT JOIN public.order_item oi ON co.order_id = oi.order_id
GROUP BY co.order_id, s.full_name, v.vendor_name, co.pickup_time, co.status, qe.queue_number, qe.status
ORDER BY co.order_id;

\echo ''
\echo '--- [CHECK 12] REPRESENTATIVE BUSINESS QUERY 3: Notifications Audit ---'
SELECT n.notification_id,
       n.order_id,
       n.message,
       n.sent_at,
       n.is_read
FROM public.notification n
ORDER BY n.notification_id;

\echo ''
\echo '=============================================================================='
\echo ' END OF RESTORATION VERIFICATION SUITE'
\echo '=============================================================================='

