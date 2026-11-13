-- =============================================================================
-- CampusSafe (Group 7) — Record Count & Seed Verification Script (06_verify_records.sql)
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Record Count & Data Integrity Audit (Phase 6 - B)    '
\echo ' Target: grp07_campussafedb_activity6_restore_test               '
\echo '================================================================='

-- Safety Check
SELECT current_database() AS connected_database;

\echo '--- 1. TABLE ROW COUNTS AUDIT (Compared Against Seed Baseline) ---'
WITH row_audit AS (
    SELECT 'role' AS table_name, COUNT(*) AS restored_count, 5 AS expected_count FROM role
    UNION ALL SELECT 'app_user', COUNT(*), 6 FROM app_user
    UNION ALL SELECT 'hazard_category', COUNT(*), 6 FROM hazard_category
    UNION ALL SELECT 'campus_location', COUNT(*), 10 FROM campus_location
    UNION ALL SELECT 'hazard_report', COUNT(*), 16 FROM hazard_report
    UNION ALL SELECT 'assignment', COUNT(*), 12 FROM assignment
    UNION ALL SELECT 'report_status_history', COUNT(*), 39 FROM report_status_history
    UNION ALL SELECT 'maintenance_action', COUNT(*), 9 FROM maintenance_action
    UNION ALL SELECT 'attachment', COUNT(*), 5 FROM attachment
)
SELECT 
    table_name,
    restored_count,
    expected_count,
    (restored_count - expected_count) AS delta,
    CASE WHEN restored_count = expected_count THEN 'PASS (Exact Match)' ELSE 'FAIL (Variance Detected)' END AS audit_status
FROM row_audit
ORDER BY table_name;

-- Total Records Audit
SELECT 
    SUM(c) AS total_restored_records,
    108 AS total_expected_records,
    CASE WHEN SUM(c) = 108 THEN 'PASS (108/108 Seed Rows Restored)' ELSE 'FAIL (Total Row Mismatch)' END AS overall_status
FROM (
    SELECT COUNT(*) AS c FROM role UNION ALL SELECT COUNT(*) FROM app_user UNION ALL SELECT COUNT(*) FROM hazard_category
    UNION ALL SELECT COUNT(*) FROM campus_location UNION ALL SELECT COUNT(*) FROM hazard_report UNION ALL SELECT COUNT(*) FROM assignment
    UNION ALL SELECT COUNT(*) FROM report_status_history UNION ALL SELECT COUNT(*) FROM maintenance_action UNION ALL SELECT COUNT(*) FROM attachment
) t;

\echo '--- 2. HAZARD REPORT LIFECYCLE STAGE DISTRIBUTION ---'
SELECT 
    status,
    priority,
    COUNT(*) AS total_reports,
    MIN(submitted_at) AS earliest_submission,
    MAX(submitted_at) AS latest_submission
FROM hazard_report
GROUP BY status, priority
ORDER BY 
    CASE status
        WHEN 'Submitted'   THEN 1
        WHEN 'Verified'    THEN 2
        WHEN 'Assigned'    THEN 3
        WHEN 'In Progress' THEN 4
        WHEN 'Resolved'    THEN 5
        WHEN 'Closed'      THEN 6
    END, priority;

\echo '--- 3. ASSIGNMENT STATUS DISTRIBUTION ---'
SELECT 
    assignment_status,
    COUNT(*) AS total_assignments
FROM assignment
GROUP BY assignment_status
ORDER BY assignment_status;

\echo '--- 4. SAMPLE RECORD VERIFICATION (KEY DEMO ENTITIES) ---'
-- App Users verification
SELECT user_id, username, full_name, email, account_status
FROM app_user
ORDER BY user_id;

-- Master Hazard Categories verification
SELECT category_id, category_name, is_active
FROM hazard_category
ORDER BY category_id;

-- Master Campus Locations verification
SELECT location_id, building, floor, room_area, is_active
FROM campus_location
ORDER BY location_id;

