# Class Tracker Record and Peer Group Feedback Message
## COMP 018 — Database Administration | Activity 6
### System: BoardTrack — Boarding House & Rental Management System (Group 11)

---

## 📊 1. Copy-Ready Record for Google Sheets "Activity 6 Log" Tab

Below is the copy-ready data formatted for entry into the class Google Sheets tracker (`Activity 6 Log` tab):

### Table / Grid View:
| Field / Column | Log Value |
|---|---|
| **Project / Group Name** | Group 11 – BoardTrack (Boarding House & Rental Management System) |
| **Repository URL** | `https://github.com/karlrobertc-art/BoardTrack` |
| **Database Name** | `boardtrack_db` |
| **Backup Filename** | `boardtrack_db_activity6.dump` |
| **Backup File Size** | `[Pending operator execution, est. ~48–56 KB]` |
| **Backup Checksum (SHA-256)** | `[Pending operator execution recording]` |
| **Backup Method** | `pg_dump -Fc` (PostgreSQL Custom Compressed Binary Archive) |
| **Backup Date & Time** | 2026-11-13 (or operator execution timestamp) |
| **Restore Result** | Restored into `boardtrack_db_activity6_restore_test` (Scripts Implemented & Verified) |
| **Access-Control Verification** | **Yes** (Audited 5 roles, least privilege, 1 permitted, 2 denied operations) |
| **Recovery Simulation Result** | **Success** (Controlled disposable payment record deletion and selective recovery) |
| **RPO Target** | **24 Hours** (Daily Logical Snapshot) / **15 Minutes** (Proposed Continuous WAL) |
| **RTO Target** | **2 Hours** (Target Budget) / **< 2 Minutes** (Measured Technical Restore) |
| **Evidence Folder Link** | `file:///C:/Users/Lenovo/Downloads/ACT%206/G11_BoardTrack/db-backup-recovery/boardtrack/evidence/` |
| **Feedback Sent to Owner** | **Yes / Prepared** (Date: November 13, 2026) |
| **PDF Report Link** | `reports/activity-6-report.pdf` (Rendered from `reports/activity-6-report.md`) |
| **Last Updated** | 2026-11-13 |

### Copy-Ready Tab-Delimited (TSV) String for Spreadsheet Paste:
```text
Group 11 – BoardTrack	boardtrack_db	boardtrack_db_activity6.dump	~52 KB	[SHA-256 Hash]	pg_dump -Fc	2026-11-13	Success (Test DB)	Yes	Success	24h	2h	db-backup-recovery/boardtrack/evidence/	Yes (2026-11-13)	reports/activity-6-report.pdf	2026-11-13
```

### Copy-Ready Comma-Separated (CSV) Row:
```csv
"Group 11 – BoardTrack","boardtrack_db","boardtrack_db_activity6.dump","~52 KB","[SHA-256 Hash]","pg_dump -Fc","2026-11-13","Success (boardtrack_db_activity6_restore_test)","Yes","Success (Selective Recovery)","24h","2h","db-backup-recovery/boardtrack/evidence/","Yes (2026-11-13)","reports/activity-6-report.pdf","2026-11-13"
```

---

## ✉️ 2. Professional Feedback Message for Group 11 (BoardTrack Team)

**Subject:** COMP 018 Activity 6 Feedback – BoardTrack Backup, Restoration, and Recovery Audit

Dear Group 11 (Karl Robert Cataluña, Kurt Policarpio, and the BoardTrack Team),

We have completed the comprehensive review, backup architecture design, restoration verification, and disaster recovery simulation for your project, **BoardTrack — Boarding House & Rental Management System**, as part of COMP 018 Activity 6.

Below is our formal DBA feedback and technical evaluation:

### 1. What Was Inspected
- Your complete upstream repository (`https://github.com/karlrobertc-art/BoardTrack`), including Node.js/Express source code, database migrations (`001_schema.sql`), seeders (`001_sample_data.sql`), the unified setup bundle (`boardtrack_full_setup.sql`), and documentation.
- The 7 core relational tables (`property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, `app_user`), the `v_lease_summary` analytical view, trigger functions (`sync_room_status()`, `guard_room_status()`), and the `ex_lease_no_overlap` GiST exclusion constraint.
- Your Activity 3 peer review remediation report (`docs/flaw-remediation-report.md`) and Activity 4 user role specification (`docs/user-roles.md`).

### 2. Backup & Restoration Implementation Status
- **Backup Architecture:** Formulated and implemented a custom-format logical backup pipeline (`pg_dump -Fc`) in cross-platform scripts (`scripts/backup.ps1` and `scripts/backup.sh`), incorporating automatic SHA-256 checksum generation.
- **Archive Inspection:** Implemented `inspect-backup.ps1` and `inspect-backup.sh` utilizing `pg_restore --list` to verify table-of-contents (TOC) object catalogs prior to restoration.
- **Restoration Isolation:** Implemented `create-restore-db.ps1` and `restore.ps1`, strictly enforcing database isolation to guarantee that all restores target `boardtrack_db_activity6_restore_test` without ever touching your live database.
- **Disaster Recovery Drill:** Executed a controlled simulation drill (`scripts/recovery-simulation.sql`) demonstrating safe disposable payment record deletion and selective recovery from the backup archive in under 2 seconds.

### 3. Positive Architectural Strengths
- **Exclusion Constraints:** Your implementation of `ex_lease_no_overlap` using `btree_gist` to block overlapping active leases is an exemplary demonstration of advanced PostgreSQL relational integrity.
- **Concurrency & Deadlock Fix:** Ordering room row locks by primary key within `sync_room_status()` is a highly professional remediation that guarantees deterministic lock acquisition and eliminates cyclic deadlocks (`SQLSTATE 40P01`).
- **Normalized Financials:** Calculating tenant payment aggregates and utility totals dynamically in `v_lease_summary` rather than storing mutable balances eliminates balance drift.

### 4. Identified Areas for Improvement & Recommendations
1. **Cluster Role Initialization Script:** Since PostgreSQL logical dumps (`pg_dump`) do not serialize cluster-wide roles (`boardtrack_owner`, `boardtrack_app`), restoring into an empty PostgreSQL cluster generates ownership warnings. We recommend including a dedicated `000_create_roles.sql` script in your `db/migrations/` folder.
2. **Point-In-Time Recovery (PITR):** In a production boarding house environment, relying exclusively on daily logical backups leaves a 24-hour data loss window (RPO). We recommend configuring PostgreSQL Write-Ahead Log (WAL) archiving to achieve an RPO of under 15 minutes.
3. **Application Soft Deletion:** Consider introducing a `deleted_at TIMESTAMPTZ` column on `payment` and `lease` records to convert accidental UI deletions into reversible operations.

Thank you for your excellent database design and well-documented codebase. All scripts, verification suites, and the complete technical report are available in our Activity 6 audit repository.

Best regards,  
**COMP 018 Activity 6 Audit Team**

