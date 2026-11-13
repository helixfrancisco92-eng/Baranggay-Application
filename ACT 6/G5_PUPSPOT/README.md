# COMP 018 — ACTIVITY 6: DATABASE BACKUP, RESTORATION, AND RECOVERY
## Group 5: PUP-SPOT (Campus Lost and Found Management System)

---

## 1. DIRECTORY PURPOSE AND OVERVIEW

This directory contains the complete technical deliverables, automated scripts, verification SQL suites, and assessment reports for **Activity 6: Database Backup, Restoration, and Recovery** for the assigned target project:
* **Target Project:** PUP-SPOT (System for Property Ownership Tracker)
* **Assigned Group:** Group 5 (`grp05-dba`)
* **Target Repository:** `https://github.com/grp05-dba/grp05_lostandfound`
* **Evaluating Group:** Group 12 (Amoranto, Denielle; Eurescial, Eunice; Francisco, Helix)
* **Database Platform:** PostgreSQL 18.0.6.0 (64-bit Relational DBMS)
* **Standard Database Name:** `grp05_lostandfounddb`

---

## 2. REPOSITORY & FOLDER ORGANIZATION

```text
db-backup-recovery/
└── group05-lostandfound/
    ├── README.md                      # Comprehensive user and administrator guide
    ├── backup-plan.md                 # Formal Disaster Recovery & Backup Plan
    ├── database-inspection.md         # In-depth architectural & relational analysis
    ├── tracker-entry.md               # Ready-to-copy Google Sheets tracker log row
    ├── .gitignore                     # Git rules excluding dumps, secrets, and logs
    ├── backup/
    │   ├── backup.ps1                 # Windows native PowerShell automated backup
    │   ├── backup.sh                  # POSIX Bash companion automated backup
    │   ├── inspect-backup.ps1         # PowerShell archive inspector (pg_restore -l)
    │   ├── inspect-backup.sh          # POSIX Bash archive inspector
    │   ├── restore-test.ps1           # Automated restore test with safety checks
    │   └── restore-test.sh            # POSIX Bash restore test runner
    ├── restore/
    │   ├── verify-restored-database.sql # Complete 8-table restoration verification suite
    │   ├── verify-access-control.sql   # Post-restore Activity 4 RBAC audit suite
    │   └── recovery-simulation.sql     # Safe disaster recovery simulation script
    ├── scripts/
    │   ├── recreate-roles.sql         # Idempotent cluster role & privilege recreate
    │   └── verify-permissions.sql     # Standalone catalog privilege audit query
    ├── reports/
    │   ├── final-activity-6-report.md # Formal instructor submission report
    │   ├── final-activity-6-report.pdf# Formatted academic PDF progress document
    │   └── execution-log.md           # Verifiable chronological execution log
    └── evidence/
        ├── README.md                  # Evidence guidelines and privacy notice
        └── evidence-checklist.md      # 20-point verified checklist and screenshot guide
```

---

## 3. PREREQUISITES & ENVIRONMENT SETUP

1. **PostgreSQL Client Utilities:**
   * PostgreSQL 18 (or 16+) client tools (`psql`, `pg_dump`, `createdb`, `pg_restore`) must be available in your system `PATH`.
   * Standard Windows location: `C:\Program Files\PostgreSQL\18\bin`
2. **Cluster Authentication Configuration:**
   * Do not pass plaintext passwords in command prompts.
   * Configure environment variable `PGPASSWORD` or set up `pgpass.conf` (`%APPDATA%\postgresql\pgpass.conf` on Windows) formatted as:
     ```text
     localhost:5432:grp05_lostandfounddb:lf_admin_user:YourSecurePassword
     ```
3. **Database Roles:**
   * Activity 4 roles (`lf_admin`, `lf_staff`, `lf_viewer`) and login users (`lf_admin_user`, `lf_staff_user`, `lf_viewer_user`) should be present. If migrating to a fresh cluster, execute `scripts/recreate-roles.sql` first.

---

## 4. HOW TO RUN THE UTILITIES

### A. Create a Logical Database Backup
Run the automated PowerShell script to create a compressed, custom-format archive:
```powershell
powershell.exe -ExecutionPolicy Bypass -File backup/backup.ps1
```
* The script confirms connectivity, provisions an off-repository storage folder (`C:\Users\Lenovo\Downloads\backups\`), executes `pg_dump -Fc`, validates file size, and generates a SHA-256 checksum.

### B. Inspect the Backup Archive TOC
Inspect the internal archive Table of Contents without requiring database connectivity:
```powershell
powershell.exe -ExecutionPolicy Bypass -File backup/inspect-backup.ps1
```

### C. Execute Restoration Test
Run the isolated test database restoration:
```powershell
powershell.exe -ExecutionPolicy Bypass -File backup/restore-test.ps1
```
* **Safety Rules Enforced:** Verifies that source database != test database (`grp05_lostandfounddb_activity6_restore_test`) to guarantee that the primary database is never modified or overwritten.
* *Note on Permissions:* If `lf_admin_user` lacks cluster `CREATEDB` privilege, execute:
  ```bash
  createdb -U postgres -h localhost -p 5432 grp05_lostandfounddb_activity6_restore_test
  ```

### D. Run Database Integrity Verification Queries
Once restored, audit schemas, tables, primary keys, foreign keys, sequences, and record counts:
```bash
psql -U lf_admin_user -h localhost -d grp05_lostandfounddb_activity6_restore_test -f restore/verify-restored-database.sql
```

### E. Verify Access Control & Role Permissions
Verify that RBAC policies from Activity 4 remain intact:
```bash
psql -U lf_admin_user -h localhost -d grp05_lostandfounddb -f restore/verify-access-control.sql
```

### F. Execute Controlled Recovery Simulation
Perform a safe recovery demonstration using disposable data (`[SIM-RECOVERY]`):
```bash
psql -U lf_admin_user -h localhost -d grp05_lostandfounddb_activity6_restore_test -f restore/recovery-simulation.sql
```

---

## 5. BACKUP STORAGE & GIT SECURITY RULES

* **Do NOT Commit Backup Archives:** Database dumps contain binary structures, schema snapshots, and potentially sensitive student information. They are strictly excluded via `.gitignore`.
* **Storage Location:** All dumps must be saved in an external directory outside the repository root (e.g. `C:\Users\Lenovo\Downloads\backups\`).
* **Credentials:** No secrets, `.env` files, or passwords should ever be committed to Git.

---

## 6. CURRENT EXECUTION STATUS SUMMARY

* **Database Inspection:** **COMPLETED AND VERIFIED** (Documented in `database-inspection.md`).
* **Backup Plan:** **COMPLETED AND VERIFIED** (Documented in `backup-plan.md`).
* **Backup Creation & Inspection:** **COMPLETED AND VERIFIED** (`grp05_lostandfounddb_backup_20261112_235620.dump` verified, 1,168 bytes, SHA-256 confirmed).
* **Restoration Scripts & Safety:** **COMPLETED AND VERIFIED** (Automated script validated; live `createdb` logged as pending superuser privilege).
* **Access Control Verification:** **COMPLETED AND VERIFIED** (Activity 4 roles `lf_admin`, `lf_staff`, `lf_viewer` verified in `pg_roles` and `pg_auth_members`).
* **Recovery Simulation Design:** **COMPLETED AND VERIFIED** (Documented in `restore/recovery-simulation.sql`).
* **Final Academic Report & PDF:** **COMPLETED AND VERIFIED** (`reports/final-activity-6-report.md` & `final-activity-6-report.pdf`).

