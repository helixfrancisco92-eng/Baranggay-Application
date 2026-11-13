# COMP 018 Activity 6 — Execution Evidence Repository
## Target Project: Group 7 — CampusSafe (Campus Hazard & Safety Reporting System)
### Evaluating Group: Group 12

---

## 1. Purpose & Verification Standards

This directory serves as the official repository for authentic execution manifests, terminal logs, cryptographic checksums, and catalog audit extracts generated during COMP 018 Activity 6.

### Academic Integrity & Safety Rules:
1. **Zero Fabrication:** In accordance with PUP CCIS academic regulations, no simulated terminal outputs, false screenshots, or mock cryptographic hashes are recorded as executed results.
2. **Clear Operational Statuses:**
   * **`IMPLEMENTED`**: All scripts, configurations, and queries are syntactically and structurally verified against the authentic CampusSafe repository.
   * **`EXECUTED`**: Commands physically executed on the evaluation machine.
   * **`VERIFIED`**: Command outputs inspected and confirmed against expected criteria.
   * **`PENDING`**: Operational commands awaiting live superuser credentials or oral defense demonstration.
3. **Zero Plaintext Secrets:** Plaintext passwords, tokens, and sensitive strings are excluded from all committed evidence files.

---

## 2. Evidence Directory Map

```
evidence/
├── README.md                      # This verification standard and execution index
├── 01_backup_manifest.txt         # Actual pg_dump parameters, timestamp, size, & SHA-256
├── 02_archive_toc_listing.txt     # Table of Contents extracted via pg_restore --list
├── 03_restore_test_log.txt        # Isolated pg_restore console log and exit code
├── 04_verification_results.txt    # Output of verification scripts 05 through 08
└── 05_recovery_simulation.txt     # Output of canary disaster loss and recovery verification
```

---

## 3. Discovered System & Catalog Baseline (VERIFIED)

### System Discovery Baseline:
* **Host Operating System:** Microsoft Windows 11 Home / Pro (x64)
* **PostgreSQL Engine:** PostgreSQL 18.0.6.0 (Service: `postgresql-x64-18` on TCP port 5432)
* **PostgreSQL Client Binaries:** `C:\Program Files\PostgreSQL\18\bin` (`psql.exe`, `pg_dump.exe`, `pg_restore.exe`, `createdb.exe`)
* **Target Repository:** `https://github.com/jeffersonorpesa2-ops/grp07-campussafe`
* **Target Database:** `grp07_campussafedb`
* **Isolated Restoration Database:** `grp07_campussafedb_activity6_restore_test`
* **Disaster Recovery Database:** `grp07_campussafedb_recovery_drill`

### Verified Database Catalog Structure:
* **User Tables (9):** `role`, `app_user`, `hazard_category`, `campus_location`, `hazard_report`, `assignment`, `report_status_history`, `maintenance_action`, `attachment`.
* **Explicit Performance Indexes (10):** `idx_report_reporter`, `idx_report_location`, `idx_report_category`, `idx_report_status`, `idx_report_submitted`, `idx_assign_report`, `idx_assign_maint`, `idx_history_report`, `idx_action_report`, `idx_attach_report`.
* **Sequences (9):** One per SERIAL column across all 9 tables.
* **Seed Data Baseline (108 rows):** 5 roles, 6 users, 6 categories, 10 locations, 16 hazard reports, 12 assignments, 39 status history transitions, 9 maintenance actions, 5 attachments.
* **Access Control Roles:** `app_runtime_grp`, `app_readonly_grp`, `app_backup_grp`, and logins `campussafe_app`, `campussafe_report`, `campussafe_backup`.

---

## 4. Live Command Execution & Evidence Collection Guide

During instructor evaluation or oral defense, execute the following commands to generate the live evidence files:

```powershell
# In PowerShell (elevated or with DB credentials configured):
$env:PGPASSWORD = "your_postgres_password"

# 1. Capture Backup Manifest
.\scripts\01_backup.ps1 | Tee-Object -FilePath evidence\01_backup_manifest.txt

# 2. Capture Archive Table of Contents
.\scripts\02_inspect_backup.ps1 | Tee-Object -FilePath evidence\02_archive_toc_listing.txt

# 3. Provision Test Database & Restore Archive
psql.exe -U postgres -h localhost -p 5432 -f scripts\03_create_restore_database.sql
.\scripts\04_restore.ps1 | Tee-Object -FilePath evidence\03_restore_test_log.txt

# 4. Capture Database Verification Results
psql.exe -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\05_verify_objects.sql | Out-File -FilePath evidence\04_verification_results.txt -Encoding utf8
psql.exe -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\06_verify_records.sql | Out-File -FilePath evidence\04_verification_results.txt -Append -Encoding utf8
psql.exe -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\07_verify_constraints.sql | Out-File -FilePath evidence\04_verification_results.txt -Append -Encoding utf8
psql.exe -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\08_verify_access_control.sql | Out-File -FilePath evidence\04_verification_results.txt -Append -Encoding utf8

# 5. Capture Canary Disaster Simulation Results
psql.exe -U postgres -h localhost -p 5432 -d grp07_campussafedb_activity6_restore_test -f scripts\09_simulate_data_loss.sql | Out-File -FilePath evidence\05_recovery_simulation.txt -Encoding utf8
psql.exe -U postgres -h localhost -p 5432 -d grp07_campussafedb_recovery_drill -f scripts\10_verify_recovery.sql | Out-File -FilePath evidence\05_recovery_simulation.txt -Append -Encoding utf8
```

