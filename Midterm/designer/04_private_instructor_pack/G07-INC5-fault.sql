-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC5 (Fault Injection Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Affected Objects: campus_location, hazard_report
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Ensure constraints are absent (simulating flawed baseline)
ALTER TABLE public.campus_location 
    DROP CONSTRAINT IF EXISTS uq_campus_location_bldg_floor_room;

ALTER TABLE public.hazard_report 
    DROP CONSTRAINT IF EXISTS chk_verified_report_requires_priority;

-- 2. Inject duplicate physical location entries
-- Inserting duplicate rows for the exact same physical room
INSERT INTO public.campus_location (building, floor, room_area, location_description, is_active)
VALUES 
    ('Main Academic Building', '3rd Floor', 'Room 302', 'North wing lecture hall (duplicate A)', true),
    ('Main Academic Building', '3rd Floor', 'Room 302', 'North wing lecture hall (duplicate B)', true);

-- 3. Inject an untriaged verified hazard report (Verified status with NULL priority)
-- Update an existing report or insert a test report
UPDATE public.hazard_report 
SET status = 'Verified',
    priority = NULL,
    verified_by_user_id = 1,
    verified_at = CURRENT_TIMESTAMP
WHERE report_id = 2;

COMMIT;

-- Verification of injected state:
-- 1. Check for duplicate physical locations
SELECT building, floor, room_area, COUNT(*) AS duplicate_count 
FROM public.campus_location 
GROUP BY building, floor, room_area 
HAVING COUNT(*) > 1;

-- 2. Check for verified reports with NULL priority
SELECT report_id, description, status, priority, verified_by_user_id, verified_at 
FROM public.hazard_report 
WHERE status = 'Verified' AND priority IS NULL;
