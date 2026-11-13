# COMP 018 – Activity 6: Database Backup, Restoration, and Recovery
## Target Project: BrewPOS (Café & Point of Sale System)

This repository contains the complete implementation, automation scripts, SQL verification suites, reports, and evidence tracking templates for **COMP 018: Database Administration – Activity 6** applied to the BrewPOS system.

---

## 📁 Directory Structure

```text
db-backup-recovery/
└── brewpos/
    ├── README.md                               # Project & Activity 6 overview (this file)
    ├── activity-6-tracker-template.csv         # Class submission tracker template
    │
    ├── backup-plan/
    │   └── backup-plan.md                      # Comprehensive backup, RPO, RTO & security strategy
    │
    ├── configuration/
    │   └── .env.example                        # Secure environment configuration template
    │
    ├── scripts/
    │   ├── backup-database.ps1 / .sh           # Full logical backup generator (pg_dump -Fc)
    │   ├── inspect-backup.ps1 / .sh            # TOC and integrity inspection (pg_restore --list)
    │   ├── create-restore-test-database.ps1/.sh# Creates isolated disposable test database
    │   ├── restore-database.ps1 / .sh          # Restores archive to test database (pg_restore)
    │   ├── verify-restoration.ps1 / .sh        # Executes schema & constraint verification queries
    │   └── recovery-simulation.ps1 / .sh       # Controlled disaster & data recovery simulation
    │
    ├── sql/
    │   ├── schema-setup.sql                    # Clean DDL extracted from repository documentation
    │   ├── verification-queries.sql            # Table, row, PK, FK, constraint & sequence checks
    │   ├── access-control-setup.sql            # Roles, privileges, grant & denial verification
    │   └── recovery-test-data.sql              # Disposable test records for recovery simulation
    │
    ├── reports/
    │   ├── repository-inspection.md            # In-depth architectural & database inspection
    │   ├── backup-report.md                    # Backup execution & validation documentation
    │   ├── restoration-report.md               # Restoration execution & object count analysis
    │   ├── verification-report.md              # Integrity, schema & constraint test results
    │   ├── recovery-simulation-report.md       # Step-by-step incident & recovery simulation report
    │   ├── limitations-and-errors.md           # Blockers, security notices & repository anomalies
    │   └── final-activity-6-report.md          # Complete formal academic report (PDF-ready)
    │
    └── evidence/
        └── README.md                           # 20-point execution evidence checklist & status
```

---

## 📌 Executive Summary & Key Technical Findings

1. **Target Project:** BrewPOS Point-of-Sale System (`https://github.com/Nycri/brewpos`)
2. **Database Management System:** PostgreSQL (Cluster version 18.6 locally installed and running)
3. **Primary Database Name:** `brewpos_db`
4. **Architectural & Schema Overview:**
   - BrewPOS uses a Node.js/NestJS REST backend paired with a PostgreSQL database and React frontend.
   - The relational database comprises **10 core tables** (`users`, `categories`, `products`, `customers`, `orders`, `order_items`, `payments`, `inventory_transactions`, `suppliers`, `shift_logs`), controlling real-time sales transactions, stock balances, and staff shifts.
   - PostgreSQL roles are managed at the cluster level; user privilege scripts have been structured in `sql/access-control-setup.sql` to support post-restore security verification.

---

## 🚀 Quick Start Guide

### 1. Environment Configuration
Copy the configuration template and supply your local database credentials:
```bash
cp configuration/.env.example configuration/.env
```
Edit `configuration/.env` to specify your PostgreSQL username, password, host, port, and database names.

### 2. Execution Workflow (PowerShell on Windows)
Run the automated scripts in sequence from the `scripts/` directory:

```powershell
# Step 1: Backup production/original database
.\scripts\backup-database.ps1

# Step 2: Inspect archive TOC and integrity
.\scripts\inspect-backup.ps1 -BackupFile "..\backups\<backup_file>.dump"

# Step 3: Create disposable restoration database
.\scripts\create-restore-test-database.ps1

# Step 4: Restore backup into test database
.\scripts\restore-database.ps1 -BackupFile "..\backups\<backup_file>.dump"

# Step 5: Verify objects, keys, and constraints
.\scripts\verify-restoration.ps1

# Step 6: Run controlled recovery simulation
.\scripts\recovery-simulation.ps1
```

*(Equivalent `.sh` scripts are also provided for Linux / macOS environments).*

---

## 📊 Status Summary Table

| Phase | Description | Status | Verification Detail |
|---|---|---|---|
| Phase 1 | Repository Inspection | **COMPLETED AND VERIFIED** | Schema mapped across 10 core tables, roles, and relational constraints |
| Phase 2 | Directory & Script Structure | **COMPLETED AND VERIFIED** | Folders, automation scripts, SQL, and templates generated |
| Phase 3 | Part A: Backup Plan | **COMPLETED AND VERIFIED** | Backup strategy, RPO (24 hrs), and RTO (30 mins) documented |
| Phase 4 | Part B: Backup Creation & Inspection | **COMPLETED AND VERIFIED** (Static/Archive TOC) / **PENDING** (Live DB connection) | `pg_restore --list` verified on disk; live backup pending credential entry |
| Phase 5 | Part C: Restoration Test | **CREATED – NOT EXECUTED / PENDING** | Script generated; awaits live execution against `brewpos_db_restore_test` |
| Phase 6 | Part D: Database Verification | **CREATED – NOT EXECUTED / PENDING** | SQL suite created matching BrewPOS schema; awaits execution |
| Phase 7 | Part E: Access-Control Verification | **CREATED – NOT EXECUTED / PENDING** | Role privilege and permission-denied tests configured |
| Phase 8 | Part F: Recovery Simulation | **CREATED – NOT EXECUTED / PENDING** | Procedure & disposable test data ready for execution |
| Phase 9 | Part G: Final Academic Report | **COMPLETED AND VERIFIED** | Generated in Markdown (`final-activity-6-report.md`) & PDF-ready format |
| Phase 10 | Evidence Checklist | **COMPLETED AND VERIFIED** | 20 mandatory execution checklist items cataloged |
| Phase 11 | Tracker CSV Template | **COMPLETED AND VERIFIED** | Populated with accurate project information |
| Phase 12 | PDF-Ready Documentation | **COMPLETED AND VERIFIED** | Formatted report & document compilation ready |