# Operational Limitations, Technical Blockers, and Strategic DBA Recommendations
## COMP 018 — Database Administration | Activity 6
### Assigned Project: Restaurant Online Ordering & Table Reservation System (Group: Binary Sisters)

---

## 1. Technical Limitations and Operational Blockers

During the comprehensive DBA evaluation and Activity 6 disaster recovery engineering for the Restaurant Online Ordering & Table Reservation System, the following constraints and operational boundaries were documented:

### 1.1 Local PostgreSQL Authentication Boundary
- **Discovered Environment:** PostgreSQL 18 is installed and actively listening on `127.0.0.1:5432` (`postgresql-x64-18` Windows Service status: Running).
- **Security Boundary:** The local PostgreSQL cluster enforces standard SCRAM-SHA-256 password authentication for administrative and system accounts (`postgres`, `rors_backup`, `rors_dba`). In strict accordance with course guidelines and industry security standards:
  - No passwords were hardcoded in scripts or files.
  - No unauthorized credential probing or password cracking was attempted.
  - Live execution of backup generation, restoration, and verification queries is properly cataloged as **IMPLEMENTED (PENDING OPERATOR DATABASE RUN)** awaiting interactive authentication by the authorized database administrator.

### 1.2 Cluster-Wide Role Scope in PostgreSQL
- **Architectural Characteristic:** In PostgreSQL, roles (`rors_app`, `rors_report`, `rors_maint`, `rors_backup`, `rors_dba`), their passwords, and role memberships are **cluster-wide (instance-level)** objects stored in the global system catalog `pg_authid`. They are **NOT** contained within a single-database `pg_dump` archive.
- **Operational Impact:** Restoring `grp_binarysisters_projectdb_activity6.dump` onto a fresh PostgreSQL server instance will restore all schemas, tables, views, and data, but privileges granted to `rors_app` or `rors_report` will fail or produce ownership errors if those roles do not already exist on that instance.
- **Remediation Implemented:** Our restoration scripts and documentation explicitly mandate pre-provisioning roles using `database/roles/01_create_roles.sql` and reapplying object grants via `02_grants.sql` or using `pg_dumpall --globals-only`.

### 1.3 Strict Read-Only Boundary of Upstream Repository
- **Operational Rule:** The assigned repository (`https://github.com/kathlenmaecallos11-arch/Restaurant-Online-Ordering-Table-Reservation-System`) belongs to Group Binary Sisters and was treated as strictly read-only.
- **Implementation:** No upstream commits, branches, or code modifications were made. All Activity 6 scripts, test plans, verification suites, and evidence tracking are maintained entirely within our own group workspace (`G10_MESA`).

### 1.4 Deferred Constraint Trigger Dependencies
- **Integrity Rule BR9:** Business Rule 9 states that *"An order must contain at least one order item."* In `database/migrations/002_integrity_logic.sql`, this is enforced by constraint trigger `trg_orders_require_items` marked `DEFERRABLE INITIALLY DEFERRED`.
- **Restoration Behavior:** Plain table-by-table data insertion without transactions would cause `orders` insertions to fail before `order_item` rows are loaded. `pg_restore` handles this correctly by deferring constraints or creating triggers after table data is loaded, but manual recovery simulations must bundle order header and line item creations in a single transaction.

### 1.5 Contrib Extension Dependencies
- **Extensions Required:** `btree_gist` (for GiST reservation exclusion constraint `ex_reservation_no_overlap`) and `pgcrypto` (for bcrypt password hashing in seeds).
- **Requirement:** Destination PostgreSQL instances must include the `postgresql-contrib` package. Our provisioning script `scripts/create-restore-db.ps1` automatically executes `CREATE EXTENSION IF NOT EXISTS btree_gist;` and `pgcrypto;` before restoration.

---

## 2. Strategic DBA Recommendations for Production Deployment

To transition the Restaurant Online Ordering and Table Reservation System to an enterprise-grade, high-availability production environment, the following engineering enhancements are recommended:

### 2.1 Automated Scheduled Backups
- **Implementation:** Configure Windows Task Scheduler (on Windows Server) or a Linux `systemd` timer / `cron` job to execute `scripts/backup.ps1` or `scripts/backup.sh` automatically every day at **02:00 AM PST**.
- **Execution Script Template (Crontab):**
  ```cron
  0 2 * * * /opt/scripts/backup.sh >> /var/log/db-backups.log 2>&1
  ```
- **Logging & Alerting:** Integrate an email or Slack webhook notification upon non-zero exit codes to immediately alert the on-call DBA.

### 2.2 Formal Grandfather-Father-Son (GFS) Retention Policy
Implement an automated archival rotation scheme to maintain legal and audit compliance while managing disk storage:
- **7 Daily Backups:** Retain for 7 rolling days.
- **4 Weekly Backups:** Retain the Sunday snapshot for 4 weeks.
- **12 Monthly Backups:** Retain end-of-month snapshots for 12 months.
- **3 Annual Backups:** Retain year-end archives for 3 years (statutory financial/tax audit).

### 2.3 Off-Site Encrypted Storage & Immutable Backups
- **Off-Site Replication:** Backup archives must not remain on the database host. Dumps should be automatically synced to a dedicated remote backup server or cloud object storage (e.g., AWS S3, Google Cloud Storage, or Azure Blob).
- **At-Rest Encryption:** Encrypt backup archives using AES-256 (e.g., `gpg --symmetric --cipher-algo AES256`) before transmission.
- **Ransomware Protection (Object Lock):** Configure cloud buckets with WORM (Write Once, Read Many) / Object Lock policies to prevent backup files from being encrypted or deleted by ransomware actors.

### 2.4 Point-in-Time Recovery (PITR) via Continuous WAL Archiving
- **Limitation of Daily Logical Dumps:** A daily `pg_dump` provides an RPO of 24 hours. In a high-volume restaurant during lunch or dinner rush, losing several hours of orders or table bookings is unacceptable.
- **Recommended Configuration:** Enable Write-Ahead Log (WAL) archiving in `postgresql.conf`:
  ```ini
  wal_level = replica
  archive_mode = on
  archive_command = 'test ! -f /mnt/wal_archive/%f && cp %p /mnt/wal_archive/%f'
  archive_timeout = 900  # 15 minutes
  ```
- **Operational Benefit:** Combining a weekly physical base backup (`pg_basebackup`) with 15-minute WAL archiving reduces the system's **Recovery Point Objective (RPO) from 24 hours down to under 15 minutes**.

### 2.5 Routine Sandbox Disaster Recovery Drills
- **Principle:** An untested backup is not a backup.
- **Automated Sandbox Testing:** Deploy a monthly CI/CD pipeline or scheduled task that spins up an ephemeral PostgreSQL container, restores the latest backup dump, executes `scripts/verify-database.sql`, confirms row counts match expected baselines, and logs the certification before tearing down the container.

### 2.6 Application Architecture: Soft Delete Pattern
- **Current Behavior:** The schema enforces `ON DELETE RESTRICT` on `menu_item` and `orders`. If staff attempt to delete an obsolete dish, the database will throw a foreign key violation error.
- **Recommended Schema Update:** Add an `is_active BOOLEAN NOT NULL DEFAULT true` or `deleted_at TIMESTAMP NULL` column to `menu_item`, `restaurant_table`, and `staff`. Application queries filter on `availability = true`, preserving historical sales audit integrity.

### 2.7 Separation of Duty in Access Control
- Binary Sisters' Activity 4 access control implementation is exemplary:
  - `rors_app`: Restricted to runtime DML (no DDL, no DELETE on orders/payments).
  - `rors_report`: Restricted to non-credential tables and sanitized views.
  - `rors_backup`: Uses `pg_read_all_data` without modification capabilities.
- **Production Recommendation:** Ensure these roles are strictly maintained in production and never bypassed using the `postgres` superuser account in application `.env` files.

