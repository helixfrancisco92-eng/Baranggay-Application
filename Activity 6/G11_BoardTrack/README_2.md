# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Assigned Project: BoardTrack — Boarding House & Rental Management System (Group 11)

---

## 📌 Executive Overview

This directory contains the complete technical implementation, automation scripts, verification suites, disaster recovery drill procedures, and formal documentation for **COMP 018 – Database Administration, Activity 6: Database Backup, Restoration, and Recovery**.

The assigned project evaluated is **BoardTrack — Boarding House & Rental Management System** developed by **Group 11 (Karl Robert Cataluña, Kurt Policarpio, Catalunazy, et al.)**. The system provides room management, tenant tracking, lease lifecycle administration, rent payment ledgering, and utility billing for boarding house landlords, backed by a Node.js/Express web application and a PostgreSQL relational database.

### Critical Academic Safety Guidelines
In strict compliance with Activity 6 safety and integrity mandates:
- **READ-ONLY Upstream Rule:** The assigned BoardTrack repository (`https://github.com/karlrobertc-art/BoardTrack`) was inspected as strictly read-only. No commits, branches, pull requests, or code modifications were introduced to the original repository.
- **Data Protection & Version Control Rule:** All backup archives (`*.dump`) and SQL transaction dumps are stored outside version control in a protected directory (`C:\db-backups\boardtrack\`). No passwords, API keys, or tenant PII are committed to Git.
- **Isolation Rule:** All restoration operations and disaster recovery drills are executed exclusively against an isolated, newly provisioned test database (`boardtrack_db_activity6_restore_test`). The primary production database (`boardtrack_db`) remains completely untouched.

---

## 🗂️ Activity 6 Directory Structure

```text
db-backup-recovery/
└── boardtrack/
    ├── README.md                              # Comprehensive operational manual (this file)
    ├── backup-plan.md                         # Complete Part A backup plan, RPO/RTO, and security policy
    ├── tracker-and-feedback.md                # Copy-ready Google Sheets log & owner feedback message
    ├── scripts/
    │   ├── backup.ps1                         # PowerShell automated backup script (Windows native)
    │   ├── backup.sh                          # Bash automated custom-format backup script (pg_dump -Fc)
    │   ├── inspect-backup.ps1                 # PowerShell TOC inspection and checksum verification
    │   ├── inspect-backup.sh                  # Bash TOC inspection and checksum verification (pg_restore --list)
    │   ├── create-restore-db.ps1              # PowerShell isolated test database provisioning
    │   ├── create-restore-db.sh               # Bash isolated test database provisioning (createdb)
    │   ├── restore.ps1                        # PowerShell test database restoration script (pg_restore)
    │   ├── restore.sh                         # Bash test database restoration script
    │   ├── verify-database.sql                # SQL audit suite: tables, PK/FKs, constraints, views, triggers
    │   ├── verify-access-control.sql          # SQL suite auditing Activity 4 RBAC, roles, and privileges
    │   └── recovery-simulation.sql           # SQL controlled recovery simulation using disposable test data
    ├── logs/
    │   └── .gitkeep                           # Operational execution logs directory (git-ignored)
    ├── evidence/
    │   └── evidence-checklist.md              # 14-item verification evidence and terminal artifact checklist
    ├── verification/
    │   ├── database-verification.md           # Schema, objects, constraints, and data integrity audit
    │   ├── access-control-verification.md     # RBAC roles, grants, schema privileges, and denied tests
    │   └── recovery-verification.md           # Controlled data loss scenario, recovery audit, and RPO/RTO
    └── reports/
        ├── activity-6-report.md               # PDF-ready formal academic report (13 required sections)
        └── limitations-and-recommendations.md # Blocker analysis, environment limitations, and DBA roadmap
```

---

## ⚙️ Target Database Architecture Summary

| Parameter | Discovered Configuration | Source Reference |
|---|---|---|
| **System Name** | BoardTrack — Boarding House & Rental Management System | `README.md`, `package.json` |
| **Assigned Group** | Group 11 (Karl Robert Cataluña & team) | Repository git log & commit history |
| **Repository URL** | `https://github.com/karlrobertc-art/BoardTrack` | Project specification |
| **Backend Stack** | Node.js (≥ 20.12), Express 4.19.2, EJS 3.1.10, `pg` (v8.12.0) | `package.json`, `src/server.js` |
| **Database Engine** | PostgreSQL 18.6 (x64) (Local binary: `C:\Program Files\PostgreSQL\18\bin`) | `psql --version`, Windows Service `postgresql-x64-18` |
| **Target Database** | `boardtrack_db` | `.env.example`, `docs/database.md` |
| **Restoration Database**| `boardtrack_db_activity6_restore_test` | Provisioned dynamically in Phase 6 |
| **PostgreSQL Extensions**| `btree_gist` (GiST exclusion constraint), `pgcrypto` (bcrypt hashing) | `db/migrations/001_schema.sql` |
| **Relational Tables** | 7 Tables: `property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, `app_user` (+ `schema_migrations`) | `db/migrations/001_schema.sql` |
| **Exclusion Constraint**| `ex_lease_no_overlap` on `lease` (blocks overlapping active leases per room) | `db/migrations/001_schema.sql` |
| **Triggers / Functions**| `sync_room_status()` (`trg_lease_sync_room`), `guard_room_status()` (`trg_room_status_guard`) | `db/migrations/001_schema.sql` |
| **Reporting Views** | `v_lease_summary` (dynamically aggregates lease totals and utility charges) | `db/migrations/001_schema.sql` |
| **Intended DB Roles** | `boardtrack_owner`, `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`, `boardtrack_app` | `docs/user-roles.md` |

---

## 🚀 Step-by-Step Operator Execution Guide

All automation scripts are cross-platform compatible and support both **Windows PowerShell** and **POSIX/Bash** (Linux, macOS, WSL).

### 1. Execute Database Backup (Phase 4)
Generates a custom-format logical archive (`-Fc`), validates exit codes, ensures non-zero file size, and computes a SHA-256 checksum:
```powershell
# Windows PowerShell
.\scripts\backup.ps1 -Database "boardtrack_db" -User "postgres" -OutputDir "C:\db-backups\boardtrack"
```
```bash
# POSIX / Bash
./scripts/backup.sh boardtrack_db postgres localhost 5432 /var/backups/boardtrack
```

### 2. Inspect Archive Table-of-Contents (Phase 5)
Extracts TOC metadata and audits all 7 tables, views, functions, and triggers without executing DDL:
```powershell
# Windows PowerShell
.\scripts\inspect-backup.ps1 -DumpPath "C:\db-backups\boardtrack\boardtrack_db_activity6.dump"
```
```bash
# POSIX / Bash
./scripts/inspect-backup.sh /var/backups/boardtrack/boardtrack_db_activity6.dump
```

### 3. Provision Isolated Test Database (Phase 6)
Creates an empty database separate from `boardtrack_db` with strict boundary checks:
```powershell
# Windows PowerShell
.\scripts\create-restore-db.ps1 -RestoreDb "boardtrack_db_activity6_restore_test" -AdminUser "postgres"
```
```bash
# POSIX / Bash
./scripts/create-restore-db.sh boardtrack_db_activity6_restore_test boardtrack_db postgres
```

### 4. Restore Dump to Test Database (Phase 6)
Restores schema and records without suppressing ownership errors:
```powershell
# Windows PowerShell
.\scripts\restore.ps1 -RestoreDb "boardtrack_db_activity6_restore_test" -DumpPath "C:\db-backups\boardtrack\boardtrack_db_activity6.dump"
```
```bash
# POSIX / Bash
./scripts/restore.sh boardtrack_db_activity6_restore_test boardtrack_db /var/backups/boardtrack/boardtrack_db_activity6.dump
```

### 5. Verify Restored Database Objects and Data (Phase 7)
Executes the comprehensive SQL audit suite validating constraints, triggers, and baseline record counts:
```bash
psql -h localhost -p 5432 -U postgres -d boardtrack_db_activity6_restore_test -f scripts/verify-database.sql
```

### 6. Verify Access-Control & Role Privileges (Phase 7.D)
Audits cluster roles, schema permissions, table grants, and executes permitted and denied operation tests:
```bash
psql -h localhost -p 5432 -U postgres -d boardtrack_db_activity6_restore_test -f scripts/verify-access-control.sql
```

### 7. Execute Controlled Recovery Simulation (Phase 8)
Simulates accidental transaction deletion on a disposable payment record and verifies selective recovery:
```bash
psql -h localhost -p 5432 -U postgres -d boardtrack_db_activity6_restore_test -f scripts/recovery-simulation.sql
```

---

## 📊 Status Classification Summary

| Task / Deliverable | Status | Justification / Operational Evidence |
|---|:---:|---|
| **Phase 1: Repository Inspection** | **VERIFIED** | Inspected full codebase, schema migrations, seeders, user roles, flaw remediation report. |
| **Phase 2: Workspace Creation** | **VERIFIED** | Provisioned `db-backup-recovery/boardtrack/` hierarchy, `.gitignore`, and log structures. |
| **Phase 3: Database Backup Plan** | **VERIFIED** | Formulated comprehensive Part A–E plan with RPO/RTO and least-privilege security. |
| **Phase 4: Backup Scripting** | **IMPLEMENTED** | Created `backup.ps1` and `backup.sh` with parameterization and SHA-256 calculation. |
| **Phase 4: Backup Live Run** | **PENDING** | Awaits local database password input from operator (no hardcoded credentials in repo). |
| **Phase 5: Archive Inspection** | **IMPLEMENTED** | Created `inspect-backup.ps1` and `inspect-backup.sh` validating TOC and checksums. |
| **Phase 6: Isolated DB Provisioning** | **IMPLEMENTED** | Created `create-restore-db.ps1` and `create-restore-db.sh` with live DB guard checks. |
| **Phase 6: Restoration Execution** | **IMPLEMENTED** | Created `restore.ps1` and `restore.sh` with verbose logging and error handling. |
| **Phase 7: Schema Verification** | **IMPLEMENTED** | Built `verify-database.sql` checking all 7 tables, views, triggers, and constraints. |
| **Phase 7: Access-Control Verification** | **IMPLEMENTED** | Built `verify-access-control.sql` testing permitted vs. denied operations (SQLSTATE 42501). |
| **Phase 8: Recovery Simulation** | **IMPLEMENTED** | Built `recovery-simulation.sql` executing safe disposable record deletion and recovery. |
| **Phase 9: Comprehensive Report** | **VERIFIED** | Authored PDF-ready `reports/activity-6-report.md` covering all 13 required sections. |
| **Phase 10: Evidence Checklist** | **VERIFIED** | Created `evidence/evidence-checklist.md` with 14 itemized terminal evidence mappings. |
| **Phase 11: Tracker & Feedback** | **VERIFIED** | Formatted copy-ready Google Sheets log row and drafted professional owner feedback. |
| **Phase 12: Final Review** | **VERIFIED** | Strict read-only enforcement confirmed; zero fabricated outputs or credentials. |

---
*Prepared by Group 11 Evaluation Team | COMP 018 Database Administration*

