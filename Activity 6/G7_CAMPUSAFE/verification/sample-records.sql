-- =============================================================================
-- CampusSafe (Group 7) — Targeted Sample Record Verification Suite
-- Course: COMP 018 — Database Administration (Activity 6)
-- Target Database: grp07_campussafedb_activity6_restore_test (or grp07_campussafedb)
-- =============================================================================

\echo '================================================================='
\echo ' CampusSafe Sample Record Verification Across All 9 Tables       '
\echo '================================================================='

\echo '--- 1. TABLE: role (All 5 Seed System Roles) ---'
SELECT role_id, role_name, description 
FROM role 
ORDER BY role_id;

\echo '--- 2. TABLE: app_user (Key Demo User Profiles) ---'
SELECT 
    u.user_id, 
    u.username, 
    u.full_name, 
    u.email, 
    r.role_name, 
    u.account_status,
    u.created_at
FROM app_user u
JOIN role r ON u.role_id = r.role_id
ORDER BY u.user_id;

\echo '--- 3. TABLE: hazard_category (All 6 Master Classifications) ---'
SELECT category_id, category_name, description, is_active 
FROM hazard_category 
ORDER BY category_id;

\echo '--- 4. TABLE: campus_location (Sample Campus Facilities) ---'
SELECT location_id, building, floor, room_area, is_active 
FROM campus_location 
ORDER BY location_id 
LIMIT 5;

\echo '--- 5. TABLE: hazard_report (Representative Lifecycle Reports) ---'
SELECT 
    report_id, 
    status, 
    COALESCE(priority, 'Unassigned') AS priority, 
    submitted_at, 
    CASE WHEN verified_by_user_id IS NOT NULL THEN 'Verified' ELSE 'Pending' END AS verification_status,
    CASE WHEN resolved_at IS NOT NULL THEN resolved_at::text ELSE 'Incomplete' END AS resolution_date,
    SUBSTRING(description FROM 1 FOR 60) || '...' AS description_snippet
FROM hazard_report
WHERE report_id IN (1, 3, 5, 8, 11, 14)
ORDER BY report_id;

\echo '--- 6. TABLE: assignment (Technician Dispatch Records) ---'
SELECT 
    a.assignment_id,
    a.report_id,
    tech.full_name AS assigned_technician,
    dispatcher.full_name AS assigned_by,
    a.assigned_at,
    a.assignment_status
FROM assignment a
JOIN app_user tech ON a.maintenance_user_id = tech.user_id
JOIN app_user dispatcher ON a.assigned_by_user_id = dispatcher.user_id
ORDER BY a.assignment_id
LIMIT 6;

\echo '--- 7. TABLE: report_status_history (Audit Trail for Report #11) ---'
SELECT 
    h.history_id,
    h.status,
    u.full_name AS changed_by,
    h.changed_at,
    h.notes
FROM report_status_history h
JOIN app_user u ON h.changed_by_user_id = u.user_id
WHERE h.report_id = 11
ORDER BY h.changed_at ASC;

\echo '--- 8. TABLE: maintenance_action (Physical Technician Repair Logs) ---'
SELECT 
    m.action_id,
    m.report_id,
    u.full_name AS technician,
    m.action_date,
    m.is_resolution,
    SUBSTRING(m.action_details FROM 1 FOR 65) || '...' AS action_summary
FROM maintenance_action m
JOIN app_user u ON m.maintenance_user_id = u.user_id
ORDER BY m.action_id
LIMIT 5;

\echo '--- 9. TABLE: attachment (Evidence Photo Attachments) ---'
SELECT 
    att.attachment_id,
    att.report_id,
    u.full_name AS uploader,
    att.file_name,
    att.mime_type,
    att.uploaded_at
FROM attachment att
JOIN app_user u ON att.uploaded_by_user_id = u.user_id
ORDER BY att.attachment_id;

