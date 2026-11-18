# FLAW #2: Cascading Deletions Purging Compliance Audit Trail & Evidence

**Flaw ID:** G07-F2  
**Project Owner:** Group 7 – CAMPUSAFE  
**Reported By:** Group 12 – iBarangay  
**Affected Area:** Schema Design, Referential Integrity & Audit Retention  
**Related Activity:** Activity 3 & 4 (Database Schema & Relational Modeling)  

---

### Description

In `database/01_schema.sql`, the foreign key relationships between the parent incident entity `hazard_report` and its four dependent child tables are defined with `ON DELETE CASCADE`:
1. `assignment`: `REFERENCES hazard_report(report_id) ON DELETE CASCADE` (Line 110)
2. `report_status_history`: `REFERENCES hazard_report(report_id) ON DELETE CASCADE` (Line 125)
3. `maintenance_action`: `REFERENCES hazard_report(report_id) ON DELETE CASCADE` (Line 139)
4. `attachment`: `REFERENCES hazard_report(report_id) ON DELETE CASCADE` (Line 153)

In physical campus safety and hazard management systems, incident records, historical status transitions, technician repair logs, and uploaded photographic evidence are compliance-audited entities subject to legal, institutional, and regulatory retention policies. Configuring `ON DELETE CASCADE` on these relations means that if an administrator, automated batch cleanup routine, or authorized user deletes a parent row from `hazard_report`, PostgreSQL automatically and irreversibly purges all corresponding historical audit rows in `report_status_history`, all dispatch records in `assignment`, all physical maintenance logs in `maintenance_action`, and all evidence metadata in `attachment`.

---

### Evidence

- **Repository File:** `grp07-campussafe/database/01_schema.sql` (Lines 110, 125, 139, 153)
  ```sql
  -- Line 110
  report_id INT NOT NULL REFERENCES hazard_report(report_id) ON DELETE CASCADE,
  -- Line 125
  report_id INT NOT NULL REFERENCES hazard_report(report_id) ON DELETE CASCADE,
  -- Line 139
  report_id INT NOT NULL REFERENCES hazard_report(report_id) ON DELETE CASCADE,
  -- Line 153
  report_id INT NOT NULL REFERENCES hazard_report(report_id) ON DELETE CASCADE,
  ```
- **Actual Database Object:** Foreign key constraints referencing `hazard_report` on tables `assignment`, `report_status_history`, `maintenance_action`, `attachment`.
- **SQL Command / Inspection Method:**
  ```sql
  SELECT conname, conrelid::regclass AS child_table, confrelid::regclass AS parent_table, confdeltype 
  FROM pg_constraint 
  WHERE confrelid = 'hazard_report'::regclass;
  ```
- **Actual Result:**
  ```
            conname           |      child_table      | parent_table  | confdeltype 
  ----------------------------+-----------------------+---------------+-------------
   assignment_report_id_fkey  | assignment            | hazard_report | c
   report_status_history_fkey | report_status_history | hazard_report | c
   maintenance_action_fkey    | maintenance_action    | hazard_report | c
   attachment_report_id_fkey  | attachment            | hazard_report | c
  (4 rows)
  ```
  *(Note: `confdeltype = 'c'` represents `CASCADE` in the PostgreSQL system catalog `pg_constraint`).*
- **Screenshot / Evidence File:** Referenced in `midterm/evidence/designer/G07_F2_cascade_evidence.txt`.
- **Baseline Comparison:** Activity 4 documentation (`docs/user-roles.md` and `database/03_roles_and_privileges.sql`) explicitly stresses that `report_status_history` and `maintenance_action` represent "immutable audit logs" where `UPDATE` and `DELETE` must never be permitted. Implementing `ON DELETE CASCADE` at the schema level completely undermines this immutability guarantee.

---

### Impact

- **Compliance & Legal Liability (Critical):** Complete destruction of evidence and historical logs. If a safety incident escalates to an official campus inquiry, accident investigation, or insurance review, an administrator deleting an old hazard report permanently wipes out the proof of technician response times, parts replaced, and supervisory approvals.
- **Accidental Data Loss:** An unintended `DELETE FROM hazard_report WHERE ...` erases hundreds of associated operational records across 4 tables in a single transaction without warning or relational rejection.

---

### Severity

**High** (Confirmed Flaw)

---

### Recommended Fix

1. Drop the cascading foreign key constraints on dependent child tables and replace them with `ON DELETE RESTRICT` (or `NO ACTION`), preventing deletion of parent hazard reports as long as child audit records exist.
2. Implement an application-level **Soft Delete** pattern by adding `is_deleted BOOLEAN NOT NULL DEFAULT FALSE` and `deleted_at TIMESTAMP` columns to `hazard_report`.

```sql
-- Step 1: Replace CASCADE foreign keys with RESTRICT
ALTER TABLE assignment DROP CONSTRAINT assignment_report_id_fkey;
ALTER TABLE assignment ADD CONSTRAINT fk_assignment_report 
    FOREIGN KEY (report_id) REFERENCES hazard_report(report_id) ON DELETE RESTRICT;

ALTER TABLE report_status_history DROP CONSTRAINT report_status_history_fkey;
ALTER TABLE report_status_history ADD CONSTRAINT fk_status_history_report 
    FOREIGN KEY (report_id) REFERENCES hazard_report(report_id) ON DELETE RESTRICT;

ALTER TABLE maintenance_action DROP CONSTRAINT maintenance_action_fkey;
ALTER TABLE maintenance_action ADD CONSTRAINT fk_maintenance_report 
    FOREIGN KEY (report_id) REFERENCES hazard_report(report_id) ON DELETE RESTRICT;

ALTER TABLE attachment DROP CONSTRAINT attachment_report_id_fkey;
ALTER TABLE attachment ADD CONSTRAINT fk_attachment_report 
    FOREIGN KEY (report_id) REFERENCES hazard_report(report_id) ON DELETE RESTRICT;

-- Step 2: Implement Soft-Delete columns on hazard_report
ALTER TABLE hazard_report ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE hazard_report ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
```

---

### Verification

1. **Negative Test (Hard Delete Blocked):**
   ```sql
   DELETE FROM hazard_report WHERE report_id = 1;
   ```
   *Expected Result:* `ERROR: update or delete on table "hazard_report" violates foreign key constraint "fk_status_history_report" on table "report_status_history" (SQLSTATE 23503)`.
2. **Positive Test (Soft Delete Preserves All Audit History):**
   ```sql
   UPDATE hazard_report SET is_deleted = TRUE, deleted_at = CURRENT_TIMESTAMP WHERE report_id = 1;
   SELECT is_deleted, deleted_at FROM hazard_report WHERE report_id = 1;
   SELECT COUNT(*) FROM report_status_history WHERE report_id = 1;
   ```
   *Expected Result:* Parent report successfully flagged as deleted (`is_deleted: true`), while 100% of child audit rows in `report_status_history`, `assignment`, `maintenance_action`, and `attachment` remain intact.
