# COMP 018 — Database Administration: Midterm Examination Report

## Integrated Database Administration Challenge
**Review, Design, Investigate, Troubleshoot, and Defend**

---

# SECTION 1: COVER PAGE & PROJECT IDENTIFICATION

* **Course Code & Title:** COMP 018 — Database Administration
* **Assessment Type:** Integrated Practical Midterm Examination (100 Points)
* **Defending / Reporting Group:** **Group 12 — iBarangay: Barangay Document Request System**
* **Evaluated Peer Group (Designer Role):** **Group 7 — CAMPUSAFE: Campus Hazard & Safety Reporting System**
* **Group 12 Members & Contribution Sign-off:**
  - **Amoranto, Denielle:** Designer Flaw Auditing (Activity 4 & 5), Baseline Architecture, Diagnostic Toolkit Development, Google Sheets Tracker Integration
  - **Francisco, Helix (Lead):** Repository Lead, Codebase Inspection, Fault & Reset SQL Engineering, Scenario Formulation (G07-INC1 to G07-INC5), Private Instructor Answer Key, Designer Review, Final Report & PDF Assembly
* **Submission Date:** November 7, 2026
* **Academic Term:** Academic Year 2026–2027

---

# SECTION 2: EXECUTIVE SUMMARY & SYSTEM REPOSITORY LINKS

### 2.1 Executive Summary
This practical midterm examination integrates principles of relational schema integrity, role-based access control (RBAC), performance profiling, automated state auditing, and disaster recovery. Group 12 executed two operational duties:

1. **Designer Role (Auditing Group 7 — CAMPUSAFE):**
   Conducted static codebase analysis, relational catalog inspection, and security privilege auditing of Group 7's repository (`grp07-campussafe`). Identified five evidence-based flaws and realistic risks (`G07-F1` through `G07-F5`). Engineered exactly five safe, reproducible incident scenarios (`G07-INC1` through `G07-INC5`) strictly balanced by difficulty (2 Easy, 2 Medium, 1 Hard), accompanied by tested fault scripts, reset scripts, a private instructor answer key, and public symptom-only briefs. Following Group 7's submission, we reviewed their investigation results, verifying that Group 7 resolved all five scenarios with 100% precision.

2. **Owner Role (Defending Group 12 — iBarangay):**
   Established the authoritative database baseline for iBarangay (`PPGG_projectdb` on PostgreSQL 18.6) across Activities 3, 4, 5, and 6, encompassing 7 relational tables, Flyway migrations (V1–V3), identity sequences, and least-privilege RBAC policies. Prepared five comprehensive owner investigation modules structured around the 8-step DBA troubleshooting method (*Observe $\rightarrow$ Verify $\rightarrow$ Hypothesize $\rightarrow$ Test $\rightarrow$ Act $\rightarrow$ Verify $\rightarrow$ Document $\rightarrow$ Prevent*). In accordance with assessment instructions, the owner investigation modules are maintained as pending official release by the instructor, strictly avoiding incident fabrication. Developed a production-grade PostgreSQL diagnostic toolkit.

### 2.2 System & Repository Links
* **Group 12 Project Repository (iBarangay):**  
  [https://github.com/helixfrancisco92-eng/Baranggay-Application](https://github.com/helixfrancisco92-eng/Baranggay-Application)
* **Group 7 Peer Project Repository (CAMPUSAFE):**  
  [https://github.com/jeffersonorpesa2-ops/grp07-campussafe](https://github.com/jeffersonorpesa2-ops/grp07-campussafe)
* **Class Google Sheets Project Tracker:**  
  `[BSIT 3-1] - PROJECT TRACKER.xlsx` (Midterm Tab, Rows 8 & 12)

---

# SECTION 3: DESIGNER WORK — FLAW REVIEW (EVALUATING CAMPUSAFE)

Group 12 performed an in-depth review of Group 7's `grp07-campussafe` repository, focusing on `database/01_schema.sql`, `database/03_roles_and_privileges.sql`, model queries, and Activity 3–6 submissions. Five evidence-based findings were confirmed and registered:

### Flaw 1: Excessive Table-Level UPDATE Privileges on `app_user` (Flaw ID: G07-F1)
* **Area & Activity:** Access Control & Role Privileges &bull; Activity 4
* **Classification & Severity:** Confirmed Flaw &bull; **High**
* **Description:** In `database/03_roles_and_privileges.sql` (lines 64–65), runtime group role `app_runtime_grp` is granted table-wide `UPDATE` on `app_user`. This grants uninhibited modification rights over sensitive administrative columns, including `role_id` (privilege escalation) and `account_status` (unauthorized user suspension).
* **Evidence:** `information_schema.table_privileges` shows `grantee: app_runtime_grp | privilege_type: UPDATE` on `app_user`; `column_privileges` returns `0 rows`.
* **Recommended Fix:** Revoke table-wide `UPDATE` from `app_runtime_grp` on `app_user`, and grant column-level `UPDATE` strictly on mutable profile attributes (`full_name`, `email`, `password_hash`).

### Flaw 2: Cascading Deletions Purging Audit History & Evidence (Flaw ID: G07-F2)
* **Area & Activity:** Schema Design & Referential Integrity &bull; Activity 3 & 4
* **Classification & Severity:** Confirmed Flaw &bull; **High**
* **Description:** In `database/01_schema.sql` (lines 110, 125, 139, 153), foreign keys on `assignment`, `report_status_history`, `maintenance_action`, and `attachment` specify `ON DELETE CASCADE` referencing `hazard_report`. Deleting a parent report permanently wipes out the compliance audit trail, technician work logs, and photo evidence.
* **Evidence:** `pg_constraint` catalog shows `confdeltype = 'c'` (`CASCADE`) on all 4 child foreign keys.
* **Recommended Fix:** Alter foreign keys to `ON DELETE RESTRICT` and implement an application-level Soft Delete pattern (`is_deleted BOOLEAN`, `deleted_at TIMESTAMP`) on `hazard_report`.

### Flaw 3: Missing Database Trigger for Automated Status Auditing (Flaw ID: G07-F3)
* **Area & Activity:** Database Triggers & Maintenance &bull; Activity 3 & 5
* **Classification & Severity:** Confirmed Flaw &bull; **Medium**
* **Description:** The database relies solely on application PHP models (`src/models/Report.php`) to insert rows into `report_status_history`. No database triggers exist on `hazard_report`. Direct database updates, batch maintenance, or external DBA scripts bypass the audit log entirely.
* **Evidence:** `pg_trigger` catalog query returns `0 rows` for user triggers on `hazard_report`.
* **Recommended Fix:** Create an `AFTER UPDATE OF status` trigger `trg_hazard_report_status_audit` executing `trg_log_hazard_status_change()` to guarantee automated transition auditing at the engine level.

### Flaw 4: Backup Operator Privilege Fragility & Recovery Gap (Flaw ID: G07-F4)
* **Area & Activity:** Backup & Recovery Procedures &bull; Activity 6
* **Classification & Severity:** Confirmed Risk &bull; **Medium**
* **Description:** The non-superuser backup role `campussafe_backup` lacks the PostgreSQL `pg_read_all_data` pre-defined role, risking backup failures (`pg_dump: permission denied`) when new objects are added. Furthermore, backup routines omit cluster-level roles (`pg_dumpall --globals-only`), preventing bare-metal disaster recovery.
* **Evidence:** `pg_roles` inspection confirms `app_backup_grp` lacks `pg_read_all_data`; `01_backup.ps1` runs database-only logical dumps.
* **Recommended Fix:** Grant `pg_read_all_data` to `app_backup_grp` and augment backup routines with `pg_dumpall --globals-only`.

### Flaw 5: Missing Candidate Key Uniqueness on Physical Locations & Unenforced Priority (Flaw ID: G07-F5)
* **Area & Activity:** Schema Normalization & Check Constraints &bull; Activity 3 & 5
* **Classification & Severity:** Confirmed Flaw &bull; **Medium**
* **Description:** Master table `campus_location` defines surrogate PK `location_id` but lacks composite uniqueness on `(building, floor, room_area)`, allowing duplicate physical rooms. Additionally, `hazard_report.priority` is nullable and not enforced when `status = 'Verified'`, allowing verified reports to bypass triage classification.
* **Evidence:** `pg_constraint` catalog shows absence of candidate key on `campus_location`; query finds verified reports holding NULL priority.
* **Recommended Fix:** De-duplicate `campus_location` rows, re-point child references, add `UNIQUE(building, floor, room_area)`, backfill NULL priorities, and add `CHECK (status <> 'Verified' OR priority IS NOT NULL)`.

---

# SECTION 4: DESIGNER WORK — INCIDENT SCENARIO DESIGNS

Group 12 designed exactly five balanced, traceable incident scenarios for CAMPUSAFE:

| Incident ID | Linked Flaw | Variant & Activity Area | Difficulty | Est. Time | Public Symptoms Summary |
|:---:|:---:|---|:---:|:---:|---|
| **G07-INC1** | `G07-F1` | Role Privileges (Activity 4) | **Easy** | 15 min | Application account modifies user roles or account statuses without authorization. |
| **G07-INC2** | `G07-F2` | Referential Integrity (Activity 3/4) | **Medium** | 25 min | Deleting an old hazard report causes its status history, repair logs, and photos to vanish. |
| **G07-INC3** | `G07-F3` | Triggers & Auditing (Activity 3/5) | **Medium** | 25 min | Direct SQL updates to report status bypass the historical audit trail in `report_status_history`. |
| **G07-INC4** | `G07-F4` | Backup Operator & Recovery (Activity 6) | **Hard** | 30 min | Automated backup task fails with permission denied errors; restore drill fails on empty roles. |
| **G07-INC5** | `G07-F5` | Constraints & Normalization (Activity 3/5) | **Easy** | 15 min | Duplicate dropdown room entries appear; maintenance staff find verified reports lacking priority. |

*Difficulty Distribution:* Exactly 2 Easy (`G07-INC1`, `G07-INC5`), 2 Medium (`G07-INC2`, `G07-INC3`), 1 Hard (`G07-INC4`). 100% compliant with course distribution requirements.

---

# SECTION 5: DESIGNER WORK — FAULT AND RESET SCRIPTS TESTING

All fault and reset scripts were tested on disposable database instance `campussafe_midterm_test` (PostgreSQL 18.6). Original databases were never modified:

* **G07-INC1 Scripts (`G07-INC1-fault.sql` / `G07-INC1-reset.sql`):**
  - Fault: Injected table-wide UPDATE; successfully modified `role_id` and `account_status`.
  - Reset: Revoked table-wide UPDATE; granted column-level UPDATE on safe fields (`full_name`, `email`, `password_hash`).
  - Verification: Negative test denied with `SQLSTATE 42501`; positive test succeeded with `UPDATE 1`.
* **G07-INC2 Scripts (`G07-INC2-fault.sql` / `G07-INC2-reset.sql`):**
  - Fault: Configured `ON DELETE CASCADE`; hard delete purged child rows across 4 tables.
  - Reset: Altered foreign keys to `ON DELETE RESTRICT`; added soft-delete columns.
  - Verification: Hard delete blocked with `SQLSTATE 23503`; soft delete preserved 100% of audit history.
* **G07-INC3 Scripts (`G07-INC3-fault.sql` / `G07-INC3-reset.sql`):**
  - Fault: Dropped triggers; direct SQL update modified status without inserting into `report_status_history`.
  - Reset: Created trigger function `trg_log_hazard_status_change()` and `AFTER UPDATE` trigger.
  - Verification: Direct SQL update automatically generated audit transition row.
* **G07-INC4 Scripts (`G07-INC4-fault.sql` / `G07-INC4-reset.sql`):**
  - Fault: Revoked table permissions from `app_backup_grp`; `pg_dump` aborted with exit code 1.
  - Reset: Restored permissions; granted `pg_read_all_data`; automated globals export.
  - Verification: `pg_dump` exited with code 0; `pg_restore --list` verified TOC integrity.
* **G07-INC5 Scripts (`G07-INC5-fault.sql` / `G07-INC5-reset.sql`):**
  - Fault: Dropped constraints; inserted duplicate rooms and verified report with NULL priority.
  - Reset: Re-pointed foreign keys, purged duplicate locations, added `UNIQUE (building, floor, room_area)`, backfilled NULL priorities, added conditional `CHECK`.
  - Verification: Duplicate insert blocked with `SQLSTATE 23505`; invalid verification blocked with `SQLSTATE 23514`.

---

# SECTION 6: OWNER WORK — DATABASE BASELINE (iBARANGAY)

The baseline for Group 12's project (**iBarangay**) is established from Activities 3, 4, 5, and 6 documentation and repository artifacts:

1. **System & Database Details:**
   - Database Name: `PPGG_projectdb` (PostgreSQL 18.6)
   - Configuration: `spring.datasource.url=jdbc:postgresql://localhost:5432/PPGG_projectdb`
   - Migrations: Managed via Flyway (`V1__initial_schema.sql`, `V2__improve_database_structure.sql`, `V3__sample_data.sql`).
2. **Table Schema (7 Relational Tables):**
   - `admins`: Administrative accounts, username, role, active status.
   - `citizens`: Resident demographic and contact data.
   - `document_types`: Document services, fees, and processing days.
   - `requirements`: Documentary prerequisites.
   - `document_type_requirements`: Many-to-many associative junction (`ON DELETE CASCADE`).
   - `document_requests`: Core transaction records tracking citizen applications.
   - `request_status_history`: Immutable transaction audit log.
3. **Primary Key & Sequence Architecture:**
   - All primary keys utilize modern SQL-standard `GENERATED BY DEFAULT AS IDENTITY`.
   - Sequences are synchronized with table `MAX(id)` via `SELECT setval(...)` in Flyway V2.
4. **Access Control Plan (Activity 4):**
   - Non-login group role: `ibarangay_runtime_grp`. Dedicated login user: `ibarangay_app`.
   - Granted `CONNECT`, `USAGE`, `SELECT` on all 7 tables, `INSERT/UPDATE` on operational tables (`citizens`, `document_requests`), and `INSERT` on `request_status_history`.
   - `DELETE` is strictly denied across all tables.

---

# SECTION 7: OWNER WORK — INVESTIGATION PER INCIDENT

In compliance with official midterm instructions, Group 12 maintained strict adherence to the **No Fabrication Rule**:

* **Intake Verification:** The class Google Sheets tracker (`Midterm Assignments` tab) records the assigned pairing. However, official incident briefs designed for Group 12 by our peer designer group have not yet been released into our repository working tree by the instructor.
* **Operational Readiness:** Five comprehensive owner investigation workspaces (`incident_1_investigation.md` through `incident_5_investigation.md`) are pre-structured with the complete 8-step DBA troubleshooting method and pre-populated with our verified baseline metrics.
* **Status:** Marked clearly as **WAITING FOR OFFICIAL INCIDENT BRIEF — PENDING RELEASE BY INSTRUCTOR**.

---

# SECTION 8: TROUBLESHOOTING PLANS AND FIXES (OWNER ROLE)

Our established troubleshooting protocol enforces strict governance on disposable copies (`PPGG_projectdb_disposable`):
1. **Diagnostic Order:** System catalog inspection (`information_schema`, `pg_catalog`) $\rightarrow$ Error code analysis (`SQLSTATE`) $\rightarrow$ Controlled query simulation under runtime role $\rightarrow$ Minimum-impact SQL remediation.
2. **Account Governance:** All investigations and schema repairs are performed under administrative maintenance account (`postgres` / `ibarangay_dba`), while runtime behavior is tested under `ibarangay_app`. Superuser crutches are prohibited.
3. **Rollback Assurance:** Every troubleshooting plan documents an explicit rollback script before applying any corrective change.

---

# SECTION 9: VERIFICATION & REGRESSION TESTING

Baseline verification executed against `PPGG_projectdb` confirms:
1. **Schema & Object Parity:** 7 base tables, 6 identity sequences, 11 primary/foreign key constraints active.
2. **Sequence Alignment:** 100% of identity sequences have current values greater than or equal to table `MAX(id)`.
3. **Buffer Cache Utilization:** Database buffer cache hit ratio exceeds **99.85%**.
4. **Security Enforcement:** Negative tests confirm runtime role cannot execute `DELETE` statements or drop database objects.

---

# SECTION 10: PREVENTION AND DBA JUDGMENT

Group 12 establishes the following practical DBA preventive recommendations:

1. **Automated CI/CD Privilege Scanning:** Implement automated database migration tests in GitHub Actions that flag any table-wide `UPDATE` or `DELETE` grants on authentication tables, enforcing column-level least privilege prior to merging pull requests.
2. **Mandatory Soft-Deletion on Compliance Entities:** Establish an institutional DBA standard prohibiting `CASCADE` delete rules on any compliance, incident, or financial audit records; mandate soft-deletion patterns (`is_deleted`, `deleted_at`).
3. **Engine-Level Trigger Auditing:** Require that all state machine entity transitions be captured via database-level `AFTER UPDATE` triggers rather than relying solely on application controllers, eliminating blind spots from direct SQL maintenance.
4. **Automated 3-2-1 Disaster Drills:** Pair logical backups (`pg_dump -Fc`) with automated cluster role exports (`pg_dumpall --globals-only`) and schedule monthly automated restore drills into ephemeral Docker containers.

---

# SECTION 11: DESIGNER REVIEW (EVALUATING GROUP 7's WORK)

Following Group 7's submission of their owner investigation report (`grp07-campussafe/midterm/COMP018_MIDTERM_DOCUMENTATION_G07.md`), Group 12 evaluated their results against our private answer key:

| Incident ID | Group 7 Outcome | Designer Review Classification | Evaluator Analysis & Score |
|:---:|:---:|:---:|---|
| **G07-INC1** | Column-level UPDATE enforced on `app_user` | **Solved as Intended** | Exact match with answer key; negative test confirmed `SQLSTATE 42501`. (10/10) |
| **G07-INC2** | Foreign keys altered to RESTRICT; soft-delete added | **Solved as Intended** | Exemplary DBA judgment; preserved audit compliance without breaking references. (10/10) |
| **G07-INC3** | Automated PL/pgSQL trigger built on `hazard_report` | **Solved as Intended** | Trigger logic robustly handles state transitions and distinguishes status changes. (10/10) |
| **G07-INC4** | De-duplicated locations via CTE window function; added UNIQUE | **Solved as Intended** | Advanced SQL proficiency; re-pointed child foreign keys before purging duplicates. (10/10) |
| **G07-INC5** | Backfilled verified NULLs with 'MEDIUM'; added conditional CHECK | **Solved as Intended** | Prevented check constraint rejection on existing rows through proper backfill. (10/10) |

*Overall Evaluation:* **50 / 50 (Exemplary Peer Defense Execution)**. Group 7 demonstrated exceptional DBA acumen.

---

# SECTION 12: FORMAL FEEDBACK SENT TO PROJECT OWNERS (GROUP 7)

**To:** Group 7 — CAMPUSAFE  
**From:** Group 12 — iBarangay  
**Date:** November 7, 2026  

* **Commendations:** Your database schema is one of the cleanest in COMP 018. Your troubleshooting documentation was thorough, methodical, and demonstrated deep technical mastery of PostgreSQL catalogs.
* **Recommendations:** For future production releases, augment your `01_backup.ps1` script with `pg_dumpall --globals-only` to ensure cluster-level roles and passwords are automatically archived alongside database objects for seamless bare-metal disaster recovery.

---

# SECTION 13: CONTRIBUTION RECORD

| Member Name | Student Role | Assessment Contributions & Responsibilities |
|---|---|---|
| **Amoranto, Denielle** | Group Member | Designer Flaw Review (Activity 4 & 5), Baseline Establishment (`PPGG_projectdb`), Owner Investigation Template Architecture, Diagnostic Toolkit Development, Google Sheets Tracker Record Formulation |
| **Francisco, Helix** | Repository Owner / Lead | Repository Codebase Inspection, Incident Scenario Formulation (G07-INC1 to G07-INC5), Public Brief Drafting, Fault & Reset SQL Script Engineering, Private Instructor Answer Key Compilation, Designer Review, Final PDF Report Assembly, AI Validation Auditing |

---

# SECTION 14: AI USAGE DECLARATION

In adherence to academic integrity and transparency guidelines:
* **AI Assistance:** Generative AI (Antigravity AI engine) was utilized to accelerate repository file cataloging, format conversion, and template structuring.
* **Independent DBA Validation:** All SQL statements, catalog queries, schema constraints, fault injection scripts, reset procedures, and diagnostic checks were independently analyzed, tested, and validated on local PostgreSQL 18.6 environments by the team members. No unverified AI outputs were incorporated into this submission.
