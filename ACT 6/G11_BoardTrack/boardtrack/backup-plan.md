# Database Backup and Disaster Recovery Plan
## COMP 018 — Database Administration | Activity 6
### Assigned Project: BoardTrack — Boarding House & Rental Management System

---

## A. Database Information and Inventory

### 1. System and Architecture Context
- **Project Name:** BoardTrack — Boarding House & Rental Management System
- **Academic Context:** COMP 018 Database Administration · Activity 6 Evaluation
- **Repository URL:** `https://github.com/karlrobertc-art/BoardTrack`
- **Assigned Development Group:** Group 11 (Karl Robert Cataluña, Kurt Policarpio, Catalunazy, et al.)
- **Database Management System (DBMS):** PostgreSQL 18.6 (x64) (Engine designed for PostgreSQL 18; fully backward compatible with PostgreSQL 13+)
- **Primary Production Database Name:** `boardtrack_db` (configured via `DATABASE_URL`)
- **Restoration Target Database Name:** `boardtrack_db_activity6_restore_test` (strictly isolated test database)
- **Application Stack:** Node.js 20.12+, Express 4.19.2, EJS 3.1.10, `pg` (Node-PostgreSQL v8.12.0)
- **Database Architecture Pattern:** Single-tenant relational database accessed via connection pooling (`pg.Pool`) in `src/db.js` with client-side date type parsing (`pg.types.setTypeParser(1082)`).

### 2. Comprehensive Relational Schema Objects
The database contains seven core relational tables, one migration tracking table, one reporting view, two trigger functions, two operational triggers, four secondary performance indexes, and two PostgreSQL core extensions:

| Database Object | Object Type | Description and Business Role |
|---|---|---|
| **`property`** | Table | Physical boarding house properties managed by the landlord (PK `property_id`, name, address). |
| **`room`** | Table | Individual rentable rooms (PK `room_id`, FK `property_id`, room number, monthly rate, status, OCC `version`). Enforces unique room numbers per property. |
| **`tenant`** | Table | Renters/occupants (PK `tenant_id`, full name, phone number, unique email, government/student ID). |
| **`lease`** | Table | Contractual rental agreement between tenant and room (PK `lease_id`, FK `tenant_id`, FK `room_id`, start/end dates, moved-out date, monthly rent, status). |
| **`payment`** | Table | Rent collection transaction ledger (PK `payment_id`, FK `lease_id`, date, amount, method, status). |
| **`utility_bill`** | Table | Periodic utility charges billed to a lease (PK `utility_bill_id`, FK `lease_id`, 1st-of-month billing period, utility type, amount, status). |
| **`app_user`** | Table | Application authentication accounts (PK `user_id`, unique username, bcrypt password hash, role enum, FK `tenant_id` for tenant role, active flag). |
| **`schema_migrations`**| Table | Internal migration journal tracking applied schema scripts (`name`, `applied_at`). |
| **`v_lease_summary`** | View | Calculated analytical view joining leases, tenants, rooms, and properties with dynamically aggregated `total_paid` and `utilities_billed`. |
| **`sync_room_status()`**| Trigger Function | Automates room occupancy (`OCCUPIED` vs `AVAILABLE`) based on active leases, updating rows in deterministic PK order to prevent deadlocks (`SQLSTATE 40P01`). |
| **`guard_room_status()`**| Trigger Function | Guard function preventing manual room status updates that contradict active lease status. |
| **`trg_lease_sync_room`**| Trigger | Fires `AFTER INSERT OR UPDATE OF status, room_id OR DELETE ON lease`. |
| **`trg_room_status_guard`**| Trigger | Fires `BEFORE INSERT OR UPDATE OF status ON room`. |
| **`btree_gist`** | Extension | PostgreSQL extension providing GiST indexing for scalar types, enabling the active lease overlap exclusion constraint. |
| **`pgcrypto`** | Extension | Cryptographic extension powering bcrypt hashing (`crypt`, `gen_salt('bf')`) for `app_user` credentials. |

### 3. Critical Integrity Constraints and Rules
1. **Exclusion Constraint (`ex_lease_no_overlap`):**
   ```sql
   CONSTRAINT ex_lease_no_overlap EXCLUDE USING gist (
     room_id WITH =,
     daterange(start_date, end_date, '[]') WITH &&
   ) WHERE (status = 'ACTIVE');
   ```
   Enforces core Business Rule 2: No room may have two simultaneous `ACTIVE` leases with overlapping calendar ranges.
2. **Referential Integrity Constraints:**
   - All foreign keys enforce `ON DELETE NO ACTION` (PostgreSQL default), preventing accidental cascade deletions of historical financial transactions, leases, or tenant records. Move-outs and terminations are handled exclusively via state transitions (`status = 'TERMINATED'`).
3. **Domain Check Constraints:**
   - Positive monetary values: `room.monthly_rate > 0`, `lease.monthly_rent > 0`, `payment.amount > 0`, `utility_bill.amount >= 0`.
   - Date validation: `lease.end_date > lease.start_date`, `lease.moved_out_on >= lease.start_date`.
   - Calendar alignment: `EXTRACT(DAY FROM utility_bill.billing_period) = 1` (forces first day of month).
   - Role-tenant parity: `((role = 'tenant') = (tenant_id IS NOT NULL))` (ensures tenant accounts must bind to a `tenant` record, while staff/admin accounts cannot).
   - State enums: `room.status` ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE'), `lease.status` ('ACTIVE', 'TERMINATED', 'EXPIRED'), `payment.payment_method` ('CASH', 'GCASH', 'BANK_TRANSFER'), `payment.status` ('COMPLETED', 'PENDING', 'FAILED'), `utility_bill.utility_type` ('ELECTRICITY', 'WATER', 'INTERNET'), `utility_bill.status` ('UNPAID', 'PAID'), `app_user.role` ('admin', 'staff', 'tenant').

### 4. Existing Access-Control Configuration (Activity 4 Baseline)
According to `docs/user-roles.md`, BoardTrack employs a two-tier security model:
- **Application Level:** Role-based access control (RBAC) enforced in `src/auth.js` distinguishing `admin` (full CRUD), `staff` (create/update, no delete, read-only properties), and `tenant` (row-level filtered read-only).
- **Database Level (PostgreSQL Roles):**
  - `boardtrack_owner`: Database owner role with login; executes schema migrations and DDL.
  - `boardtrack_admin_grp`: Group role with full DML (`ALL`) on all business tables.
  - `app_runtime_grp`: Runtime group role with `SELECT`, `INSERT`, `UPDATE`, `DELETE` on business tables, `USAGE` on sequences, and `SELECT` on `v_lease_summary` and `app_user`.
  - `app_readonly_grp`: Read-only reporting group with `SELECT` privileges only.
  - `boardtrack_app`: Dedicated application login account assigned membership in `app_runtime_grp`.

---

## B. Backup Method and Technical Rationale

### 1. Selected Method: Logical Custom Archive (`pg_dump -Fc`)
For the BoardTrack database, the primary backup mechanism is a **logical backup executed via PostgreSQL `pg_dump` using the custom archive format (`-Fc`)**.

```bash
pg_dump -h localhost -p 5432 -U boardtrack_backup -d boardtrack_db -Fc -v -f boardtrack_db_activity6.dump
```

### 2. Technical Justification
The PostgreSQL custom format (`-Fc`) is superior to plain text SQL dumps (`-Fp`) and tar archives (`-Ft`) for several key reasons:
1. **Built-in Compression:** The `-Fc` format applies zlib block compression natively, reducing storage footprint by 70–85% compared to raw SQL text without requiring external utilities (`gzip`).
2. **Table-of-Contents (TOC) Metadata:** Custom archives embed structured object headers and dependencies. This allows DBAs to inspect the archive structure (`pg_restore --list`), generate archive catalogues, and selectively restore specific tables or schemas without parsing the entire file.
3. **Flexible Out-of-Order Restoration:** Unlike plain SQL scripts where foreign key constraints fail if child tables are inserted before parent tables, `pg_restore` dynamically reorders schema creation, data loading, constraint validation, index generation, and trigger creation to prevent dependency failures.
4. **Parallel Processing Support:** The custom format supports multi-threaded parallel restoration via the `-j` (`--jobs`) flag, drastically decreasing Recovery Time Objective (RTO) for larger datasets.
5. **Platform Independence:** The binary archive is byte-order independent and can be moved seamlessly between Windows, Linux, and macOS database hosts running compatible PostgreSQL versions.

### 3. Scope of Backup Contents
- **Included Objects:**
  - Table definitions (DDL) and metadata for all 7 application tables and `schema_migrations`.
  - Primary keys, foreign keys, unique constraints, and check constraints.
  - Specialized exclusion constraints (`ex_lease_no_overlap`) requiring GiST index structures.
  - Secondary performance indexes (`idx_lease_room`, `idx_lease_tenant`, etc.).
  - User-defined trigger functions (`sync_room_status()`, `guard_room_status()`) and triggers.
  - Calculated reporting views (`v_lease_summary`).
  - Sequence definitions, sequence ownership, and current sequence state values (`SERIAL` sequences).
  - All relational table records (DML) captured in an ACID-consistent snapshot transaction (`REPEATABLE READ`).
- **Cluster Objects NOT Automatically Included:**
  - PostgreSQL cluster-wide globals: Database roles (`boardtrack_owner`, `boardtrack_app`, etc.), role passwords, and group memberships (`GRANT role TO user`).
  - Tablespace definitions.
  - Server-level configuration parameters.
  - *Mitigation:* Cluster roles must be backed up separately using `pg_dumpall --globals-only` or provisioned via infrastructure-as-code scripts prior to restoring the logical dump.

---

## C. Backup Storage, Security, and Integrity Policy

### 1. Storage Location and Segregation
- **Protected Storage Path (Windows):** `C:\db-backups\boardtrack\`
- **Protected Storage Path (Linux/POSIX):** `/var/backups/boardtrack/`
- **Isolation Rule:** Backup files **MUST NEVER** be stored within the application source tree or committed to version control repositories. The `.gitignore` configuration explicitly excludes `*.dump`, `*.tar`, `*.bak`, `*.sql.gz`, and `logs/*.log`.

### 2. Principle of Least Privilege Backup Account
The web application's runtime account (`boardtrack_app`) must **NEVER** be used to execute database backups. A dedicated database backup role must be established:
```sql
-- Provision dedicated backup account
CREATE ROLE boardtrack_backup WITH LOGIN PASSWORD '<SECURE_BACKUP_PASSWORD>';
GRANT CONNECT ON DATABASE boardtrack_db TO boardtrack_backup;
GRANT USAGE ON SCHEMA public TO boardtrack_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO boardtrack_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO boardtrack_backup;

-- Alternative in PostgreSQL 14+:
-- GRANT pg_read_all_data TO boardtrack_backup;
```
This role possesses read-only access across the schema, cannot insert, update, or truncate data, and lacks superuser privileges (`NOSUPERUSER`, `NOCREATEROLE`, `NOCREATEDB`).

### 3. Credential Protection Mechanisms
- Scripts must **never** contain plaintext passwords.
- Authentication must be handled via:
  - Interactive password prompt (`-W` / standard prompt).
  - Environment variable injection (`PGPASSWORD`) via secure process memory.
  - PostgreSQL password file (`%APPDATA%\postgresql\pgpass.conf` on Windows or `~/.pgpass` on Linux) with file permissions restricted to `0600` (user read/write only).

### 4. Integrity Verification via SHA-256 Checksums
Every backup operation must automatically compute and record a cryptographic SHA-256 hash immediately following file creation:
```powershell
# Windows PowerShell SHA-256 Generation
Get-FileHash -Path "boardtrack_db_activity6.dump" -Algorithm SHA256 | Format-List
```
```bash
# POSIX / Linux SHA-256 Generation
sha256sum boardtrack_db_activity6.dump > boardtrack_db_activity6.dump.sha256
```
Prior to any restoration or disaster recovery drill, the checksum of the archive must be recalculated and compared against the stored hash to detect silent bit rot, transmission corruption, or unauthorized tampering.

### 5. Why Database Dumps Must Not Be Committed to GitHub
1. **PII and Data Privacy Act Compliance:** Real database records contain Personally Identifiable Information (PII) including tenant full names, active phone numbers, email addresses, and valid government ID numbers (`valid_id_number`). Committing these violates Philippine Republic Act 10173 (Data Privacy Act of 2012) and international standards.
2. **Credential Exposure:** The `app_user` table contains cryptographic password hashes (`password_hash`). Although hashed with bcrypt, exposing hashes facilitates offline dictionary and rainbow table attacks.
3. **Repository Bloat:** Binary dump files are not diffable by Git. Every backup commit permanently inflates the Git history, degrading cloning and pull speeds.
4. **Permanent Commit History Risk:** Removing a sensitive file from Git requires complex history rewrites (`git filter-repo` / BFG Repo-Cleaner); once pushed to a public remote, the data is irreversibly compromised.

---

## D. Proposed Backup Schedule and Retention Policy

The following schedule represents a formal DBA recommendation for BoardTrack production environments:

### 1. Proposed Schedule and Frequency
- **Daily Full Logical Backup:** Executed daily at **02:00 AM PHT (UTC+8)** during minimal rental management activity.
- **Continuous WAL Archiving (Proposed Enhancement):** Write-Ahead Logging (WAL) archiving configured to write completed WAL segments to offsite storage every 15 minutes, enabling Point-In-Time Recovery (PITR).

### 2. Retention Policy (Grandfather-Father-Son - GFS)
| Backup Tier | Generation Frequency | Retention Duration | Maximum Copies Stored |
|---|---|---|---|
| **Daily (Son)** | Every 24 hours | 7 Days | 7 archives |
| **Weekly (Father)** | Every Sunday at 02:00 | 4 Weeks | 4 archives |
| **Monthly (Grandfather)** | 1st of every month | 12 Months | 12 archives |

Automated lifecycle management scripts must prune archives exceeding their retention window to prevent disk exhaustion.

### 3. Recovery Point Objective (RPO) and Recovery Time Objective (RTO)
- **Target RPO (Recovery Point Objective): 24 Hours**
  - *Definition:* The maximum acceptable age of data that can be lost following an unrecoverable failure.
  - *Rationale:* With daily full logical backups taken at 02:00 AM, in a worst-case scenario occurring at 01:59 AM, up to 23 hours and 59 minutes of newly recorded rent payments, tenant updates, or lease agreements could be lost if relying solely on logical dumps.
  - *Proposed Optimization:* Enabling PostgreSQL WAL archiving reduces the effective RPO to **15 minutes**.
- **Target RTO (Recovery Time Objective): 2 Hours**
  - *Definition:* The maximum allowable downtime to restore database service from disaster initiation to verified operational availability.
  - *Rationale:* For small-to-medium boarding house operations, 2 hours provides ample budget to provision replacement hardware/containers, restore the compressed archive, verify referential constraints, and bind the Node.js application. Technical restoration of the seed dataset executes in **under 2 minutes**.

---

## E. Restoration and Disaster Recovery Plan

### 1. Strict Database Isolation Rule
**CRITICAL OPERATIONAL MANDATE:**
Restoration must **NEVER** be performed over the live or original `boardtrack_db`. Restorations must always target a newly provisioned, isolated test database:
- **Restoration Target:** `boardtrack_db_activity6_restore_test`

### 2. Step-by-Step Restoration Procedure
1. **Pre-Restoration Verification:**
   - Confirm target host has PostgreSQL 18 tools installed.
   - Verify SHA-256 checksum of `boardtrack_db_activity6.dump`.
   - Inspect archive TOC using `pg_restore --list`.
2. **Provision Clean Destination Database:**
   ```bash
   createdb -h localhost -p 5432 -U postgres boardtrack_db_activity6_restore_test
   ```
3. **Pre-Create Required Roles and Extensions (if necessary):**
   - Ensure `btree_gist` and `pgcrypto` extensions are available.
   - Ensure destination cluster has required database roles created.
4. **Execute Logical Restore:**
   ```bash
   pg_restore -h localhost -p 5432 -U postgres -d boardtrack_db_activity6_restore_test -v boardtrack_db_activity6.dump
   ```
5. **Post-Restoration Audit:**
   - Run `scripts/verify-database.sql` to validate all 7 tables, view, functions, triggers, and record counts.
   - Run `scripts/verify-access-control.sql` to validate RBAC permissions.
   - Run `scripts/recovery-simulation.sql` to validate controlled recovery.
6. **Error and Warning Handling Protocol:**
   - *Ownership / Role Warnings (`role does not exist`):* Documented in Phase 6. If restoring into a cluster lacking the original owner role, inspect differences. Do not blindly hide errors with `--no-owner` without documenting security implications.
   - *Extension Warnings:* If extensions are created as superuser, non-superuser restore will trigger permission warnings.

---
*Prepared for COMP 018 — Database Administration Activity 6.*

