-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC3 (Fault Injection Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Affected Objects: hazard_report, report_status_history, pg_trigger
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Ensure no automated status auditing triggers exist on hazard_report (simulating flawed baseline)
DROP TRIGGER IF EXISTS trg_hazard_report_status_audit ON public.hazard_report;
DROP FUNCTION IF EXISTS public.trg_log_hazard_status_change();

-- 2. Simulate administrative direct SQL status updates
-- This transitions reports without creating any corresponding rows in report_status_history
UPDATE public.hazard_report 
SET status = 'In Progress' 
WHERE report_id = 1;

UPDATE public.hazard_report 
SET status = 'Verified', priority = 'Medium', verified_by_user_id = 1, verified_at = CURRENT_TIMESTAMP
WHERE report_id = 2 AND status = 'Submitted';

COMMIT;

-- 3. Verification output showing lack of status history rows for recent changes
SELECT hr.report_id, hr.status, hr.priority,
       (SELECT COUNT(*) FROM public.report_status_history rsh WHERE rsh.report_id = hr.report_id) AS history_rows_count
FROM public.hazard_report hr
WHERE hr.report_id IN (1, 2);
