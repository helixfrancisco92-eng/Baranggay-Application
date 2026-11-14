# CampusSafe — Backup Execution & Archive Inspection Report
## Assigned Project: Group 7 — CampusSafe
### Course: COMP 018 — Database Administration (Activity 6)

---

## 1. Backup Execution Specification

### 1.1 Command Invocation Structure
The logical backup of the CampusSafe relational database was formulated using the official Activity 6 command specification:

```bash
pg_dump -U campussafe_backup -h localhost -p 5432 -Fc -d grp07_campussafedb -f grp07_campussafedb_activity6.dump
```

### 1.2 Parameter Dissection & Justification
* `-U campussafe_backup`: Connects as the least-privileged backup operator defined in Activity 4 (`app_backup_grp`), preventing the use of the superuser account for operational backups.
* `-h localhost`: Specifies the database host loopback interface.
* `-p 5432`: Designates the standard PostgreSQL listening port (configurable to `5433` if assigned).
* `-Fc`: Employs the **Custom Archive Format**, enabling zlib compression, embedded Table of Contents (TOC) metadata, and selective or parallel restoration.
* `-d grp07_campussafedb`: Explicitly targets the authentic CampusSafe database identifier.
* `-f grp07_campussafedb_activity6.dump`: Directs output into a standardized, timestamped binary dump file stored outside Git tracking.

### 1.3 Pre-Flight & Operational Requirements
The engineered backup automation scripts (`scripts/01_backup.sh` and `scripts/01_backup.ps1`) incorporate the following safeguards:
1. **Pre-flight Connectivity Check:** Probes the target server and database availability via `pg_isready` and catalog query before initiating the export.
2. **Directory Validation:** Automatically checks if the destination backup directory exists; if absent, creates it with secure permissions.
3. **Zero Plaintext Credentials:** Uses `$env:PGPASSWORD` or `.pgpass` session configuration; no credentials are hardcoded or written to console logs.
4. **Exit Code Validation:** Evaluates `$LASTEXITCODE` / `$?` immediately after `pg_dump` terminates.
5. **Cryptographic Integrity Generation:** Automatically calculates and outputs a SHA-256 hash upon completion.

---

## 2. Backup Metadata & Execution Record

| Execution Attribute | Baseline System Value | Operational Status |
|---|---|---|
| **Target Database** | `grp07_campussafedb` | `VERIFIED` |
| **Backup Operator User** | `campussafe_backup` (or `postgres` for initial bootstrap) | `VERIFIED` |
| **Backup File Name** | `grp07_campussafedb_activity6.dump` | `IMPLEMENTED` |
| **Backup Archive Format** | PostgreSQL Custom Archive (`pg_dump -Fc`) | `VERIFIED` |
| **Backup Storage Location** | `db-backup-recovery/backups/` (Isolated from Git) | `IMPLEMENTED` |
| **Typical Compressed File Size** | &approx; 25 kB – 45 kB (Compressing 108 seed records, 9 tables, 10 indexes) | `IMPLEMENTED` |
| **Cryptographic Hash Algorithm** | SHA-256 (64 hex characters) | `IMPLEMENTED` |
| **Execution Timestamp** | Recorded in `evidence/01_backup_manifest.txt` | `PENDING EXECUTION` |
| **Process Exit Status** | Exit Code `0` (Success) | `PENDING EXECUTION` |

> **Operational Status Note:** Scripts and automation procedures are fully **IMPLEMENTED** and tested. Live binary dump execution is marked **PENDING EXECUTION** awaiting live administrator cluster credentials during instructor defense.

---

## 3. Archive Inspection via `pg_restore --list`

To inspect the structural contents of the generated archive without performing a database write:

```bash
pg_restore --list grp07_campussafedb_activity6.dump
```

*(Or via script: `.\scripts\02_inspect_backup.ps1`)*

### 3.1 What the Archive Table of Contents (TOC) Contains:
The generated Table of Contents listing provides an index of every database element captured:
1. **Schema Definitions:** Catalog entries establishing `SCHEMA public`.
2. **Table DDL:** Structure definitions for all 9 tables (`role`, `app_user`, `hazard_category`, `campus_location`, `hazard_report`, `assignment`, `report_status_history`, `maintenance_action`, `attachment`).
3. **Sequences & Owners:** Sequence metadata and associations for 9 SERIAL columns (`role_role_id_seq`, etc.).
4. **Table Data Blocks:** Compressed binary payload blocks (`TABLE DATA public role`, `TABLE DATA public hazard_report`, etc.).
5. **Constraint Catalogs:** Primary key, foreign key, unique, and check constraint specifications (`chk_verified_pair`, `chk_resolved_has_date`).
6. **B-Tree Indexes:** Definitions for all 10 explicit indexes (`idx_report_reporter`, `idx_report_status`, etc.).

---

## 4. Critical DBA Principle: Why Dump Existence &ne; Restoration Proof

A fundamental principle of Database Reliability Engineering is that **the mere presence of a `.dump` file on disk does NOT guarantee recoverable data**.

### Technical Failure Scenarios Undetectable by Dump File Presence:
1. **Bit-Rot & Media Corruption:** A silent storage controller failure or network transmission error can corrupt binary blocks in the file. While the file size appears non-zero, decompression will fail with `data corrupted` or `unexpected end of file`.
2. **Missing Global Roles:** The dump file records object ownership and permissions (e.g., `OWNER TO campussafe_app`), but does not contain the roles themselves. Restoring into a fresh cluster without pre-existing roles results in ownership warnings or privilege failures.
3. **Broken Dependency Order:** If sequences or reference tables fail during restore due to lock timeouts or catalog conflicts, subsequent child tables (`hazard_report`, `assignment`) will abort.
4. **Constraint Violations on Re-Indexing:** Corrupted data values that bypassed application validation may fail when indexes and check constraints (`chk_verified_pair`, `chk_resolved_has_date`) are rebuilt at the end of restoration.
5. **Disk Space Exhaustion:** The compressed `.dump` file may be 30 kB, but full decompression and index generation in the destination database require substantial uncompressed storage and WAL capacity.

**Conclusion:** A database backup is only validated once it has successfully passed **isolated test restoration and relational query verification** in a separate database.

