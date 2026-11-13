# CampusSafe — Comprehensive Database Backup Plan
## Assigned Project: Group 7 — CampusSafe
### Course: COMP 018 — Database Administration (Activity 6)

---

## 1. System Identification & Scope of Protection

* **Database Name:** `grp07_campussafedb`
* **Owning Group:** Group 7
* **Evaluating Group:** Group 12 (Amoranto, Denielle; Francisco, Helix)
* **DBMS Engine:** PostgreSQL 14+ (Target Platform: PostgreSQL 18.0.6.0 x64)
* **Schema Scope:** `public` schema containing:
  * 9 Relational Tables (`role`, `app_user`, `hazard_category`, `campus_location`, `hazard_report`, `assignment`, `report_status_history`, `maintenance_action`, `attachment`)
  * 9 Auto-Incrementing Sequences (`role_role_id_seq`, `app_user_user_id_seq`, `hazard_category_category_id_seq`, `campus_location_location_id_seq`, `hazard_report_report_id_seq`, `assignment_assignment_id_seq`, `report_status_history_history_id_seq`, `maintenance_action_action_id_seq`, `attachment_attachment_id_seq`)
  * 10 Explicit Performance B-Tree Indexes
  * All Primary, Foreign Key, Unique, and Check Constraints
  * All Referential Integrity Triggers and System Catalogs

---

## 2. Selected Backup Methodology

### Backup Utility: PostgreSQL Logical Dump (`pg_dump`)
The designated backup strategy utilizes PostgreSQL's native logical export utility with the **Custom Archive Format (`-Fc`)**:

```bash
pg_dump -U campussafe_backup -h localhost -p 5432 -Fc -d grp07_campussafedb -f grp07_campussafedb_activity6.dump
```

### Technical Justification for `pg_dump -Fc`:
1. **Built-in Compression:** The `-Fc` flag applies native zlib compression, reducing on-disk storage requirements by 70% to 80% compared to plain SQL text files.
2. **Internal Table of Contents (TOC):** Custom archives embed structured metadata indexing every database object, enabling fast inspection with `pg_restore --list` without restoring or decompressing the entire file.
3. **Selective Object Recovery:** Administrators can selectively restore individual tables, schemas, or specific data subsets using the `-t` or `-L` flags in `pg_restore`.
4. **Parallel Restoration Support:** When restoring large databases into multi-core servers, `pg_restore -j <n>` enables concurrent multi-threaded table loading, dramatically reducing the Recovery Time Objective (RTO).
5. **Cross-Version & Architecture Portability:** Logical dumps represent database definitions and data in an architecture-independent format, allowing migration across different operating systems or PostgreSQL minor/major revisions.
6. **Non-Blocking Operation:** `pg_dump` takes a consistent point-in-time snapshot using PostgreSQL Multi-Version Concurrency Control (MVCC) without acquiring exclusive table locks, ensuring regular user operations remain unaffected.

---

## 3. Storage Architecture, Naming, and Security

### 3.1 Backup File Naming Convention
* **Activity 6 Standard:** `grp07_campussafedb_activity6.dump`
* **Automated Production Convention:** `grp07_campussafedb_YYYYMMDD_HHMMSS.dump`
  * Example: `grp07_campussafedb_20261113_010000.dump`

### 3.2 Backup Storage Location
Backups must be written to an isolated directory physically separated from the PostgreSQL cluster data directory (`PGDATA`):
* **Local Workspace Directory:** `C:\Users\Lenovo\Downloads\ACT 6\G7_CAMPUSAFE\db-backup-recovery\backups\`
* **Production Isolation Rule:** Stored on an independent secondary drive or dedicated Network Attached Storage (NAS) / Object Storage bucket (e.g., AWS S3 / Cloud Storage).

### 3.3 Access Control & File Permissions
* **OS-Level Permissions:** Read/Write access granted exclusively to the database administrative service account (`postgres` / system DBA). General users and developers are denied file-system read access.
* **Database Operator Least Privilege:** Backups are executed by `campussafe_backup` (holding only `SELECT` privileges on public tables and sequences via `app_backup_grp`). The backup account is strictly prohibited from executing DDL modifications, data deletions, or administrative mutations.
* **Version Control Security:** Git tracking of `.dump` files is strictly blocked via `.gitignore`.

---

## 4. Operational Recovery Metrics: RPO and RTO

### Explanation of Concepts:
* **Recovery Point Objective (RPO):** The maximum tolerable age of data lost measured backward from the time of a disaster. It defines *how much data* the organization can afford to lose.
* **Recovery Time Objective (RTO):** The maximum tolerable elapsed duration from the declaration of a disaster to the full restoration of operational service. It defines *how quickly* the system must be brought back online.

### Proposed Planning Values:
* **Proposed RPO: 24 Hours**
  * *Operational Justification:* CampusSafe manages non-financial physical hazard reports (typically 10 to 30 submissions monthly across a university campus). Nightly backups capture daily activity, meaning at most 24 hours of newly filed reports would need to be re-entered manually from dispatch logs or email receipts in a catastrophic total loss event.
* **Proposed RTO: 2 Hours**
  * *Operational Justification:* The total database payload (under 2 MB) restores in less than 5 minutes. The 2-hour window accounts for hardware reprovisioning, OS setup, archive transfer, integrity verification, access-control re-application, and DNS/application DSN reconnection.

> **Important Disclosure:** The 24-hour RPO and 2-hour RTO are **proposed organizational planning targets**, not empirically measured recovery performance benchmarks under live catastrophic outage conditions.

---

## 5. Proposed Backup Schedule & Retention Policy

### 5.1 Schedule
* **Frequency:** Daily Full Logical Backups
* **Execution Window:** 01:00 AM Daily (Scheduled low-traffic campus maintenance window)
* **Automation Mechanism:** Windows Task Scheduler (using `01_backup.ps1`) or Linux Cron (using `01_backup.sh`).

### 5.2 Retention Policy (Grandfather-Father-Son Model)
To optimize storage while ensuring historical audit compliance:
1. **Daily Tier:** Retain **7 daily backups** (provides daily rollback granularity for the past week).
2. **Weekly Tier:** Retain **4 weekly backups** taken every Sunday at 01:00 AM (provides rollback coverage for the past month).
3. **Pruning Automation:** Automated rotation script removes snapshots older than 28 days unless tagged for permanent regulatory archive.

---

## 6. Verification and Disaster Recovery Procedure

Every backup file generated must undergo three mandatory verification gates:
1. **Cryptographic Integrity:** Compute a SHA-256 hash immediately upon creation and compare against the generated manifest to detect bit-rot or transfer corruption.
2. **Archive Table of Contents Audit:** Execute `pg_restore --list` to verify that all 9 tables, 10 indexes, 9 sequences, and constraints exist within the archive TOC.
3. **Isolated Test Restoration:** Restore the archive into an independent test database (`grp07_campussafedb_activity6_restore_test`). **Never restore over the live production database.**

---

## 7. Cluster-Wide Roles and Activity 4 Re-Establishment Plan

### PostgreSQL Architectural Rule:
`pg_dump` operates exclusively at the single-database level. It extracts schemas, tables, sequences, and data belonging to `grp07_campussafedb`, but **does NOT include global cluster-wide roles, users, passwords, or cluster memberships** stored in `pg_authid`.

### Role Recovery Procedure:
To re-establish complete operational security upon restoring into a clean PostgreSQL cluster:
1. Global roles and memberships must be recreated using Group 7's Activity 4 script:
   `database/03_roles_and_privileges.sql`
2. Group roles re-established:
   * `app_runtime_grp` (NOLOGIN)
   * `app_readonly_grp` (NOLOGIN)
   * `app_backup_grp` (NOLOGIN)
3. Login accounts re-established:
   * `campussafe_app` (Member of `app_runtime_grp`)
   * `campussafe_report` (Member of `app_readonly_grp`)
   * `campussafe_backup` (Member of `app_backup_grp`)
4. Explicit table, sequence, and default privileges are reapplied in the restored database catalog to enforce the Principle of Least Privilege (PoLP).

