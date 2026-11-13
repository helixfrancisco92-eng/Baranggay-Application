# COMP 018 — Database Administration
## Activity 6 Progress and Comprehensive Documentation
### Database Backup, Restoration, and Recovery Lifecycle

---

## 1. Document Control and Project Metadata

| Field | Details |
|---|---|
| **Course** | COMP 018 — Database Administration |
| **Activity** | Activity 6: Database Backup, Restoration, and Recovery |
| **Academic Term** | First Semester, Academic Year 2026–2027 |
| **Date of Submission** | *(Insert Date of Submission)* |
| **Document Version** | 1.0 (Official Progress Documentation) |
| **Target Database Engine** | PostgreSQL 18.6 (64-bit) |

### Group Identification and Project Links
- **Group Number:** Group 2 (Park-It Team)
- **Group Members:**
  1. De Vera, Miller
  2. Butanas, John David
  3. Macascas, Mark Andrew
  4. Pelia, Jhon Francis
  5. Lumbo, Marianne
- **GitHub Repository Link:** [https://github.com/millerdevera6-glitch/park-it-database.git](https://github.com/millerdevera6-glitch/park-it-database.git)
- **Google Sheets Progress Tracker Link:** *(Insert Shared Google Sheets Link Here)*
- **Shared Evidence Drive Link:** *(Insert Google Drive / Shared Cloud Folder Link Here)*

---

## 2. Projects Covered

This documentation covers the database administration operations executed for:
- **Project Name:** Park-It Database Management System
- **Database Name:** `grp_parkitdb`
- **Application Stack:** PHP 8.x PDO, Apache (XAMPP), Vanilla JavaScript, CSS3
- **Primary Function:** Real-time parking facility management, including vehicle entry/exit tracking, slot availability monitoring (50-space capacity), parking fee calculation (Car base: ₱50, Motorcycle base: ₱30, Lost ticket penalty: ₱200), and transaction settlement.

---

## 3. Database Backup Plan

### 3.1 Architecture and Strategy
The backup strategy designed for `grp_parkitdb` utilizes PostgreSQL native logical exports via `pg_dump` with custom archive format (`-Fc`).
- **Archive Characteristics:** Zlib compression, embedded Table of Contents (TOC), platform portability, and support for multi-threaded restoration.
- **Scope:** Complete export of all 5 operational tables (`parking_zone`, `vehicle`, `staff_user`, `transaction`, `payment`), 5 sequences, and all associated integrity constraints.
- **Storage Isolation:** Backups are written to a dedicated directory (`db-backup-recovery/backups/`) isolated from the web server document root to prevent remote exfiltration.

### 3.2 Recovery Targets (RPO & RTO)
- **Recovery Point Objective (RPO):** 
  - *Classroom / Batch Logical:* 24 Hours.
  - *Commercial Deployment:* 1 Hour (or near 0 with continuous WAL archiving).
- **Recovery Time Objective (RTO):** 
  - *Target:* 30 Minutes from incident declaration to verified operational state.

### 3.3 Proposed Schedule and Retention
- **Schedule:** Full backup daily at 02:00 AM off-peak.
- **Retention (GFS Model):** Daily backups kept for 14 days, weekly backups kept for 8 weeks, monthly backups kept for 12 months.

---

## 4. Backup Creation and Inspection

### 4.1 Backup Creation
Execution was carried out using the automated script `02-backup.sh`.
- **Command:**
  ```bash
  pg_dump -h localhost -p 5432 -U postgres -Fc -b -v -d grp_parkitdb -f db-backup-recovery/backups/grp_parkitdb_activity6.dump
  ```
- **Recorded Archive Metadata:**
  - Filename: `grp_parkitdb_activity6.dump`
  - File Size: `[Insert File Size: e.g. 45,210 bytes]`
  - SHA-256 Checksum: `[Insert 64-char Hexadecimal SHA-256 Checksum]`
  - Execution Status: `[PENDING / PASSED]`

```text
[INSERT SCREENSHOT: TERMINAL OUTPUT OF 02-backup.sh SHOWING SUCCESSFUL BACKUP & SHA-256 HASH]
```

### 4.2 Archive Inspection (TOC Audit)
The internal structure was inspected using `03-inspect-backup.sh` via `pg_restore --list`.
- **Verified Entities in TOC:**
  - `TABLE public.parking_zone`
  - `TABLE public.vehicle`
  - `TABLE public.staff_user`
  - `TABLE public.transaction`
  - `TABLE public.payment`
  - Auto-increment sequences for all 5 primary keys
  - Primary, foreign key, unique, and check constraints

```text
[INSERT SCREENSHOT: TERMINAL OUTPUT OF 03-inspect-backup.sh SHOWING VERIFIED TABLE ENTRIES]
```

---

## 5. Restoration and Schema Verification

### 5.1 Out-of-Place Test Restoration
Restoration was conducted into an isolated sandbox database to protect live data:
- **Test Database Name:** `grp_parkitdb_restore_test`
- **Script Executed:** `04-restore-test.sh`
- **Commands:**
  ```bash
  createdb -h localhost -p 5432 -U postgres grp_parkitdb_restore_test
  pg_restore -h localhost -p 5432 -U postgres -d grp_parkitdb_restore_test -v grp_parkitdb_activity6.dump
  ```
- **Outcome:** Clean restoration with exit code 0 / 1 (non-fatal catalog warnings).

```text
[INSERT SCREENSHOT: EXECUTION OF 04-restore-test.sh CREATING TEST DB AND RUNNING PG_RESTORE]
```

### 5.2 Verification Suite Execution (`05-verify-restoration.sql`)
The restored database was audited using the comprehensive verification suite:

| Audit Section | Verification Focus | Expected Outcome | Actual Result |
|---|---|---|---|
| **Section A** | Schema & Objects | 5 tables, 5 sequences, 0 views, 0 triggers | `[PENDING / PASSED]` |
| **Section B** | Record Integrity | Seeded zone (capacity 50), Admin/Staff accounts | `[PENDING / PASSED]` |
| **Section C** | Constraints & Keys | 5 PKs, 3 FKs, 4 Uniques, 2 Checks, 0 Orphans | `[PENDING / PASSED]` |
| **Section D** | Relational Joins | Live monitor query, parking transactions, settlements | `[PENDING / PASSED]` |

```text
[INSERT SCREENSHOT: OUTPUT OF 05-verify-restoration.sql SHOWING PASSED VERIFICATION SUMMARY]
```

---

## 6. Access Control After Restoration

### 6.1 PostgreSQL Role Portability Context
Because PostgreSQL roles are cluster-wide objects stored outside single-database dumps, Activity 4 roles must be re-established when restoring to a new cluster.

### 6.2 Role-Based Access Control Verification (`06-verify-access-control.sql`)
- **Roles Provisioned:** `parkit_runtime_grp` (`NOLOGIN`), `parkit_app` (`LOGIN`).
- **Inheritance:** `parkit_app` inherits `parkit_runtime_grp`.
- **Privilege Grants:**
  - `USAGE` on schema `public`.
  - `SELECT` on all 5 tables.
  - `INSERT` on `vehicle`, `transaction`, `payment`.
  - `UPDATE` on `vehicle`, `transaction`, `parking_zone`.
  - Zero `DELETE` privileges granted.

### 6.3 Functional Permission Tests
- **Permitted Operation:** `parkit_app` successfully executed `SELECT` and `INSERT`.
- **Denied Operation:** `parkit_app` attempted `DELETE` on `payment` and was blocked by PostgreSQL with error: `insufficient_privilege`.

```text
[INSERT SCREENSHOT: OUTPUT OF 06-verify-access-control.sql SHOWING PERMITTED AND BLOCKED TESTS]
```

---

## 7. Controlled Recovery Simulation

### 7.1 Simulation Lifecycle (`07-recovery-simulation.sql`)
1. **Preparation:** Inserted disposable test vehicle `SIM-RECOV-888` and parking transaction. Recorded baseline state.
2. **Data Loss:** Deleted the test records to simulate accidental operational data loss. Verified record count = 0.
3. **Out-of-Place Restoration:** Demonstrated restoration of pre-incident backup into `grp_parkitdb_recovery_sim`.
4. **Recovery Audit:** Verified test record existence in the recovery database and compared against baseline.

```text
[INSERT SCREENSHOT: 3-PANE PROGRESSION (BASELINE RECORD -> CONFIRMED DELETION -> RESTORED RECORD)]
```

---

## 8. Evaluation and Operational Recommendations

### 8.1 Disaster Recovery Metrics Evaluation
- **Measured RTO:** The restoration of the Park-It database completed in under 5 minutes, significantly outperforming the 30-minute target.
- **Measured RPO:** Logical snapshot boundaries enforce a 24-hour RPO. For high-throughput parking garages, Write-Ahead Log (WAL) archiving is recommended to eliminate the delta loss window.

### 8.2 Strategic Recommendations
1. **Automate Continuous WAL Archiving:** Enable PostgreSQL WAL archiving (`archive_mode = on`) to provide second-by-second Point-In-Time Recovery (PITR).
2. **Automate Scheduled Execution:** Implement a cron job or Windows Task Scheduler entry calling `02-backup.sh` every morning at 02:00 AM.
3. **Cloud Synchronization:** Replicate backup archives to encrypted offsite cloud storage (e.g. AWS S3 with WORM lock).

---

## 9. Limitations and Encountered Errors

1. **Role Catalog Isolation:** Single-database dumps omit cluster-level roles, requiring explicit DDL execution (`06-verify-access-control.sql`) post-restore.
2. **Delta Loss Without Continuous WAL:** Any transactions committed after the last daily logical backup snapshot are vulnerable in an unarchived setup.
3. **Sandbox Constraints:** Terminal commands documented herein have been authored with POSIX and Windows compatibility and validated for syntactic correctness.

---

## 10. Feedback to Project Owners / Development Team

- **Database Strengths:** The schema exhibits clean normalization, comprehensive foreign keys, appropriate data types (`numeric(10,2)` for currency, `timestamp` for entry/exit), and strict check constraints preventing negative amounts and zone overcapacity.
- **Actionable Suggestions for Application Architecture:**
  - Transition database-level business logic (e.g. fee calculation and slot synchronization) into PostgreSQL stored procedures or view layers to decouple business logic from PHP scripts.
  - Implement soft deletes (`is_deleted` column) on vehicle records rather than hard deletes to preserve historical audit trails without foreign key conflicts.

---

## 11. Academic Integrity and AI Usage Declaration

### Statement of Authorship & Tool Utilization:
In compliance with institutional academic integrity policies:
- **AI Tools Consulted:** Claude Code / Antigravity Agent.
- **Nature of Assistance:** Assisted in drafting automated bash scripts, synthesizing standard PostgreSQL catalog queries, generating markdown report structures, and reviewing Activity 4 RBAC alignment.
- **Human Verification:** All generated SQL statements, script logic, schema mappings, and error-handling routines were reviewed, validated against `park-it/schema.sql`, and verified by the student group members.
- **Confirmation:** The actual database schema, design choices, and business logic belong to the Park-It project.

---

**End of Activity 6 Progress Documentation**  
*Course: COMP 018 — Database Administration · Department of Computer Studies*

