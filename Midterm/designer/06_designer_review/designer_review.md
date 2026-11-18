# Designer Review Report: Evaluation of Group 7 (CAMPUSAFE)

**Course:** COMP 018 — Database Administration  
**Designer Group:** Group 12 — iBarangay (Amoranto, Denielle; & Francisco, Helix)  
**Evaluated Owner Group:** Group 7 — CAMPUSAFE (Alba, Arreza, Orpesa, Robiso, Santos)  
**Evaluated Submission:** `grp07-campussafe/midterm/COMP018_MIDTERM_DOCUMENTATION_G07.md`  
**Review Date:** November 7, 2026  
**Assessment Phase:** Phase K — Designer Review Scorecard & Peer Feedback  

---

## 1. Executive Evaluation Summary

Group 12 has conducted a rigorous technical review of the owner investigation report, troubleshooting plans, and corrective SQL scripts submitted by Group 7 (CampusSafe) in response to the five incidents designed for their system (`G07-INC1` through `G07-INC5`).

Overall, Group 7 demonstrated exemplary database administration discipline, methodical root-cause reasoning, and proportionate remediation on an isolated disposable test database (`campussafe_midterm_test` on PostgreSQL 18). All five incident scenarios were resolved cleanly, accompanied by comprehensive negative constraint tests and positive regression verification.

---

## 2. Incident-by-Incident Evaluation Scorecard

### Incident 1: G07-INC1 (Excessive UPDATE Privileges on `app_user`)
- **Assigned Difficulty & Time:** Easy &bull; 15 Minutes
- **Reported Symptoms:** Application runtime account modifies user roles or account statuses without authorization.
- **Group 7 Owner Finding:** Confirmed that `app_runtime_grp` held table-wide `UPDATE` on `app_user` in `database/03_roles_and_privileges.sql`.
- **Group 7 Corrective Action:** Executed `midterm/owner/scripts/fixes/fix_inc1_role_privilege.sql`, revoking table-wide UPDATE and granting column-level UPDATE strictly on `(full_name, email, password_hash)`.
- **Group 7 Verification:**
  - Negative Test: `UPDATE app_user SET role = 'admin' WHERE user_id = 2;` $\rightarrow$ Denied with `SQLSTATE 42501` (**PASS**).
  - Positive Test: `UPDATE app_user SET full_name = 'Updated User Name' WHERE user_id = 2;` $\rightarrow$ Succeeded with `UPDATE 1` (**PASS**).
- **Designer Classification:** **Solved as Intended**
- **Designer Analysis:** Group 7 executed the exact least-privilege remediation specified in our private answer key. Their diagnostic query on `information_schema.table_privileges` was accurate, and their rollback plan was sound.

---

### Incident 2: G07-INC2 (Cascading Deletions Purging Compliance Audit History)
- **Assigned Difficulty & Time:** Medium &bull; 25 Minutes
- **Reported Symptoms:** Administrator deletes a hazard report, causing associated status history, maintenance actions, assignments, and uploaded evidence to disappear.
- **Group 7 Owner Finding:** Confirmed that foreign keys in child relations were configured with `confdeltype = 'c'` (`ON DELETE CASCADE`).
- **Group 7 Corrective Action:** Executed `midterm/owner/scripts/fixes/fix_inc2_cascade_restrict.sql`, altering foreign keys on `report_status_history`, `maintenance_action`, `assignment`, and `attachment` to `ON DELETE RESTRICT`, and adding soft-delete columns `is_deleted` and `deleted_at` to `hazard_report`.
- **Group 7 Verification:**
  - Negative Test: `DELETE FROM hazard_report WHERE report_id = 1;` $\rightarrow$ Denied with `SQLSTATE 23503` (**PASS**).
  - Positive Test: Soft-delete update preserved 100% of child rows (**PASS**).
- **Designer Classification:** **Solved as Intended**
- **Designer Analysis:** Exceptional DBA judgment. Group 7 rightly recognized that compliance records must never be hard-deleted and implemented both the relational guardrail (`RESTRICT`) and the application architectural pattern (`Soft Delete`).

---

### Incident 3: G07-INC3 (Missing Database Trigger for Status History Auditing)
- **Assigned Difficulty & Time:** Medium &bull; 25 Minutes
- **Reported Symptoms:** Direct SQL updates to report status bypass the historical audit trail in `report_status_history`.
- **Group 7 Owner Finding:** Confirmed that `pg_trigger` catalog held zero status change triggers on `hazard_report`, leaving direct database updates unlogged.
- **Group 7 Corrective Action:** Executed `midterm/owner/scripts/fixes/fix_inc3_status_trigger.sql`, building an automated PL/pgSQL function `trg_log_hazard_status_change()` and attaching an `AFTER UPDATE OF status` trigger `trg_hazard_report_status_audit` to `hazard_report`.
- **Group 7 Verification:**
  - Positive Test: Direct SQL update `UPDATE hazard_report SET status = 'IN_PROGRESS' WHERE report_id = 1;` automatically populated `report_status_history` with old status, new status, and timestamp (**PASS**).
- **Designer Classification:** **Solved as Intended**
- **Designer Analysis:** Implemented with high technical precision. The trigger correctly checks `OLD.status IS DISTINCT FROM NEW.status`, preventing redundant rows on non-status updates.

---

### Incident 4: G07-INC4 (Missing Composite Unique Constraint on Physical Locations)
- **Assigned Difficulty & Time:** Easy / Medium &bull; 20 Minutes
- **Reported Symptoms:** Administrators encounter duplicate dropdown entries representing the same physical building, floor, and room.
- **Group 7 Owner Finding:** Confirmed that `campus_location` relied solely on surrogate PK `location_id` and lacked candidate key uniqueness.
- **Group 7 Corrective Action:** Executed `midterm/owner/scripts/fixes/fix_inc4_unique_location.sql`. Used an advanced window function (`FIRST_VALUE`) to re-point child references in `hazard_report`, deleted duplicate location records, and added `UNIQUE (building, floor, room)`.
- **Group 7 Verification:**
  - Negative Test: Inserting duplicate location rows failed with `SQLSTATE 23505` (**PASS**).
- **Designer Classification:** **Solved as Intended**
- **Designer Analysis:** Outstanding execution. Re-pointing foreign keys prior to purging duplicate parent rows demonstrated advanced SQL proficiency and prevented relational constraint aborts.

---

### Incident 5: G07-INC5 (Missing Conditional Priority Requirement on Verified Reports)
- **Assigned Difficulty & Time:** Easy &bull; 15 Minutes
- **Reported Symptoms:** Maintenance personnel encounter verified hazard reports without assigned priority ratings.
- **Group 7 Owner Finding:** Confirmed that `priority` was declared nullable without state-dependent check constraints.
- **Group 7 Corrective Action:** Executed `midterm/owner/scripts/fixes/fix_inc5_priority_check.sql`, backfilling existing verified nulls with `'MEDIUM'` and adding check constraint `CHECK (status <> 'VERIFIED' OR priority IS NOT NULL)`.
- **Group 7 Verification:**
  - Negative Test: Updating a report to `'VERIFIED'` with `priority = NULL` failed with `SQLSTATE 23514` (**PASS**).
  - Positive Test: Updating with valid priority succeeded with `UPDATE 1` (**PASS**).
- **Designer Classification:** **Solved as Intended**
- **Designer Analysis:** Clean, proportionate correction. The backfill step before constraint creation avoided `check_violation` failures on existing rows.

---

## 3. Overall Designer Assessment & Rubric Scorecard

| Assessment Dimension | Evaluator Feedback | Rating |
|---|---|:---:|
| **Diagnostic Accuracy** | Identified exact root causes across all 5 scenarios without guessing or executing unwarranted reboots. | 10 / 10 |
| **Troubleshooting Discipline** | Followed the 8-step DBA workflow; documented ordered checks, hypotheses, and rollback options prior to executing fixes. | 10 / 10 |
| **Proportionate Remediation** | Applied smallest justified fixes on disposable copies; avoided superuser crutches or destructive workarounds. | 10 / 10 |
| **Verification & Regression** | Executed comprehensive negative tests (confirming security denials) and positive regression tests. | 10 / 10 |
| **Preventive Judgment** | Formulated realistic, forward-looking architectural recommendations for CI/CD checks, soft deletion, and engine triggers. | 10 / 10 |
| **Total Evaluated Score** | **Exemplary Peer Defense Execution** | **50 / 50** |

---

## 4. Formal Peer Feedback Sent to Group 7 (CampusSafe)

**To:** Group 7 — CAMPUSAFE (Jefferson Orpesa Lead, Alba, Arreza, Robiso, Santos)  
**From:** Group 12 — iBarangay (Helix Francisco Lead, Denielle Amoranto)  
**Date:** November 7, 2026  

### Commendations:
1. **Flawless Remediation Execution:** Your team analyzed all five public incident briefs and identified the intended underlying causes without ambiguity. Your corrective scripts in `midterm/owner/scripts/fixes/` are robust, idempotent, and production-ready.
2. **Advanced SQL Proficiency:** The window function CTE used in `fix_inc4_unique_location.sql` to gracefully deduplicate physical rooms while preserving referential integrity was brilliant.
3. **Immutability Defense:** Your response to the cascading deletion flaw (`G07-INC2`) demonstrated a mature understanding of compliance auditing by implementing soft-deletion rather than simply leaving data vulnerable.

### Recommendations for Future Production Releases:
1. **Automate Global Role Backups:** While your Activity 6 `01_backup.ps1` script performs excellent custom database archives (`pg_dump -Fc`), incorporate `pg_dumpall --globals-only` to ensure cluster-level roles (`campussafe_app`, `campussafe_report`, `campussafe_backup`) are automatically archived for true bare-metal recovery drills.
2. **Pre-defined Reading Roles:** For future PostgreSQL 14+ deployments, grant `pg_read_all_data` to `app_backup_grp` to make your automated backup service resilient against future schema migrations.
