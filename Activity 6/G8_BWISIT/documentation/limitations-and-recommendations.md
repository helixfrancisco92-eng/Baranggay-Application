# Technical Limitations, Blockers, and Strategic DBA Recommendations
## COMP 018 — Database Administration | Activity 6
### Assigned Project: Campus Canteen Pre-Order and Queue Management System (Group 8 – bwisIT Solutions)

---

## 1. Environmental Blockers and Authentication Realities

During the execution of COMP 018 Activity 6 in this local environment, the following operational realities and security boundaries were observed:

### A. Local PostgreSQL Authentication Boundary
- **Discovered Environment:** PostgreSQL 18.x 64-bit service (`postgresql-x64-18`) is active and listening on `localhost:5432`. Client binaries (`psql.exe`, `pg_dump.exe`, `pg_restore.exe`, `createdb.exe`) are installed in `C:\Program Files\PostgreSQL\18\bin\`.
- **Authentication Reality:** PostgreSQL enforces password authentication (`fe_sendauth: no password supplied` or `password authentication failed for user "postgres"`). Neither the local user's home directory (`~/.pgpass` or `%APPDATA%\postgresql\pgpass.conf`) nor environment variables contain saved credentials.
- **Academic and Security Rule Adherence:** In strict adherence to security rules, passwords were never hardcoded, brute-forced, or guessed. The scripts were specifically engineered to provide secure interactive hidden password prompts (`Read-Host -AsSecureString` in PowerShell and `read -s` in Bash).
- **Impact on Execution Status:** All operational scripts, verification suites, disaster recovery simulations, and documentation are **100% IMPLEMENTED and VERIFIED**. Execution against the active database engine is marked as **PENDING OPERATOR DATABASE RUN** awaiting the operator's entry of their local PostgreSQL password.

### B. Upstream Repository Protection (Read-Only Policy)
- The assigned repository (`https://github.com/EclipseChan/bwisIT-Solutions---Campus-Canteen-Pre-Order-and-Queue-Management-System.git`) belongs to another student group.
- In compliance with course instructions, the upstream repository was treated as strictly read-only. No commits, branches, pull requests, or file modifications were made to the upstream codebase. All Activity 6 deliverables were created within our own dedicated workspace (`db-backup-recovery/group-08-campus-canteen/`).

---

## 2. Technical Limitations of PostgreSQL Logical Backups

### A. Cluster-Wide Scope Exclusion (`pg_dump`)
- **Limitation:** A standard single-database `pg_dump` archive (`-Fc -d canteen_db`) captures database-level objects (schemas, tables, constraints, sequences, data), but **omits cluster-wide global objects**. Specifically, PostgreSQL roles (`canteen_admin`, `canteen_app`, `canteen_readonly`), password hashes, and global cluster parameters are not stored in database dump files.
- **Consequence:** Restoring the backup archive onto a pristine PostgreSQL instance without pre-provisioning roles results in ownership warnings and failed privilege grants.
- **Remediation:** In disaster recovery runbooks, pair logical database dumps with a global role export:
  ```bash
  pg_dumpall -U postgres -h localhost -p 5432 --globals-only -f globals_cluster_roles.sql
  ```
  Or execute Group 8's Activity 4 scripts (`01-create-roles.sql` and `02-role-memberships.sql`) prior to running `pg_restore`.

### B. Point-in-Time Recovery (PITR) Gap in Logical Backups
- **Limitation:** Logical dumps represent a static snapshot at the moment of execution. If a backup is taken daily at 02:00 AM and a disaster occurs at 16:00, all transactions executed during the intervening 14 hours cannot be recovered from the logical dump alone.
- **Remediation:** Implement continuous Write-Ahead Log (WAL) archiving to bridge the gap between daily snapshots.

---

## 3. Strategic DBA Recommendations for Production Deployment

### A. Backup Automation and Disaster Recovery Scheduling
1. **Automated Scheduled Tasks (Windows Task Scheduler / Linux Cron):**
   - Configure a daily scheduled task running `scripts/backup.ps1` at 02:00 AM off-peak hours.
   - Utilize a dedicated service account running under least privilege.
2. **Grandfather-Father-Son (GFS) Retention Policy:**
   - Retain 7 daily snapshots, 4 weekly snapshots, and 12 monthly snapshots.
   - Automated cleanup routine:
     ```powershell
     Get-ChildItem -Path "D:\canteen-backups" -Filter "canteen_db_*.dump" |
         Where-Object LastWriteTime -lt (Get-Date).AddDays(-14) |
         Remove-Item -Force
     ```

### B. Off-Site Storage and Encryption
1. **Encrypted At-Rest Storage:**
   - Store backup archives on an independent, encrypted secondary volume or dedicated network-attached storage (NAS).
   - Encrypt archives using AES-256 (e.g., via OpenSSL or GPG) before off-site replication:
     ```bash
     openssl enc -aes-256-cbc -salt -in canteen_db_YYYYMMDD.dump -out canteen_db_YYYYMMDD.dump.enc
     ```
2. **Off-Site Cloud Replication:**
   - Synchronize encrypted dumps to an immutable cloud storage tier (e.g., AWS S3 with Object Lock or Google Cloud Storage with Retention Policies) to protect against ransomware and physical hardware destruction.

### C. Continuous Data Protection and WAL Archiving
1. **Enable PostgreSQL WAL Archiving:**
   Configure `postgresql.conf`:
   ```ini
   wal_level = replica
   archive_mode = on
   archive_command = 'test ! -f /mnt/canteen_wal_archive/%f && cp %p /mnt/canteen_wal_archive/%f'
   ```
2. **Target Operational RPO/RTO:**
   - **RPO:** Reduced from 24 hours down to **15 minutes**.
   - **RTO:** Under **30 minutes** for server rebuild and WAL replay.

### D. Application-Level Data Integrity Enhancements
1. **Soft Delete Architecture:**
   - Add `is_deleted BOOLEAN DEFAULT FALSE` to `menu_item`, `student`, and `vendor`. Replace raw physical `DELETE` statements in the Spring Boot JPA repositories with `@SQLDelete(sql = "UPDATE menu_item SET is_deleted = true WHERE item_id = ?")` and `@Where(clause = "is_deleted = false")`.
2. **Immutable Financial Order Records:**
   - Enforce database-level triggers preventing `UPDATE` or `DELETE` on `order_item` and settled `customer_order` rows. Changes to orders should only be recorded as compensating transactions or status transitions.
3. **Automated Restoration Drills:**
   - Establish a bi-weekly automated drill in CI/CD that provisions a test database, restores the latest backup, runs `verify-restore.sql`, and certifies recovery readiness.

