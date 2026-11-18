# FLAW #3: Missing Database Triggers for Automated Status History Auditing

**Flaw ID:** G07-F3  
**Project Owner:** Group 7 – CAMPUSAFE  
**Reported By:** Group 12 – iBarangay  
**Affected Area:** Database Triggers, Auditing & Maintenance  
**Related Activity:** Activity 3 & 5 (Triggers, Monitoring & Maintenance)  

---

### Description

In `grp07-campussafe`, the application defines a dedicated audit logging table `report_status_history` intended to capture every lifecycle transition of a hazard report (`Submitted` $\rightarrow$ `Verified` $\rightarrow$ `Assigned` $\rightarrow$ `In Progress` $\rightarrow$ `Resolved` $\rightarrow$ `Closed`). 

However, inspection of the database schema (`database/01_schema.sql`) and system triggers reveals that **zero database-level triggers are defined on `hazard_report`**. 

Instead, status transition logging is implemented entirely within application-level PHP models (`src/models/Report.php`). When a user updates a report status via the web interface, the PHP controller issues two independent queries:
1. `UPDATE hazard_report SET status = :status ...`
2. `INSERT INTO report_status_history (report_id, changed_by_user_id, status, notes) VALUES (...)`

This application-centric design creates a severe auditing blind spot:
- Any direct SQL query executed via `psql`, pgAdmin, or maintenance scripts that modifies `hazard_report.status` updates the incident status without creating any corresponding record in `report_status_history`.
- In the event of network disruption, partial transaction rollback, or uncaught exceptions between the two PHP statements, the status updates but the history row is lost.
- High-volume updates generate dead tuples in `hazard_report` that accumulate without automated maintenance or trigger-based change-tracking.

---

### Evidence

- **Repository File:** `grp07-campussafe/database/01_schema.sql` (Entire schema definition)
- **Actual Database Object:** Table `public.hazard_report` and PostgreSQL catalog `pg_trigger`.
- **SQL Command / Inspection Method:**
  ```sql
  SELECT tgname, tgtype, tgenabled, tgrelid::regclass AS table_name 
  FROM pg_trigger 
  WHERE tgrelid = 'hazard_report'::regclass AND NOT tgisinternal;
  ```
- **Actual Result:**
  ```
   tgname | tgtype | tgenabled | table_name 
  --------+--------+-----------+------------
  (0 rows)
  ```
  *(Zero user-defined triggers exist on `hazard_report`).*
- **Application Logic Evidence:** `grp07-campussafe/src/models/Report.php` lines 145–160 show manual PHP-level SQL inserts into `report_status_history`.
- **Screenshot / Evidence File:** Referenced in `midterm/evidence/designer/G07_F3_trigger_evidence.txt`.
- **Baseline Comparison:** Activity 5 Progress Report (`progress-report/ACTIVITY_05_MAINTENANCE_MONITORING_REPORT.md`) emphasizes maintaining audit reliability and monitoring table transactions. Relying solely on client PHP scripts fails to provide database-level auditing guarantees.

---

### Impact

- **Audit Integrity & Non-Repudiation (Moderate to High):** Administrative status modifications performed during database maintenance windows, emergency overrides, or batch data reconciliations leave no audit trail. Compliance officers inspecting `report_status_history` see gaps in report timelines.
- **Data Inconsistency:** In distributed or batch scenarios, the report status can be modified without generating an audit trail, violating ISO/IEC 27001 auditability principles.

---

### Severity

**Medium** (Confirmed Flaw)

---

### Recommended Fix

Implement an `AFTER UPDATE OF status` trigger on `hazard_report` that fires automatically whenever `status` is modified. The trigger function records the transition, previous status, new status, timestamp, and changing user into `report_status_history`.

```sql
-- Step 1: Create automated audit trigger function
CREATE OR REPLACE FUNCTION trg_log_hazard_status_change()
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
            COALESCE(NEW.verified_by_user_id, OLD.reporter_user_id),
            NEW.status,
            CURRENT_TIMESTAMP,
            'Automated database trigger audit log (transition from ' || OLD.status || ' to ' || NEW.status || ')'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Bind trigger to hazard_report
DROP TRIGGER IF EXISTS trg_hazard_report_status_audit ON public.hazard_report;
CREATE TRIGGER trg_hazard_report_status_audit
AFTER UPDATE OF status ON public.hazard_report
FOR EACH ROW
EXECUTE FUNCTION trg_log_hazard_status_change();
```

---

### Verification

1. **Direct SQL Update Test:**
   ```sql
   -- Update status directly via psql / SQL command
   UPDATE hazard_report SET status = 'In Progress' WHERE report_id = 1;
   
   -- Query status history table
   SELECT history_id, report_id, status, changed_at, notes 
   FROM report_status_history 
   WHERE report_id = 1 
   ORDER BY history_id DESC LIMIT 1;
   ```
2. **Expected Result:**
   A new audit record appears automatically in `report_status_history` reflecting `status = 'In Progress'`, a current timestamp, and the automated transition remarks, proving engine-level enforcement without requiring PHP code execution.
