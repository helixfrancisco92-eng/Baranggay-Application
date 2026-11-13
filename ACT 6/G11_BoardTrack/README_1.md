# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Assigned Project: BoardTrack — Boarding House & Rental Management System (Group 11)

---

## 📌 Workspace Overview

This workspace contains the complete technical implementation, automated PowerShell and Bash scripts, comprehensive SQL verification and simulation suites, evidence checklists, and formal documentation for **COMP 018 – Database Administration, Activity 6**.

- **Assigned Upstream Project:** BoardTrack — Boarding House & Rental Management System
- **Assigned Group:** Group 11 (Karl Robert Cataluña, Kurt Policarpio, Catalunazy, et al.)
- **Upstream Repository:** `https://github.com/karlrobertc-art/BoardTrack` (Inspected as strictly **READ-ONLY**)
- **Target DBMS:** PostgreSQL 18.6 (x64) (Compatible with PostgreSQL 13+)
- **Primary Database:** `boardtrack_db`
- **Isolated Test Restoration Target:** `boardtrack_db_activity6_restore_test`

---

## 🗂️ Directory Structure

```text
G11_BoardTrack/
├── README.md                                  # Workspace overview and navigation guide (this file)
├── .gitignore                                 # Git rules excluding dumps, credentials, and logs
├── boardtrack_repo/                           # READ-ONLY inspection clone of the assigned project
└── db-backup-recovery/
    └── boardtrack/
        ├── README.md                          # Comprehensive operational manual and execution guide
        ├── backup-plan.md                     # Complete Part A backup plan, RPO/RTO, and security policy
        ├── tracker-and-feedback.md            # Copy-ready Google Sheets log & owner feedback message
        ├── scripts/
        │   ├── backup.ps1                     # PowerShell automated backup script (Windows native)
        │   ├── backup.sh                      # Bash automated custom-format backup script (pg_dump -Fc)
        │   ├── inspect-backup.ps1             # PowerShell TOC inspection and checksum verification
        │   ├── inspect-backup.sh              # Bash TOC inspection and checksum verification (pg_restore --list)
        │   ├── create-restore-db.ps1          # PowerShell isolated test database provisioning
        │   ├── create-restore-db.sh           # Bash isolated test database provisioning (createdb)
        │   ├── restore.ps1                    # PowerShell test database restoration script (pg_restore)
        │   ├── restore.sh                     # Bash test database restoration script
        │   ├── verify-database.sql            # SQL audit suite: tables, PK/FKs, constraints, views, triggers
        │   ├── verify-access-control.sql      # SQL suite auditing Activity 4 RBAC, roles, and privileges
        │   └── recovery-simulation.sql       # SQL controlled recovery simulation using disposable test data
        ├── logs/
        │   └── .gitkeep                       # Operational execution logs directory (git-ignored)
        ├── evidence/
        │   └── evidence-checklist.md          # 14-item verification evidence and terminal artifact checklist
        ├── verification/
        │   ├── database-verification.md       # Schema, objects, constraints, and data integrity audit
        │   ├── access-control-verification.md # RBAC roles, grants, schema privileges, and denied tests
        │   └── recovery-verification.md       # Controlled data loss scenario, recovery audit, and RPO/RTO
        └── reports/
            ├── activity-6-report.md           # PDF-ready formal academic report (13 required sections)
            └── limitations-and-recommendations.md # Blocker analysis, environment limitations, and DBA roadmap
```

---

## ⚡ Quick Start: Operator Command Reference

From `db-backup-recovery/boardtrack/`:

```powershell
# 1. Execute Backup (pg_dump -Fc)
.\scripts\backup.ps1 -Database "boardtrack_db" -User "postgres" -OutputDir "C:\db-backups\boardtrack"

# 2. Inspect Backup Archive TOC (pg_restore --list)
.\scripts\inspect-backup.ps1 -DumpPath "C:\db-backups\boardtrack\boardtrack_db_activity6.dump"

# 3. Create Isolated Test Database (createdb)
.\scripts\create-restore-db.ps1 -RestoreDb "boardtrack_db_activity6_restore_test" -AdminUser "postgres"

# 4. Restore Dump to Test Database (pg_restore)
.\scripts\restore.ps1 -RestoreDb "boardtrack_db_activity6_restore_test" -DumpPath "C:\db-backups\boardtrack\boardtrack_db_activity6.dump"

# 5. Verify Relational Schema & Data Integrity
psql -h localhost -p 5432 -U postgres -d boardtrack_db_activity6_restore_test -f .\scripts\verify-database.sql

# 6. Verify Access Control & Role Permissions
psql -h localhost -p 5432 -U postgres -d boardtrack_db_activity6_restore_test -f .\scripts\verify-access-control.sql

# 7. Execute Controlled Recovery Simulation
psql -h localhost -p 5432 -U postgres -d boardtrack_db_activity6_restore_test -f .\scripts\recovery-simulation.sql
```

---
*COMP 018 — Database Administration | Polytechnic University of the Philippines*

