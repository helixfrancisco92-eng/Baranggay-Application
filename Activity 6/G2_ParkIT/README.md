# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Project: Park-It Database Management System (`grp_parkitdb`)

---

## 📌 Executive Overview

This directory contains the complete implementation of **COMP 018 Activity 6: Database Backup, Restoration, and Recovery** for the **Park-It Database Management System**. 

The Park-It database operates on **PostgreSQL 18.6** and manages real-time parking slot occupancy, vehicle entry/exit tracking, automated parking fee calculations, lost-ticket penalty assessments, and administrative access controls. The procedures and scripts implemented here establish a dependable disaster recovery framework adhering to strict academic, operational, and least-privilege standards.

---

## 🗂️ Directory Structure

```text
db-backup-recovery/
│
├── README.md                                # Root documentation and operational guide (this file)
│
├── park-it/
│   ├── 01-backup-plan.md                    # Part A: Formal backup plan, RPO/RTO, policies, and strategy
│   ├── 02-backup.sh                         # Part B: Interactive, secure custom-format backup script (pg_dump)
│   ├── 03-inspect-backup.sh                 # Part B: TOC archive inspector and checksum verifier (pg_restore)
│   ├── 04-restore-test.sh                   # Part C: Isolated test database restoration script (createdb + pg_restore)
│   ├── 05-verify-restoration.sql            # Part C: SQL verification suite (objects, records, constraints, joins)
│   ├── 06-verify-access-control.sql         # Part C: Activity 4 RBAC role and privilege verification script
│   ├── 07-recovery-simulation.sql           # Part D: Controlled data-loss simulation and recovery validation
│   ├── 08-recovery-report.md                # Part E: Comprehensive academic recovery report (22 sections)
│   ├── 09-evidence-checklist.md             # Part F: Submission evidence matrix and command output checklist
│   └── 10-activity6-summary.md              # Part F: Requirement-by-requirement verification audit
│
└── templates/
    ├── activity6-log-template.csv           # Standardized progress tracking log (Google Sheets importable)
    └── progress-documentation-template.md   # Academic documentation template formatted for PDF conversion
```

---

## ⚙️ Target Environment & Database Specifications

| Parameter | Specification | Source / Verification |
|---|---|---|
| **System Name** | Park-It Database Management System | `PARK IT DATABASE MANAGEMENT...pdf` |
| **Course** | COMP 018 — Database Administration | Official Activity 6 Guidelines |
| **Database Platform** | PostgreSQL 18.6 (64-bit) | `park-it/schema.sql` (Line 7) |
| **Target Database** | `grp_parkitdb` | `park-it/config/database.php`, `user-role.md` |
| **Isolated Test Database** | `grp_parkitdb_restore_test` | Created dynamically during Part C |
| **Recovery Simulation DB** | `grp_parkitdb_recovery_sim` | Created dynamically during Part D |
| **Application Tables (5)** | `parking_zone`, `vehicle`, `staff_user`, `transaction`, `payment` | `park-it/schema.sql` |
| **Application Roles** | `parkit_runtime_grp` (`NOLOGIN`), `parkit_app` (`LOGIN`) | `user-role.md` (Activity 4) |
| **Administrative Account** | `postgres` (Superuser) | Utilized strictly for backup/restoration DDL |
| **Backup Storage Path** | `db-backup-recovery/backups/` (Git-ignored) | Script-generated directory |

---

## 🚀 Execution Workflow & Step-by-Step Guide

### Step 1: Review the Backup Plan
Read [`park-it/01-backup-plan.md`](file:///c:/Users/Lenovo/Downloads/G2_ParkIT/park-it-database/db-backup-recovery/park-it/01-backup-plan.md) to understand the backup architecture, rationale for PostgreSQL custom archive format (`-Fc`), Recovery Point Objective (RPO), Recovery Time Objective (RTO), and retention guidelines.

### Step 2: Execute the Backup Script
Run the automated backup script to produce a timestamped, custom-format archive:
- **Bash / Git Bash / WSL:**
  ```bash
  cd db-backup-recovery/park-it
  chmod +x *.sh
  ./02-backup.sh
  ```
- **Windows Command Prompt / PowerShell:**
  You can execute `./02-backup.sh` inside **Git Bash**, or execute the underlying command directly:
  ```powershell
  pg_dump -U postgres -h localhost -p 5432 -Fc -b -v -d grp_parkitdb -f ..\backups\grp_parkitdb_activity6.dump
  ```
The script automatically generates a SHA-256 checksum and logs backup metadata.

### Step 3: Inspect the Backup Archive
Verify the physical and structural integrity of the dump file without restoring it:
```bash
./03-inspect-backup.sh
```
This utility calculates and verifies the SHA-256 hash, runs `pg_restore --list`, and outputs the archive Table of Contents (TOC) to `../backups/<dump_file>_toc.txt`.

### Step 4: Perform Isolated Test Restoration
Restore the backup archive into a separate test database (`grp_parkitdb_restore_test`):
```bash
./04-restore-test.sh
```
*Safety Guarantee:* The script explicitly validates that the target database is not the production `grp_parkitdb`. It creates the database via `createdb` and executes `pg_restore`.

### Step 5: Verify Restored Schema, Records, and Constraints
Connect to the restored test database and execute the verification suite:
```bash
psql -U postgres -h localhost -p 5432 -d grp_parkitdb_restore_test -f 05-verify-restoration.sql
```
This script audits:
- All 5 tables and their 5 associated sequences.
- Primary key, foreign key, unique, and check constraints (`parking_zone_check`, `payment_amount_check`).
- Record counts and sample data consistency.
- Complex multi-table relational joins.

### Step 6: Verify Activity 4 Access Control (RBAC)
Recreate and verify cluster-level roles and object permissions on the test database:
```bash
psql -U postgres -h localhost -p 5432 -d grp_parkitdb_restore_test -f 06-verify-access-control.sql
```
This script verifies:
- Idempotent provisioning of `parkit_runtime_grp` and `parkit_app`.
- `CONNECT`, `USAGE`, `SELECT`, `INSERT`, and `UPDATE` grants.
- Enforces security isolation by testing permitted operations and explicitly denied operations (`DELETE` rejection).

### Step 7: Conduct Controlled Recovery Simulation
Simulate a data-loss scenario using strictly disposable test records:
```bash
psql -U postgres -h localhost -p 5432 -d grp_parkitdb_restore_test -f 07-recovery-simulation.sql
```
*Safety Guarantee:* No production data, actual bookings, or seeded staff accounts are deleted. The simulation follows a structured 5-step lifecycle:
1. Disposable test record creation (`TEST-SIM-999`).
2. Simulated accidental deletion.
3. Verification of data loss.
4. Out-of-place restore verification from pre-incident backup.
5. Post-recovery verification and downtime evaluation.

### Step 8: Document Evidence and Prepare Submission
1. Consult [`09-evidence-checklist.md`](file:///c:/Users/Lenovo/Downloads/G2_ParkIT/park-it-database/db-backup-recovery/park-it/09-evidence-checklist.md) to gather required terminal screenshots.
2. Complete [`08-recovery-report.md`](file:///c:/Users/Lenovo/Downloads/G2_ParkIT/park-it-database/db-backup-recovery/park-it/08-recovery-report.md) with actual file sizes, checksums, and measured execution durations.
3. Update [`templates/activity6-log-template.csv`](file:///c:/Users/Lenovo/Downloads/G2_ParkIT/park-it-database/db-backup-recovery/templates/activity6-log-template.csv) and import it into your shared Google Sheets tracker.
4. Export [`templates/progress-documentation-template.md`](file:///c:/Users/Lenovo/Downloads/G2_ParkIT/park-it-database/db-backup-recovery/templates/progress-documentation-template.md) to PDF for final academic submission.

---

## 🔒 Security and Safety Principles

1. **Least-Privilege Isolation:**
   - Normal application runtime uses `parkit_app` (via `parkit_runtime_grp`), which is stripped of `DELETE` permissions on financial transactions and parking logs.
   - Backup and restore procedures require the `postgres` superuser or a dedicated `backup_admin` role due to PostgreSQL's requirement for catalog read and schema recreation privileges.
2. **Protection Against Accidental Overwrite:**
   - All scripts enforce strict target checks. The restoration script will immediately abort if pointed at `grp_parkitdb`.
   - Existing backups are never automatically purged or overwritten.
3. **Credential Protection:**
   - No passwords are hardcoded in any script or SQL query. Password prompting or standard `.pgpass` / environment variable mechanisms are utilized.
   - The `.gitignore` file strictly blocks all `.dump`, `.backup`, `.log`, and credential artifacts from being committed to GitHub.

