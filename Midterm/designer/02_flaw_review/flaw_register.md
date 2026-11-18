# CAMPUSAFE Flaw Register (Master Record)

**Project Owner:** Group 7 — CAMPUSAFE: Campus Hazard & Safety Reporting System  
**Evaluating Group:** Group 12 — iBarangay  
**Target Repository:** `https://github.com/jeffersonorpesa2-ops/grp07-campussafe`  
**Target Database:** `grp07_campussafedb`  
**Registration Date:** November 7, 2026  
**Assessment Phase:** Phase B — Designer Flaw Review  

---

## 1. Master Flaw Register Table

| Flaw ID | Project | Reported By | Area | Related Activity | Description | Evidence Reference | Classification | Severity | Recommended Fix | Owner Status |
|:---:|---|:---:|---|:---:|---|---|:---:|:---:|---|:---:|
| **G07-F1** | Group 7 – CAMPUSAFE | Group 12 | Privileges & Access Control | Activity 4 | The application runtime database role (`app_runtime_grp` / `campussafe_app`) holds full table-level `UPDATE` privileges on `app_user`, allowing modification of sensitive security attributes including `role_id` (privilege escalation) and `account_status` without administrative authorization. | `database/03_roles_and_privileges.sql` (Lines 64–65)<br>`information_schema.table_privileges`<br>Query output showing `grantee: app_runtime_grp \| privilege_type: UPDATE` | Confirmed Flaw | High | Revoke whole-table `UPDATE` on `app_user` from `app_runtime_grp` and grant column-level `UPDATE` strictly on non-sensitive profile attributes (`full_name`, `email`, `password_hash`). | **Fixed** |
| **G07-F2** | Group 7 – CAMPUSAFE | Group 12 | Schema & Referential Integrity | Activity 3 & 4 | Schema foreign key constraints on dependent child tables (`report_status_history`, `maintenance_action`, `assignment`, and `attachment`) specify `ON DELETE CASCADE` referencing `hazard_report`. Deleting a parent report permanently wipes out the entire compliance audit trail, technician work logs, and photo evidence. | `database/01_schema.sql` (Lines 110, 125, 139, 153)<br>`pg_constraint` catalog inspection showing `confdeltype: 'c'` on all 4 child foreign keys | Confirmed Flaw | High | Reconfigure foreign keys to `ON DELETE RESTRICT` on compliance child tables, and implement an application-level soft-delete mechanism (`is_deleted BOOLEAN`, `deleted_at TIMESTAMP`) on `hazard_report`. | **Fixed** |
| **G07-F3** | Group 7 – CAMPUSAFE | Group 12 | Triggers, Maintenance & Performance | Activity 3 & 5 | The database relies solely on application PHP controllers to insert status history records into `report_status_history`, omitting an automated database trigger on `hazard_report`. Direct database updates, batch maintenance, or external DBA scripts bypass the audit log entirely. | `database/01_schema.sql`<br>`pg_trigger` catalog query returning `0 rows` for user-defined triggers on `hazard_report`<br>`src/models/Report.php` application logic | Confirmed Flaw | Medium | Create an `AFTER UPDATE OF status` trigger `trg_hazard_report_status_audit` executing a trigger function `trg_log_hazard_status_change()` to guarantee automated transition auditing at the engine level. | **Fixed** |
| **G07-F4** | Group 7 – CAMPUSAFE | Group 12 | Backup, Recovery & Disaster Readiness | Activity 6 | The non-superuser backup role `campussafe_backup` (`app_backup_grp`) lacks the standard PostgreSQL `pg_read_all_data` pre-defined role, risking backup failures (`pg_dump: permission denied`) when new objects or schemas are added. Furthermore, the backup procedure omits global cluster role export (`pg_dumpall --globals-only`), preventing bare-metal recovery. | `database/03_roles_and_privileges.sql` (Lines 80–84)<br>`campusafe/01_backup.ps1` (Line 86)<br>`pg_roles` inspection showing missing `pg_read_all_data` grant | Risk | Medium | Grant pre-defined role `pg_read_all_data` to `app_backup_grp` / `campussafe_backup`. Augment the automated backup suite with `pg_dumpall --globals-only` to archive global roles and credentials. | **Acknowledged** |
| **G07-F5** | Group 7 – CAMPUSAFE | Group 12 | Schema Normalization & Check Constraints | Activity 3 & 5 | Master table `campus_location` lacks a composite `UNIQUE` constraint on `(building, floor, room_area)`, allowing duplicate physical location records to proliferate. Additionally, `hazard_report.priority` is nullable and not enforced when `status = 'Verified'`, allowing verified reports to bypass triage classification. | `database/01_schema.sql` (Lines 66–73, 87–90)<br>`pg_constraint` catalog showing absence of candidate key on `campus_location`<br>`SELECT COUNT(*) FROM hazard_report WHERE status = 'Verified' AND priority IS NULL` | Confirmed Flaw | Medium | Cleanse duplicate location rows, re-point child `hazard_report.location_id` references, and add `UNIQUE(building, floor, room_area)` to `campus_location`. Backfill null priorities and add `CHECK (status <> 'Verified' OR priority IS NOT NULL)` to `hazard_report`. | **Fixed** |

---

## 2. Flaw Traceability Matrix to Assessment Incidents

| Flaw ID | Mapped Incident ID | Incident Classification | Primary Activity Area | Assigned Difficulty | Target Resolution Time |
|:---:|:---:|---|---|:---:|:---:|
| **G07-F1** | `G07-INC1` | Privilege Escalation & Excessive UPDATE on `app_user` | Activity 4 (Access Control & Least Privilege) | **Easy** | 15 Minutes |
| **G07-F2** | `G07-INC2` | Cascading Deletion Purging Compliance Audit History | Activity 3 & 4 (Referential Integrity & Schema) | **Medium** | 25 Minutes |
| **G07-F3** | `G07-INC3` | Bypassed State Transition Audit Logging (Missing Trigger) | Activity 3 & 5 (Triggers, Auditing & Maintenance) | **Medium** | 25 Minutes |
| **G07-F4** | `G07-INC4` | Automated Backup Operator Permission Fragility & Recovery Gap | Activity 6 (Disaster Recovery & Backup Operator) | **Hard** | 30 Minutes |
| **G07-F5** | `G07-INC5` | Duplicate Physical Locations & Missing Verification Priority | Activity 3 & 5 (Schema Normalization & Constraints) | **Easy** | 15 Minutes |
