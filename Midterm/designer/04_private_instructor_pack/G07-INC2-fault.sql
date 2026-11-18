-- =============================================================================
-- COMP 018 — Database Administration: Midterm Examination
-- Incident ID: G07-INC2 (Fault Injection Script)
-- Target Database: grp07_campussafedb_disposable / campussafe_midterm_test
-- Affected Objects: hazard_report, report_status_history, maintenance_action,
--                   assignment, attachment
-- Designer Group: Group 12 (iBarangay)
-- Evaluation Target: Group 7 (CAMPUSAFE)
-- =============================================================================

BEGIN;

-- 1. Ensure foreign keys are configured with ON DELETE CASCADE (simulating flawed baseline)
ALTER TABLE public.assignment DROP CONSTRAINT IF EXISTS assignment_report_id_fkey;
ALTER TABLE public.assignment DROP CONSTRAINT IF EXISTS fk_assignment_report;
ALTER TABLE public.assignment ADD CONSTRAINT assignment_report_id_fkey 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE CASCADE;

ALTER TABLE public.report_status_history DROP CONSTRAINT IF EXISTS report_status_history_fkey;
ALTER TABLE public.report_status_history DROP CONSTRAINT IF EXISTS fk_status_history_report;
ALTER TABLE public.report_status_history ADD CONSTRAINT report_status_history_fkey 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE CASCADE;

ALTER TABLE public.maintenance_action DROP CONSTRAINT IF EXISTS maintenance_action_fkey;
ALTER TABLE public.maintenance_action DROP CONSTRAINT IF EXISTS fk_maintenance_report;
ALTER TABLE public.maintenance_action ADD CONSTRAINT maintenance_action_fkey 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE CASCADE;

ALTER TABLE public.attachment DROP CONSTRAINT IF EXISTS attachment_report_id_fkey;
ALTER TABLE public.attachment DROP CONSTRAINT IF EXISTS fk_attachment_report;
ALTER TABLE public.attachment ADD CONSTRAINT attachment_report_id_fkey 
    FOREIGN KEY (report_id) REFERENCES public.hazard_report(report_id) ON DELETE CASCADE;

-- 2. Insert an isolated test hazard report with child audit rows to demonstrate the symptom
INSERT INTO public.hazard_report (report_id, reporter_user_id, location_id, category_id, description, status)
VALUES (9999, 1, 1, 1, 'Temporary Audit Test Report for Incident G07-INC2', 'Submitted')
ON CONFLICT (report_id) DO NOTHING;

INSERT INTO public.report_status_history (report_id, changed_by_user_id, status, notes)
VALUES (9999, 1, 'Submitted', 'Initial audit trail record')
ON CONFLICT DO NOTHING;

INSERT INTO public.attachment (report_id, uploaded_by_user_id, file_name, file_path_or_url, mime_type)
VALUES (9999, 1, 'test_evidence.jpg', 'uploads/test_evidence.jpg', 'image/jpeg')
ON CONFLICT DO NOTHING;

-- 3. Execute the destructive delete demonstrating CASCADE behavior
DELETE FROM public.hazard_report WHERE report_id = 9999;

COMMIT;

-- Verification query confirming that child audit records were completely wiped out
SELECT 'Child rows in report_status_history' AS check_item, COUNT(*) AS count 
FROM public.report_status_history WHERE report_id = 9999
UNION ALL
SELECT 'Child rows in attachment', COUNT(*) 
FROM public.attachment WHERE report_id = 9999;
