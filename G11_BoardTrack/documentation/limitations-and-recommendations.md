# Problems, Limitations, and DBA Recommendations
## COMP 018 — Database Administration | Activity 6
### Assigned Project: BoardTrack — Boarding House & Rental Management System (Group 11)

---

## 1. Technical Problems and Environmental Limitations

During the execution of COMP 018 Activity 6 for the BoardTrack project, several critical architectural and environmental factors were analyzed:

### 1.1 Local PostgreSQL Authentication Gate
- **Observed Limitation:** The host workstation runs PostgreSQL 18.6 (`postgresql-x64-18` Windows service) with password authentication enforced for administrative and database roles.
- **Academic Safety Compliance:** Under strict security guidelines, no passwords may be hardcoded into automation scripts, committed to version control, or guessed via brute-force.
- **Technical Resolution:** Scripts (`backup.ps1`, `restore.ps1`, `backup.sh`, `restore.sh`) were engineered with dynamic parameterization. They support:
  1. Standard PostgreSQL interactive password prompting (`-W` flag).
  2. Memory-injected environment variables (`$env:PGPASSWORD` / `PGPASSWORD`).
  3. Pre-configured `.pgpass` / `pgpass.conf` credential stores with strict OS-level permissions (`0600`).

### 1.2 PostgreSQL Cluster Globals vs. Single-Database Logical Dumps
- **Observed Limitation:** `pg_dump` operates strictly at the individual database scope. Cluster-wide global objects—specifically user roles (`boardtrack_owner`, `boardtrack_app`), group memberships, and global role passwords—are stored in cluster catalog tables (`pg_authid`, `pg_auth_members`) and are **NOT** exported in `boardtrack_db_activity6.dump`.
- **Restoration Impact:** Restoring the backup into a fresh PostgreSQL cluster where these roles do not yet exist will trigger ownership and privilege warnings (`role "boardtrack_owner" does not exist`).
- **Technical Resolution:** DBAs must execute an initialization script (`create-roles.sql`) or export cluster globals prior to database restoration:
  ```bash
  pg_dumpall -U postgres -h localhost -p 5432 --globals-only -f cluster_globals.sql
  ```

### 1.3 Core Extension Dependencies (`btree_gist` and `pgcrypto`)
- **Observed Limitation:** The BoardTrack schema relies on:
  - `btree_gist`: Required to build GiST indexes for the `ex_lease_no_overlap` constraint (comparing scalar `room_id` alongside `daterange`).
  - `pgcrypto`: Required for bcrypt password hashing functions (`crypt`, `gen_salt('bf')`) in `app_user`.
- **Restoration Impact:** If the destination PostgreSQL server does not have these standard extension libraries installed in its `share/extension` directory, restoration of constraints and seeder records will fail.
- **Technical Resolution:** Both extensions ship standard with official PostgreSQL distributions (13 through 18). The restoration plan includes pre-restoration extension validation to ensure seamless DDL recreation.

### 1.4 Read-Only Upstream Policy Enforcement
- **Constraint:** The upstream repository (`https://github.com/karlrobertc-art/BoardTrack`) belongs to peer students and must be treated as strictly read-only.
- **Technical Resolution:** The entire Activity 6 operational workspace, automation scripts, logs, verification suites, and documentation were created in our group's dedicated workspace (`db-backup-recovery/boardtrack/`), completely isolated from upstream files.

---

## 2. Practical Recommendations for Enterprise DBA Operations

To elevate BoardTrack's data protection from an academic project baseline to an enterprise-grade production standard, the following recommendations are provided:

### 2.1 Implementation of Continuous WAL Archiving and Point-In-Time Recovery (PITR)
- **Current State:** Daily logical backups (`pg_dump -Fc`) yield a 24-hour Recovery Point Objective (RPO). Any transaction recorded between 02:00 AM and an afternoon hardware crash is permanently lost.
- **Recommendation:** Enable Write-Ahead Log (WAL) archiving in `postgresql.conf`:
  ```ini
  wal_level = replica
  archive_mode = on
  archive_command = 'test ! -f /var/backups/wal_archive/%f && cp %p /var/backups/wal_archive/%f'
  archive_timeout = 900  # Forces WAL segment switch every 15 minutes
  ```
- **Operational Value:** Reduces the RPO from **24 hours to under 15 minutes**. DBAs can recover the database to an exact timestamp (e.g. `recovery_target_time = '2026-11-13 14:32:00 PHT'`), completely reversing accidental data purges while preserving valid subsequent transactions.

### 2.2 Automated Lifecycle Management and 3-2-1 Backup Strategy
- **Recommendation:** Implement the standard **3-2-1 Backup Rule**:
  - **3 Copies:** 1 primary database, 1 local backup copy, 1 offsite copy.
  - **2 Media Types:** Local high-speed NVMe/SSD storage for immediate restores; cloud object storage (AWS S3, Cloudflare R2, or Google Cloud Storage) for disaster resilience.
  - **1 Offsite Copy:** Geographically segregated bucket with Object Lock (immutability) enabled to protect against ransomware.
- **Lifecycle Retention Policy (GFS):**
  - Retain 7 daily snapshots.
  - Retain 4 weekly snapshots.
  - Retain 12 monthly snapshots.
  - Implement an automated lifecycle script to prune expired archives and prevent disk exhaustion.

### 2.3 Automated Restoration and Integrity Verification Pipeline
- **Recommendation:** Never trust an unverified backup. Implement an automated monthly validation pipeline using Docker or a secondary staging server:
  1. Automated job downloads the latest `.dump` archive.
  2. Spawns an isolated PostgreSQL container.
  3. Executes `pg_restore`.
  4. Runs `scripts/verify-database.sql`.
  5. Computes record count variances and constraint checks.
  6. Emits an automated Discord/Slack/Email notification confirming restoration integrity.

### 2.4 Application-Level Soft Deletion
- **Recommendation:** Add a `deleted_at TIMESTAMPTZ NULL` column to `payment`, `lease`, and `utility_bill` tables.
- **Operational Value:** In rental operations, human errors (such as clicking "Delete Payment" instead of "Edit") are common. Soft deletion converts destructive SQL `DELETE` operations into reversible metadata flags (`UPDATE payment SET deleted_at = now() WHERE ...`). The application filters active rows (`WHERE deleted_at IS NULL`), allowing instantaneous recovery without resorting to database-level restores.

### 2.5 Security Hardening and Dedicated Backup Role
- **Recommendation:** Establish a dedicated least-privilege `boardtrack_backup` role:
  ```sql
  CREATE ROLE boardtrack_backup WITH LOGIN PASSWORD '<SECURE_RANDOM_PASSWORD>';
  GRANT CONNECT ON DATABASE boardtrack_db TO boardtrack_backup;
  GRANT USAGE ON SCHEMA public TO boardtrack_backup;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO boardtrack_backup;
  GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO boardtrack_backup;
  ```
- **Operational Value:** Prevents backup automation from using the application runtime account (`boardtrack_app`) or the database superuser (`postgres`), adhering to the principle of least privilege.

---
*Prepared for COMP 018 — Database Administration Activity 6.*

