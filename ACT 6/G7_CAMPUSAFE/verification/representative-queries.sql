-- =============================================================================
-- CampusSafe (Group 7) — Representative Business Logic Queries Suite
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test (or grp07_campussafedb)
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Representative Business Query Execution Suite        '
\echo '================================================================='

\echo '--- QUERY 1: ADMINISTRATIVE HAZARD TRIAGE QUEUE (Submitted State) ---'
-- Purpose: Administrators inspect newly submitted reports to assign risk priority and verify authenticity.
SELECT 
    r.report_id,
    u.full_name AS reporter_name,
    ro.role_name AS reporter_role,
    c.category_name AS hazard_category,
    l.building || ' — ' || l.room_area AS physical_location,
    r.description,
    r.submitted_at,
    (SELECT COUNT(*) FROM attachment att WHERE att.report_id = r.report_id) AS photo_evidence_count
FROM hazard_report r
JOIN app_user u ON r.reporter_user_id = u.user_id
JOIN role ro ON u.role_id = ro.role_id
JOIN hazard_category c ON r.category_id = c.category_id
JOIN campus_location l ON r.location_id = l.location_id
WHERE r.status = 'Submitted'
ORDER BY r.submitted_at ASC;

\echo '--- QUERY 2: DISPATCH QUEUE (Verified Hazards Awaiting Technician Assignment) ---'
-- Purpose: Dispatches verified safety hazards to active maintenance personnel.
SELECT 
    r.report_id,
    r.priority,
    c.category_name,
    l.building,
    l.room_area,
    admin.full_name AS verified_by,
    r.verified_at,
    r.description
FROM hazard_report r
JOIN hazard_category c ON r.category_id = c.category_id
JOIN campus_location l ON r.location_id = l.location_id
JOIN app_user admin ON r.verified_by_user_id = admin.user_id
WHERE r.status = 'Verified'
ORDER BY 
    CASE r.priority 
        WHEN 'Critical' THEN 1 
        WHEN 'High'     THEN 2 
        WHEN 'Medium'   THEN 3 
        WHEN 'Low'      THEN 4 
    END, r.verified_at ASC;

\echo '--- QUERY 3: TECHNICIAN WORK QUEUE (Active Work Orders for Alex Davis) ---'
-- Purpose: Personal technician dashboard displaying active repairs and instructions.
SELECT 
    a.assignment_id,
    r.report_id,
    r.priority,
    r.status AS report_lifecycle_status,
    a.assignment_status,
    l.building || ' (' || l.room_area || ')' AS location,
    c.category_name,
    r.description,
    a.assigned_at,
    disp.full_name AS assigned_by_admin
FROM assignment a
JOIN hazard_report r ON a.report_id = r.report_id
JOIN campus_location l ON r.location_id = l.location_id
JOIN hazard_category c ON r.category_id = c.category_id
JOIN app_user disp ON a.assigned_by_user_id = disp.user_id
WHERE a.maintenance_user_id = 2 -- Alex Davis (Senior Tech)
  AND a.assignment_status IN ('Assigned', 'In Progress')
ORDER BY a.assigned_at ASC;

\echo '--- QUERY 4: COMPLETE 6-STAGE INCIDENT AUDIT TIMELINE (Report #11) ---'
-- Purpose: Complete chronological forensic timeline for safety compliance auditing.
SELECT 
    h.history_id,
    h.status AS transition_status,
    u.full_name AS actor_name,
    ro.role_name AS actor_role,
    h.changed_at AS event_timestamp,
    COALESCE(h.notes, 'No remarks provided.') AS audit_remarks
FROM report_status_history h
JOIN app_user u ON h.changed_by_user_id = u.user_id
JOIN role ro ON u.role_id = ro.role_id
WHERE h.report_id = 11
ORDER BY h.changed_at ASC;

\echo '--- QUERY 5: EXECUTIVE SAFETY ANALYTICS & RISK HEATMAP ---'
-- Purpose: Campus-wide safety metrics grouped by facility and priority.
SELECT 
    l.building,
    COUNT(r.report_id) AS total_incidents,
    COUNT(CASE WHEN r.priority = 'Critical' THEN 1 END) AS critical_risks,
    COUNT(CASE WHEN r.priority = 'High' THEN 1 END) AS high_risks,
    COUNT(CASE WHEN r.status IN ('Resolved', 'Closed') THEN 1 END) AS remediated_hazards,
    COUNT(CASE WHEN r.status IN ('Submitted', 'Verified', 'Assigned', 'In Progress') THEN 1 END) AS active_hazards
FROM campus_location l
LEFT JOIN hazard_report r ON l.location_id = r.location_id
GROUP BY l.building
ORDER BY critical_risks DESC, total_incidents DESC;

