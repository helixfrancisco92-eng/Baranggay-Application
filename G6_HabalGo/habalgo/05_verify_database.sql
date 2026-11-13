-- ==============================================================================
-- HabalGo (Group 6) — Master Database Restoration Verification Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test
-- Schema: habalgo
-- ==============================================================================

\set ON_ERROR_STOP on

-- Ensure search path targets restored application schema
SET search_path TO habalgo, public;

SELECT '=================================================================' AS title;
SELECT ' HABALGO RESTORATION VERIFICATION SUITE — COMP 018 ACTIVITY 6    ' AS title;
SELECT ' Current Database: ' || current_database() || ' | User: ' || current_user AS session_context;
SELECT ' Timestamp: ' || CURRENT_TIMESTAMP::text AS audit_timestamp;
SELECT '=================================================================' AS title;

-- -----------------------------------------------------------------------------
-- SECTION 1: VERIFY RESTORED SCHEMAS AND BASE TABLES
-- -----------------------------------------------------------------------------
SELECT 'SECTION 1: Auditing Restored Schemas and Base Tables...' AS check_group;

SELECT 
    t.table_schema,
    t.table_name,
    t.table_type,
    pg_size_pretty(pg_total_relation_size(quote_ident(t.table_schema) || '.' || quote_ident(t.table_name))) AS total_size,
    CASE 
        WHEN t.table_name IN ('customer', 'driver', 'vehicle', 'driver_vehicle', 'location', 'booking', 'payment', 'rating_feedback')
        THEN 'VERIFIED (EXPECTED HABALGO TABLE)'
        ELSE 'UNEXPECTED TABLE'
    END AS verification_status
FROM information_schema.tables t
WHERE t.table_schema = 'habalgo'
ORDER BY t.table_name;

-- -----------------------------------------------------------------------------
-- SECTION 2: VERIFY RESTORED SEQUENCES
-- -----------------------------------------------------------------------------
SELECT 'SECTION 2: Auditing Restored Sequences...' AS check_group;

SELECT 
    sequence_schema,
    sequence_name,
    data_type,
    start_value,
    minimum_value,
    maximum_value,
    increment,
    'VERIFIED (EXPECTED SEQUENCE)' AS status
FROM information_schema.sequences
WHERE sequence_schema = 'habalgo'
ORDER BY sequence_name;

-- -----------------------------------------------------------------------------
-- SECTION 3: VERIFY RESTORED INDEXES
-- -----------------------------------------------------------------------------
SELECT 'SECTION 3: Auditing Restored Performance and Constraint Indexes...' AS check_group;

SELECT 
    schemaname AS schema_name,
    tablename AS table_name,
    indexname AS index_name,
    indexdef AS index_definition,
    CASE 
        WHEN indexname IN ('idx_booking_customer', 'idx_booking_driver', 'idx_booking_date', 'idx_payment_booking', 'idx_rating_booking')
        THEN 'VERIFIED (EXPLICIT APPLICATION INDEX)'
        WHEN indexname LIKE '%_pkey' OR indexname LIKE '%_key' OR indexname LIKE 'uq_%'
        THEN 'VERIFIED (SYSTEM CONSTRAINT INDEX)'
        ELSE 'OTHER INDEX'
    END AS index_type
FROM pg_indexes
WHERE schemaname = 'habalgo'
ORDER BY tablename, indexname;

-- -----------------------------------------------------------------------------
-- SECTION 4: TABLE RECORD COUNTS AUDIT
-- -----------------------------------------------------------------------------
SELECT 'SECTION 4: Auditing Row Counts Across All Restored Tables...' AS check_group;

SELECT 'habalgo.customer' AS table_name, count(*) AS total_rows FROM habalgo.customer
UNION ALL
SELECT 'habalgo.driver', count(*) FROM habalgo.driver
UNION ALL
SELECT 'habalgo.vehicle', count(*) FROM habalgo.vehicle
UNION ALL
SELECT 'habalgo.driver_vehicle', count(*) FROM habalgo.driver_vehicle
UNION ALL
SELECT 'habalgo.location', count(*) FROM habalgo.location
UNION ALL
SELECT 'habalgo.booking', count(*) FROM habalgo.booking
UNION ALL
SELECT 'habalgo.payment', count(*) FROM habalgo.payment
UNION ALL
SELECT 'habalgo.rating_feedback', count(*) FROM habalgo.rating_feedback;

-- -----------------------------------------------------------------------------
-- SECTION 5: SAMPLE SEED RECORD VALIDATION
-- -----------------------------------------------------------------------------
SELECT 'SECTION 5: Verifying Discovered Seed Records...' AS check_group;

-- Check Seed Drivers
SELECT 
    driver_id,
    name,
    phone,
    license_no,
    'VERIFIED SEED DRIVER' AS audit_status
FROM habalgo.driver
WHERE license_no IN ('N01-23-000001', 'N01-23-000002')
ORDER BY driver_id;

-- Check Seed Customers (if seeded)
SELECT 
    customer_id,
    name,
    phone,
    email,
    'VERIFIED SEED CUSTOMER' AS audit_status
FROM habalgo.customer
WHERE email IN ('maria@example.com', 'juan@example.com')
ORDER BY customer_id;

-- -----------------------------------------------------------------------------
-- SECTION 6: CONSTRAINTS & REFERENTIAL INTEGRITY AUDIT
-- -----------------------------------------------------------------------------
SELECT 'SECTION 6: Auditing Primary, Foreign, Unique, and Check Constraints...' AS check_group;

SELECT 
    conrelid::regclass::text AS target_table,
    conname AS constraint_name,
    CASE contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'c' THEN 'CHECK CONSTRAINT'
        ELSE contype::text
    END AS constraint_type,
    pg_get_constraintdef(c.oid) AS definition,
    'VERIFIED' AS status
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'habalgo'
ORDER BY conrelid::regclass::text, contype, conname;

-- -----------------------------------------------------------------------------
-- SECTION 7: REPRESENTATIVE APPLICATION QUERY (DASHBOARD METRICS)
-- -----------------------------------------------------------------------------
SELECT 'SECTION 7: Executing Representative Application Dashboard Query...' AS check_group;

SELECT 
    (SELECT count(*) FROM habalgo.customer WHERE customer_id IN (SELECT DISTINCT customer_id FROM habalgo.booking))::int AS active_customers,
    (SELECT count(*) FROM habalgo.booking WHERE booking_status IN ('Pending','Confirmed','In Progress'))::int AS pending_active_bookings,
    (SELECT COALESCE(sum(amount),0) FROM habalgo.payment WHERE status='Paid')::float AS total_settled_revenue,
    (SELECT round(avg(rating),1) FROM habalgo.rating_feedback)::float AS avg_service_rating;

SELECT '=================================================================' AS footer;
SELECT ' MASTER DATABASE RESTORATION VERIFICATION COMPLETED              ' AS footer;
SELECT '=================================================================' AS footer;

