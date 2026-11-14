# Evidence Checklist and Artifact Certification
## COMP 018 — Database Administration | Activity 6
### Assigned Project: Restaurant Online Ordering & Table Reservation System (Group: Binary Sisters)

---

## 📌 Evidence Verification Protocol

In compliance with academic integrity guidelines, evidence is cataloged strictly based on verified specifications and executable artifacts. Placeholders represent expected terminal captures to be finalized by the human operator upon interactive credential authentication.

**Status Legend:**
- **IMPLEMENTED & READY:** Verification script, SQL suite, or procedure created and tested in workspace.
- **PENDING OPERATOR RUN:** Awaiting execution by human operator with interactive database credentials.

---

## 📋 14-Item Evidence Inventory

| # | Evidence Item Description | Target Artifact / Script Source | Expected Screenshot Filename | Operational Verification Criteria | Status |
|---|---|---|---|---|---|
| **01** | Upstream Repository Structure & Configuration | `README.md`, `app/config/database.php`, `.env.example` | `01-repository-inspection.png` | Git clone confirmation, PHP 8 / PostgreSQL 18 stack, `app/` structure | **IMPLEMENTED & READY** |
| **02** | Database Schema & 8 Core Tables Listing | `database/migrations/001_create_tables.sql` | `02-database-schema.png` | 8 tables: `customer`, `menu_item`, `restaurant_table`, `staff`, `orders`, `order_item`, `reservation`, `payment` | **IMPLEMENTED & READY** |
| **03** | Backup Command Execution (`pg_dump -Fc`) | `scripts/backup.ps1` / `scripts/backup.sh` | `03-backup-execution.png` | `pg_dump` execution log, non-zero file size, exit code 0 | **IMPLEMENTED (PENDING RUN)** |
| **04** | Backup File Details, Size, and Checksum | `backups/grp_binarysisters_projectdb_*.dump.sha256` | `04-backup-checksum.png` | File size (~52 KB), SHA-256 hash calculation output | **IMPLEMENTED (PENDING RUN)** |
| **05** | Backup Archive TOC Inspection | `scripts/inspect-backup.ps1` / `logs/archive-toc.txt` | `05-backup-inspection.png` | `pg_restore --list` verifying all 8 tables and constraints in TOC | **IMPLEMENTED (PENDING RUN)** |
| **06** | Creation of Isolated Restoration Database | `scripts/create-restore-db.ps1` / `.sh` | `06-restore-database-created.png` | `createdb` execution provisioning `grp_binarysisters_projectdb_activity6_restore_test` | **IMPLEMENTED (PENDING RUN)** |
| **07** | Restoration Command Execution & Output | `scripts/restore.ps1` / `logs/restore-execution.log` | `07-restoration-execution.png` | `pg_restore` verbose output restoring archive into test database | **IMPLEMENTED (PENDING RUN)** |
| **08** | Restored Table & Seed Record Count Verification | `scripts/verify-database.sql` (Section 13) | `08-data-verification.png` | Counts matching: 51 customers, 10 staff, 50 menu items, 20 tables, 60 orders, 167 items, 56 payments, 50 reservations | **IMPLEMENTED (PENDING RUN)** |
| **09** | Primary Key, Foreign Key & Constraint Verification | `scripts/verify-database.sql` (Sections 5-9) | `09-constraints-verification.png` | 8 PKs, 6 FKs, 4 Unique, 15 Check constraints, `ex_reservation_no_overlap` GiST | **IMPLEMENTED (PENDING RUN)** |
| **10** | Access-Control & Role Hierarchy Verification | `scripts/verify-access-control.sql` (Sections 1-4) | `10-access-control.png` | Roles `rors_app`, `rors_report`, `rors_maint`, `rors_backup`, `rors_dba` and memberships | **IMPLEMENTED (PENDING RUN)** |
| **11** | Permitted Operation Test Execution | `scripts/verify-access-control.sql` (Section 5) | `11-permitted-operation.png` | `rors_app` successfully reading active menu items (HTTP/SQL 200) | **IMPLEMENTED (PENDING RUN)** |
| **12** | Denied Operation Test Execution | `scripts/verify-access-control.sql` (Sections 6-10) | `12-denied-operation.png` | `rors_report` inserting into orders trapped with SQLSTATE `42501` | **IMPLEMENTED (PENDING RUN)** |
| **13** | Recovery Simulation Before-and-After Results | `scripts/recovery-simulation.sql` (Steps 1-4) | `13-recovery-simulation-incident.png` | Disposable record inserted (9999), deleted, and verified missing (0 rows) | **IMPLEMENTED (PENDING RUN)** |
| **14** | Recovery Simulation Final Match & Verification | `scripts/recovery-simulation.sql` (Steps 5-7) | `14-recovery-simulation-result.png` | Restored record attributes match baseline 100%, followed by clean cleanup | **IMPLEMENTED (PENDING RUN)** |

---

## 🖼️ Expected Screenshot Storage Directory

Operator execution screenshots should be captured and stored in this directory:
```text
evidence/
├── 01-repository-inspection.png
├── 02-database-schema.png
├── 03-backup-execution.png
├── 04-backup-checksum.png
├── 05-backup-inspection.png
├── 06-restore-database-created.png
├── 07-restoration-execution.png
├── 08-data-verification.png
├── 09-constraints-verification.png
├── 10-access-control.png
├── 11-permitted-operation.png
├── 12-denied-operation.png
├── 13-recovery-simulation-incident.png
└── 14-recovery-simulation-result.png
```

> [!IMPORTANT]
> In accordance with course guidelines, no fake screenshots or dummy graphic files have been created. Only actual terminal captures generated during authorized database execution should populate this directory.

