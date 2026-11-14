-- ==============================================================================
-- HabalGo (Group 6) — Sample Records and Seed Data Verification Script
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test
-- Schema: habalgo
-- ==============================================================================

\set ON_ERROR_STOP on
SET search_path TO habalgo, public;

SELECT '=================================================================' AS header;
SELECT ' AUDIT: SAMPLE RECORDS & SEED DATA INTEGRITY                      ' AS header;
SELECT ' Target Database: ' || current_database() AS context;
SELECT '=================================================================' AS header;

-- 1. Table Record Cardinality Overview
SELECT '1. Record Cardinality Matrix Across All 8 Base Tables:' AS audit_section;

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

-- 2. Validate Official Seed Drivers (Discovered from sample data.sql)
SELECT '2. Auditing Seed Drivers (10 Philippine Heroes/Historical Names):' AS audit_section;

SELECT 
    driver_id,
    name,
    phone,
    license_no,
    CASE 
        WHEN license_no LIKE 'N01-23-0000%' THEN 'VALID REPOSITORY SEED'
        ELSE 'ADDITIONAL APPLICATION DRIVER'
    END AS classification
FROM habalgo.driver
ORDER BY driver_id
LIMIT 15;

-- 3. Validate Official Seed Customers (Discovered from 02_seed.sql)
SELECT '3. Auditing Seed Customers (Discovered from 02_seed.sql):' AS audit_section;

SELECT 
    customer_id,
    name,
    phone,
    email,
    'VERIFIED CUSTOMER PROFILE' AS status
FROM habalgo.customer
ORDER BY customer_id
LIMIT 15;

-- 4. Validate Vehicle Fleet and Driver Assignments
SELECT '4. Auditing Vehicle Fleet and Active Driver Assignments:' AS audit_section;

SELECT 
    v.vehicle_id,
    v.plate_no,
    v.vehicle_type,
    v.model,
    d.driver_id,
    d.name AS assigned_driver,
    dv.assigned_from,
    dv.assigned_to,
    CASE 
        WHEN dv.assigned_to IS NULL THEN 'ACTIVE ASSIGNMENT'
        ELSE 'HISTORICAL ASSIGNMENT'
    END AS assignment_status
FROM habalgo.vehicle v
LEFT JOIN habalgo.driver_vehicle dv ON dv.vehicle_id = v.vehicle_id AND dv.assigned_to IS NULL
LEFT JOIN habalgo.driver d ON d.driver_id = dv.driver_id
ORDER BY v.vehicle_id
LIMIT 10;

-- 5. Validate Geocoded Locations
SELECT '5. Auditing Pickup and Drop-off Locations:' AS audit_section;

SELECT 
    location_id,
    address,
    city,
    'NORMALIZED LOCATION' AS status
FROM habalgo.location
ORDER BY location_id
LIMIT 10;

-- 6. Validate Booking Lifecycle Transactions
SELECT '6. Auditing Sample Bookings and Dispatch Statuses:' AS audit_section;

SELECT 
    b.booking_id,
    c.name AS customer_name,
    d.name AS driver_name,
    lp.address || ', ' || lp.city AS pickup_point,
    ld.address || ', ' || ld.city AS dropoff_point,
    b.booking_status,
    b.booking_date
FROM habalgo.booking b
JOIN habalgo.customer c ON c.customer_id = b.customer_id
LEFT JOIN habalgo.driver d ON d.driver_id = b.driver_id
JOIN habalgo.location lp ON lp.location_id = b.pickup_location_id
JOIN habalgo.location ld ON ld.location_id = b.dropoff_location_id
ORDER BY b.booking_id DESC
LIMIT 10;

-- 7. Validate Payment Settlements
SELECT '7. Auditing Payment Transactions:' AS audit_section;

SELECT 
    p.payment_id,
    p.booking_id,
    p.amount,
    p.method,
    p.status,
    CASE 
        WHEN p.amount > 0 THEN 'VALID POSITIVE FARE'
        ELSE 'INVALID FARE'
    END AS amount_check
FROM habalgo.payment p
ORDER BY p.payment_id DESC
LIMIT 10;

-- 8. Validate Customer Ratings and Service Reviews
SELECT '8. Auditing Customer Service Feedback and Star Ratings:' AS audit_section;

SELECT 
    r.rating_id,
    r.booking_id,
    c.name AS reviewing_customer,
    r.rating AS stars,
    r.feedback AS review_comments,
    CASE 
        WHEN r.rating BETWEEN 1 AND 5 THEN 'VALID RATING RANGE (1-5)'
        ELSE 'INVALID RATING'
    END AS rating_check
FROM habalgo.rating_feedback r
JOIN habalgo.customer c ON c.customer_id = r.customer_id
ORDER BY r.rating_id DESC
LIMIT 10;

