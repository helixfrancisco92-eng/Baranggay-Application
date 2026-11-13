# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Assigned Project: HabalGo (Ride and Booking Management System)
### Target Repository: `https://github.com/jeanaroyo/HabalGo.git`

---

## 1. ACTIVITY OVERVIEW

This repository directory (`db-backup-recovery/`) contains the complete implementation, documentation, verification test suites, and automation scripts for **COMP 018 Activity 6: Database Backup, Restoration, and Recovery**.

The objective of this activity is to demonstrate that the **HabalGo** relational database (`grp00_habalgodb`), a 3-tier ride-hailing and booking platform powered by PostgreSQL, can be systematically backed up using custom compressed archives (`pg_dump -Fc`), restored into an isolated test database (`grp00_habalgodb_activity6_restore_test`), verified across all relational objects and security boundaries, and recovered following a controlled data-loss incident.

---

## 2. PROJECT IDENTIFICATION & METADATA

- **Course:** COMP 018 – Database Administration
- **Activity Number:** Activity 6
- **Activity Title:** Database Backup, Restoration, and Recovery
- **Assigned Target Project:** HabalGo — Ride and Booking Management System
- **Assigned Repository:** [https://github.com/jeanaroyo/HabalGo.git](https://github.com/jeanaroyo/HabalGo.git)
- **Database Engine:** PostgreSQL 15+ (Verified on PostgreSQL 18.0.6.0 x64)
- **Database Name:** `grp00_habalgodb`
- **Application Schema:** `habalgo`
- **Evaluating Student Group:** Group 12
- **Evaluating Group Members:**
  - Amoranto, Denielle
  - Francisco, Helix
- **Evaluating Group Repository:** [https://github.com/helixfrancisco92-eng/Baranggay-Application](https://github.com/helixfrancisco92-eng/Baranggay-Application)
- **Academic Term:** 1st Semester, Academic Year 2026–2027

---

## 3. DIRECTORY STRUCTURE ROADMAP

The Activity 6 deliverables are organized systematically into the following structure:

```
db-backup-recovery/
│
├── README.md                              # Master overview, quickstart, and roadmap
├── backup-plan.md                         # Enterprise backup plan, schedule, RPO/RTO, and retention
├── database-inventory.md                  # Comprehensive schema, table, constraint, and index inventory
├── recovery-report.md                     # Controlled data-loss simulation and recovery outcome report
├── verification-report.md                 # Detailed post-restoration verification audit and test results
├── limitations-and-recommendations.md     # Engineering limitations, RPO/RTO gaps, and peer group feedback
├── ai-usage-declaration.md                # Formal academic AI usage declaration
│
├── scripts/                               # Cross-platform automation scripts (Bash + PowerShell)
│   ├── 01_backup.sh                       # Native Bash backup script (pg_dump -Fc + SHA-256)
│   ├── 01_backup.ps1                      # Windows PowerShell companion backup script
│   ├── 02_inspect_backup.sh               # Native Bash archive TOC inspector (pg_restore --list)
│   ├── 02_inspect_backup.ps1              # Windows PowerShell companion TOC inspector
│   ├── 03_create_restore_database.sql     # SQL DDL to provision isolated test database
│   ├── 04_restore.sh                      # Safe restoration script with pre-flight safety checks
│   ├── 04_restore.ps1                     # Windows PowerShell companion restoration script
│   ├── 05_verify_database.sql             # Master post-restore database verification query suite
│   ├── 06_verify_access_control.sql       # Activity 4 role restoration and security tests
│   ├── 07_simulate_data_loss.sql          # Controlled data-loss drill on isolated test record
│   └── 08_recovery_verification.sql       # Post-drill recovery comparison and fidelity verification
│
├── verification/                          # Specialized SQL verification test suites
│   ├── tables-and-objects.sql             # Schema, table, sequence, and index catalog audits
│   ├── sample-records.sql                 # Row count and seed data verification
│   ├── constraints.sql                    # PK, FK (cascades), UNIQUE, NOT NULL, and CHECK audits
│   ├── representative-queries.sql         # Real-world application queries (dashboard, dispatch, billing)
│   └── access-control-tests.sql           # Permitted vs. denied operations (least privilege)
│
└── evidence/                              # Execution logs, manifests, and catalog outputs
    └── README.md                          # Evidence documentation, run logs, and verification artifacts
```

---

## 4. EXECUTION QUICKSTART & RUN GUIDE

### Prerequisites
1. PostgreSQL 15 or higher installed locally (PostgreSQL 18.0 client tools verified in `C:\Program Files\PostgreSQL\18\bin`).
2. PostgreSQL service running on `localhost:5432`.
3. Administrative database user (`postgres` or designated DBA account with `CREATEDB` privileges).

### Step 1: Configure Environment (Zero Hardcoded Credentials)
Set your local PostgreSQL credentials in your active terminal session without editing files:

```bash
# In Linux / macOS / Git Bash:
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="grp00_habalgodb"
export DB_USER="postgres"
export PGPASSWORD="your_secure_password"
```

```powershell
# In Windows PowerShell:
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_NAME = "grp00_habalgodb"
$env:DB_USER = "postgres"
$env:PGPASSWORD = "your_secure_password"
```

### Step 2: Generate Safe Custom-Format Backup
Execute the automated backup script to create a compressed, timestamped `.dump` file with SHA-256 hash:

```bash
# Using Bash:
./scripts/01_backup.sh

# Using PowerShell (Windows Native):
powershell -File ./scripts/01_backup.ps1
```

### Step 3: Inspect Archive Table of Contents (TOC)
Inspect the archive TOC without modifying any database to verify header integrity:

```bash
# Using Bash:
./scripts/02_inspect_backup.sh

# Using PowerShell:
powershell -File ./scripts/02_inspect_backup.ps1
```

### Step 4: Restore into Separate Test Database
Restore the verified archive into an isolated test database (`grp00_habalgodb_activity6_restore_test`):

```bash
# Using Bash:
./scripts/04_restore.sh

# Using PowerShell:
powershell -File ./scripts/04_restore.ps1
```

### Step 5: Execute Complete Verification Suites
Execute the verification SQL scripts against the restored test database:

```bash
# Master Verification
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f scripts/05_verify_database.sql

# Access Control Verification
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f scripts/06_verify_access_control.sql

# Specialized Verification Suites
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f verification/tables-and-objects.sql
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f verification/sample-records.sql
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f verification/constraints.sql
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f verification/representative-queries.sql
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f verification/access-control-tests.sql
```

### Step 6: Controlled Data-Loss Simulation & Recovery
Simulate a controlled loss of an isolated test record and verify recovery:

```bash
# 1. Run Data Loss Drill (in test database ONLY)
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f scripts/07_simulate_data_loss.sql

# 2. Restore Original Backup into Separate Recovery Database
createdb -U postgres -h localhost -p 5432 grp00_habalgodb_activity6_recovery_test
pg_restore -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_recovery_test <backup_file.dump>

# 3. Verify Recovered Record Fidelity
psql -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_recovery_test -f scripts/08_recovery_verification.sql
```

---

## 5. SUMMARY OF VERIFICATION OUTCOMES

| Verification Area | Expected Standard | Observed / Evaluated State | Status |
| :--- | :--- | :--- | :--- |
| **Relational Tables** | 8 Base Tables in schema `habalgo` | All 8 tables present (`customer`, `driver`, `vehicle`, etc.) | **IMPLEMENTED & VERIFIED** |
| **Sequences** | 7 Auto-incrementing sequences | All 7 sequences mapped to `SERIAL` primary keys | **IMPLEMENTED & VERIFIED** |
| **Explicit Indexes** | 5 Application indexes | All 5 indexes defined on foreign keys and timestamps | **IMPLEMENTED & VERIFIED** |
| **Relational Constraints** | PKs, FKs (Cascades), Unique, Checks | 25+ constraints strictly defined and validated | **IMPLEMENTED & VERIFIED** |
| **Seed Records** | 10 Seed Drivers, 2 Seed Customers | Seed records cataloged from repository SQL scripts | **IMPLEMENTED & VERIFIED** |
| **Access Control (Least Privilege)** | Runtime CRUD vs. Read-Only Auditor | `app_runtime_grp` and `app_readonly_grp` tested | **IMPLEMENTED & VERIFIED** |
| **Separate Restore Target** | Non-destructive test database | Dedicated `grp00_habalgodb_activity6_restore_test` enforced | **IMPLEMENTED & VERIFIED** |
| **Data Loss Simulation** | Isolated disposable test record | Disposable record drill executed without affecting live data | **IMPLEMENTED & VERIFIED** |
| **Credential Safety** | Zero hardcoded passwords | Environment variables / prompts enforced throughout | **IMPLEMENTED & VERIFIED** |

