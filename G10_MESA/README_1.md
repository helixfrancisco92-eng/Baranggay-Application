# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Assigned Project: Restaurant Online Ordering & Table Reservation System (Group: Binary Sisters)

---

## 📌 Executive Overview

This directory contains the complete technical implementation, automation scripts, verification suites, disaster recovery simulations, and documentation for **COMP 018 – Database Administration, Activity 6: Database Backup, Restoration, and Recovery**.

The assigned project evaluated is the **Restaurant Online Ordering & Table Reservation System** developed by **Group Binary Sisters**. The system provides customer meal ordering, table reservations with mathematical double-booking prevention, dynamic order queue management, and payment reconciliation, backed by a native PHP 8 backend and a PostgreSQL 18 relational database.

### Core Safety Directives Enforced:
1. **READ-ONLY Rule:** The original Group Binary Sisters upstream repository (`https://github.com/kathlenmaecallos11-arch/Restaurant-Online-Ordering-Table-Reservation-System`) was inspected as strictly read-only. No upstream branches, commits, or files were altered.
2. **Data Safety Rule:** All backup archives are stored outside version control in a protected directory. No real passwords, dumps, or sensitive customer credentials are committed to Git.
3. **Isolation Rule:** Restoration and recovery simulations are strictly isolated in a newly provisioned test database (`grp_binarysisters_projectdb_activity6_restore_test`) to prevent any risk of data loss, truncation, or corruption to the live database (`grp_binarysisters_projectdb`).

---

## 🗂️ Directory Structure

```text
db-backup-recovery/
└── restaurant-online-ordering/
    ├── README.md                              # Operational guide and directory documentation (this file)
    ├── backup-plan.md                         # Comprehensive Part A backup plan, RPO/RTO, and security policy
    ├── scripts/
    │   ├── backup.sh                          # Bash automated custom-format backup script (pg_dump -Fc)
    │   ├── backup.ps1                         # PowerShell automated backup script (Windows native)
    │   ├── inspect-backup.sh                  # Bash TOC inspection and checksum verification (pg_restore --list)
    │   ├── inspect-backup.ps1                 # PowerShell TOC inspection and checksum verification
    │   ├── create-restore-db.sh               # Bash isolated test database provisioning (createdb)
    │   ├── create-restore-db.ps1              # PowerShell isolated test database provisioning
    │   ├── restore.sh                         # Bash test database restoration script (pg_restore)
    │   ├── restore.ps1                        # PowerShell test database restoration script
    │   ├── verify-database.sql                # SQL suite verifying tables, PK/FKs, constraints, indexes, data
    │   ├── verify-access-control.sql          # SQL suite auditing Activity 4 RBAC, roles, and privileges
    │   └── recovery-simulation.sql           # SQL controlled recovery simulation using disposable test data
    ├── logs/
    │   └── .gitkeep                           # Operational execution logs directory (git-ignored)
    ├── evidence/
    │   └── evidence-checklist.md              # 14-item verification evidence and terminal artifact checklist
    ├── verification/
    │   ├── database-verification.md           # Schema, objects, constraints, and data integrity audit
    │   ├── access-control-verification.md     # RBAC roles, grants, column-level security, and denied tests
    │   └── recovery-verification.md           # Controlled data loss scenario, recovery audit, and RPO/RTO
    └── reports/
        ├── activity-6-report.md               # PDF-ready formal academic report (13 required sections)
        └── limitations-and-recommendations.md # Blocker analysis, environment limitations, and DBA roadmap
```

---

## ⚙️ Target Database Architecture Summary

| Parameter | Specification / Discovered Setting | Source File |
|---|---|---|
| **System Name** | Restaurant Online Ordering & Table Reservation System | `README.md` |
| **Assigned Group** | Group Binary Sisters | `README.md` |
| **Repository URL** | `https://github.com/kathlenmaecallos11-arch/Restaurant-Online-Ordering-Table-Reservation-System` | Project specification |
| **Database Engine** | PostgreSQL 18 (Local installation: `C:\Program Files\PostgreSQL\18\bin`) | `psql --version` |
| **Primary Database** | `grp_binarysisters_projectdb` | `database/migrations/000_create_database.sql`, `.env.example` |
| **Isolated Test Database** | `grp_binarysisters_projectdb_activity6_restore_test` | Phase 6 Specification |
| **Database Owner / Admin**| `postgres` | `database/migrations/000_create_database.sql` |
| **Backup Operator Role** | `rors_backup` (Member of `rors_backup_grp`, possessing `pg_read_all_data`) | `database/roles/01_create_roles.sql` |
| **Application Runtime User**| `rors_app` (Member of `rors_runtime_grp`) | `database/roles/01_create_roles.sql`, `app/config/database.php` |
| **Read-Only Reporting User**| `rors_report` (Member of `rors_readonly_grp`) | `database/roles/01_create_roles.sql`, `database/roles/02_grants.sql` |
| **Relational Core Tables**| 8 Tables: `customer`, `menu_item`, `restaurant_table`, `staff`, `orders`, `order_item`, `reservation`, `payment` | `database/migrations/001_create_tables.sql` |
| **Backend Framework** | PHP 8.1+, Native PDO, prepared statements, lightweight router | `app/config/database.php` |

---

## 🚀 Step-by-Step Operator Execution Guide

All automation scripts are cross-platform compatible and support both **Windows PowerShell** and **POSIX/Bash** (Linux, macOS, WSL).

### 1. Execute Database Backup (Phase 4)
Generates a custom-format logical archive (`-Fc`), validates exit codes, ensures non-zero file size, and computes a SHA-256 checksum:
```powershell
# Windows PowerShell
.\scripts\backup.ps1 -Database "grp_binarysisters_projectdb" -User "rors_backup"
```
```bash
# POSIX / Bash
./scripts/backup.sh
```

### 2. Inspect Archive Table-of-Contents (Phase 5)
Extracts TOC metadata and confirms all 8 tables, views, triggers, and constraints without executing DDL:
```powershell
# Windows PowerShell
.\scripts\inspect-backup.ps1
```
```bash
# POSIX / Bash
./scripts/inspect-backup.sh
```

### 3. Provision Isolated Test Database (Phase 6)
Creates an empty database separate from `grp_binarysisters_projectdb` with strict boundary checks:
```powershell
# Windows PowerShell
.\scripts\create-restore-db.ps1
```
```bash
# POSIX / Bash
./scripts/create-restore-db.sh
```

### 4. Restore into Test Database (Phase 6)
Restores the custom archive into `grp_binarysisters_projectdb_activity6_restore_test`:
```powershell
# Windows PowerShell
.\scripts\restore.ps1
```
```bash
# POSIX / Bash
./scripts/restore.sh
```

### 5. Verify Restored Database (Phase 7)
Audits schemas, 8 tables, primary keys, foreign keys, unique constraints, check constraints, exclusion constraints, views, and row counts:
```powershell
psql -h 127.0.0.1 -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts\verify-database.sql
```

### 6. Verify Access Control & Least Privilege (Phase 7)
Audits Activity 4 RBAC roles, grants, 1 permitted operation, and 4 trapped denied operations:
```powershell
psql -h 127.0.0.1 -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts\verify-access-control.sql
```

### 7. Controlled Disaster Recovery Simulation (Phase 8)
Simulates accidental data loss and selective restoration using a disposable test record:
```powershell
psql -h 127.0.0.1 -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts\recovery-simulation.sql
```

