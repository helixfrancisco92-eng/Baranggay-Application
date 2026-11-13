# Evidence Checklist and Artifact Registry
## COMP 018 — Database Administration | Activity 6
### Assigned Project: BoardTrack — Boarding House & Rental Management System

---

## 📌 Evidence Verification Protocol

In compliance with academic integrity guidelines, evidence artifacts are recorded with clear distinction between verified structural/code inspection, implemented scripts, and operator execution logs. No fabricated screenshots, placeholder image binaries, or simulated command terminal dumps are marked as completed without actual execution evidence.

---

## 📋 14-Item Evidence Registry

| Item # | Verification Target / Requirement | Artifact Reference | Associated Script / Command | Status |
|:---:|---|---|---|:---:|
| **01** | **Repository Structure & DB Configuration** | `evidence/01-repository-inspection.png` | `Get-ChildItem -Recurse boardtrack_repo` | **VERIFIED** |
| **02** | **Database Schema & Table Definitions** | `evidence/02-database-schema.png` | `db/migrations/001_schema.sql` audit | **VERIFIED** |
| **03** | **Backup Command Execution** | `evidence/03-backup-execution.png` | `scripts/backup.ps1` / `scripts/backup.sh` | **IMPLEMENTED** (Pending Operator Run) |
| **04** | **Backup File Size & SHA-256 Checksum** | `evidence/04-backup-checksum.png` | `Get-FileHash -Algorithm SHA256` | **IMPLEMENTED** (Pending Operator Run) |
| **05** | **Archive Table-of-Contents Inspection** | `evidence/05-backup-inspection.png` | `scripts/inspect-backup.ps1` (`pg_restore --list`) | **IMPLEMENTED** (Pending Operator Run) |
| **06** | **Creation of Separate Restoration DB** | `evidence/06-restore-database-created.png` | `scripts/create-restore-db.ps1` (`createdb`) | **IMPLEMENTED** (Pending Operator Run) |
| **07** | **Restoration Command Execution & Output**| `evidence/07-restoration-execution.png` | `scripts/restore.ps1` (`pg_restore -v`) | **IMPLEMENTED** (Pending Operator Run) |
| **08** | **Restored Tables & Record Counts** | `evidence/08-data-verification.png` | `scripts/verify-database.sql` [Section 2] | **IMPLEMENTED** (Pending Operator Run) |
| **09** | **Primary & Foreign Key Constraints** | `evidence/09-constraints-and-keys.png` | `scripts/verify-database.sql` [Sections 3, 4, 5] | **IMPLEMENTED** (Pending Operator Run) |
| **10** | **Access-Control & Database Roles** | `evidence/10-access-control-roles.png` | `scripts/verify-access-control.sql` [Sections 1–5] | **IMPLEMENTED** (Pending Operator Run) |
| **11** | **Permitted Operation Execution** | `evidence/11-permitted-operation.png` | `scripts/verify-access-control.sql` [Test A] | **IMPLEMENTED** (Pending Operator Run) |
| **12** | **Denied Operation Execution (SQLSTATE 42501)**| `evidence/12-denied-operation.png` | `scripts/verify-access-control.sql` [Tests B, C] | **IMPLEMENTED** (Pending Operator Run) |
| **13** | **Recovery Simulation: Incident & Deletion**| `evidence/13-recovery-incident.png` | `scripts/recovery-simulation.sql` [Steps 1–4] | **IMPLEMENTED** (Pending Operator Run) |
| **14** | **Recovery Simulation: Recovered Data** | `evidence/14-recovery-result.png` | `scripts/recovery-simulation.sql` [Steps 5–7] | **IMPLEMENTED** (Pending Operator Run) |

---

## 🔍 Detailed Evidence Descriptions & Expected Outputs

### Evidence 01: Repository Structure & Database Configuration
- **Objective:** Demonstrate that the upstream BoardTrack repository was inspected without modification, identifying the Node.js/Express stack and PostgreSQL connection configuration.
- **Evidence Target:** Directory listing showing `src/`, `db/migrations/`, `db/seeds/`, `package.json`, and `.env.example`.
- **Expected Terminal Output:**
  ```text
  Directory: C:\Users\Lenovo\Downloads\ACT 6\G11_BoardTrack\boardtrack_repo
  Mode   Length Name
  d----         db
  d----         docs
  d----         src
  -a---    605  .env.example
  -a---    635  package.json
  -a---   5806  README.md
  ```

### Evidence 02: Database Schema & Relational Tables
- **Objective:** Document the DDL schema confirming all seven application tables, extensions (`btree_gist`, `pgcrypto`), triggers, views, and exclusion constraints.
- **Evidence Target:** Inspection of `001_schema.sql` showing tables `property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, and `app_user`.

### Evidence 03: Backup Command Execution
- **Objective:** Capture execution of `pg_dump -Fc` targeting `boardtrack_db` using the dedicated backup user.
- **Expected Terminal Output:**
  ```text
  ====================================================================
    BoardTrack Database Logical Backup — COMP 018 Activity 6
  ====================================================================
  [INFO] Initiating pg_dump in custom format (-Fc)...
  pg_dump: saving database definition
  pg_dump: dumping contents of table "public.property"
  pg_dump: dumping contents of table "public.room"
  ...
  ====================================================================
    BACKUP COMPLETED SUCCESSFULLY
  ====================================================================
  ```

### Evidence 04: Backup File Details, Size, and Checksum
- **Objective:** Document the physical backup archive outside version control (`C:\db-backups\boardtrack\`), recording exact byte size and SHA-256 hash.
- **Expected Terminal Output:**
  ```powershell
  Get-FileHash -Path "C:\db-backups\boardtrack\boardtrack_db_activity6.dump" -Algorithm SHA256
  # Algorithm : SHA256
  # Hash      : [64-character hexadecimal hash]
  # Path      : C:\db-backups\boardtrack\boardtrack_db_activity6.dump
  ```

### Evidence 05: Backup Archive Inspection (TOC)
- **Objective:** Extract and audit archive Table of Contents using `pg_restore --list`.
- **Expected Terminal Output:**
  ```text
  ; Archive created at 2026-11-13 ...
  ;     dbname: boardtrack_db
  ;     TOC Entries: 85
  ...
  TABLE public property
  TABLE public room
  TABLE public tenant
  TABLE public lease
  TABLE public payment
  TABLE public utility_bill
  TABLE public app_user
  VIEW public v_lease_summary
  ```

### Evidence 06: Separate Restoration Database Creation
- **Objective:** Prove that `boardtrack_db_activity6_restore_test` was provisioned as a new, clean database separate from `boardtrack_db`.
- **Expected Terminal Output:**
  ```text
  [INFO] Creating clean restoration database: 'boardtrack_db_activity6_restore_test'...
  ====================================================================
    ISOLATED TEST DATABASE PROVISIONED SUCCESSFULLY
  ====================================================================
  ```

### Evidence 07: Restoration Command Execution & Output
- **Objective:** Execute `pg_restore -v` restoring the custom archive into `boardtrack_db_activity6_restore_test`.
- **Expected Terminal Output:**
  ```text
  pg_restore: connecting to database for restore
  pg_restore: creating SCHEMA "public"
  pg_restore: creating TABLE "public.property"
  pg_restore: processing data for table "public.property"
  pg_restore: creating CONSTRAINT "public.property property_pkey"
  ...
  ====================================================================
    RESTORATION EXECUTION AUDIT SUMMARY: SUCCESS (Exit Code 0)
  ====================================================================
  ```

### Evidence 08: Restored Table and Record Count Verification
- **Objective:** Execute query verifying exact match against original seed baseline.
- **Expected Query Output:**
  ```text
   table_name        | exact_count | expected_baseline
  -------------------+-------------+-------------------
   property          |           2 |                 2
   room              |           6 |                 6
   tenant            |           4 |                 4
   lease             |           4 |                 4
   payment           |           6 |                 6
   utility_bill      |           4 |                 4
   app_user          |           3 |                 3
   schema_migrations |           1 |                 1
  ```

### Evidence 09: Primary and Foreign Key Integrity
- **Objective:** Confirm all PKs, FKs, CHECK constraints, and exclusion constraint `ex_lease_no_overlap` are fully active.

### Evidence 10: Access-Control & Role Verification
- **Objective:** Audit roles `boardtrack_owner`, `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`, `boardtrack_app`.

### Evidence 11: Permitted Operation Execution
- **Objective:** Execute `SELECT * FROM v_lease_summary` under an authorized role, returning successful rows.

### Evidence 12: Denied Operation Execution
- **Objective:** Demonstrate unauthorized `DELETE` or `DROP TABLE` blocked with `SQLSTATE 42501 (insufficient_privilege)`.

### Evidence 13 & 14: Controlled Recovery Simulation (Before, Data Loss, After)
- **Objective:** Demonstrate injection of disposable payment record, deletion, recovery from backup archive, and post-recovery state comparison.

---
*Maintained under COMP 018 Academic Integrity and DBA Safety Standards.*

