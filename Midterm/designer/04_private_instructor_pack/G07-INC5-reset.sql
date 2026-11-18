-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC5 (Reset & Remediation Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Affected Objects: campus_location, hazard_report
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Re-point any hazard reports referencing duplicate location rows to the lowest primary location_id
WITH ranked_locations AS (
    SELECT location_id,
           FIRST_VALUE(location_id) OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS keep_id,
           ROW_NUMBER() OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS rn
    FROM public.campus_location
)
UPDATE public.hazard_report hr
SET location_id = rl.keep_id
FROM ranked_locations rl
WHERE hr.location_id = rl.location_id AND rl.rn > 1;

-- 2. Delete duplicate location records, preserving the lowest primary location_id
WITH duplicates AS (
    SELECT location_id,
           ROW_NUMBER() OVER (PARTITION BY building, floor, room_area ORDER BY location_id) AS rn
    FROM public.campus_location
)
DELETE FROM public.campus_location
WHERE location_id IN (SELECT location_id FROM duplicates WHERE rn > 1);

-- 3. Enforce business-level uniqueness on campus physical locations
ALTER TABLE public.campus_location 
    DROP CONSTRAINT IF EXISTS uq_campus_location_bldg_floor_room;

ALTER TABLE public.campus_location 
    ADD CONSTRAINT uq_campus_location_bldg_floor_room 
    UNIQUE (building, floor, room_area);

-- 4. Backfill existing NULL priorities on verified/active reports
UPDATE public.hazard_report 
SET priority = 'Medium' 
WHERE status IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') AND priority IS NULL;

-- 5. Enforce conditional check constraint requiring priority when verified
ALTER TABLE public.hazard_report 
    DROP CONSTRAINT IF EXISTS chk_verified_report_requires_priority;

ALTER TABLE public.hazard_report 
    ADD CONSTRAINT chk_verified_report_requires_priority 
    CHECK (status NOT IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') OR priority IS NOT NULL);

COMMIT;

-- Verification:
-- 1. Verify zero duplicate locations exist
SELECT building, floor, room_area, COUNT(*) 
FROM public.campus_location 
GROUP BY building, floor, room_area 
HAVING COUNT(*) > 1;

-- 2. Verify zero verified reports have NULL priority
SELECT COUNT(*) AS unprioritized_verified_count 
FROM public.hazard_report 
WHERE status IN ('Verified', 'Assigned', 'In Progress', 'Resolved', 'Closed') AND priority IS NULL;

-- 3. Verify constraints in pg_constraint
SELECT conname, contype, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid IN ('public.campus_location'::regclass, 'public.hazard_report'::regclass)
  AND conname IN ('uq_campus_location_bldg_floor_room', 'chk_verified_report_requires_priority');
