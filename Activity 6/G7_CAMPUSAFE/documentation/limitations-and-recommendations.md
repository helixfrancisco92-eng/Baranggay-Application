# CampusSafe — Technical Limitations, Hardening Recommendations & Peer Feedback
## Assigned Project: Group 7 — CampusSafe
### Course: COMP 018 — Database Administration (Activity 6)

---

## 1. Technical Evaluation of Current Architecture

The CampusSafe relational database (`grp07_campussafedb`) engineered by Group 7 demonstrates remarkable maturity in relational design, data integrity enforcement, and access-control segmentation:

### Architectural Strengths:
1. **Strict Relational Domain Constraints:** The schema employs sophisticated check constraints (`chk_verified_pair`, `chk_resolved_has_date`) that guarantee state machine atomicity at the database engine level, independent of application logic.
2. **Explicit Foreign Key Indexing:** PostgreSQL does not automatically index foreign keys; Group 7 proactively created 10 targeted B-tree indexes covering high-frequency search and join predicates.
3. **Immutability of Audit Trails:** The Activity 4 RBAC design explicitly revokes UPDATE and DELETE privileges on `report_status_history` and `maintenance_action`, ensuring legal non-repudiation of campus incident logs.
4. **Credential Isolation:** The compliance auditor role (`campussafe_report`) is completely barred from querying `app_user`, safeguarding bcrypt password hashes.

---

## 2. Identified Limitations of the Logical Backup Strategy

While PostgreSQL custom archives (`pg_dump -Fc`) provide an excellent baseline, several technical limitations must be acknowledged:

### 2.1 The Point-in-Time Data Loss Gap (RPO Limit)
* **The Problem:** `pg_dump` takes a static, point-in-time snapshot. Backups scheduled at 01:00 AM daily leave a potential 24-hour vulnerability window. Any hazard reports filed or work orders completed between 01:01 AM and 11:59 PM would be unrecoverable if a total hardware failure occurs before the next scheduled snapshot.
* **Impact:** High-severity safety incidents submitted during daytime hours could be lost.

### 2.2 Global Cluster Roles Exclusion
* **The Problem:** `pg_dump` backs up only database-level objects. It does not export global cluster users, passwords, or role grants stored in `pg_authid`.
* **Impact:** In a true bare-metal recovery into a newly provisioned server, restoring the dump fails unless `database/03_roles_and_privileges.sql` is manually executed first.

### 2.3 Physical Evidence Decoupling (Binary File Assets)
* **The Problem:** The `attachment` table stores metadata (`file_name`, `mime_type`, `file_path_or_url`), but the actual image files reside in the host filesystem under `uploads/`.
* **Impact:** Restoring `grp07_campussafedb` restores the database rows, but if the `uploads/` directory is lost or corrupted, all photo evidence links will result in broken HTTP 404 images.

### 2.4 Single Point of Failure (Drive Colocation)
* **The Problem:** Storing backup archives on the same local physical disk as the PostgreSQL cluster data directory (`PGDATA`) creates vulnerability.
* **Impact:** Physical drive failure, ransomware, or local filesystem corruption destroys both the live database and its backups simultaneously.

---

## 3. Production Hardening Recommendations

To elevate CampusSafe to an enterprise-grade disaster-resilient system, we recommend the following five architectural improvements:

### Recommendation 1: Implement Write-Ahead Log (WAL) Continuous Archiving (Near-Zero RPO)
Enable WAL continuous archiving to transition from static 24-hour snapshots to continuous Point-in-Time Recovery (PITR):

```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'copy "%p" "D:\\pg_wal_archive\\%f"'
```
* **Benefit:** Enables restoring the database to the exact minute or transaction immediately prior to an accidental corruption or crash, reducing the RPO from 24 hours to under 5 minutes.

### Recommendation 2: Automate Global Roles Export (`pg_dumpall --globals-only`)
Integrate a dedicated cluster-level globals export alongside the nightly database dump:

```bash
pg_dumpall -U postgres -h localhost -p 5432 --globals-only -f backups/globals_backup.sql
```
* **Benefit:** Captures all cluster roles, group memberships, and global privileges in an executable SQL script, enabling 1-click account recreation during disaster recovery.

### Recommendation 3: Adopt the 3-2-1 Off-Site Backup Rule
1. Maintain **3 copies** of data (Live production, local backup snapshot, remote cloud backup).
2. Store on **2 different storage media types** (Local NVMe/SSD and Cloud Object Storage).
3. Keep **1 copy off-site** (e.g., AWS S3 Glacier, Google Cloud Storage, or Backblaze B2) with Object Lock (immutability) enabled to defend against ransomware.

### Recommendation 4: Synchronize File Storage with Cloud Object Storage
Refactor the file attachment handler in `public/attachment.php` to push evidence photos directly to an S3-compatible object storage service (e.g., Cloudflare R2 / AWS S3) rather than storing them in local `uploads/`.
* **Benefit:** Ensures that photo evidence attachments are versioned, globally replicated, and survive server destruction independently of the PostgreSQL instance.

### Recommendation 5: Automated Integrity Drills via CI/CD
Incorporate an automated monthly restore drill into GitHub Actions or local maintenance cron:
* Script spins up a temporary PostgreSQL Docker container, restores the latest backup, runs `scripts/05_verify_objects.sql` and `scripts/06_verify_records.sql`, and posts a success notification to the administrator dashboard.

---

## 4. Formal Peer Feedback for Group 7 (CampusSafe Owning Group)

* **To:** Group 7 (Jefferson Orpesa, Alba, Arreza, Robiso, Santos)
* **From:** Group 12 (Amoranto, Denielle; Francisco, Helix)
* **Evaluation Date:** November 13, 2026

**Commendations:**
* Your database schema is one of the cleanest and most structurally sound designs in COMP 018. The relational normalization, explicit foreign key indexes, and check constraints (`chk_verified_pair`, `chk_resolved_has_date`) reflect outstanding DBA engineering.
* Your Activity 4 least-privilege RBAC architecture (`app_runtime_grp`, `app_readonly_grp`, `app_backup_grp`) is exceptionally well-documented and completely aligns with enterprise security principles.
* Your 1-click web setup wizard (`install.php`) and automated batch installer (`setup.bat`) provide a flawless onboarding experience.

**Suggestions for Further Development:**
* Pair your `01_backup.ps1` script with an automated `pg_dumpall --globals-only` routine to eliminate manual role recreation during disaster failover.
* Consider implementing an automated cloud sync for the `uploads/` folder using rsync, rclone, or direct S3 SDK integration.

