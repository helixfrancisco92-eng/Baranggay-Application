-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC3 (Reset & Remediation Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Affected Objects: hazard_report, report_status_history, pg_trigger
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Create or replace the automated status transition audit trigger function
CREATE OR REPLACE FUNCTION public.trg_log_hazard_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO public.report_status_history (
            report_id,
            changed_by_user_id,
            status,
            changed_at,
            notes
        ) VALUES (
            NEW.report_id,
            COALESCE(NEW.verified_by_user_id, OLD.reporter_user_id, 1),
            NEW.status,
            CURRENT_TIMESTAMP,
            'Automated database trigger audit log (transition from ' || OLD.status || ' to ' || NEW.status || ')'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Bind the trigger to hazard_report for AFTER UPDATE OF status
DROP TRIGGER IF EXISTS trg_hazard_report_status_audit ON public.hazard_report;
CREATE TRIGGER trg_hazard_report_status_audit
AFTER UPDATE OF status ON public.hazard_report
FOR EACH ROW
EXECUTE FUNCTION public.trg_log_hazard_status_change();

-- 3. Backfill missing history row for report 1 to ensure audit completeness
INSERT INTO public.report_status_history (report_id, changed_by_user_id, status, changed_at, notes)
SELECT 1, 1, 'In Progress', CURRENT_TIMESTAMP, 'Reconciled missing status history entry during incident reset'
WHERE NOT EXISTS (
    SELECT 1 FROM public.report_status_history WHERE report_id = 1 AND status = 'In Progress'
);

COMMIT;

-- 4. Execute maintenance routine to reclaim dead tuples and refresh planner statistics
VACUUM (ANALYZE) public.hazard_report;
VACUUM (ANALYZE) public.report_status_history;

-- Verification:
-- 1. Check trigger presence in catalog
SELECT tgname, tgtype, tgenabled, tgrelid::regclass AS table_name 
FROM pg_trigger 
WHERE tgrelid = 'public.hazard_report'::regclass AND NOT tgisinternal;

-- 2. Verify audit logging by triggering a test transition
UPDATE public.hazard_report SET status = 'Resolved', resolved_at = CURRENT_TIMESTAMP WHERE report_id = 1;

SELECT history_id, report_id, status, changed_at, notes 
FROM public.report_status_history 
WHERE report_id = 1 
ORDER BY history_id DESC LIMIT 2;
