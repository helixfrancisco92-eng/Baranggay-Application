# Evidence and Output Capture Checklist
## COMP 018 — Database Administration | Activity 6
### System: Campus Canteen Pre-Order and Queue Management System (Group 8 – bwisIT Solutions)

---

## 📌 Evidence Verification Protocol

This document tracks all 14 mandatory evidence items required for COMP 018 Activity 6 certification.

In compliance with academic integrity and DBA audit standards:
- **Only mark evidence as VERIFIED / COMPLETED when the actual command output capture or screenshot exists.**
- Items that are fully prepared in scripts but await interactive operator database execution are marked as **PENDING OPERATOR EXECUTION**.

---

## 📋 Comprehensive Evidence Matrix

| Evidence ID | Required Demonstration / Evidence Item | Target Script / Source | Current Status | Evidence Location / Terminal Artifact |
|---|---|---|---|---|
| **EVID-01** | Repository structure and database configuration | `Get-ChildItem -Path repo_upstream`, `application.properties` | **VERIFIED** | `verification/database-verification.md` (§ 1), Git inspection log |
| **EVID-02** | Database schema and 7-table dependency listing | `database/migrations/*.sql`, `verify-restore.sql` | **VERIFIED** | `verification/database-verification.md` (§ 2), Schema audit |
| **EVID-03** | Backup command execution (`pg_dump -Fc`) | `scripts/backup.ps1` / `scripts/backup.sh` | **IMPLEMENTED / PENDING EXECUTION** | `logs/backup-execution.log`, Terminal screenshot placeholder |
| **EVID-04** | Backup file details, size (bytes), and SHA-256 checksum | `Get-Item`, `Get-FileHash`, `.sha256` | **IMPLEMENTED / PENDING EXECUTION** | `logs/backup-execution.log`, Hash record placeholder |
| **EVID-05** | Backup archive inspection (`pg_restore --list`) | `scripts/inspect-backup.ps1` / `.sh` | **IMPLEMENTED / PENDING EXECUTION** | `logs/archive-toc.txt`, `logs/inspect-backup.log` |
| **EVID-06** | Creation of separate restoration test database | `scripts/create-restore-db.ps1` / `.sh` | **IMPLEMENTED / PENDING EXECUTION** | `logs/restore-execution.log`, Terminal capture placeholder |
| **EVID-07** | Restoration command and execution output (`pg_restore`) | `scripts/restore.ps1` / `scripts/restore.sh` | **IMPLEMENTED / PENDING EXECUTION** | `logs/restore-execution.log`, Exit code confirmation |
| **EVID-08** | Restored table and record row count verification | `scripts/verify-restore.sql` (Check 2 & 9) | **IMPLEMENTED / PENDING EXECUTION** | `verification/database-verification.md` (§ 3) |
| **EVID-09** | Primary key and foreign key constraint verification | `scripts/verify-restore.sql` (Check 3 & 4) | **IMPLEMENTED / PENDING EXECUTION** | `verification/database-verification.md` (§ 4) |
| **EVID-10** | Access-control, roles, and membership verification | `scripts/verify-access-control.sql` (Check 1 & 2)| **IMPLEMENTED / PENDING EXECUTION** | `verification/access-control-verification.md` (§ 2) |
| **EVID-11** | Permitted operation test (Role: `canteen_app`) | `scripts/verify-access-control.sql` (Check 7) | **IMPLEMENTED / PENDING EXECUTION** | `verification/access-control-verification.md` (§ 3) |
| **EVID-12** | Denied operation test (Role: `canteen_readonly`) | `scripts/verify-access-control.sql` (Check 8 & 9)| **IMPLEMENTED / PENDING EXECUTION** | `verification/access-control-verification.md` (§ 4) |
| **EVID-13** | Recovery simulation: Initial state vs. simulated loss | `scripts/recovery-simulation.sql` (Steps 1–4) | **IMPLEMENTED / PENDING EXECUTION** | `verification/recovery-verification.md` (§ 2) |
| **EVID-14** | Recovery simulation: Restored state and integrity audit | `scripts/recovery-simulation.sql` (Steps 5–7) | **IMPLEMENTED / PENDING EXECUTION** | `verification/recovery-verification.md` (§ 3) |

---

## 📷 Terminal Capture and Screenshot Placeholders

### Screenshot 1: Repository Structure and Database Configuration (EVID-01)
```text
[INSERT SCREENSHOT HERE: Terminal showing repo_upstream directory tree and application.properties datasource configuration]
File reference: repo_upstream/src/main/resources/application.properties
```

### Screenshot 2: Database Schema & Relational Tables (EVID-02)
```text
[INSERT SCREENSHOT HERE: Terminal or DBeaver/pgAdmin showing 7 tables: student, vendor, menu_item, customer_order, order_item, queue_entry, notification]
File reference: repo_upstream/database/migrations/001_create_tables.sql
```

### Screenshot 3: Backup Execution via pg_dump (EVID-03 & EVID-04)
```text
[INSERT SCREENSHOT HERE: Execution of backup.ps1 / backup.sh displaying database name, destination path, file size in bytes, and SHA-256 hash]
Log file: logs/backup-execution.log
```

### Screenshot 4: Archive TOC Inspection via pg_restore --list (EVID-05)
```text
[INSERT SCREENSHOT HERE: Terminal showing execution of inspect-backup.ps1 / inspect-backup.sh displaying TOC entries for 7 core tables]
Log file: logs/archive-toc.txt
```

### Screenshot 5: Test Database Creation (EVID-06)
```text
[INSERT SCREENSHOT HERE: Execution of create-restore-db.ps1 provisioning canteen_db_activity6_restore_test owned by canteen_admin]
Command: createdb -h localhost -p 5432 -U postgres -O canteen_admin canteen_db_activity6_restore_test
```

### Screenshot 6: Restoration Execution via pg_restore (EVID-07)
```text
[INSERT SCREENSHOT HERE: Execution of restore.ps1 / restore.sh showing verbose output and exit code 0 or 1 into test database]
Log file: logs/restore-execution.log
```

### Screenshot 7: Restored Objects and Row Count Verification (EVID-08 & EVID-09)
```text
[INSERT SCREENSHOT HERE: Execution of verify-restore.sql displaying table list, PK/FK constraints, and row count union table]
Script: scripts/verify-restore.sql
```

### Screenshot 8: Access Control and RBAC Audit (EVID-10, EVID-11, EVID-12)
```text
[INSERT SCREENSHOT HERE: Execution of verify-access-control.sql showing role audit, permitted SELECT by canteen_app, and denied INSERT/SELECT by canteen_readonly]
Script: scripts/verify-access-control.sql
```

### Screenshot 9: Recovery Simulation Execution (EVID-13 & EVID-14)
```text
[INSERT SCREENSHOT HERE: Execution of recovery-simulation.sql showing test record creation, simulated deletion, selective recovery, and cleanup]
Script: scripts/recovery-simulation.sql
```

