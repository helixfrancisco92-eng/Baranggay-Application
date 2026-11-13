# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Assigned Project: GROUP 8 – Campus Canteen Pre-Order and Queue Management System (bwisIT Solutions)

---

## 📌 Executive Overview

This directory contains the complete technical implementation, automation scripts, verification suites, disaster recovery simulations, and documentation for **COMP 018 – Database Administration, Activity 6: Database Backup, Restoration, and Recovery**.

The assigned project evaluated is the **Campus Canteen Pre-Order and Queue Management System** developed by **Group 8 (bwisIT Solutions)**. The system provides pre-ordering, menu management, pickup time scheduling, queue ticket assignment, and order tracking for campus food stalls, backed by a Spring Boot REST API and a PostgreSQL relational database.

In accordance with strict academic guidelines and operational safety rules:
- **READ-ONLY Rule:** The original Group 8 upstream repository (`https://github.com/EclipseChan/bwisIT-Solutions---Campus-Canteen-Pre-Order-and-Queue-Management-System.git`) was inspected as strictly read-only. No upstream branches, commits, or files were altered.
- **Data Safety Rule:** All backup archives are stored outside version control in a protected directory. No real passwords, dumps, or sensitive customer credentials are committed.
- **Isolation Rule:** Restoration and recovery simulations are strictly isolated in a newly provisioned test database (`canteen_db_activity6_restore_test`) to prevent any risk of data loss, truncation, or corruption to the live database (`canteen_db`).

---

## 🗂️ Project Directory Structure

```text
db-backup-recovery/
└── group-08-campus-canteen/
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
    │   ├── verify-restore.sql                 # SQL suite verifying tables, PK/FKs, constraints, indexes, data
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
| **System Name** | Campus Canteen Pre-Order and Queue Management System | `README.md` |
| **Assigned Group** | Group 8 (bwisIT Solutions) | `README.md` |
| **Repository URL** | `https://github.com/EclipseChan/bwisIT-Solutions---Campus-Canteen-Pre-Order-and-Queue-Management-System.git` | Project specification |
| **Database Engine** | PostgreSQL 18 (Local installation: `C:\Program Files\PostgreSQL\18\bin`) | `psql --version`, `pom.xml` |
| **Primary Database** | `canteen_db` | `.env.example`, `application.properties` |
| **Isolated Test Database** | `canteen_db_activity6_restore_test` | Provisioned dynamically in Phase 6 |
| **Database Owner / Admin**| `canteen_admin` (Owns all tables, migrations, sequences) | `001_create_role_and_database.sql` |
| **Application Runtime User**| `canteen_app` (Member of `canteen_app_grp`) | `01-create-roles.sql`, `04-schema-and-table-privileges.sql` |
| **Read-Only Reporting User**| `canteen_readonly` (Member of `canteen_readonly_grp`) | `01-create-roles.sql`, `04-schema-and-table-privileges.sql` |
| **Relational Core Tables**| 7 Tables: `student`, `vendor`, `menu_item`, `customer_order`, `order_item`, `queue_entry`, `notification` | `database/migrations/001_create_tables.sql` |
| **Backend Framework** | Java 21, Spring Boot 3.4.1, Spring Data JPA, Hibernate, Spring Security, JWT | `pom.xml`, `application.properties` |

---

## 🚀 Step-by-Step Operator Execution Guide

All scripts are cross-platform compatible and support both **Windows PowerShell** and **POSIX/Bash** (Linux, macOS, WSL).

### 1. Execute Database Backup (Phase 4)
Generates a custom-format logical archive (`-Fc`), validates exit codes, ensures non-zero file size, and computes a SHA-256 checksum:
```powershell
# Windows PowerShell
.\scripts\backup.ps1 -Database "canteen_db" -User "canteen_admin"
```
```bash
# POSIX / Bash
./scripts/backup.sh
```

### 2. Inspect Archive Table-of-Contents (Phase 5)
Extracts TOC metadata and confirms all 7 tables and constraints without executing DDL:
```powershell
# Windows PowerShell
.\scripts\inspect-backup.ps1
```
```bash
# POSIX / Bash
./scripts/inspect-backup.sh
```

### 3. Provision Isolated Test Database (Phase 6)
Creates an empty database separate from `canteen_db` with strict boundary checks:
```powershell
# Windows PowerShell
.\scripts\create-restore-db.ps1 -RestoreDb "canteen_db_activity6_restore_test"
```
```bash
# POSIX / Bash
./scripts/create-restore-db.sh
```

### 4. Restore Dump to Test Database (Phase 6)
Restores schema and records without suppressing ownership errors:
```powershell
# Windows PowerShell
.\scripts\restore.ps1 -RestoreDb "canteen_db_activity6_restore_test"
```
```bash
# POSIX / Bash
./scripts/restore.sh
```

### 5. Verify Restored Database Objects and Data (Phase 7)
```powershell
psql -U canteen_admin -h localhost -p 5432 -d canteen_db_activity6_restore_test -f .\scripts\verify-restore.sql
```

### 6. Verify Access Controls and Least Privilege (Phase 7)
Audits roles, memberships, column-level grants, permitted operations, and denied operations:
```powershell
psql -U postgres -h localhost -p 5432 -d canteen_db_activity6_restore_test -f .\scripts\verify-access-control.sql
```

### 7. Run Controlled Recovery Simulation (Phase 8)
Simulates accidental record deletion and verifies selective object recovery using strictly disposable test data:
```powershell
psql -U canteen_admin -h localhost -p 5432 -d canteen_db_activity6_restore_test -f .\scripts\recovery-simulation.sql
```

---

## 🏷️ Standard Status Labels

In compliance with activity standards:
- **IMPLEMENTED** — The file, script, verification test, or configuration was fully authored and prepared.
- **EXECUTED** — The command or procedure was run in the live operating environment.
- **VERIFIED** — The output was validated against documented criteria and evidence collected.
- **PENDING** — The task requires operator action (e.g., providing local PostgreSQL credentials).
- **NOT APPLICABLE** — The requirement does not apply to the confirmed PostgreSQL architecture.

