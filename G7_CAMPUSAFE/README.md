# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Target Project: Group 7 — CampusSafe (Campus Hazard & Safety Reporting System)

---

## 1. Executive Summary & Project Identification

* **Assigned Project:** CampusSafe (Campus Hazard & Safety Reporting System)
* **Assigned Group:** Group 7
* **Target Project Repository:** [https://github.com/jeffersonorpesa2-ops/grp07-campussafe](https://github.com/jeffersonorpesa2-ops/grp07-campussafe)
* **Evaluating Group:** Group 12
* **Evaluating Group Members:**
  * Amoranto, Denielle
  * Francisco, Helix
* **Evaluating Group Repository:** [https://github.com/helixfrancisco92-eng/Baranggay-Application](https://github.com/helixfrancisco92-eng/Baranggay-Application)
* **Course Subject:** COMP 018 – Database Administration
* **Academic Term:** 1st Semester, Academic Year 2026–2027
* **Academic Institution:** Polytechnic University of the Philippines (PUP), College of Computer and Information Sciences (CCIS)
* **Target DBMS:** PostgreSQL 14+ (Evaluated and executed on PostgreSQL 18.0.6.0 x64 on `localhost:5432`)
* **Primary Database Name:** `grp07_campussafedb`
* **Isolated Restoration Database:** `grp07_campussafedb_activity6_restore_test`
* **Recovery Simulation Database:** `grp07_campussafedb_recovery_drill`

This implementation establishes an enterprise-grade backup, restoration, verification, and disaster-recovery suite engineered strictly against the authentic schema, constraints, sequences, relational dependencies, and Activity 4 Role-Based Access Control (RBAC) architecture of the CampusSafe system.

---

## 2. Directory Structure

```
db-backup-recovery/
│
├── README.md                           # Master activity index & execution guide
├── database-inventory.md               # Complete schema, tables, keys, & catalog inventory
├── backup-plan.md                      # Backup methodology, RPO/RTO, & retention policy
├── backup-execution-report.md          # Backup execution specifications & archive inspection
├── restoration-report.md               # Isolated database restoration procedures & audit
├── verification-report.md              # Relational, object, constraint, & query verification
├── recovery-simulation-report.md       # Controlled canary data-loss & recovery drill
├── access-control-recovery.md          # Activity 4 RBAC & privilege re-establishment plan
├── limitations-and-recommendations.md  # Production hardening recommendations & evaluation
├── ai-usage-declaration.md             # Transparent AI disclosure in compliance with CCIS rules
│
├── scripts/                            # Production-ready automation scripts (Bash & PowerShell)
│   ├── 01_backup.sh                    # POSIX custom-format backup script (pg_dump -Fc)
│   ├── 01_backup.ps1                   # Windows PowerShell custom-format backup script
│   ├── 02_inspect_backup.sh            # POSIX archive TOC inspection script (pg_restore -l)
│   ├── 02_inspect_backup.ps1           # Windows PowerShell TOC inspection script
│   ├── 03_create_restore_database.sql  # DDL script provisioning isolated test database
│   ├── 04_restore.sh                   # POSIX test database restoration script (pg_restore)
│   ├── 04_restore.ps1                  # Windows PowerShell test database restoration script
│   ├── 05_verify_objects.sql           # SQL audit for 9 tables, 10 indexes, & 9 sequences
│   ├── 06_verify_records.sql           # SQL audit for record counts & seed integrity
│   ├── 07_verify_constraints.sql       # SQL audit for PK, FK, UNIQUE, NOT NULL, & CHECK
│   ├── 08_verify_access_control.sql    # SQL re-application & verification of Activity 4 roles
│   ├── 09_simulate_data_loss.sql       # SQL canary record creation & controlled deletion
│   └── 10_verify_recovery.sql          # SQL validation of recovered record from backup
│
├── verification/                       # Deep verification query suites
│   ├── database-objects.sql            # Exhaustive schema catalog inspection queries
│   ├── sample-records.sql              # Target data verification queries across all 9 tables
│   ├── constraints.sql                 # Comprehensive constraint validation & test suite
│   ├── representative-queries.sql      # Realistic multi-table operational business queries
│   └── access-control-tests.sql        # Granular permitted vs. denied privilege test cases
│
└── evidence/                           # Non-sensitive execution evidence & manifests
    ├── README.md                       # Evidence catalog index and verification standards
    ├── 01_backup_manifest.txt          # Backup execution parameters, timestamp, & SHA-256
    ├── 02_archive_toc_listing.txt      # Table of Contents extract from pg_restore --list
    ├── 03_restore_test_log.txt         # Isolated restoration console output
    ├── 04_verification_results.txt     # Test database object and row count validation
    └── 05_recovery_simulation.txt      # Canary disaster simulation and comparison log
```

---

## 3. Quick Start & Execution Workflow

All scripts are provided in dual formats: **Bash (`.sh`)** for Linux/macOS/Git Bash environments and **PowerShell (`.ps1`)** for native Windows environments.

### Phase 1: Environment Configuration
Set your PostgreSQL administrative or backup operator credentials in your session. Never hardcode credentials into files or commits:

```powershell
# Windows PowerShell
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_NAME = "grp07_campussafedb"
$env:DB_USER = "campussafe_backup"    # Or "postgres" for superuser operations
$env:PGPASSWORD = "your_secure_password"
$env:BACKUP_DIR = "C:\Users\Lenovo\Downloads\ACT 6\G7_CAMPUSAFE\db-backup-recovery\backups"
```

```bash
# POSIX Shell / Git Bash
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="grp07_campussafedb"
export DB_USER="campussafe_backup"
export PGPASSWORD="your_secure_password"
export BACKUP_DIR="./backups"
```

### Phase 2: Execute Backup
```powershell
# Windows PowerShell
.\scripts\01_backup.ps1

# POSIX Bash
chmod +x ./scripts/*.sh
./scripts/01_backup.sh
```

### Phase 3: Inspect Archive Table of Contents
```powershell
.\scripts\02_inspect_backup.ps1
```

### Phase 4: Provision Isolated Test Database
```powershell
psql -U postgres -h localhost -p 5432 -f scripts\03_create_restore_database.sql
```

### Phase 5: Restore Backup into Test Database
```powershell
.\scripts\04_restore.ps1
```

### Phase 6: Run Comprehensive Integrity Verification
```powershell
psql -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\05_verify_objects.sql
psql -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\06_verify_records.sql
psql -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\07_verify_constraints.sql
psql -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\08_verify_access_control.sql
```

### Phase 7: Execute Controlled Disaster Recovery Simulation
```powershell
# Step A: Seed canary record and simulate accidental loss in test DB
psql -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\09_simulate_data_loss.sql

# Step B: Restore snapshot to recovery database and verify data preservation
psql -U postgres -h localhost -p 5432 -d grp07_campussafedb_recovery_drill -f scripts\10_verify_recovery.sql
```

---

## 4. Academic Integrity & Safety Standards

1. **Zero Fabrication:** No simulated command outputs, mock checksums, or fabricated screenshots are presented as executed results.
2. **Clear Operational Statuses:**
   * `IMPLEMENTED`: All configuration files, SQL queries, DDL, and scripts are engineered and validated syntactically.
   * `EXECUTED`: Actual command has been physically run against the host environment.
   * `VERIFIED`: Actual execution output has been checked against expected criteria.
   * `PENDING`: Awaiting live cluster credentials, manual human execution, or defense presentation.
3. **Database Protection:** Zero destructive operations on the live `grp07_campussafedb` production database. All tests are conducted strictly in isolated databases (`grp07_campussafedb_activity6_restore_test` and `grp07_campussafedb_recovery_drill`).
4. **Credential Security:** Plaintext passwords, tokens, and session secrets are strictly excluded from repository tracking via `.gitignore`.

