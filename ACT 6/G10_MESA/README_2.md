# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Assigned Project: Restaurant Online Ordering & Table Reservation System (Group: Binary Sisters)
### Evaluating Group: Group 10 (`G10_MESA`)

---

## 📌 Executive Summary

This repository contains the complete technical implementation, automation scripts, verification suites, disaster recovery models, and formal documentation for **COMP 018 – Database Administration, Activity 6: Database Backup, Restoration, and Recovery**.

The assigned project evaluated is the **Restaurant Online Ordering & Table Reservation System**, developed by **Group Binary Sisters** (`https://github.com/kathlenmaecallos11-arch/Restaurant-Online-Ordering-Table-Reservation-System`).

### Operational Guidelines Strictly Enforced:
- **READ-ONLY Mandate:** The upstream repository was cloned and evaluated strictly in read-only mode. No upstream commits, branch modifications, or data changes were executed.
- **Data Protection Mandate:** All backup files, credentials, and sensitive customer emails/hashes are strictly excluded from version control via `.gitignore`.
- **Restoration Isolation:** Restoration and disaster simulations are conducted strictly in an isolated test database (`grp_binarysisters_projectdb_activity6_restore_test`) to guarantee that the primary database (`grp_binarysisters_projectdb`) remains untouched.

---

## 🗂️ Complete Activity 6 Directory Structure

```text
G10_MESA/
├── .gitignore                                 # Protection rules excluding .dump, .env, and sensitive logs
├── README.md                                  # Root operational guide and project overview (this file)
├── tracker-and-feedback.md                    # Copy-ready Google Sheets log row and Group Binary Sisters feedback
└── db-backup-recovery/
    └── restaurant-online-ordering/
        ├── README.md                          # Detailed operational manual for the assigned project
        ├── backup-plan.md                     # Comprehensive Part A backup plan, RPO/RTO, and security policy
        ├── scripts/
        │   ├── backup.sh                      # Bash automated custom-format backup script (pg_dump -Fc)
        │   ├── backup.ps1                     # PowerShell automated backup script (Windows native)
        │   ├── inspect-backup.sh              # Bash TOC inspection and checksum verification (pg_restore --list)
        │   ├── inspect-backup.ps1             # PowerShell TOC inspection and checksum verification
        │   ├── create-restore-db.sh           # Bash isolated test database provisioning (createdb)
        │   ├── create-restore-db.ps1          # PowerShell isolated test database provisioning
        │   ├── restore.sh                     # Bash test database restoration script (pg_restore)
        │   ├── restore.ps1                    # PowerShell test database restoration script
        │   ├── verify-database.sql            # SQL suite verifying tables, PK/FKs, constraints, indexes, data
        │   ├── verify-access-control.sql      # SQL suite auditing Activity 4 RBAC, roles, and privileges
        │   └── recovery-simulation.sql       # SQL controlled recovery simulation using disposable test data
        ├── logs/
        │   └── .gitkeep                       # Operational execution logs directory (git-ignored)
        ├── evidence/
        │   └── evidence-checklist.md          # 14-item verification evidence and terminal artifact checklist
        ├── verification/
        │   ├── database-verification.md       # Schema, objects, constraints, and data integrity audit
        │   ├── access-control-verification.md # RBAC roles, grants, column-level security, and denied tests
        │   └── recovery-verification.md       # Controlled data loss scenario, recovery audit, and RPO/RTO
        └── reports/
            ├── activity-6-report.md           # PDF-ready formal academic report (13 required sections)
            └── limitations-and-recommendations.md # Blocker analysis, environment limitations, and DBA roadmap
```

---

## ⚙️ Target Database Architecture Summary

| Architecture Item | Setting / Value | Documentation Source |
|---|---|---|
| **System Name** | Restaurant Online Ordering & Table Reservation System | `README.md` |
| **Assigned Development Group** | Binary Sisters (Kathlen Mae Callos & Team) | `README.md` |
| **Upstream Repository URL** | `https://github.com/kathlenmaecallos11-arch/Restaurant-Online-Ordering-Table-Reservation-System` | Assigned Project Specification |
| **Database Engine** | PostgreSQL 18 (Local installation: `C:\Program Files\PostgreSQL\18\bin`) | `psql --version` |
| **Primary Database Name** | `grp_binarysisters_projectdb` | `database/migrations/000_create_database.sql` |
| **Restoration Test Database** | `grp_binarysisters_projectdb_activity6_restore_test` | Phase 6 Specification |
| **Database Owner** | `postgres` | `database/migrations/000_create_database.sql` |
| **Backup Operator Role** | `rors_backup` (Possessing `pg_read_all_data`) | `database/roles/01_create_roles.sql` |
| **Application Runtime User** | `rors_app` (Member of `rors_runtime_grp`) | `database/roles/01_create_roles.sql`, `app/config/database.php` |
| **Read-Only Reporting User** | `rors_report` (Member of `rors_readonly_grp`) | `database/roles/01_create_roles.sql`, `database/roles/02_grants.sql` |
| **Core Relational Tables** | 8 Tables: `customer`, `menu_item`, `restaurant_table`, `staff`, `orders`, `order_item`, `reservation`, `payment` | `database/migrations/001_create_tables.sql` |
| **Application Backend** | PHP 8.1+, Native PDO with prepared statements | `app/config/database.php` |

---

## 🚀 Quick Operator Execution Commands

### Windows PowerShell:
```powershell
cd "c:\Users\Lenovo\Downloads\ACT 6\G10_MESA\db-backup-recovery\restaurant-online-ordering"

# 1. Execute Backup (pg_dump -Fc)
.\scripts\backup.ps1 -Database "grp_binarysisters_projectdb" -User "rors_backup"

# 2. Inspect Archive Table of Contents
.\scripts\inspect-backup.ps1

# 3. Create Isolated Test Database
.\scripts\create-restore-db.ps1

# 4. Restore Dump into Test Database
.\scripts\restore.ps1

# 5. Run Relational & Data Verification Suite
psql -h 127.0.0.1 -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts\verify-database.sql

# 6. Run Access-Control Verification Suite
psql -h 127.0.0.1 -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts\verify-access-control.sql

# 7. Run Controlled Recovery Simulation
psql -h 127.0.0.1 -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts\recovery-simulation.sql
```

### Linux / macOS / WSL (Bash):
```bash
cd db-backup-recovery/restaurant-online-ordering

# 1. Backup
./scripts/backup.sh

# 2. Inspect
./scripts/inspect-backup.sh

# 3. Create Test Database
./scripts/create-restore-db.sh

# 4. Restore
./scripts/restore.sh

# 5. SQL Verification Suites
psql -h localhost -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts/verify-database.sql
psql -h localhost -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts/verify-access-control.sql
psql -h localhost -p 5432 -U postgres -d grp_binarysisters_projectdb_activity6_restore_test -f scripts/recovery-simulation.sql
```

---

## 📊 Implementation & Quality Assurance Dashboard

| Phase | Milestone / Required Deliverable | Status Classification | Notes / Evidence |
|---|---|---|---|
| **Phase 1** | Repository Architecture Inspection | **VERIFIED** | PHP 8 + PostgreSQL 18 stack, 8 tables, 6 FKs, 15 checks, GiST exclusion |
| **Phase 2** | Activity 6 Workspace & Git Protection | **IMPLEMENTED** | `.gitignore`, clean folder hierarchy in `G10_MESA` |
| **Phase 3** | Database Backup Plan (`backup-plan.md`) | **VERIFIED** | Custom format rationale, GFS retention, RPO 24h/15m, RTO 2h/<3m |
| **Phase 4** | Automated Backup Script (`backup.ps1` / `.sh`) | **IMPLEMENTED (PENDING RUN)** | Validates binary, zero-echo prompt, exit code, SHA-256 hash |
| **Phase 5** | Archive TOC Inspector (`inspect-backup.ps1` / `.sh`) | **IMPLEMENTED (PENDING RUN)** | Parses TOC via `pg_restore --list`, audits 8 tables and views |
| **Phase 6** | Isolated Test DB Restoration Suite | **IMPLEMENTED (PENDING RUN)** | Safeguards live DB, provisions test DB, restores cleanly |
| **Phase 7** | Structural & Data Verification Suite | **IMPLEMENTED (PENDING RUN)** | `verify-database.sql` audits schemas, counts, constraints, views |
| **Phase 8** | Access Control Verification Suite | **IMPLEMENTED (PENDING RUN)** | `verify-access-control.sql` audits RBAC, 1 permitted, 4 denied tests |
| **Phase 9** | Controlled Recovery Simulation Suite | **IMPLEMENTED (PENDING RUN)** | `recovery-simulation.sql` tests disposable item 9999 lifecycle |
| **Phase 10** | Comprehensive Academic Report | **COMPLETED & PDF-READY** | `reports/activity-6-report.md` (All 13 required sections) |
| **Phase 11** | Evidence Checklist & Class Tracker | **COMPLETED & READY** | `evidence-checklist.md`, `tracker-and-feedback.md` |
| **Phase 12** | Final Verification & Quality Assurance Audit | **VERIFIED** | Strict adherence to DBA guidelines and academic integrity |

