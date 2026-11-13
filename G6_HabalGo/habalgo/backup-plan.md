# COMP 018 Activity 6 — Database Backup Plan
## Project: HabalGo (Ride and Booking Management System)
### Database Platform: PostgreSQL 15+ (PostgreSQL 18.0.6.0 x64)

---

## 1. EXECUTIVE SUMMARY & OBJECTIVE

This document establishes the official enterprise backup policy and recovery strategy for the **HabalGo** ride-hailing database (`grp00_habalgodb`). As a 24/7 relational transactional system managing customer profiles, driver dispatches, vehicle assignments, location routing, payment transactions, and customer ratings, ensuring continuous data availability, durability, and business continuity is paramount.

The core objective of this plan is to define a standardized, secure, and verifiable logical backup regimen using PostgreSQL client utilities, establishing rigorous protocols for backup generation, cryptographic hashing, integrity verification, access restriction, and disaster recovery.

---

## 2. DATABASE ENVIRONMENT & ASSET IDENTIFICATION

| Attribute | Specification |
| :--- | :--- |
| **System Name** | HabalGo Ride and Booking Management System |
| **Target Database Engine** | PostgreSQL 15+ (Current Environment: PostgreSQL 18.0.6.0) |
| **Target Database Name** | `grp00_habalgodb` |
| **Primary Production Schema** | `habalgo` |
| **Host & Port** | `localhost:5432` |
| **Database Encoding & Collation** | UTF-8 / C.UTF-8 |
| **Database Owner** | `postgres` (Superuser) |
| **Application Runtime Account** | `habalgo_app_user` (Inherits `app_runtime_grp`) |
| **Auditor / Read-Only Account** | `habalgo_readonly_user` (Inherits `app_readonly_grp`) |

### Critical Database Objects in Scope:
1. **Relational Schemas:** `habalgo` (containing all application objects) and `public`.
2. **Transactional & Master Tables (8 Tables):**
   - `habalgo.customer` (Customer credentials, contact numbers, unique emails)
   - `habalgo.driver` (Driver identities, contact details, unique license numbers)
   - `habalgo.vehicle` (Fleet vehicle specifications, unique plate numbers)
   - `habalgo.driver_vehicle` (Driver-to-vehicle assignment timeline and history)
   - `habalgo.location` (Pickup and drop-off coordinates/addresses across Philippine cities)
   - `habalgo.booking` (Core ride requests, operational statuses, driver assignments)
   - `habalgo.payment` (Monetary transactions, payment modes, settlement statuses)
   - `habalgo.rating_feedback` (Service quality ratings 1–5, customer feedback text)
3. **Sequences (7 Objects):** Auto-incrementing counters for primary keys across all base tables.
4. **Indexes (5 Explicit Performance Indexes):** `idx_booking_customer`, `idx_booking_driver`, `idx_booking_date`, `idx_payment_booking`, `idx_rating_booking`.
5. **Constraints & Relationships (25+ Constraint Objects):** Primary keys, cascading foreign keys, unique keys, and check constraints (`ck_assignment_dates`, `ck_booking_status`, `amount > 0`, `rating BETWEEN 1 AND 5`).

---

## 3. BACKUP METHODOLOGY & JUSTIFICATION

### Selected Backup Utility: `pg_dump` with Custom Archive Format (`-Fc`)

The logical backup is executed using the standard PostgreSQL client utility `pg_dump`, specifying the custom compressed binary format (`-Fc`):

```bash
pg_dump -U <username> -h localhost -p 5432 -Fc -d grp00_habalgodb -f grp00_habalgodb_activity6.dump
```

### Technical Justification for Custom Format (`-Fc`):
1. **Built-in Compression:** The `-Fc` flag automatically utilizes zlib compression, reducing backup file footprint by 60%–80% compared to plain `.sql` text files.
2. **Internal Table of Contents (TOC):** Unlike plain SQL dumps, custom archives embed a detailed binary TOC. This allows administrators to inspect object contents (`pg_restore --list`) without altering any database.
3. **Selective Object Restoration:** Individual tables, schemas, or specific constraints can be restored independently using `-t` or `-n` flags without executing the full archive.
4. **Parallel Restoration Capability:** When restoring large databases, `pg_restore` supports multi-core parallel processing via `-j <workers>`, drastically lowering recovery downtime.
5. **Platform Independence & Security:** Custom archive format prevents accidental SQL execution and mitigates accidental disclosure of table schemas or credentials compared to uncompressed SQL scripts.

---

## 4. BACKUP STORAGE & ACCESS RESTRICTIONS

### Storage Architecture
- **Primary On-Disk Target:** A dedicated local directory outside the git repository tree:
  - Windows: `C:\Users\Lenovo\Downloads\backups\` or `<workspace>/backups/`
  - Linux: `/var/backups/postgresql/habalgo/`
- **Secondary Off-Site Target:** Encrypted cloud object storage (e.g., AWS S3, GCP Cloud Storage) with immutable WORM (Write Once, Read Many) retention.

### Access Control & Security Policies:
1. **Git Isolation:** Backup archives (`*.dump`, `*.tar`, `*.bak`) are strictly prohibited from Git version control via repository `.gitignore` rules.
2. **Filesystem DACLs:** Backup files are restricted using Windows NTFS Access Control Lists (`icacls`) or Linux POSIX permissions (`chmod 600`), readable strictly by the DBA service account and administrative users.
3. **Zero Plaintext Secrets:** Scripts must never store hardcoded database passwords. Credentials are passed securely via the temporary environment variable `PGPASSWORD` or protected `.pgpass` / `pgpass.conf` configuration files.

---

## 5. BACKUP VERIFICATION STRATEGY

The mere existence of a `.dump` file does not guarantee recoverability. The HabalGo backup verification strategy enforces a 4-tier verification protocol:

```mermaid
flowchart LR
    A["Tier 1: Exit Code Validation"] --> B["Tier 2: File Size & Non-Zero Check"]
    B --> C["Tier 3: SHA-256 Hashing"]
    C --> D["Tier 4: Archive TOC Inspection"]
    D --> E["Tier 5: Isolated Test Restore"]
```

1. **Tier 1 — Exit Code Verification:** The backup runner monitors the `pg_dump` exit code ($LASTEXITCODE / $?). Only an exit code of `0` denotes an uncorrupted stream completion.
2. **Tier 2 — Non-Zero File Size:** The backup script verifies that the resulting `.dump` file exists and has a file length greater than zero bytes.
3. **Tier 3 — Cryptographic Checksum (SHA-256):** Immediately following backup generation, a SHA-256 hash is computed using `Get-FileHash` (PowerShell) or `sha256sum` (Linux) and stored alongside the backup manifest.
4. **Tier 4 — Table of Contents Inspection:** The archive TOC is parsed via `pg_restore --list <archive_file>` to confirm header integrity, valid schema definitions, sequence ownership, and table existence.
5. **Tier 5 — Periodic Automated Restoration:** Once weekly, the latest backup is restored into an isolated sandbox database (`grp00_habalgodb_activity6_restore_test`) to confirm relational integrity, row count parity, and query functionality.

---

## 6. PROPOSED BACKUP SCHEDULE & RETENTION POLICY

> [!NOTE]
> The schedule, retention periods, RPO, and RTO values below are proposed planning baselines for academic evaluation and production modeling, clearly distinguished from live measured operational benchmarks.

### Proposed Backup Schedule
- **Full Logical Backup (`pg_dump -Fc`):** Daily at 02:00:00 UTC+8 (low-traffic maintenance window).
- **Continuous WAL Archiving (Production Recommendation):** Every 15 minutes or 16 MB segment completion to achieve near-zero data loss.

### Proposed Grandfather-Father-Son (GFS) Retention Policy
- **Daily Backups:** Retained for **7 days** (covering immediate rolling recovery).
- **Weekly Backups:** Captured every Sunday at 02:00:00 UTC+8; retained for **4 weeks** (covering monthly audit cycles).
- **Monthly Backups:** Captured on the 1st of every month; retained for **12 months** (covering annual financial and regulatory audits).
- **Pruning Automation:** Automated lifecycle scripts delete backups exceeding their defined retention threshold to prevent disk exhaustion.

---

## 7. RECOVERY POINT OBJECTIVE (RPO) & RECOVERY TIME OBJECTIVE (RTO)

### Recovery Point Objective (RPO)
- **Proposed Planning Baseline:** **24 Hours**
- **Analysis:** Under a daily logical backup regimen, any failure occurring immediately prior to the next scheduled backup (e.g., 01:59 UTC+8) results in the loss of up to 24 hours of newly submitted bookings, driver assignments, and payments.
- **Enterprise Recommendation:** For production ride-hailing operations where losing customer bookings is unacceptable, the actual RPO must be reduced to **< 5 minutes** by implementing PostgreSQL Write-Ahead Logging (WAL) continuous archiving and Point-in-Time Recovery (PITR).

### Recovery Time Objective (RTO)
- **Proposed Planning Baseline:** **2 Hours**
- **Analysis:** This window accounts for incident declaration, hardware/database provisioning, test database initialization, binary archive streaming, `pg_restore` execution, schema integrity auditing, and application connection redirection.
- **Enterprise Recommendation:** For the current HabalGo database size (< 10 MB), actual restore time is under **15 seconds**. As transactional volume expands into gigabytes, multi-threaded restoration (`pg_restore -j 4`) and pre-warmed standby replicas are recommended to maintain RTO < 30 minutes.

---

## 8. ACTIVITY 4 ROLES & PRIVILEGES RESTORATION STRATEGY

### Fundamental PostgreSQL Architectural Constraint
A single-database backup generated via `pg_dump` contains **only local database objects** (schemas, tables, views, sequences, constraints, and object-level ACLs). It **does NOT** contain:
- Cluster-wide login accounts (`CREATE ROLE ... LOGIN`)
- Group roles (`CREATE ROLE ... NOLOGIN`)
- Role passwords and authentication hashes
- Cluster-wide role memberships (`GRANT group TO user`)
- Database-level connection grants (`GRANT CONNECT ON DATABASE ...`)

If a database is restored onto a fresh PostgreSQL cluster without prior role creation, `pg_restore` outputs multiple warnings:
```
pg_restore: warning: role "habalgo_app_user" does not exist
pg_restore: warning: could not execute query: ERROR: role "app_runtime_grp" does not exist
```

### Access Control Recovery Procedure
To ensure seamless post-restoration operations and uphold the principle of least privilege without granting dangerous `SUPERUSER` privileges:

1. **Pre-Restoration Role Verification:** Before executing `pg_restore`, the cluster is audited using catalog query `SELECT rolname FROM pg_roles;`.
2. **Automated Role Provisioning:** If roles are absent, the official Activity 4 provisioning script (`database/03_roles_and_privileges.sql` or `scripts/06_verify_access_control.sql`) is executed by a database administrator:
   - Group Roles: `app_runtime_grp`, `app_readonly_grp`
   - Login Users: `habalgo_app_user`, `habalgo_readonly_user`
   - Role Memberships: `habalgo_app_user` assigned to `app_runtime_grp`; `habalgo_readonly_user` assigned to `app_readonly_grp`
   - Schema & Object Permissions: `USAGE` on schema `habalgo`, CRUD on all tables for runtime, SELECT on all tables for read-only.
3. **Globals Backup Alternative:** In production clusters, global objects are backed up independently using:
   ```bash
   pg_dumpall -U postgres -h localhost -p 5432 --globals-only -f cluster_globals_backup.sql
   ```

---

## 9. SAFETY CHECKLIST BEFORE RESTORATION

- [ ] Confirm original production database (`grp00_habalgodb`) is **NOT** targeted as destination.
- [ ] Confirm backup archive exists and is non-empty.
- [ ] Confirm SHA-256 hash matches the generation manifest.
- [ ] Confirm destination test database has a distinct name (e.g., `grp00_habalgodb_activity6_restore_test`).
- [ ] Confirm destination database is empty before executing restore.
- [ ] Confirm database roles and group memberships exist prior to restoring object permissions.

