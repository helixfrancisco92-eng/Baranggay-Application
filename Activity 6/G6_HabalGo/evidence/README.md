# COMP 018 Activity 6 — Execution Evidence Repository
## Project: HabalGo (Group 6)
### Course: COMP 018 – Database Administration

---

## 1. PURPOSE & EVIDENCE STANDARDS

This directory stores authentic execution logs, terminal command outputs, cryptographic manifests, and database catalog extracts generated during the execution of COMP 018 Activity 6.

### Academic Integrity & Safety Rules:
1. **Zero Fabrication:** In accordance with academic guidelines, no simulated command outputs, fake screenshots, mock file hashes, or falsified terminal sessions are recorded.
2. **Distinction of States:** Every operational step is labeled strictly as:
   - **IMPLEMENTED:** File or script has been completely engineered and validated syntactically.
   - **EXECUTED:** Command has been physically run against the target system or cluster.
   - **VERIFIED:** Actual execution output has been checked against expected criteria.
   - **PENDING:** Operation awaits live runtime credentials, manual instructor review, or local execution authorization.
3. **Credential Protection:** Plaintext passwords, session keys, and database tokens are strictly excluded from all committed evidence files.

---

## 2. EVIDENCE REPOSITORY MAP

```
evidence/
├── README.md                      # This evidence documentation index
├── 01_system_discovery.txt        # Host OS, PostgreSQL version, and port inspection output
├── 02_cluster_catalog.txt         # Discovered database names, owners, and cluster-wide roles
├── 03_schema_inspection.txt       # Discovered habalgo schema, tables, and constraints
├── 04_backup_manifest.txt         # Actual pg_dump execution log, file size, timestamp, and SHA-256 hash
├── 05_archive_toc_listing.txt     # pg_restore --list full table of contents extract
├── 06_restore_test_log.txt        # pg_restore console output and exit code
├── 07_verification_results.txt    # Output of 05_verify_database.sql execution
└── 08_recovery_simulation.txt     # Output of data-loss simulation and recovery comparison
```

---

## 3. ACTUAL SYSTEM & CLUSTER EXECUTION EVIDENCE (VERIFIED)

### Evidence Item E-01: PostgreSQL Tools and Service Inspection
- **Operation:** PostgreSQL binary discovery and Windows service audit.
- **Commands Executed:**
  ```powershell
  Get-Command psql.exe, pg_dump.exe, pg_restore.exe
  Get-Service *postgres*
  Test-NetConnection -ComputerName localhost -Port 5432
  ```
- **Actual Verified Output:**
  - `psql.exe`: `C:\Program Files\PostgreSQL\18\bin\psql.exe` (Version 18.0.6.0)
  - `pg_dump.exe`: `C:\Program Files\PostgreSQL\18\bin\pg_dump.exe`
  - `pg_restore.exe`: `C:\Program Files\PostgreSQL\18\bin\pg_restore.exe`
  - Service: `postgresql-x64-18` — Status: `Running`
  - Port 5432 Connectivity: `True` (Accepting TCP connections)

### Evidence Item E-02: Target Database Catalog Discovery
- **Operation:** PostgreSQL cluster database audit via catalog query.
- **Target Database Identified:** `grp00_habalgodb` (Owner: `postgres`)
- **Schema Identified:** `habalgo` (Owner: `postgres`)
- **Roles Identified in Cluster:**
  - `habalgo_admin_role`, `habalgo_app_role`, `habalgo_auditor_role`
  - `habalgo_admin_user`, `habalgo_app_user`, `habalgo_auditor_user`
  - Application Group Roles from Activity 4: `app_runtime_grp`, `app_readonly_grp`

### Evidence Item E-03: Repository Codebase & Schema Inspection
- **Target Repository:** `https://github.com/jeanaroyo/HabalGo.git`
- **Tables Verified in Source Schema:**
  - `habalgo.customer` (customer_id, name, phone, email UNIQUE)
  - `habalgo.driver` (driver_id, name, phone, license_no UNIQUE)
  - `habalgo.vehicle` (vehicle_id, plate_no UNIQUE, vehicle_type, model)
  - `habalgo.driver_vehicle` (driver_id, vehicle_id, assigned_from, assigned_to, CHECK dates)
  - `habalgo.location` (location_id, address, city)
  - `habalgo.booking` (booking_id, customer_id, driver_id, pickup_location_id, dropoff_location_id, booking_date, CHECK status)
  - `habalgo.payment` (payment_id, booking_id, amount CHECK > 0, method, status)
  - `habalgo.rating_feedback` (rating_id, booking_id, customer_id, rating CHECK 1-5, feedback, UNIQUE booking_customer)

---

## 4. PENDING LIVE EXECUTION EVIDENCE CHECKLIST

For submission completion, when live administrative credentials are supplied during oral defense or instructor evaluation, execute the runner scripts and pipe output into the designated evidence files:

```bash
# 1. Capture Backup Evidence
./scripts/01_backup.sh | tee evidence/04_backup_manifest.txt

# 2. Capture TOC Archive Listing
./scripts/02_inspect_backup.sh | tee evidence/05_archive_toc_listing.txt

# 3. Capture Restore Execution Output
./scripts/04_restore.sh | tee evidence/06_restore_test_log.txt

# 4. Capture Database Verification Output
psql -U postgres -d grp00_habalgodb_activity6_restore_test -f scripts/05_verify_database.sql | tee evidence/07_verification_results.txt

# 5. Capture Access Control Output
psql -U postgres -d grp00_habalgodb_activity6_restore_test -f scripts/06_verify_access_control.sql | tee evidence/08_access_control_audit.txt
```

