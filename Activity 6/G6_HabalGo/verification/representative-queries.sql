-- ==============================================================================
-- HabalGo (Group 6) — Representative Application Queries Verification
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp00_habalgodb_activity6_restore_test
-- Schema: habalgo
-- ==============================================================================
-- These queries are derived directly from the HabalGo production application logic
-- defined in api.php and js/app.js.
-- ==============================================================================

\set ON_ERROR_STOP on
SET search_path TO habalgo, public;

SELECT '=================================================================' AS header;
SELECT ' REPRESENTATIVE APPLICATION QUERIES — REAL-WORLD WORKLOADS      ' AS header;
SELECT ' Database: ' || current_database() || ' | Timestamp: ' || CURRENT_TIMESTAMP::text AS session;
SELECT '=================================================================' AS header;

-- -----------------------------------------------------------------------------
-- QUERY 1: EXECUTIVE DASHBOARD KPI METRICS
-- Source: api.php?t=dashboard
-- Description: Computes real-time platform statistics including active customers,
-- pending/in-progress bookings, settled revenue, and aggregate customer satisfaction.
-- -----------------------------------------------------------------------------
SELECT '--- Query 1: Platform Overview & Performance KPIs ---' AS query_title;

SELECT 
    (SELECT count(*) FROM habalgo.customer WHERE customer_id IN (SELECT DISTINCT customer_id FROM habalgo.booking))::int AS customers_with_bookings,
    (SELECT count(*) FROM habalgo.booking WHERE booking_status IN ('Pending','Confirmed','In Progress'))::int AS active_ongoing_trips,
    (SELECT count(*) FROM habalgo.booking WHERE booking_status = 'Completed')::int AS completed_trips,
    (SELECT COALESCE(sum(amount),0) FROM habalgo.payment WHERE status='Paid')::numeric(12,2) AS total_settled_revenue_php,
    (SELECT round(avg(rating),2) FROM habalgo.rating_feedback)::numeric(3,2) AS average_service_rating;

-- -----------------------------------------------------------------------------
-- QUERY 2: ACTIVE FLEET & DRIVER ASSIGNMENT ROSTER
-- Source: api.php?t=vehicles
-- Description: Retrieves motorcycle/vehicle fleet inventory combined with current
-- active driver assignments (dv.assigned_to IS NULL).
-- -----------------------------------------------------------------------------
SELECT '--- Query 2: Active Vehicle Fleet & Driver Assignment Roster ---' AS query_title;

SELECT 
    v.vehicle_id,
    v.plate_no,
    v.vehicle_type,
    v.model,
    COALESCE(d.name, 'UNASSIGNED') AS current_driver_name,
    COALESCE(d.phone, 'N/A') AS driver_contact,
    COALESCE(to_char(dv.assigned_from, 'YYYY-MM-DD HH24:MI'), 'N/A') AS assignment_started
FROM habalgo.vehicle v
LEFT JOIN habalgo.driver_vehicle dv 
    ON dv.vehicle_id = v.vehicle_id 
   AND dv.assigned_to IS NULL
LEFT JOIN habalgo.driver d 
    ON d.driver_id = dv.driver_id
ORDER BY v.vehicle_id;

-- -----------------------------------------------------------------------------
-- QUERY 3: COMPREHENSIVE BOOKING DISPATCH & JOURNEY LEDGER
-- Source: api.php ($BK query)
-- Description: Core ride-hailing operational view joining booking details, customer
-- contacts, driver info, and origin/destination city routing.
-- -----------------------------------------------------------------------------
SELECT '--- Query 3: Ride-Hailing Dispatch & Journey Ledger ---' AS query_title;

SELECT 
    b.booking_id,
    c.name AS customer_name,
    c.phone AS customer_phone,
    lp.address || ' (' || lp.city || ')' AS pickup_location,
    ld.address || ' (' || ld.city || ')' AS dropoff_location,
    COALESCE(d.name, 'Awaiting Driver') AS assigned_driver,
    b.booking_status,
    to_char(b.booking_date, 'Mon DD, YYYY HH24:MI') AS booking_timestamp
FROM habalgo.booking b
JOIN habalgo.customer c ON c.customer_id = b.customer_id
JOIN habalgo.location lp ON lp.location_id = b.pickup_location_id
JOIN habalgo.location ld ON ld.location_id = b.dropoff_location_id
LEFT JOIN habalgo.driver d ON d.driver_id = b.driver_id
ORDER BY b.booking_id DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- QUERY 4: FINANCIAL SETTLEMENT & REVENUE RECONCILIATION
-- Source: api.php?t=payments
-- Description: Financial audit joining payment transactions, parent booking IDs,
-- and paying customers to verify payment amounts and statuses.
-- -----------------------------------------------------------------------------
SELECT '--- Query 4: Financial Transactions & Settlement Audit ---' AS query_title;

SELECT 
    p.payment_id,
    p.booking_id,
    c.name AS paying_customer,
    p.amount AS fare_amount,
    p.method AS payment_channel,
    p.status AS payment_status,
    b.booking_status AS trip_status
FROM habalgo.payment p
JOIN habalgo.booking b ON b.booking_id = p.booking_id
JOIN habalgo.customer c ON c.customer_id = b.customer_id
ORDER BY p.payment_id DESC
LIMIT 10;

-- -----------------------------------------------------------------------------
-- QUERY 5: SERVICE QUALITY, STAR RATINGS, AND CUSTOMER REVIEWS
-- Source: api.php?t=ratings
-- Description: Aggregates passenger service ratings, textual reviews, and driver
-- performance across completed journeys.
-- -----------------------------------------------------------------------------
SELECT '--- Query 5: Customer Ratings and Driver Service Evaluation ---' AS query_title;

SELECT 
    r.rating_id,
    r.booking_id,
    r.rating AS star_score,
    r.feedback AS customer_review,
    c.name AS passenger_name,
    lp.city AS pickup_city,
    ld.city AS dropoff_city,
    COALESCE(d.name, 'No Driver Recorded') AS evaluated_driver
FROM habalgo.rating_feedback r
JOIN habalgo.booking b ON b.booking_id = r.booking_id
JOIN habalgo.customer c ON c.customer_id = r.customer_id
JOIN habalgo.location lp ON lp.location_id = b.pickup_location_id
JOIN habalgo.location ld ON ld.location_id = b.dropoff_location_id
LEFT JOIN habalgo.driver d ON d.driver_id = b.driver_id
ORDER BY r.rating_id DESC
LIMIT 10;

SELECT '=================================================================' AS footer;
SELECT ' ALL REPRESENTATIVE APPLICATION QUERIES EXECUTED SUCCESSFULLY    ' AS footer;
SELECT '=================================================================' AS footer;

