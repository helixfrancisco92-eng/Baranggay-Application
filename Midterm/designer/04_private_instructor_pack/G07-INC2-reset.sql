-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC2 (Reset & Remediation Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Affected Objects: hazard_report, report_status_history, maintenance_action,
--                   assignment, attachment
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Drop CASCADE foreign keys and replace with ON DELETE RESTRICT on all audit/compliance relations
ALTER TABLE public.assignment DROP CONSTRAINT IF EXISTS assignment_report_id_fkey;
ALTER TABLE public.assignment DROP CONSTRAINT IF EXISTS fk_assignment_report;
ALTER TABLE public.assignment ADD CONSTRAINT fk_assignment_report 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

ALTER TABLE public.report_status_history DROP CONSTRAINT IF EXISTS report_status_history_fkey;
ALTER TABLE public.report_status_history DROP CONSTRAINT IF EXISTS fk_status_history_report;
ALTER TABLE public.report_status_history ADD CONSTRAINT fk_status_history_report 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

ALTER TABLE public.maintenance_action DROP CONSTRAINT IF EXISTS maintenance_action_fkey;
ALTER TABLE public.maintenance_action DROP CONSTRAINT IF EXISTS fk_maintenance_report;
ALTER TABLE public.maintenance_action ADD CONSTRAINT fk_maintenance_report 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

ALTER TABLE public.attachment DROP CONSTRAINT IF EXISTS attachment_report_id_fkey;
ALTER TABLE public.attachment DROP CONSTRAINT IF EXISTS fk_attachment_report;
ALTER TABLE public.attachment ADD CONSTRAINT fk_attachment_report 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE RESTRICT;

-- 2. Add Soft-Delete support to hazard_report
ALTER TABLE public.hazard_report ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.hazard_report ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;

-- 3. Clean up any temporary test records safely
DELETE FROM public.attachment WHERE report_id = 9999;
DELETE FROM public.report_status_history WHERE report_id = 9999;
DELETE FROM public.hazard_report WHERE report_id = 9999;

COMMIT;

-- Verification of foreign key constraint configuration in pg_constraint catalog
SELECT conname, conrelid::regclass AS child_table, confrelid::regclass AS parent_table, confdeltype 
FROM pg_constraint 
WHERE confrelid = 'public.hazard_report'::regclass
ORDER BY child_table;
